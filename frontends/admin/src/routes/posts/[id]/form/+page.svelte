<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import PostForm from '$lib/components/posts/PostForm.svelte';
	import { getPost, updatePost } from '$lib/api/admin';
	import type { Post } from '$lib/types/admin';

	let post: Post | null = null;
	let loading = true;
	let saving = false;
	let error = '';

	onMount(async () => {
		const postId = $page.params.id;
		console.log('Edit page: 게시글 로드 시작', postId);
		try {
			post = await getPost(postId);
			console.log('Edit page: 게시글 로드 완료', post);
		} catch (err) {
			error = '게시글을 불러오는 중 오류가 발생했습니다.';
			console.error('Failed to load post:', err);
		} finally {
			loading = false;
		}
	});

	async function handleSubmit(postData: any) {
		try {
			saving = true;
			error = '';
			
			await updatePost($page.params.id, postData);
			alert('게시글이 성공적으로 수정되었습니다.');
			goto(`/posts/${$page.params.id}`);
		} catch (err) {
			error = '게시글 수정 중 오류가 발생했습니다.';
			console.error('Failed to update post:', err);
			throw err;
		} finally {
			saving = false;
		}
	}

	function handleCancel() {
		goto(`/posts/${$page.params.id}`);
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div class="flex items-center space-x-4">
			<Button variant="outline" onclick={handleCancel}>
				← 상세보기로
			</Button>
			<div>
				<h1 class="text-3xl font-bold text-gray-900">게시글 수정</h1>
				<p class="mt-2 text-gray-600">게시글 정보를 수정합니다.</p>
			</div>
		</div>
	</div>

	<!-- 게시글 폼 -->
	<PostForm
		mode="edit"
		{post}
		onSubmit={handleSubmit}
		onCancel={handleCancel}
		{loading}
		{saving}
		{error}
	/>
</div> 