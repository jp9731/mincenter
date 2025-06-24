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
	import { loadPosts, posts, postsPagination, hidePost } from '$lib/stores/admin';
	import type { Post } from '$lib/types/admin';

	let searchQuery = '';
	let boardFilter = '';
	let statusFilter = '';
	let currentPage = 1;

	onMount(() => {
		loadPosts({ page: 1, limit: 20 });
	});

	function handleSearch() {
		currentPage = 1;
		loadPosts({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			board_id: boardFilter,
			status: statusFilter
		});
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadPosts({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			board_id: boardFilter,
			status: statusFilter
		});
	}

	function handleHidePost(postId: string) {
		if (confirm('정말로 이 게시글을 숨기시겠습니까?')) {
			hidePost(postId, '관리자에 의한 숨김');
		}
	}

	function getStatusBadge(status: string) {
		switch (status) {
			case 'published':
				return { variant: 'default', text: '공개' };
			case 'hidden':
				return { variant: 'destructive', text: '숨김' };
			case 'draft':
				return { variant: 'secondary', text: '임시저장' };
			default:
				return { variant: 'outline', text: status };
		}
	}

	function truncateText(text: string, maxLength: number = 100) {
		if (text.length <= maxLength) return text;
		return text.substring(0, maxLength) + '...';
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">게시글 관리</h1>
			<p class="mt-2 text-gray-600">시스템의 모든 게시글을 관리합니다.</p>
		</div>
		<Button>새 게시글 작성</Button>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardHeader>
			<CardTitle>검색 및 필터</CardTitle>
			<CardDescription>게시글을 검색하고 필터링합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-4">
				<Input
					type="text"
					placeholder="제목, 내용, 작성자로 검색"
					bind:value={searchQuery}
					onkeydown={(e: any) => e.key === 'Enter' && handleSearch()}
				/>
				<Select
					type="single"
					value={boardFilter}
					onValueChange={(value: any) => {
						boardFilter = value;
						handleSearch();
					}}
				>
					<SelectTrigger>
						{boardFilter || '게시판 선택'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체</SelectItem>
						<SelectItem value="notice">공지사항</SelectItem>
						<SelectItem value="free">자유게시판</SelectItem>
						<SelectItem value="volunteer">봉사활동</SelectItem>
					</SelectContent>
				</Select>
				<Select
					type="single"
					value={statusFilter}
					onValueChange={(value: any) => {
						statusFilter = value;
						handleSearch();
					}}
				>
					<SelectTrigger>
						{statusFilter || '상태 선택'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체</SelectItem>
						<SelectItem value="published">공개</SelectItem>
						<SelectItem value="hidden">숨김</SelectItem>
						<SelectItem value="draft">임시저장</SelectItem>
					</SelectContent>
				</Select>
				<Button onclick={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 게시글 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>게시글 목록</CardTitle>
			<CardDescription>총 {$postsPagination.total}개의 게시글이 있습니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>제목</TableHead>
						<TableHead>작성자</TableHead>
						<TableHead>게시판</TableHead>
						<TableHead>상태</TableHead>
						<TableHead>작성일</TableHead>
						<TableHead>조회수</TableHead>
						<TableHead>댓글</TableHead>
						<TableHead>액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#each $posts as post}
						<TableRow>
							<TableCell>
								<div class="max-w-xs">
									<p class="truncate font-medium text-gray-900">
										{#if post.is_notice}<Badge variant="secondary" class="mr-2">공지</Badge>{/if}
										{post.title}
									</p>
									<p class="truncate text-sm text-gray-500">
										{truncateText(post.content)}
									</p>
								</div>
							</TableCell>
							<TableCell>
								<div class="flex items-center space-x-2">
									<div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-300">
										<span class="text-xs font-medium text-gray-700">
											{post.user_name?.[0] || 'U'}
										</span>
									</div>
									<span class="text-sm">{post.user_name}</span>
								</div>
							</TableCell>
							<TableCell>
								<Badge variant="outline">{post.board_name}</Badge>
							</TableCell>
							<TableCell>
								{@const statusBadge = getStatusBadge(post.status)}
								<Badge variant={statusBadge.variant}>{statusBadge.text}</Badge>
							</TableCell>
							<TableCell>
								{new Date(post.created_at).toLocaleDateString('ko-KR')}
							</TableCell>
							<TableCell>{post.views.toLocaleString()}</TableCell>
							<TableCell>{post.comment_count}</TableCell>
							<TableCell>
								<div class="flex space-x-2">
									{#if post.status === 'published'}
										<Button variant="outline" size="sm" onclick={() => handleHidePost(post.id)}>
											숨기기
										</Button>
									{:else if post.status === 'hidden'}
										<Button variant="outline" size="sm">공개</Button>
									{/if}
									<Button variant="outline" size="sm">상세보기</Button>
									<Button variant="outline" size="sm">수정</Button>
								</div>
							</TableCell>
						</TableRow>
					{/each}
				</TableBody>
			</Table>

			<!-- 페이지네이션 -->
			{#if $postsPagination.total_pages > 1}
				<div class="mt-6 flex justify-center">
					<div class="flex space-x-2">
						{#if currentPage > 1}
							<Button variant="outline" size="sm" onclick={() => handlePageChange(currentPage - 1)}>
								이전
							</Button>
						{/if}

						{#each Array.from({ length: $postsPagination.total_pages }, (_, i) => i + 1) as pageNum}
							<Button
								variant={currentPage === pageNum ? 'default' : 'outline'}
								size="sm"
								onclick={() => handlePageChange(pageNum)}
							>
								{pageNum}
							</Button>
						{/each}

						{#if currentPage < $postsPagination.total_pages}
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
