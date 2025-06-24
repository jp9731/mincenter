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
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { loadUsers, users, usersPagination, suspendUser, activateUser } from '$lib/stores/admin';
	import type { User } from '$lib/types/admin';

	let searchQuery = '';
	let statusFilter = '';
	let roleFilter = '';
	let currentPage = 1;

	onMount(() => {
		loadUsers({ page: 1, limit: 20 });
	});

	function handleSearch() {
		currentPage = 1;
		loadUsers({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			status: statusFilter,
			role: roleFilter
		});
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadUsers({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			status: statusFilter,
			role: roleFilter
		});
	}

	function handleSuspendUser(userId: string) {
		if (confirm('정말로 이 사용자를 정지하시겠습니까?')) {
			suspendUser(userId, '관리자에 의한 정지');
		}
	}

	function handleActivateUser(userId: string) {
		if (confirm('이 사용자를 활성화하시겠습니까?')) {
			activateUser(userId);
		}
	}

	function getStatusBadge(status: string) {
		switch (status) {
			case 'active':
				return { variant: 'default', text: '활성' };
			case 'suspended':
				return { variant: 'destructive', text: '정지' };
			case 'pending':
				return { variant: 'secondary', text: '대기' };
			default:
				return { variant: 'outline', text: status };
		}
	}

	function getRoleBadge(role: string) {
		switch (role) {
			case 'admin':
				return { variant: 'default', text: '관리자' };
			case 'moderator':
				return { variant: 'secondary', text: '모더레이터' };
			case 'user':
				return { variant: 'outline', text: '일반 사용자' };
			default:
				return { variant: 'outline', text: role };
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">사용자 관리</h1>
			<p class="mt-2 text-gray-600">시스템에 등록된 사용자들을 관리합니다.</p>
		</div>
		<Button>새 사용자 추가</Button>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardHeader>
			<CardTitle>검색 및 필터</CardTitle>
			<CardDescription>사용자를 검색하고 필터링합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-4">
				<Input
					type="text"
					placeholder="이름, 이메일, 사용자명으로 검색"
					bind:value={searchQuery}
					onkeydown={(e) => e.key === 'Enter' && handleSearch()}
				/>
				<Select
					type="single"
					value={statusFilter}
					onValueChange={(value) => {
						statusFilter = value;
						handleSearch();
					}}
				>
					<SelectTrigger>
						{statusFilter || '상태 선택'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체</SelectItem>
						<SelectItem value="active">활성</SelectItem>
						<SelectItem value="suspended">정지</SelectItem>
						<SelectItem value="pending">대기</SelectItem>
					</SelectContent>
				</Select>
				<Select
					type="single"
					value={roleFilter}
					onValueChange={(value) => {
						roleFilter = value;
						handleSearch();
					}}
				>
					<SelectTrigger>
						{roleFilter || '역할 선택'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체</SelectItem>
						<SelectItem value="user">일반 사용자</SelectItem>
						<SelectItem value="moderator">모더레이터</SelectItem>
						<SelectItem value="admin">관리자</SelectItem>
					</SelectContent>
				</Select>
				<Button onclick={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 사용자 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>사용자 목록</CardTitle>
			<CardDescription>총 {$usersPagination.total}명의 사용자가 있습니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>사용자</TableHead>
						<TableHead>이메일</TableHead>
						<TableHead>역할</TableHead>
						<TableHead>상태</TableHead>
						<TableHead>가입일</TableHead>
						<TableHead>게시글</TableHead>
						<TableHead>포인트</TableHead>
						<TableHead>액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#each $users as user}
						<TableRow>
							<TableCell>
								<div class="flex items-center space-x-3">
									<div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300">
										<span class="text-sm font-medium text-gray-700">
											{user.name?.[0] || user.username?.[0] || 'U'}
										</span>
									</div>
									<div>
										<p class="font-medium text-gray-900">{user.name}</p>
										<p class="text-sm text-gray-500">@{user.username}</p>
									</div>
								</div>
							</TableCell>
							<TableCell>{user.email}</TableCell>
							<TableCell>
								{@const roleBadge = getRoleBadge(user.role)}
								<Badge variant={roleBadge.variant}>{roleBadge.text}</Badge>
							</TableCell>
							<TableCell>
								{@const statusBadge = getStatusBadge(user.status)}
								<Badge variant={statusBadge.variant}>{statusBadge.text}</Badge>
							</TableCell>
							<TableCell>
								{new Date(user.created_at).toLocaleDateString('ko-KR')}
							</TableCell>
							<TableCell>{user.post_count}</TableCell>
							<TableCell>{user.point_balance.toLocaleString()}</TableCell>
							<TableCell>
								<div class="flex space-x-2">
									{#if user.status === 'active'}
										<Button variant="outline" size="sm" onclick={() => handleSuspendUser(user.id)}>
											정지
										</Button>
									{:else if user.status === 'suspended'}
										<Button variant="outline" size="sm" onclick={() => handleActivateUser(user.id)}>
											활성화
										</Button>
									{/if}
									<Button variant="outline" size="sm">상세보기</Button>
								</div>
							</TableCell>
						</TableRow>
					{/each}
				</TableBody>
			</Table>

			<!-- 페이지네이션 -->
			{#if $usersPagination.total_pages > 1}
				<div class="mt-6 flex justify-center">
					<div class="flex space-x-2">
						{#if currentPage > 1}
							<Button variant="outline" size="sm" onclick={() => handlePageChange(currentPage - 1)}>
								이전
							</Button>
						{/if}

						{#each Array.from({ length: $usersPagination.total_pages }, (_, i) => i + 1) as pageNum}
							<Button
								variant={currentPage === pageNum ? 'default' : 'outline'}
								size="sm"
								onclick={() => handlePageChange(pageNum)}
							>
								{pageNum}
							</Button>
						{/each}

						{#if currentPage < $usersPagination.total_pages}
							<Button variant="outline" size="sm" onclick={() => handlePageChange(currentPage + 1)}>
								다음
							</Button>
						{/if}
					</div>
				</div>
			{/if}
		</CardContent>
	</Card>
</div>
