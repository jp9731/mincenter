<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import {
		createPost,
		categories,
		boards,
		loadCategories,
		loadBoards,
		isLoading,
		error
	} from '$lib/stores/community';

	let title = '';
	let content = '';
	let selectedCategory = '';
	let selectedBoard = '';
	let boardName = '';

	onMount(async () => {
		// URL에서 board_id 가져오기
		const boardId = $page.url.searchParams.get('board');
		if (boardId) {
			selectedBoard = boardId;
			await loadCategories(boardId);
		}

		// 게시판 목록 로드
		await loadBoards();

		// 게시판 이름 설정
		if (boardId) {
			const board = $boards.find((b) => b.id === boardId);
			boardName = board?.name || '게시판';
		}
	});

	async function handleSubmit() {
		if (!selectedBoard) {
			alert('게시판을 선택해주세요.');
			return;
		}

		const post = await createPost({
			board_id: selectedBoard,
			category_id: selectedCategory || undefined,
			title,
			content
		});

		if (post) {
			goto(`/community/${post.board_id}/${post.id}`);
		}
	}

	function handleBoardChange(value: string) {
		selectedBoard = value;
		selectedCategory = ''; // 게시판 변경 시 카테고리 초기화
		loadCategories(value);

		// 게시판 이름 설정
		const board = $boards.find((b) => b.id === value);
		boardName = board?.name || '게시판';
	}

	function getBoardLabel(boardId: string) {
		if (!boardId) return '게시판을 선택하세요';
		const board = $boards.find((b) => b.id === boardId);
		return board ? board.name : '게시판을 선택하세요';
	}

	function getCategoryLabel(categoryId: string) {
		if (!categoryId) return '카테고리를 선택하세요 (선택사항)';
		const category = $categories.find((c) => c.id === categoryId);
		return category ? category.name : '카테고리를 선택하세요 (선택사항)';
	}
</script>

<div class="container mx-auto py-8">
	<div class="mx-auto max-w-3xl">
		<h1 class="mb-8 text-3xl font-bold">글쓰기</h1>

		<form on:submit|preventDefault={handleSubmit} class="space-y-6">
			<div>
				<label for="board" class="mb-1 block text-sm font-medium text-gray-700"> 게시판 </label>
				<Select value={selectedBoard} onValueChange={handleBoardChange}>
					<SelectTrigger>
						{getBoardLabel(selectedBoard)}
					</SelectTrigger>
					<SelectContent>
						{#each $boards as board}
							<SelectItem value={board.id}>{board.name}</SelectItem>
						{/each}
					</SelectContent>
				</Select>
			</div>

			{#if selectedBoard && $categories.length > 0}
				<div>
					<label for="category" class="mb-1 block text-sm font-medium text-gray-700">
						카테고리
					</label>
					<Select value={selectedCategory} onValueChange={(value) => (selectedCategory = value)}>
						<SelectTrigger>
							{getCategoryLabel(selectedCategory)}
						</SelectTrigger>
						<SelectContent>
							<SelectItem value="">카테고리 없음</SelectItem>
							{#each $categories as category}
								<SelectItem value={category.id}>{category.name}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>
			{/if}

			<div>
				<label for="title" class="mb-1 block text-sm font-medium text-gray-700"> 제목 </label>
				<Input id="title" bind:value={title} required placeholder="제목을 입력하세요" />
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

			{#if $error}
				<div class="text-sm text-red-500">{$error}</div>
			{/if}

			<div class="flex justify-end gap-4">
				<Button type="button" variant="outline" on:click={() => goto('/community')}>취소</Button>
				<Button type="submit" disabled={$isLoading}>
					{$isLoading ? '작성 중...' : '작성하기'}
				</Button>
			</div>
		</form>
	</div>
</div>
