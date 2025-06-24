<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import RichTextEditor from '$lib/components/editor/RichTextEditor.svelte';
	import FileUpload from '$lib/components/upload/FileUpload.svelte';
	import {
		createPost,
		createPostBySlug,
		categories,
		boards,
		loadCategories,
		loadBoards,
		isLoading,
		error
	} from '$lib/stores/community';
	import { isAuthenticated } from '$lib/stores/auth';
	import type { Board, Category } from '$lib/types/community.ts';
	import { get } from 'svelte/store';

	export let data;
	let title = '';
	let content = '';
	let selectedCategory = '';
	let selectedSlug = data?.slug || '';
	let boardName = '';
	let boardSettings: Board | null = null;
	let boardsList: Board[] = [];
	let categoriesList: Category[] = [];
	let uploadedFiles: string[] = [];
	let attachedFiles: File[] = [];
	let boardSelected = false;

	onMount(async () => {
		// 인증 확인
		const authenticated = get(isAuthenticated);
		if (!authenticated) {
			alert('로그인이 필요합니다.');
			goto('/auth/login');
			return;
		}

		await loadBoards();
		$: boardsList = $boards;
		$: categoriesList = $categories;

		if (selectedSlug && selectedSlug !== 'general') {
			const board = boardsList.find((b: Board) => b.slug === selectedSlug);
			boardName = board?.name || '게시판';
			boardSettings = board;
			boardSelected = true;
		} else {
			boardSelected = false;
		}

		if (selectedSlug && selectedSlug !== 'general') {
			await loadCategories(selectedSlug);
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();

		// 인증 재확인
		const authenticated = get(isAuthenticated);
		if (!authenticated) {
			alert('로그인이 필요합니다.');
			goto('/auth/login');
			return;
		}

		if (!selectedSlug) {
			alert('게시판을 선택해주세요.');
			return;
		}

		try {
			const post = await createPostBySlug(selectedSlug, {
				category_id: selectedCategory || undefined,
				title,
				content,
				attached_files: uploadedFiles
			});

			if (post) {
				goto(`/community/${post.board_slug}/${post.id}`);
			}
		} catch (err) {
			console.error('글쓰기 실패:', err);
			if (err instanceof Error && err.message.includes('401')) {
				alert('로그인이 만료되었습니다. 다시 로그인해주세요.');
				goto('/auth/login');
			} else {
				alert('글쓰기에 실패했습니다. 다시 시도해주세요.');
			}
		}
	}

	function handleBoardChange(value: string) {
		selectedSlug = value;
		selectedCategory = '';
		loadCategories(value);
		const board = boardsList.find((b: Board) => b.slug === value) || null;
		boardName = board?.name || '게시판';
		boardSettings = board;
		boardSelected = true;
	}

	function getBoardLabel(boardId: string) {
		if (!boardId) return '게시판을 선택하세요';
		const board = $boards.find((b) => b.slug === boardId);
		return board ? board.name : '게시판을 선택하세요';
	}

	function getCategoryLabel(categoryId: string) {
		if (!categoryId) return '카테고리를 선택하세요 (선택사항)';
		const category = $categories.find((c) => c.id === categoryId);
		return category ? category.name : '카테고리를 선택하세요 (선택사항)';
	}

	// 이미지 업로드 핸들러
	async function handleImageUpload(file: File): Promise<string> {
		// 실제 구현에서는 서버로 이미지를 업로드하고 URL을 반환
		// 여기서는 임시로 FileReader를 사용
		return new Promise((resolve, reject) => {
			const reader = new FileReader();
			reader.onload = () => resolve(reader.result as string);
			reader.onerror = reject;
			reader.readAsDataURL(file);
		});
	}

	// 파일 업로드 핸들러
	async function handleFileUpload(file: File): Promise<string> {
		// 실제 구현에서는 서버로 파일을 업로드하고 URL을 반환
		// 여기서는 임시로 파일명을 반환
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
</script>

<div class="container mx-auto py-8">
	<div class="mx-auto max-w-4xl">
		<h1 class="mb-8 text-3xl font-bold">글쓰기</h1>

		<form onsubmit={handleSubmit} class="space-y-6">
			<div>
				<label for="title" class="mb-1 block text-sm font-medium text-gray-700">제목</label>
				<Input id="title" bind:value={title} required placeholder="제목을 입력하세요" />
			</div>

			{#if data?.slug === 'general'}
				{#if !boardSelected}
					<div>
						<label for="board" class="mb-1 block text-sm font-medium text-gray-700">게시판</label>
						<Select type="single" value={selectedSlug} onValueChange={handleBoardChange}>
							<SelectTrigger>
								{getBoardLabel(selectedSlug)}
							</SelectTrigger>
							<SelectContent>
								{#each boardsList as board}
									<SelectItem value={board.slug}>{board.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
				{:else}
					<div>
						<label class="mb-1 block text-sm font-medium text-gray-700">게시판</label>
						<div
							class="rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-900"
						>
							{boardName}
						</div>
					</div>
				{/if}
			{:else}
				<div>
					<label class="mb-1 block text-sm font-medium text-gray-700">게시판</label>
					<div class="rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-900">
						{boardName}
					</div>
				</div>
			{/if}

			{#if selectedSlug && $categories.length > 0}
				<div>
					<label for="category" class="mb-1 block text-sm font-medium text-gray-700">
						카테고리
					</label>
					<Select
						type="single"
						value={selectedCategory}
						onValueChange={(value: string) => (selectedCategory = value)}
					>
						<SelectTrigger>
							{getCategoryLabel(selectedCategory)}
						</SelectTrigger>
						<SelectContent>
							<SelectItem value="">카테고리 없음</SelectItem>
							{#each categoriesList as category}
								<SelectItem value={category.id}>{category.name}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>
			{/if}

			<div>
				<label for="content" class="mb-1 block text-sm font-medium text-gray-700">내용</label>
				<textarea
					id="content"
					bind:value={content}
					required
					placeholder="내용을 입력하세요"
					class="min-h-[300px] w-full rounded-md border border-gray-300 p-3 focus:border-transparent focus:ring-2 focus:ring-blue-500"
				></textarea>
			</div>

			{#if boardSettings?.allow_file_upload}
				<div>
					<label class="mb-1 block text-sm font-medium text-gray-700">첨부파일</label>
					<FileUpload
						bind:files={attachedFiles}
						maxFiles={boardSettings?.max_files}
						maxFileSize={boardSettings?.max_file_size}
						allowedTypes={boardSettings?.allowed_file_types}
						onUpload={handleFileUpload}
					/>
				</div>
			{/if}

			{#if $error}
				<div class="text-sm text-red-500">{$error}</div>
			{/if}

			<div class="flex justify-end gap-4">
				<Button type="button" variant="outline" onclick={() => goto('/community')}>취소</Button>
				<Button type="submit" disabled={$isLoading}>
					{$isLoading ? '작성 중...' : '작성하기'}
				</Button>
			</div>
		</form>
	</div>
</div>
