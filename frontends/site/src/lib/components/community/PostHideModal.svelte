<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Dialog, DialogContent, DialogHeader, DialogTitle } from '$lib/components/ui/dialog';
	import { Textarea } from '$lib/components/ui/textarea';
	import { X, EyeOff } from 'lucide-svelte';

	export let isOpen = false;
	export let postId: number;
	export let postTitle: string;

	const dispatch = createEventDispatcher();

	let hideReason = '';
	let isLoading = false;
	let error = '';

	// 게시글 숨김 처리
	async function handleHide() {
		if (!hideReason.trim()) {
			error = '숨김 사유를 입력해주세요.';
			return;
		}

		try {
			isLoading = true;
			const response = await fetch(`/api/community/posts/${postId}/hide`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
				},
				body: JSON.stringify({
					hide_reason: hideReason.trim(),
				}),
			});

			if (!response.ok) {
				throw new Error('게시글 숨김에 실패했습니다.');
			}

			// 성공 시 모달 닫기
			dispatch('close');
			dispatch('hidden', {
				postId,
				hideReason: hideReason.trim(),
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

	// 모달이 열릴 때 초기화
	$: if (isOpen) {
		hideReason = '';
		error = '';
	}
</script>

<Dialog bind:open={isOpen} onOpenChange={(open: boolean) => !open && closeModal()}>
	<DialogContent class="sm:max-w-md">
		<DialogHeader>
			<DialogTitle class="flex items-center gap-2">
				<EyeOff class="w-5 h-5" />
				게시글 숨김
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
						게시글 제목
					</label>
					<Input
						value={postTitle}
						disabled
						class="bg-gray-50"
					/>
				</div>

				<div>
					<label class="block text-sm font-medium text-gray-700 mb-1">
						숨김 사유 <span class="text-red-500">*</span>
					</label>
					<Textarea
						bind:value={hideReason}
						placeholder="게시글을 숨기는 이유를 입력하세요"
						rows={3}
						class="resize-none"
					/>
				</div>
			</div>

			<div class="flex justify-end gap-2 pt-4">
				<Button variant="outline" onclick={closeModal} disabled={isLoading}>
					취소
				</Button>
				<Button onclick={handleHide} disabled={isLoading || !hideReason.trim()}>
					{isLoading ? '숨김 중...' : '숨김'}
				</Button>
			</div>
		</div>
	</DialogContent>
</Dialog>
