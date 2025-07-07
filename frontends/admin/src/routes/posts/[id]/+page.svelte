<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import { Separator } from '$lib/components/ui/separator';
	import { getPost, getComments } from '$lib/api/admin';
	import type { Post } from '$lib/types/admin';

	let post: Post | null = null;
	let comments: any[] = [];
	let loading = true;
	let error = '';

	onMount(async () => {
		const postId = $page.params.id;
		try {
			loading = true;
			// 게시글 상세 정보 조회
			post = await getPost(postId);
			
			// 댓글 목록 조회
			const commentsData = await getComments({ post_id: postId });
			comments = commentsData.comments || [];
		} catch (err) {
			error = '게시글을 불러오는 중 오류가 발생했습니다.';
			console.error('Failed to load post:', err);
		} finally {
			loading = false;
		}
	});

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleString('ko-KR');
	}

	function getStatusBadge(status: string) {
		switch (status) {
			case 'Active':
				return { variant: 'default', text: '공개' };
			case 'Hidden':
				return { variant: 'destructive', text: '숨김' };
			case 'Deleted':
				return { variant: 'secondary', text: '삭제됨' };
			default:
				return { variant: 'outline', text: status };
		}
	}

	function handleBack() {
		goto('/posts');
	}

	function handleEdit() {
		goto(`/posts/${$page.params.id}/edit`);
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div class="flex items-center space-x-4">
			<Button variant="outline" onclick={handleBack}>
				← 목록으로
			</Button>
			<div>
				<h1 class="text-3xl font-bold text-gray-900">게시글 상세보기</h1>
				<p class="mt-2 text-gray-600">게시글 내용과 댓글을 확인합니다.</p>
			</div>
		</div>
		<div class="flex space-x-2">
			<Button variant="outline" onclick={handleEdit}>수정</Button>
		</div>
	</div>

	{#if loading}
		<Card>
			<CardContent class="pt-6">
				<div class="flex items-center justify-center py-8">
					<div class="text-gray-500">로딩 중...</div>
				</div>
			</CardContent>
		</Card>
	{:else if error}
		<Card>
			<CardContent class="pt-6">
				<div class="flex items-center justify-center py-8">
					<div class="text-red-500">{error}</div>
				</div>
			</CardContent>
		</Card>
	{:else if post}
		<!-- 게시글 정보 -->
		<Card>
			<CardHeader>
				<div class="flex items-start justify-between">
					<div class="space-y-2">
						<div class="flex items-center space-x-2">
							{#if post.is_notice}
								<Badge variant="secondary">공지</Badge>
							{/if}
							<Badge variant={getStatusBadge(post.status).variant as any}>{getStatusBadge(post.status).text}</Badge>
						</div>
						<CardTitle class="text-2xl">{post.title}</CardTitle>
						<CardDescription>
							작성자: {post.user_name} | 게시판: {post.board_name} | 
							작성일: {formatDate(post.created_at)} | 
							조회수: {post.views.toLocaleString()} | 
							댓글: {post.comment_count}개
						</CardDescription>
					</div>
				</div>
			</CardHeader>
			<CardContent>
				<div class="prose max-w-none">
					<div class="whitespace-pre-wrap text-gray-700 leading-relaxed">
						{post.content}
					</div>
				</div>
			</CardContent>
		</Card>

		<!-- 댓글 목록 -->
		<Card>
			<CardHeader>
				<CardTitle>댓글 목록 ({comments.length}개)</CardTitle>
			</CardHeader>
			<CardContent>
				{#if comments.length === 0}
					<div class="text-center py-8 text-gray-500">
						댓글이 없습니다.
					</div>
				{:else}
					<div class="space-y-4">
						{#each comments as comment}
							<div class="border rounded-lg p-4">
								<div class="flex items-start justify-between">
									<div class="flex items-center space-x-2">
										<div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300">
											<span class="text-sm font-medium text-gray-700">
												{comment.user_name?.[0] || 'U'}
											</span>
										</div>
										<div>
											<div class="font-medium text-gray-900">{comment.user_name}</div>
											<div class="text-sm text-gray-500">{formatDate(comment.created_at)}</div>
										</div>
									</div>
									<div class="flex space-x-2">
										{#if comment.status === 'Active'}
											<Badge variant="default">공개</Badge>
										{:else}
											<Badge variant="destructive">숨김</Badge>
										{/if}
									</div>
								</div>
								<div class="mt-3 text-gray-700">
									{comment.content}
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</CardContent>
		</Card>
	{/if}
</div> 