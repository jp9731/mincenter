<script lang="ts">
	import { Textarea } from '$lib/components/ui/textarea';
	import type { ParagraphBlock } from '$lib/types/blocks';

	interface Props {
		block: ParagraphBlock;
		isSelected?: boolean;
		onupdate?: (data: Partial<ParagraphBlock>) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		ondelete?: () => void;
		onselect?: () => void;
	}

	let { block, isSelected = false, onupdate, onkeydown, ondelete, onselect }: Props = $props();

	function handleInput(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		onupdate?.({ content: target.value });
	}

	function handleKeyDown(event: KeyboardEvent) {
		// Delete block if it's empty and backspace is pressed
		if (event.key === 'Backspace' && !block.content.trim()) {
			event.preventDefault();
			ondelete?.();
			return;
		}
		
		onkeydown?.(event);
	}
</script>

<div class="relative">
	<Textarea
		value={block.content}
		placeholder="문단을 입력하세요..."
		rows={3}
		class="border-none p-0 resize-none focus-visible:ring-0 focus-visible:ring-offset-0"
		oninput={handleInput}
		onkeydown={handleKeyDown}
		onclick={onselect}
	/>
	{#if isSelected}
		<div class="absolute inset-0 border-2 border-blue-500 rounded pointer-events-none"></div>
	{/if}
</div>