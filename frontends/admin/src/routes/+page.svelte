<script lang="ts">
	import { page } from '$app/stores';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';

	export let data: { stats: any; error?: string };

	$: ({ stats, error: errorMessage } = data);
</script>

<svelte:head>
	<title>관리자 대시보드</title>
</svelte:head>

<div class="container mx-auto p-6">
	<div class="mb-8">
		<h1 class="text-3xl font-bold text-gray-900">관리자 대시보드</h1>
		<p class="mt-2 text-gray-600">사이트 현황을 한눈에 확인하세요</p>
	</div>

	{#if !stats && !errorMessage}
		<div class="flex h-64 items-center justify-center">
			<div class="text-gray-500">로딩 중...</div>
		</div>
	{:else if errorMessage}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4">
			<p class="text-red-600">{errorMessage}</p>
		</div>
	{:else if stats}
		<div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
			<Card>
				<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
					<CardTitle class="text-sm font-medium">총 사용자</CardTitle>
					<Badge variant="secondary">{stats.totalUsers}</Badge>
				</CardHeader>
				<CardContent>
					<div class="text-2xl font-bold">{stats.totalUsers}</div>
					<p class="text-muted-foreground text-xs">
						+{stats.newUsersThisMonth}명 이번 달
					</p>
				</CardContent>
			</Card>

			<Card>
				<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
					<CardTitle class="text-sm font-medium">총 게시글</CardTitle>
					<Badge variant="secondary">{stats.totalPosts}</Badge>
				</CardHeader>
				<CardContent>
					<div class="text-2xl font-bold">{stats.totalPosts}</div>
					<p class="text-muted-foreground text-xs">
						+{stats.newPostsThisMonth}개 이번 달
					</p>
				</CardContent>
			</Card>

			<Card>
				<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
					<CardTitle class="text-sm font-medium">총 댓글</CardTitle>
					<Badge variant="secondary">{stats.totalComments}</Badge>
				</CardHeader>
				<CardContent>
					<div class="text-2xl font-bold">{stats.totalComments}</div>
					<p class="text-muted-foreground text-xs">
						+{stats.newCommentsThisMonth}개 이번 달
					</p>
				</CardContent>
			</Card>

			<Card>
				<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
					<CardTitle class="text-sm font-medium">오늘 방문자</CardTitle>
					<Badge variant="secondary">{stats.todayVisitors}</Badge>
				</CardHeader>
				<CardContent>
					<div class="text-2xl font-bold">{stats.todayVisitors}</div>
					<p class="text-muted-foreground text-xs">
						+{stats.visitorIncrease}% 어제 대비
					</p>
				</CardContent>
			</Card>
		</div>

		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<Card>
				<CardHeader>
					<CardTitle>최근 게시글</CardTitle>
					<CardDescription>최근에 작성된 게시글 목록입니다</CardDescription>
				</CardHeader>
				<CardContent>
					{#if stats.recentPosts && stats.recentPosts.length > 0}
						<div class="space-y-4">
							{#each stats.recentPosts as post}
								<div class="flex items-center justify-between rounded-lg border p-3">
									<div>
										<h4 class="font-medium">{post.title}</h4>
										<p class="text-sm text-gray-500">{post.author} • {post.created_at}</p>
									</div>
									<Badge variant={post.board_name ? 'default' : 'secondary'}>
										{post.board_name || '일반'}
									</Badge>
								</div>
							{/each}
						</div>
					{:else}
						<p class="py-4 text-center text-gray-500">최근 게시글이 없습니다</p>
					{/if}
				</CardContent>
			</Card>

			<Card>
				<CardHeader>
					<CardTitle>시스템 상태</CardTitle>
					<CardDescription>서버 및 데이터베이스 상태입니다</CardDescription>
				</CardHeader>
				<CardContent>
					<div class="space-y-4">
						<div class="flex items-center justify-between">
							<span class="text-sm font-medium">서버 상태</span>
							<Badge variant="default" class="bg-green-100 text-green-800">정상</Badge>
						</div>
						<div class="flex items-center justify-between">
							<span class="text-sm font-medium">데이터베이스</span>
							<Badge variant="default" class="bg-green-100 text-green-800">정상</Badge>
						</div>
						<div class="flex items-center justify-between">
							<span class="text-sm font-medium">파일 저장소</span>
							<Badge variant="default" class="bg-green-100 text-green-800">정상</Badge>
						</div>
						<div class="flex items-center justify-between">
							<span class="text-sm font-medium">메모리 사용량</span>
							<Badge variant="secondary">{stats.memoryUsage || '45%'}</Badge>
						</div>
					</div>
				</CardContent>
			</Card>
		</div>
	{:else}
		<div class="rounded-lg border border-yellow-200 bg-yellow-50 p-4">
			<p class="text-yellow-600">데이터를 불러올 수 없습니다.</p>
		</div>
	{/if}
</div>
