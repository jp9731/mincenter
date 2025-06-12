<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Badge } from '$lib/components/ui/badge';
	import { Card, CardContent, CardFooter, CardHeader, CardTitle } from '$lib/components/ui/card';
	import {
		currentPost,
		comments,
		isLoading,
		error,
		fetchPost,
		createComment,
		likePost
	} from '$lib/stores/community';

	let commentContent = '';

	onMount(() => {
		fetchPost($page.params.id);
	});

	async function handleCommentSubmit() {
		if (!commentContent.trim()) return;

		const comment = await createComment({
			content: commentContent,
			postId: $page.params.id
		});

		if (comment) {
			commentContent = '';
		}
	}

	function formatDate(date: string) {
		return new Date(date).toLocaleString();
	}
</script>

<div class="container mx-auto py-8">
	{#if $isLoading}
		<div class="py-8 text-center">로딩 중...</div>
	{:else if $error}
		<div class="py-8 text-center text-red-500">{$error}</div>
	{:else if $currentPost}
		<div class="mx-auto max-w-4xl">
			<!-- 게시글 -->
			<Card class="mb-8">
				<CardHeader>
					<div class="flex items-start justify-between">
						<div>
							<CardTitle class="mb-2 text-2xl">{$currentPost.title}</CardTitle>
							<div class="flex items-center gap-4 text-sm text-gray-500">
								<span>{$currentPost.category}</span>
								<span>{formatDate($currentPost.createdAt)}</span>
								<span>조회 {$currentPost.views}</span>
							</div>
						</div>
						<div class="flex items-center gap-2">
							<Button variant="ghost" on:click={() => likePost($currentPost.id)}>
								좋아요 {$currentPost.likes}
							</Button>
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
						<img
							src={$currentPost.author.avatar || '/default-avatar.png'}
							alt={$currentPost.author.name}
							class="h-8 w-8 rounded-full"
						/>
						<span>{$currentPost.author.name}</span>
					</div>
					<div class="ml-auto flex gap-2">
						{#each $currentPost.tags as tag}
							<Badge variant="secondary">{tag}</Badge>
						{/each}
					</div>
				</CardFooter>
			</Card>

			<!-- 댓글 작성 -->
			<Card class="mb-8">
				<CardContent class="pt-6">
					<Textarea bind:value={commentContent} placeholder="댓글을 입력하세요" class="mb-4" />
					<div class="flex justify-end">
						<Button on:click={handleCommentSubmit}>댓글 작성</Button>
					</div>
				</CardContent>
			</Card>

			<!-- 댓글 목록 -->
			<div class="space-y-4">
				<h2 class="mb-4 text-xl font-bold">댓글 {$currentPost.comments}개</h2>
				{#each $comments as comment}
					<Card>
						<CardContent class="pt-6">
							<div class="flex items-start gap-4">
								<img
									src={comment.author.avatar || '/default-avatar.png'}
									alt={comment.author.name}
									class="h-8 w-8 rounded-full"
								/>
								<div class="flex-1">
									<div class="mb-2 flex items-center gap-2">
										<span class="font-medium">{comment.author.name}</span>
										<span class="text-sm text-gray-500">
											{formatDate(comment.createdAt)}
										</span>
									</div>
									<p class="text-gray-700">{comment.content}</p>
								</div>
							</div>
						</CardContent>
					</Card>
				{/each}
			</div>
		</div>
	{:else}
		<div class="py-8 text-center">게시글을 찾을 수 없습니다.</div>
	{/if}
</div>
