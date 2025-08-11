<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Dialog, DialogContent, DialogHeader, DialogTitle } from '$lib/components/ui/dialog';
	import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '$lib/components/ui/select';
	import { X, Move } from 'lucide-svelte';
	import { onMount } from 'svelte';

	export let isOpen = false;
	export let postId: number;
	export let currentBoardId: number;
	export let currentCategoryId: number;

	const dispatch = createEventDispatcher();

	let boards: Array<{ id: number; name: string; categories: Array<{ id: number; name: string }> }> = [];
	let selectedBoardId: number = 0;
	let selectedCategoryId: number = 0;
	let isLoading = false;
	let error = '';

	// 게시판과 카테고리 목록 가져오기
	async function fetchBoards() {
		try {
			isLoading = true;
			const response = await fetch('/api/community/boards-with-categories');
			if (!response.ok) {
				throw new Error('게시판 정보를 가져오는데 실패했습니다.');
			}
			boards = await response.json();
			
			// 현재 게시판과 카테고리 선택
			selectedBoardId = currentBoardId;
			selectedCategoryId = currentCategoryId;
		} catch (err) {
			error = err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.';
		} finally {
			isLoading = false;
		}
	}

	// 게시글 이동 처리
	async function handleMove() {
		if (!selectedBoardId || !selectedCategoryId) {
			error = '게시판과 카테고리를 선택해주세요.';
			return;
		}

		try {
			isLoading = true;
			const response = await fetch(`/api/community/posts/${postId}/move`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					board_id: selectedBoardId,
					category_id: selectedCategoryId,
				}),
			});

			if (!response.ok) {
				throw new Error('게시글 이동에 실패했습니다.');
			}

			// 성공 시 모달 닫기
			dispatch('close');
			dispatch('moved', {
				postId,
				newBoardId: selectedBoardId,
				newCategoryId: selectedCategoryId,
			});
		} catch (err) {
			error = err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.';
		} finally {
			isLoading = false;
		}
	}

	function closeModal() {
		dispatch('close');
	}

	// 게시판 변경 시 카테고리 초기화
	$: if (selectedBoardId !== currentBoardId) {
		selectedCategoryId = 0;
	}

	onMount(() => {
		if (isOpen) {
			fetchBoards();
		}
	});

	$: if (isOpen) {
		fetchBoards();
	}
</script>

<Dialog bind:open={isOpen} onOpenChange={(open: boolean) => !open && closeModal()}>
	<DialogContent class="sm:max-w-md">
		<DialogHeader>
			<DialogTitle class="flex items-center gap-2">
				<Move class="w-5 h-5" />
				게시글 이동
			</DialogTitle>
		</DialogHeader>

		<div class="space-y-4">
			{#if (error)}
				<div class="p-3 text-sm text-red-600 bg-red-50 border border-red-200 rounded-md">
					{error}
				</div>
			{/if}

			<div class="space-y-3">
				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">
						게시판 선택
					</label>
					<Select bind:value={selectedBoardId}>
						<SelectTrigger>
							<SelectValue placeholder="게시판을 선택하세요" />
						</SelectTrigger>
						<SelectContent>
							{#each boards as board}
								<SelectItem value={board.id}>{board.name}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>

				{#if selectedBoardId}
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-1">
							카테고리 선택
						</label>
						<Select bind:value={selectedCategoryId}>
							<SelectTrigger>
								<SelectValue placeholder="카테고리를 선택하세요" />
							</SelectTrigger>
							<SelectContent>
								{#each boards.find(b => b.id === selectedBoardId)?.categories || [] as category}
									<SelectItem value={category.id}>{category.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
				{/if}
			</div>

			<div class="flex justify-end gap-2 pt-4">
				<Button variant="outline" onclick={closeModal} disabled={isLoading}>
					취소
				</Button>
				<Button onclick={handleMove} disabled={isLoading || !selectedBoardId || !selectedCategoryId}>
					{isLoading ? '이동 중...' : '이동'}
				</Button>
			</div>
		</div>
	</DialogContent>
</Dialog>
