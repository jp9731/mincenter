<script lang="ts">
	import { Textarea } from '$lib/components/ui/textarea';
	import { Input } from '$lib/components/ui/input';
	import type { QuoteBlock } from '$lib/types/blocks';

	interface Props {
		block: QuoteBlock;
		onupdate?: (data: Partial<QuoteBlock>) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, onkeydown, ondelete }: Props = $props();

	function handleContentChange(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		onupdate?.({ content: target.value });
	}

	function handleAuthorChange(event: Event) {
		const target = event.target as HTMLInputElement;
		onupdate?.({ author: target.value });
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

<div class="border-l-4 border-gray-300 pl-4 space-y-3">
	<Textarea
		value={block.content}
		placeholder="인용문을 입력하세요..."
		rows={3}
		class="border-none p-0 resize-none focus-visible:ring-0 focus-visible:ring-offset-0 italic text-lg"
		oninput={handleContentChange}
		onkeydown={handleKeyDown}
	/>
	
	<Input
		value={block.author || ''}
		placeholder="출처 (선택사항)"
		class="border-none p-0 focus-visible:ring-0 focus-visible:ring-offset-0 text-sm text-gray-600"
		oninput={handleAuthorChange}
	/>
</div>