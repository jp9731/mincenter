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
		loadComments,
		comments,
		commentsPagination,
		isLoading,
		error,
		hideComment
	} from '$lib/stores/admin';
	import * as adminApi from '$lib/api/admin.js';
	import type { Comment } from '$lib/types/admin.js';

	let searchQuery = '';
	let statusFilter = '';
	let currentPage = 1;
	let showDetailDialog = false;
	let selectedComment: Comment | null = null;

	onMount(() => {
		loadComments({ page: 1, limit: 20 });
	});

	function handleSearch() {
		currentPage = 1;
		loadComments({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			status: statusFilter
		});
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadComments({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			status: statusFilter
		});
	}

	function handleHideComment(commentId: string) {
		if (confirm('이 댓글을 숨기시겠습니까?')) {
			hideComment(commentId, '관리자에 의한 숨김 처리');
		}
	}

	function handleDeleteComment(commentId: string) {
		if (confirm('이 댓글을 삭제하시겠습니까?')) {
			adminApi
				.deleteComment(commentId)
				.then(() => {
					loadComments({
						page: currentPage,
						limit: 20,
						search: searchQuery,
						status: statusFilter
					});
				})
				.catch((e: any) => {
					console.error('댓글 삭제 실패:', e);
				});
		}
	}

	function openDetailDialog(comment: Comment) {
		selectedComment = comment;
		showDetailDialog = true;
	}

	function closeDetailDialog() {
		showDetailDialog = false;
		selectedComment = null;
	}

	function getStatusBadge(status: string) {
		switch (status) {
			case 'published':
				return { variant: 'default' as const, text: '공개' };
			case 'hidden':
				return { variant: 'secondary' as const, text: '숨김' };
			default:
				return { variant: 'outline' as const, text: status };
		}
	}

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleString('ko-KR');
	}

	function truncateText(text: string, maxLength: number = 100) {
		return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			handleSearch();
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">댓글 관리</h1>
			<p class="mt-2 text-gray-600">사용자 댓글을 관리하고 모더레이션합니다.</p>
		</div>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardHeader>
			<CardTitle>검색 및 필터</CardTitle>
			<CardDescription>댓글을 검색하고 필터링합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
				<Input
					type="text"
					placeholder="댓글 내용, 작성자로 검색"
					bind:value={searchQuery}
					on:keydown={handleKeydown}
				/>
				<select
					bind:value={statusFilter}
					class="border-input bg-background rounded-md border px-3 py-2"
				>
					<option value="">전체 상태</option>
					<option value="published">공개</option>
					<option value="hidden">숨김</option>
				</select>
				<Button on:click={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 댓글 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>댓글 목록</CardTitle>
			<CardDescription>총 {$commentsPagination.total || 0}개의 댓글이 있습니다.</CardDescription>
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
							<TableHead>작성자</TableHead>
							<TableHead>댓글 내용</TableHead>
							<TableHead>게시글</TableHead>
							<TableHead>좋아요</TableHead>
							<TableHead>상태</TableHead>
							<TableHead>작성일</TableHead>
							<TableHead>액션</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{#each $comments as comment}
							{@const statusBadge = getStatusBadge(comment.status)}
							<TableRow>
								<TableCell>
									<div class="flex items-center space-x-3">
										<div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300">
											<span class="text-sm font-medium text-gray-700">
												{comment.user_name?.[0] || 'U'}
											</span>
										</div>
										<div>
											<p class="font-medium text-gray-900">{comment.user_name}</p>
											<p class="text-sm text-gray-500">ID: {comment.user_id}</p>
										</div>
									</div>
								</TableCell>
								<TableCell>
									<div class="max-w-xs">
										<p class="text-sm text-gray-900">{truncateText(comment.content)}</p>
										<Button variant="link" size="sm" on:click={() => openDetailDialog(comment)}>
											전체 보기
										</Button>
									</div>
								</TableCell>
								<TableCell>
									<div class="max-w-xs">
										<p class="text-sm font-medium text-gray-900">{comment.post_title}</p>
										<p class="text-xs text-gray-500">ID: {comment.post_id}</p>
									</div>
								</TableCell>
								<TableCell>{comment.likes}</TableCell>
								<TableCell>
									<Badge variant={statusBadge.variant}>{statusBadge.text}</Badge>
								</TableCell>
								<TableCell>{formatDate(comment.created_at)}</TableCell>
								<TableCell>
									<div class="flex space-x-2">
										{#if comment.status === 'published'}
											<Button
												variant="outline"
												size="sm"
												on:click={() => handleHideComment(comment.id)}
											>
												숨기기
											</Button>
										{/if}
										<Button variant="outline" size="sm" on:click={() => openDetailDialog(comment)}>
											상세
										</Button>
										<Button
											variant="outline"
											size="sm"
											on:click={() => handleDeleteComment(comment.id)}
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
				{#if ($commentsPagination.total_pages || 0) > 1}
					<div class="mt-6 flex items-center justify-between">
						<div class="text-sm text-gray-700">
							페이지 {$commentsPagination.page} / {$commentsPagination.total_pages}
						</div>
						<div class="flex space-x-2">
							{#if $commentsPagination.page > 1}
								<Button
									variant="outline"
									size="sm"
									on:click={() => handlePageChange($commentsPagination.page - 1)}
								>
									이전
								</Button>
							{/if}
							{#if $commentsPagination.page < ($commentsPagination.total_pages || 0)}
								<Button
									variant="outline"
									size="sm"
									on:click={() => handlePageChange($commentsPagination.page + 1)}
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

<!-- 댓글 상세 다이얼로그 -->
<Dialog bind:open={showDetailDialog}>
	<DialogContent class="sm:max-w-[600px]">
		<DialogHeader>
			<DialogTitle>댓글 상세 정보</DialogTitle>
			<DialogDescription>댓글의 상세 정보를 확인합니다.</DialogDescription>
		</DialogHeader>
		{#if selectedComment}
			{@const statusBadge = getStatusBadge(selectedComment.status)}
			<div class="space-y-4">
				<div>
					<label class="text-sm font-medium text-gray-700">작성자</label>
					<p class="mt-1 text-sm text-gray-900">
						{selectedComment.user_name} (ID: {selectedComment.user_id})
					</p>
				</div>
				<div>
					<label class="text-sm font-medium text-gray-700">게시글</label>
					<p class="mt-1 text-sm text-gray-900">{selectedComment.post_title}</p>
					<p class="text-xs text-gray-500">게시글 ID: {selectedComment.post_id}</p>
				</div>
				<div>
					<label class="text-sm font-medium text-gray-700">댓글 내용</label>
					<div class="mt-1 rounded-md border border-gray-200 bg-gray-50 p-3">
						<p class="whitespace-pre-wrap text-sm text-gray-900">{selectedComment.content}</p>
					</div>
				</div>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="text-sm font-medium text-gray-700">좋아요 수</label>
						<p class="mt-1 text-sm text-gray-900">{selectedComment.likes}</p>
					</div>
					<div>
						<label class="text-sm font-medium text-gray-700">상태</label>
						<div class="mt-1">
							<Badge variant={statusBadge.variant}>{statusBadge.text}</Badge>
						</div>
					</div>
				</div>
				<div class="grid grid-cols-2 gap-4">
					<div>
						<label class="text-sm font-medium text-gray-700">작성일</label>
						<p class="mt-1 text-sm text-gray-900">{formatDate(selectedComment.created_at)}</p>
					</div>
					{#if selectedComment.updated_at}
						<div>
							<label class="text-sm font-medium text-gray-700">수정일</label>
							<p class="mt-1 text-sm text-gray-900">{formatDate(selectedComment.updated_at)}</p>
						</div>
					{/if}
				</div>
			</div>
		{/if}
		<DialogFooter>
			<Button variant="outline" on:click={closeDetailDialog}>닫기</Button>
			{#if selectedComment && selectedComment.status === 'published'}
				<Button
					variant="outline"
					on:click={() => {
						handleHideComment(selectedComment.id);
						closeDetailDialog();
					}}
				>
					숨기기
				</Button>
			{/if}
			{#if selectedComment}
				<Button
					variant="destructive"
					on:click={() => {
						handleDeleteComment(selectedComment.id);
						closeDetailDialog();
					}}
				>
					삭제
				</Button>
			{/if}
		</DialogFooter>
	</DialogContent>
</Dialog>
