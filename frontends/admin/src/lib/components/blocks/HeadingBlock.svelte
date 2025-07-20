<script lang="ts">
	import { Input } from '$lib/components/ui/input';
	import type { HeadingBlock } from '$lib/types/blocks';

	interface Props {
		block: HeadingBlock;
		onupdate?: (data: Partial<HeadingBlock>) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, onkeydown, ondelete }: Props = $props();

	function handleInput(event: Event) {
		const target = event.target as HTMLInputElement;
		onupdate?.({ content: target.value });
	}

	function handleLevelChange(value: string) {
		const level = parseInt(value) as 1 | 2 | 3 | 4 | 5 | 6;
		onupdate?.({ level });
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

	const headingClass = $derived({
		1: 'text-3xl font-bold',
		2: 'text-2xl font-bold',
		3: 'text-xl font-bold',
		4: 'text-lg font-semibold',
		5: 'text-base font-semibold',
		6: 'text-sm font-semibold'
	}[block.level]);
</script>

<div class="space-y-3">
	<div class="flex items-center gap-3">
		<select 
			value={block.level} 
			onchange={(e) => handleLevelChange((e.target as HTMLSelectElement).value)}
			class="px-3 py-1 border border-gray-300 rounded-md text-sm w-20"
		>
			<option value="1">H1</option>
			<option value="2">H2</option>
			<option value="3">H3</option>
			<option value="4">H4</option>
			<option value="5">H5</option>
			<option value="6">H6</option>
		</select>
	</div>

	<Input
		value={block.content}
		placeholder="제목을 입력하세요..."
		class={`border-none p-0 focus-visible:ring-0 focus-visible:ring-offset-0 ${headingClass}`}
		oninput={handleInput}
		onkeydown={handleKeyDown}
	/>
</div>