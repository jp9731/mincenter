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
	import { Switch } from '$lib/components/ui/switch';
	import {
		loadVolunteerActivities,
		volunteerActivities,
		volunteerPagination,
		isLoading,
		error
	} from '$lib/stores/admin';
	import * as adminApi from '$lib/api/admin.js';
	import type { VolunteerActivity } from '$lib/types/admin.js';
	import { PlusIcon, UsersIcon, CalendarIcon, ChartBarIcon } from 'lucide-svelte';

	let searchQuery = '';
	let statusFilter = '';
	let currentPage = 1;
	let showCreateDialog = false;
	let showEditDialog = false;
	let selectedActivity: VolunteerActivity | null = null;

	// 새 봉사 활동 데이터
	let newActivity = {
		title: '',
		description: '',
		date: '',
		location: '',
		max_volunteers: 10,
		status: 'upcoming' as const
	};

	// 편집용 봉사 활동 데이터
	let editActivity = {
		title: '',
		description: '',
		date: '',
		location: '',
		max_volunteers: 10,
		status: 'upcoming' as const
	};

	// 임시 봉사 데이터
	const volunteerStats = {
		total_applications: 45,
		active_volunteers: 28,
		completed_activities: 156,
		total_hours: 1247
	};

	onMount(() => {
		loadVolunteerActivities({ page: 1, limit: 20 });
	});

	function handleSearch() {
		currentPage = 1;
		loadVolunteerActivities({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			status: statusFilter
		});
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadVolunteerActivities({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			status: statusFilter
		});
	}

	function handleCreateActivity() {
		if (
			!newActivity.title ||
			!newActivity.description ||
			!newActivity.date ||
			!newActivity.location
		) {
			return;
		}

		adminApi
			.createVolunteerActivity(newActivity)
			.then(() => {
				loadVolunteerActivities({
					page: currentPage,
					limit: 20,
					search: searchQuery,
					status: statusFilter
				});
				showCreateDialog = false;
				newActivity = {
					title: '',
					description: '',
					date: '',
					location: '',
					max_volunteers: 10,
					status: 'upcoming'
				};
			})
			.catch((e: any) => {
				console.error('봉사 활동 생성 실패:', e);
			});
	}

	function handleEditActivity() {
		if (
			!selectedActivity ||
			!editActivity.title ||
			!editActivity.description ||
			!editActivity.date ||
			!editActivity.location
		) {
			return;
		}

		adminApi
			.updateVolunteerActivity(selectedActivity.id, editActivity)
			.then(() => {
				loadVolunteerActivities({
					page: currentPage,
					limit: 20,
					search: searchQuery,
					status: statusFilter
				});
				showEditDialog = false;
				selectedActivity = null;
			})
			.catch((e: any) => {
				console.error('봉사 활동 수정 실패:', e);
			});
	}

	function handleDeleteActivity(activityId: string) {
		if (confirm('이 봉사 활동을 삭제하시겠습니까?')) {
			adminApi
				.deleteVolunteerActivity(activityId)
				.then(() => {
					loadVolunteerActivities({
						page: currentPage,
						limit: 20,
						search: searchQuery,
						status: statusFilter
					});
				})
				.catch((e: any) => {
					console.error('봉사 활동 삭제 실패:', e);
				});
		}
	}

	function openEditDialog(activity: VolunteerActivity) {
		selectedActivity = activity;
		editActivity = {
			title: activity.title,
			description: activity.description,
			date: activity.date,
			location: activity.location,
			max_volunteers: activity.max_volunteers,
			status: activity.status
		};
		showEditDialog = true;
	}

	function closeCreateDialog() {
		showCreateDialog = false;
	}

	function closeEditDialog() {
		showEditDialog = false;
	}

	function getStatusBadge(status: string) {
		switch (status) {
			case 'upcoming':
				return { variant: 'default' as const, text: '예정' };
			case 'ongoing':
				return { variant: 'secondary' as const, text: '진행중' };
			case 'completed':
				return { variant: 'outline' as const, text: '완료' };
			case 'cancelled':
				return { variant: 'destructive' as const, text: '취소' };
			default:
				return { variant: 'outline' as const, text: status };
		}
	}

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleDateString('ko-KR');
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">봉사 활동 관리</h1>
			<p class="mt-2 text-gray-600">봉사 활동을 관리하고 모니터링합니다.</p>
		</div>
		<Dialog bind:open={showCreateDialog}>
			<DialogTrigger>
				<Button>새 봉사 활동 생성</Button>
			</DialogTrigger>
			<DialogContent class="sm:max-w-[500px]">
				<DialogHeader>
					<DialogTitle>새 봉사 활동 생성</DialogTitle>
					<DialogDescription>새로운 봉사 활동을 생성합니다.</DialogDescription>
				</DialogHeader>
				<div class="grid gap-4 py-4">
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="title" class="text-right">제목</label>
						<Input id="title" bind:value={newActivity.title} class="col-span-3" />
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="description" class="text-right">설명</label>
						<Textarea id="description" bind:value={newActivity.description} class="col-span-3" />
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="date" class="text-right">날짜</label>
						<Input id="date" type="date" bind:value={newActivity.date} class="col-span-3" />
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="location" class="text-right">장소</label>
						<Input id="location" bind:value={newActivity.location} class="col-span-3" />
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="max_volunteers" class="text-right">최대 인원</label>
						<Input
							id="max_volunteers"
							type="number"
							bind:value={newActivity.max_volunteers}
							class="col-span-3"
						/>
					</div>
					<div class="grid grid-cols-4 items-center gap-4">
						<label for="status" class="text-right">상태</label>
						<select
							bind:value={newActivity.status}
							class="border-input bg-background col-span-3 rounded-md border px-3 py-2"
						>
							<option value="upcoming">예정</option>
							<option value="ongoing">진행중</option>
							<option value="completed">완료</option>
							<option value="cancelled">취소</option>
						</select>
					</div>
				</div>
				<DialogFooter>
					<Button variant="outline" onclick={closeCreateDialog}>취소</Button>
					<Button onclick={handleCreateActivity}>생성</Button>
				</DialogFooter>
			</DialogContent>
		</Dialog>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardHeader>
			<CardTitle>검색 및 필터</CardTitle>
			<CardDescription>봉사 활동을 검색하고 필터링합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
				<Input type="text" placeholder="활동 제목, 설명으로 검색" bind:value={searchQuery} />
				<select
					bind:value={statusFilter}
					class="border-input bg-background rounded-md border px-3 py-2"
				>
					<option value="">전체 상태</option>
					<option value="upcoming">예정</option>
					<option value="ongoing">진행중</option>
					<option value="completed">완료</option>
					<option value="cancelled">취소</option>
				</select>
				<Button on:click={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 봉사 활동 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>봉사 활동 목록</CardTitle>
			<CardDescription
				>총 {$volunteerPagination.total || 0}개의 봉사 활동이 있습니다.</CardDescription
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
							<TableHead>날짜</TableHead>
							<TableHead>장소</TableHead>
							<TableHead>봉사자</TableHead>
							<TableHead>상태</TableHead>
							<TableHead>생성일</TableHead>
							<TableHead>액션</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{#each $volunteerActivities as activity}
							{@const statusBadge = getStatusBadge(activity.status)}
							<TableRow>
								<TableCell class="font-medium">{activity.title}</TableCell>
								<TableCell>{formatDate(activity.date)}</TableCell>
								<TableCell>{activity.location}</TableCell>
								<TableCell>
									{activity.volunteer_count} / {activity.max_volunteers}
								</TableCell>
								<TableCell>
									<Badge variant={statusBadge.variant}>{statusBadge.text}</Badge>
								</TableCell>
								<TableCell>{formatDate(activity.created_at)}</TableCell>
								<TableCell>
									<div class="flex space-x-2">
										<Button variant="outline" size="sm" on:click={() => openEditDialog(activity)}>
											수정
										</Button>
										<Button
											variant="outline"
											size="sm"
											on:click={() => handleDeleteActivity(activity.id)}
										>
											삭제
										</Button>
									</div>
								</TableCell>
							</TableRow>
						{/each}
					</TableBody>
				</Table>

				<!-- 페이지네이션 -->
				{#if ($volunteerPagination.total_pages || 0) > 1}
					<div class="mt-6 flex items-center justify-between">
						<div class="text-sm text-gray-700">
							페이지 {$volunteerPagination.page} / {$volunteerPagination.total_pages}
						</div>
						<div class="flex space-x-2">
							{#if $volunteerPagination.page > 1}
								<Button
									variant="outline"
									size="sm"
									on:click={() => handlePageChange($volunteerPagination.page - 1)}
								>
									이전
								</Button>
							{/if}
							{#if $volunteerPagination.page < ($volunteerPagination.total_pages || 0)}
								<Button
									variant="outline"
									size="sm"
									on:click={() => handlePageChange($volunteerPagination.page + 1)}
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

	<!-- 통계 카드 -->
	<div class="grid grid-cols-1 gap-6 md:grid-cols-4">
		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-blue-100 p-2">
						<UsersIcon class="h-6 w-6 text-blue-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 신청자</p>
						<p class="text-2xl font-bold text-gray-900">{volunteerStats.total_applications}</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-green-100 p-2">
						<UsersIcon class="h-6 w-6 text-green-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">활성 봉사자</p>
						<p class="text-2xl font-bold text-gray-900">{volunteerStats.active_volunteers}</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-purple-100 p-2">
						<CalendarIcon class="h-6 w-6 text-purple-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">완료 활동</p>
						<p class="text-2xl font-bold text-gray-900">{volunteerStats.completed_activities}</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-orange-100 p-2">
						<ChartBarIcon class="h-6 w-6 text-orange-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 봉사시간</p>
						<p class="text-2xl font-bold text-gray-900">{volunteerStats.total_hours}h</p>
					</div>
				</div>
			</CardContent>
		</Card>
	</div>

	<!-- 관리 메뉴 -->
	<div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<UsersIcon class="mr-2 h-5 w-5" />
					신청자 목록
				</CardTitle>
				<CardDescription>봉사 신청자들을 관리합니다</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/volunteer/applications" class="w-full">관리하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<CalendarIcon class="mr-2 h-5 w-5" />
					실행 내역
				</CardTitle>
				<CardDescription>봉사 활동 실행 내역 및 평가</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/volunteer/activities" class="w-full">관리하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<UsersIcon class="mr-2 h-5 w-5" />
					출석 관리
				</CardTitle>
				<CardDescription>봉사자별 출석 관리</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/volunteer/attendance" class="w-full">관리하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<ChartBarIcon class="mr-2 h-5 w-5" />
					평가 관리
				</CardTitle>
				<CardDescription>봉사자별 개별 평가</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/volunteer/evaluations" class="w-full">관리하기</Button>
			</CardContent>
		</Card>
	</div>
</div>

<!-- 편집 다이얼로그 -->
<Dialog bind:open={showEditDialog}>
	<DialogContent class="sm:max-w-[500px]">
		<DialogHeader>
			<DialogTitle>봉사 활동 수정</DialogTitle>
			<DialogDescription>봉사 활동 정보를 수정합니다.</DialogDescription>
		</DialogHeader>
		<div class="grid gap-4 py-4">
			<div class="grid grid-cols-4 items-center gap-4">
				<label for="edit-title" class="text-right">제목</label>
				<Input id="edit-title" bind:value={editActivity.title} class="col-span-3" />
			</div>
			<div class="grid grid-cols-4 items-center gap-4">
				<label for="edit-description" class="text-right">설명</label>
				<Textarea id="edit-description" bind:value={editActivity.description} class="col-span-3" />
			</div>
			<div class="grid grid-cols-4 items-center gap-4">
				<label for="edit-date" class="text-right">날짜</label>
				<Input id="edit-date" type="date" bind:value={editActivity.date} class="col-span-3" />
			</div>
			<div class="grid grid-cols-4 items-center gap-4">
				<label for="edit-location" class="text-right">장소</label>
				<Input id="edit-location" bind:value={editActivity.location} class="col-span-3" />
			</div>
			<div class="grid grid-cols-4 items-center gap-4">
				<label for="edit-max_volunteers" class="text-right">최대 인원</label>
				<Input
					id="edit-max_volunteers"
					type="number"
					bind:value={editActivity.max_volunteers}
					class="col-span-3"
				/>
			</div>
			<div class="grid grid-cols-4 items-center gap-4">
				<label for="edit-status" class="text-right">상태</label>
				<select
					bind:value={editActivity.status}
					class="border-input bg-background col-span-3 rounded-md border px-3 py-2"
				>
					<option value="upcoming">예정</option>
					<option value="ongoing">진행중</option>
					<option value="completed">완료</option>
					<option value="cancelled">취소</option>
				</select>
			</div>
		</div>
		<DialogFooter>
			<Button variant="outline" on:click={closeEditDialog}>취소</Button>
			<Button on:click={handleEditActivity}>수정</Button>
		</DialogFooter>
	</DialogContent>
</Dialog>
