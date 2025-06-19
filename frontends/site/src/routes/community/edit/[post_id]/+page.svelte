<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import {
		currentPost,
		categories,
		tags,
		isLoading,
		error,
		fetchPost,
		updatePost,
		fetchCategories,
		fetchTags
	} from '$lib/stores/community';
	import { user } from '$lib/stores/auth';
	import { canEditPost } from '$lib/utils/permissions';

	let title = '';
	let content = '';
	let category = '';
	let selectedTags: string[] = [];
	let tagInput = '';

	onMount(async () => {
		await Promise.all([fetchPost($page.params.post_id), fetchCategories(), fetchTags()]);
	});

	// 현재 게시글 데이터가 로드되면 폼에 설정
	$: if ($currentPost) {
		title = $currentPost.title;
		content = $currentPost.content;
		category = $currentPost.board_id;
		selectedTags = $currentPost.tags || [];
	}

	async function handleSubmit() {
		const post = await updatePost($page.params.post_id, {
			title,
			content,
			board_id: category,
			tags: selectedTags
		});

		if (post) {
			goto(`/community/${post.board_id}/${post.id}`);
		}
	}

	function handleTagInput(e: KeyboardEvent) {
		if (e.key === 'Enter' && tagInput.trim()) {
			e.preventDefault();
			if (!selectedTags.includes(tagInput.trim())) {
				selectedTags = [...selectedTags, tagInput.trim()];
			}
			tagInput = '';
		}
	}

	function removeTag(tag: string) {
		selectedTags = selectedTags.filter((t) => t !== tag);
	}

	function getCategoryLabel(categoryId: string) {
		if (!categoryId) return '카테고리를 선택하세요';
		const cat = $categories.find((c: any) => c.id === categoryId);
		return cat ? cat.name : '카테고리를 선택하세요';
	}

	// 권한 확인
	$: if ($currentPost && $user && !canEditPost($currentPost)) {
		goto('/community');
	}
</script>

<div class="container mx-auto py-8">
	<div class="mx-auto max-w-3xl">
		<h1 class="mb-8 text-3xl font-bold">게시글 수정</h1>

		{#if $isLoading}
			<div class="py-8 text-center">로딩 중...</div>
		{:else if $error}
			<div class="py-8 text-center text-red-500">{$error}</div>
		{:else if $currentPost}
			<form on:submit|preventDefault={handleSubmit} class="space-y-6">
				<div>
					<label for="title" class="mb-1 block text-sm font-medium text-gray-700"> 제목 </label>
					<Input id="title" bind:value={title} required placeholder="제목을 입력하세요" />
				</div>

				<div>
					<label for="category" class="mb-1 block text-sm font-medium text-gray-700">
						카테고리
					</label>
					<Select value={category} onValueChange={(value: string) => (category = value)}>
						<SelectTrigger>
							{getCategoryLabel(category)}
						</SelectTrigger>
						<SelectContent>
							{#each $categories as cat}
								<SelectItem value={cat.id}>{cat.name}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>

				<div>
					<label for="content" class="mb-1 block text-sm font-medium text-gray-700"> 내용 </label>
					<Textarea
						id="content"
						bind:value={content}
						required
						placeholder="내용을 입력하세요"
						class="min-h-[300px]"
					/>
				</div>

				<div>
					<label for="tags" class="mb-1 block text-sm font-medium text-gray-700"> 태그 </label>
					<div class="space-y-2">
						<Input
							id="tags"
							bind:value={tagInput}
							on:keydown={handleTagInput}
							placeholder="태그를 입력하고 Enter를 누르세요"
						/>
						<div class="flex flex-wrap gap-2">
							{#each selectedTags as tag}
								<div
									class="inline-flex items-center gap-1 rounded-full bg-gray-100 px-2 py-1 text-sm"
								>
									{tag}
									<button
										type="button"
										class="text-gray-500 hover:text-gray-700"
										on:click={() => removeTag(tag)}
									>
										×
									</button>
								</div>
							{/each}
						</div>
					</div>
				</div>

				{#if $error}
					<div class="text-sm text-red-500">{$error}</div>
				{/if}

				<div class="flex justify-end gap-4">
					<Button type="button" variant="outline" asChild>
						<a href="/community/{$currentPost.board_id}/{$currentPost.id}">취소</a>
					</Button>
					<Button type="submit" disabled={$isLoading}>
						{$isLoading ? '수정 중...' : '수정하기'}
					</Button>
				</div>
			</form>
		{:else}
			<div class="py-8 text-center">게시글을 찾을 수 없습니다.</div>
		{/if}
	</div>
</div>
