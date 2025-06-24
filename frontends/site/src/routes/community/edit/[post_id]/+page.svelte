<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import RichTextEditor from '$lib/components/editor/RichTextEditor.svelte';
	import FileUpload from '$lib/components/upload/FileUpload.svelte';
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

	export let data;
	let title = '';
	let content = '';
	let category = '';
	let selectedTags: string[] = [];
	let tagInput = '';
	let boardName = '';
	let boardSettings = null;
	let uploadedFiles: string[] = [];
	let attachedFiles: File[] = [];

	onMount(async () => {
		await Promise.all([fetchPost(data.postId), fetchCategories(), fetchTags()]);
	});

	// 현재 게시글 데이터가 로드되면 폼에 설정
	$: if ($currentPost) {
		title = $currentPost.title;
		content = $currentPost.content;
		category = $currentPost.board_id;
		selectedTags = $currentPost.tags || [];
		boardName = $currentPost.board_name || '게시판';
		// 게시판 설정 가져오기 (실제로는 API에서 가져와야 함)
		boardSettings = {
			allowFileUpload: true,
			maxFiles: 5,
			maxFileSize: 10 * 1024 * 1024,
			allowedFileTypes: ['image/*', 'application/pdf'],
			allowRichText: true
		};
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();
		const post = await updatePost(data.postId, {
			title,
			content,
			board_id: category,
			tags: selectedTags,
			attached_files: uploadedFiles
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

	// 이미지 업로드 핸들러
	async function handleImageUpload(file: File): Promise<string> {
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onload = () => resolve(reader.result as string);
			reader.onerror = reject;
			reader.readAsDataURL(file);
		});
	}

	// 파일 업로드 핸들러
	async function handleFileUpload(file: File): Promise<string> {
		return new Promise((resolve) => {
			setTimeout(() => {
				resolve(`/uploads/${Date.now()}_${file.name}`);
			}, 1000);
		});
	}

	function handleFilesChange(event: CustomEvent) {
		attachedFiles = event.detail.files;
	}

	function handleUploadComplete(event: CustomEvent) {
		const { url } = event.detail;
		uploadedFiles = [...uploadedFiles, url];
	}

	// 권한 확인
	$: if ($currentPost && $user && !canEditPost($currentPost)) {
		goto('/community');
	}
</script>

<div class="container mx-auto py-8">
	<div class="mx-auto max-w-4xl">
		<h1 class="mb-8 text-3xl font-bold">게시글 수정</h1>

		{#if $isLoading}
			<div class="py-8 text-center">로딩 중...</div>
		{:else if $error}
			<div class="py-8 text-center text-red-500">{$error}</div>
		{:else if $currentPost}
			<form onsubmit={handleSubmit} class="space-y-6">
				<div>
					<label for="title" class="mb-1 block text-sm font-medium text-gray-700">제목</label>
					<Input id="title" bind:value={title} required placeholder="제목을 입력하세요" />
				</div>

				<div>
					<label for="board" class="mb-1 block text-sm font-medium text-gray-700">게시판</label>
					<div class="rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-900">
						{boardName}
					</div>
				</div>

				{#if $categories.length > 0}
					<div>
						<label for="category" class="mb-1 block text-sm font-medium text-gray-700">
							카테고리
						</label>
						<Select
							type="single"
							value={category}
							onValueChange={(value: string) => (category = value)}
						>
							<SelectTrigger>
								{getCategoryLabel(category)}
							</SelectTrigger>
							<SelectContent>
								<SelectItem value="">카테고리 없음</SelectItem>
								{#each $categories as cat}
									<SelectItem value={cat.id}>{cat.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
				{/if}

				<div>
					<label for="content" class="mb-1 block text-sm font-medium text-gray-700">내용</label>
					{#if boardSettings?.allowRichText}
						<RichTextEditor
							bind:value={content}
							placeholder="내용을 입력하세요..."
							onImageUpload={handleImageUpload}
						/>
					{:else}
						<textarea
							id="content"
							bind:value={content}
							required
							placeholder="내용을 입력하세요"
							class="min-h-[300px] w-full rounded-md border border-gray-300 p-3 focus:border-transparent focus:ring-2 focus:ring-blue-500"
						></textarea>
					{/if}
				</div>

				{#if boardSettings?.allowFileUpload}
					<div>
						<label class="mb-1 block text-sm font-medium text-gray-700">첨부파일</label>
						<FileUpload
							bind:files={attachedFiles}
							maxFiles={boardSettings.maxFiles}
							maxFileSize={boardSettings.maxFileSize}
							allowedTypes={boardSettings.allowedFileTypes}
							onUpload={handleFileUpload}
							onfilesChange={handleFilesChange}
							onuploadComplete={handleUploadComplete}
						/>
					</div>
				{/if}

				<div>
					<label for="tags" class="mb-1 block text-sm font-medium text-gray-700">태그</label>
					<div class="space-y-2">
						<Input
							id="tags"
							bind:value={tagInput}
							onkeydown={handleTagInput}
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
										onclick={() => removeTag(tag)}
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
