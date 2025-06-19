<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Card,
		CardContent,
		CardDescription,
		CardFooter,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Separator } from '$lib/components/ui/separator';
	import {
		currentPost,
		comments,
		isLoading,
		error,
		fetchPost,
		loadComments,
		createComment,
		updatePost,
		deletePost
	} from '$lib/stores/community';
	import { user, isAuthenticated } from '$lib/stores/auth';
	import { canEditPost, canDeletePost } from '$lib/utils/permissions';

	let newComment = '';
	let isEditing = false;
	let editTitle = '';
	let editContent = '';

	onMount(async () => {
		const { board_id, post_id } = $page.params;
		await Promise.all([fetchPost(post_id), loadComments(post_id)]);
	});

	function handleCommentSubmit() {
		if (!newComment.trim()) return;

		createComment({
			post_id: $page.params.post_id,
			content: newComment
		});
		newComment = '';
	}

	function startEdit() {
		if ($currentPost) {
			editTitle = $currentPost.title;
			editContent = $currentPost.content;
			isEditing = true;
		}
	}

	async function handleEdit() {
		if (!$currentPost) return;

		const success = await updatePost($currentPost.id, {
			title: editTitle,
			content: editContent
		});

		if (success) {
			isEditing = false;
		}
	}

	async function handleDelete() {
		if (!$currentPost || !confirm('정말 삭제하시겠습니까?')) return;

		await deletePost($currentPost.id);
		// 목록으로 돌아가기
		window.location.href = `/community/${$currentPost.board_id}`;
	}

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleString('ko-KR');
	}
</script>

<div class="container mx-auto px-4 py-8">
	{#if $isLoading}
		<div class="py-8 text-center">로딩 중...</div>
	{:else if $error}
		<div class="py-8 text-center text-red-500">{$error}</div>
	{:else if $currentPost}
		<!-- 게시글 헤더 -->
		<div class="mb-6">
			<div class="mb-4 flex items-center justify-between">
				<div>
					<a href="/community/{$currentPost.board_id}" class="text-blue-600 hover:underline">
						← {$currentPost.board_name}
					</a>
				</div>
				{#if $isAuthenticated && (canEditPost($currentPost) || canDeletePost($currentPost))}
					<div class="flex gap-2">
						{#if canEditPost($currentPost)}
							<Button variant="outline" size="sm" on:click={startEdit}>수정</Button>
						{/if}
						{#if canDeletePost($currentPost)}
							<Button variant="outline" size="sm" on:click={handleDelete}>삭제</Button>
						{/if}
					</div>
				{/if}
			</div>

			{#if isEditing}
				<div class="space-y-4">
					<input
						type="text"
						bind:value={editTitle}
						class="w-full rounded-lg border border-gray-300 p-3"
						placeholder="제목을 입력하세요"
					/>
					<textarea
						bind:value={editContent}
						class="h-64 w-full rounded-lg border border-gray-300 p-3"
						placeholder="내용을 입력하세요"
					></textarea>
					<div class="flex gap-2">
						<Button on:click={handleEdit}>저장</Button>
						<Button variant="outline" on:click={() => (isEditing = false)}>취소</Button>
					</div>
				</div>
			{:else}
				<Card>
					<CardHeader>
						<div class="flex items-start justify-between">
							<div>
								<CardTitle class="text-2xl">{$currentPost.title}</CardTitle>
								<CardDescription>
									{$currentPost.board_name} · {formatDate($currentPost.created_at)}
								</CardDescription>
							</div>
							<div class="flex items-center gap-4 text-sm text-gray-500">
								<span>조회 {$currentPost.views || 0}</span>
								<span>좋아요 {$currentPost.likes || 0}</span>
								<span>댓글 {$currentPost.comment_count || 0}</span>
							</div>
						</div>
					</CardHeader>
					<CardContent>
						<div class="prose max-w-none">
							{$currentPost.content}
						</div>
					</CardContent>
					<CardFooter>
						<div class="flex items-center gap-2">
							<div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300">
								<span class="text-sm text-gray-600">{$currentPost.user_name?.[0] || 'U'}</span>
							</div>
							<span class="text-sm text-gray-500">{$currentPost.user_name || '익명'}</span>
						</div>
						<div class="ml-auto flex gap-2">
							{#if $currentPost.is_notice}
								<Badge variant="secondary">공지</Badge>
							{/if}
						</div>
					</CardFooter>
				</Card>
			{/if}
		</div>

		<!-- 댓글 섹션 -->
		{#if !isEditing}
			<Separator class="my-8" />

			<div class="space-y-6">
				<h3 class="text-xl font-semibold">댓글 ({$currentPost.comment_count || 0})</h3>

				{#if $isAuthenticated}
					<div class="space-y-4">
						<textarea
							bind:value={newComment}
							class="h-24 w-full rounded-lg border border-gray-300 p-3"
							placeholder="댓글을 입력하세요"
						></textarea>
						<Button on:click={handleCommentSubmit}>댓글 작성</Button>
					</div>
				{:else}
					<div class="py-4 text-center">
						<a href="/auth/login" class="text-blue-600 hover:underline"
							>로그인하여 댓글을 작성하세요</a
						>
					</div>
				{/if}

				<div class="space-y-4">
					{#each $comments as comment}
						<Card>
							<CardContent class="pt-6">
								<div class="flex items-start gap-3">
									<div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300">
										<span class="text-sm text-gray-600">{comment.user_name?.[0] || 'U'}</span>
									</div>
									<div class="flex-1">
										<div class="mb-2 flex items-center gap-2">
											<span class="font-medium">{comment.user_name || '익명'}</span>
											<span class="text-sm text-gray-500">{formatDate(comment.created_at)}</span>
										</div>
										<p class="text-gray-700">{comment.content}</p>
									</div>
								</div>
							</CardContent>
						</Card>
					{/each}
				</div>
			</div>
		{/if}
	{/if}
</div>
