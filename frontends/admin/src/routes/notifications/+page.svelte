<script lang="ts">
	import { onMount } from 'svelte';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import {
		Dialog,
		DialogContent,
		DialogDescription,
		DialogFooter,
		DialogHeader,
		DialogTitle,
		DialogTrigger
	} from '$lib/components/ui/dialog';
	import { Textarea } from '$lib/components/ui/textarea';
	import {
		loadNotifications,
		notifications,
		notificationsPagination,
		isLoading,
		error
	} from '$lib/stores/admin';
	import * as adminApi from '$lib/api/admin.js';
	import type { Notification } from '$lib/types/admin.js';

	let searchQuery = '';
	let typeFilter = '';
	let currentPage = 1;
	let showCreateDialog = false;
	let showDetailDialog = false;
	let selectedNotification: Notification | null = null;

	// 새 알림 데이터
	let newNotification = {
		title: '',
		message: '',
		type: 'info' as const,
		target_users: 'all' as const,
		target_user_ids: [] as string[]
	};

	onMount(() => {
		loadNotifications({ page: 1, limit: 20 });
	});

	function handleSearch() {
		currentPage = 1;
		loadNotifications({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			type: typeFilter
		});
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadNotifications({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			type: typeFilter
		});
	}

	function handleCreateNotification() {
		if (!newNotification.title || !newNotification.message) {
			return;
		}

		adminApi
			.createNotification(newNotification)
			.then(() => {
				loadNotifications({
					page: currentPage,
					limit: 20,
					search: searchQuery,
					type: typeFilter
				});
				showCreateDialog = false;
				newNotification = {
					title: '',
					message: '',
					type: 'info',
					target_users: 'all',
					target_user_ids: []
				};
			})
			.catch((e: any) => {
				console.error('알림 생성 실패:', e);
			});
	}

	function handleSendNotification(notificationId: string) {
		if (confirm('이 알림을 발송하시겠습니까?')) {
			adminApi
				.sendNotification(notificationId)
				.then(() => {
					loadNotifications({
						page: currentPage,
						limit: 20,
						search: searchQuery,
						type: typeFilter
					});
				})
				.catch((e: any) => {
					console.error('알림 발송 실패:', e);
				});
		}
	}

	function openDetailDialog(notification: Notification) {
		selectedNotification = notification;
		showDetailDialog = true;
	}

	function closeCreateDialog() {
		showCreateDialog = false;
	}

	function closeDetailDialog() {
		showDetailDialog = false;
		selectedNotification = null;
	}

	function getTypeBadge(type: string) {
		switch (type) {
			case 'info':
				return { variant: 'default' as const, text: '정보' };
			case 'success':
				return { variant: 'default' as const, text: '성공' };
			case 'warning':
				return { variant: 'secondary' as const, text: '경고' };
			case 'error':
				return { variant: 'destructive' as const, text: '오류' };
			default:
				return { variant: 'outline' as const, text: type };
		}
	}

	function getTargetBadge(target: string) {
		switch (target) {
			case 'all':
				return { variant: 'default' as const, text: '전체' };
			case 'admins':
				return { variant: 'secondary' as const, text: '관리자' };
			case 'specific':
				return { variant: 'outline' as const, text: '특정 사용자' };
			default:
				return { variant: 'outline' as const, text: target };
		}
	}

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleString('ko-KR');
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">알림 관리</h1>
			<p class="mt-2 text-gray-600">시스템 알림을 생성하고 관리합니다.</p>
		</div>
		<Dialog bind:open={showCreateDialog}>
			<DialogTrigger>
				<Button>새 알림 생성</Button>
			</DialogTrigger>
			<DialogContent class="sm:max-w-[500px]">
				<DialogHeader>
					<DialogTitle>새 알림 생성</DialogTitle>
					<DialogDescription>새로운 알림을 생성합니다.</DialogDescription>
				</DialogHeader>
				<div class="grid gap-4 py-4">
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="title" class="text-right">제목</label>
						<Input id="title" bind:value={newNotification.title} class="col-span-3" />
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="message" class="text-right">메시지</label>
						<Textarea id="message" bind:value={newNotification.message} class="col-span-3" />
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="type" class="text-right">타입</label>
						<select
							bind:value={newNotification.type}
							class="border-input bg-background col-span-3 rounded-md border px-3 py-2"
						>
							<option value="info">정보</option>
							<option value="success">성공</option>
							<option value="warning">경고</option>
							<option value="error">오류</option>
						</select>
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="target" class="text-right">대상</label>
						<select
							bind:value={newNotification.target_users}
							class="border-input bg-background col-span-3 rounded-md border px-3 py-2"
						>
							<option value="all">전체 사용자</option>
							<option value="admins">관리자만</option>
							<option value="specific">특정 사용자</option>
						</select>
					</div>
				</div>
				<DialogFooter>
					<Button variant="outline" on:click={closeCreateDialog}>취소</Button>
					<Button on:click={handleCreateNotification}>생성</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardHeader>
			<CardTitle>검색 및 필터</CardTitle>
			<CardDescription>알림을 검색하고 필터링합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
				<Input type="text" placeholder="알림 제목, 메시지로 검색" bind:value={searchQuery} />
				<select
					bind:value={typeFilter}
					class="border-input bg-background rounded-md border px-3 py-2"
				>
					<option value="">전체 타입</option>
					<option value="info">정보</option>
					<option value="success">성공</option>
					<option value="warning">경고</option>
					<option value="error">오류</option>
				</select>
				<Button on:click={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 알림 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>알림 목록</CardTitle>
			<CardDescription
				>총 {$notificationsPagination.total || 0}개의 알림이 있습니다.</CardDescription
			>
		</CardHeader>
		<CardContent>
			{#if $isLoading}
				<div class="flex items-center justify-center py-8">
					<div class="h-8 w-8 animate-spin rounded-full border-b-2 border-blue-600"></div>
					<span class="ml-2 text-gray-600">로딩 중...</span>
				</div>
			{:else if $error}
				<div class="rounded-md border border-red-200 bg-red-50 p-4">
					<p class="text-red-700">{$error}</p>
				</div>
			{:else}
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>제목</TableHead>
							<TableHead>메시지</TableHead>
							<TableHead>타입</TableHead>
							<TableHead>대상</TableHead>
							<TableHead>읽은 수</TableHead>
							<TableHead>발송일</TableHead>
							<TableHead>액션</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{#each $notifications as notification}
							{@const typeBadge = getTypeBadge(notification.type)}
							{@const targetBadge = getTargetBadge(notification.target_users)}
							<TableRow>
								<TableCell class="font-medium">{notification.title}</TableCell>
								<TableCell>
									<div class="max-w-xs">
										<p class="truncate text-sm text-gray-900">{notification.message}</p>
									</div>
								</TableCell>
								<TableCell>
									<Badge variant={typeBadge.variant}>{typeBadge.text}</Badge>
								</TableCell>
								<TableCell>
									<Badge variant={targetBadge.variant}>{targetBadge.text}</Badge>
								</TableCell>
								<TableCell>{notification.read_count}</TableCell>
								<TableCell>
									{notification.sent_at ? formatDate(notification.sent_at) : '미발송'}
								</TableCell>
								<TableCell>
									<div class="flex space-x-2">
										{#if !notification.sent_at}
											<Button
												variant="outline"
												size="sm"
												on:click={() => handleSendNotification(notification.id)}
											>
												발송
											</Button>
										{/if}
										<Button
											variant="outline"
											size="sm"
											on:click={() => openDetailDialog(notification)}
										>
											상세
										</Button>
									</div>
								</TableCell>
							</TableRow>
						{/each}
					</TableBody>
				</Table>

				<!-- 페이지네이션 -->
				{#if ($notificationsPagination.total_pages || 0) > 1}
					<div class="mt-6 flex items-center justify-between">
						<div class="text-sm text-gray-700">
							페이지 {$notificationsPagination.page} / {$notificationsPagination.total_pages}
						</div>
						<div class="flex space-x-2">
							{#if $notificationsPagination.page > 1}
								<Button
									variant="outline"
									size="sm"
									on:click={() => handlePageChange($notificationsPagination.page - 1)}
								>
									이전
								</Button>
							{/if}
							{#if $notificationsPagination.page < ($notificationsPagination.total_pages || 0)}
								<Button
									variant="outline"
									size="sm"
									on:click={() => handlePageChange($notificationsPagination.page + 1)}
								>
									다음
								</Button>
							{/if}
						</div>
					</div>
				{/if}
			{/if}
		</CardContent>
	</Card>
</div>

<!-- 알림 상세 다이얼로그 -->
<Dialog bind:open={showDetailDialog}>
	<DialogContent class="sm:max-w-[500px]">
		<DialogHeader>
			<DialogTitle>알림 상세 정보</DialogTitle>
			<DialogDescription>알림의 상세 정보를 확인합니다.</DialogDescription>
		</DialogHeader>
		{#if selectedNotification}
			{@const typeBadge = getTypeBadge(selectedNotification.type)}
			{@const targetBadge = getTargetBadge(selectedNotification.target_users)}
			<div class="space-y-4">
				<div>
					<label class="text-sm font-medium text-gray-700">제목</label>
					<p class="mt-1 text-sm text-gray-900">{selectedNotification.title}</p>
				</div>
				<div>
					<label class="text-sm font-medium text-gray-700">메시지</label>
					<div class="mt-1 rounded-md border border-gray-200 bg-gray-50 p-3">
						<p class="whitespace-pre-wrap text-sm text-gray-900">{selectedNotification.message}</p>
					</div>
				</div>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="text-sm font-medium text-gray-700">타입</label>
						<div class="mt-1">
							<Badge variant={typeBadge.variant}>{typeBadge.text}</Badge>
						</div>
					</div>
					<div>
						<label class="text-sm font-medium text-gray-700">대상</label>
						<div class="mt-1">
							<Badge variant={targetBadge.variant}>{targetBadge.text}</Badge>
						</div>
					</div>
				</div>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="text-sm font-medium text-gray-700">읽은 수</label>
						<p class="mt-1 text-sm text-gray-900">{selectedNotification.read_count}</p>
					</div>
					<div>
						<label class="text-sm font-medium text-gray-700">생성일</label>
						<p class="mt-1 text-sm text-gray-900">{formatDate(selectedNotification.created_at)}</p>
					</div>
				</div>
				{#if selectedNotification.sent_at}
					<div>
						<label class="text-sm font-medium text-gray-700">발송일</label>
						<p class="mt-1 text-sm text-gray-900">{formatDate(selectedNotification.sent_at)}</p>
					</div>
				{/if}
			</div>
		{/if}
		<DialogFooter>
			<Button variant="outline" on:click={closeDetailDialog}>닫기</Button>
			{#if selectedNotification && !selectedNotification.sent_at}
				<Button
					variant="default"
					on:click={() => {
						handleSendNotification(selectedNotification.id);
						closeDetailDialog();
					}}
				>
					발송
				</Button>
			{/if}
		</DialogFooter>
	</DialogContent>
</Dialog>
