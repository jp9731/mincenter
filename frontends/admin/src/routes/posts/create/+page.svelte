<script lang="ts">
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import PostForm from '$lib/components/posts/PostForm.svelte';
	import { createPost } from '$lib/api/admin';

	let saving = false;
	let error = '';

	async function handleSubmit(postData: any) {
		try {
			saving = true;
			error = '';
			
			const newPost = await createPost(postData);
			alert('게시글이 성공적으로 작성되었습니다.');
			goto(`/posts/${newPost.id}`);
		} catch (err) {
			error = '게시글 작성 중 오류가 발생했습니다.';
			console.error('Failed to create post:', err);
			throw err;
		} finally {
			saving = false;
		}
	}

	function handleCancel() {
		goto('/posts');
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div class="flex items-center space-x-4">
			<Button variant="outline" onclick={handleCancel}>
				← 목록으로
			</Button>
			<div>
				<h1 class="text-3xl font-bold text-gray-900">새 게시글 작성</h1>
				<p class="mt-2 text-gray-600">새로운 게시글을 작성합니다.</p>
			</div>
		</div>
	</div>

	<!-- 게시글 폼 -->
	<PostForm
		mode="create"
		post={null}
		onSubmit={handleSubmit}
		onCancel={handleCancel}
		loading={false}
		{saving}
		{error}
	/>
</div> 