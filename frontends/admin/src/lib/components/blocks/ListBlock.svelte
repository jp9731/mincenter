<script lang="ts">
	import { Input } from '$lib/components/ui/input';
	import { Button } from '$lib/components/ui/button';
	import { Plus, Minus } from 'lucide-svelte';
	import type { ListBlock } from '$lib/types/blocks';

	interface Props {
		block: ListBlock;
		onupdate?: (data: Partial<ListBlock>) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, onkeydown, ondelete }: Props = $props();

	function handleStyleChange(value: string) {
		const style = value as 'ordered' | 'unordered';
		onupdate?.({ style });
	}

	function handleItemChange(index: number, value: string) {
		const newItems = [...block.items];
		newItems[index] = value;
		onupdate?.({ items: newItems });
	}

	function addItem() {
		const newItems = [...block.items, ''];
		onupdate?.({ items: newItems });
	}

	function removeItem(index: number) {
		if (block.items.length <= 1) {
			ondelete?.();
			return;
		}
		
		const newItems = block.items.filter((_, i) => i !== index);
		onupdate?.({ items: newItems });
	}

	function handleKeyDown(event: KeyboardEvent, index: number) {
		if (event.key === 'Enter' && !event.shiftKey) {
			event.preventDefault();
			addItem();
			return;
		}
		
		if (event.key === 'Backspace' && !block.items[index].trim()) {
			event.preventDefault();
			removeItem(index);
			return;
		}
		
		onkeydown?.(event);
	}
</script>

<div class="space-y-4">
	<div class="flex items-center justify-between">
		<select 
			value={block.style}
			onchange={(e) => handleStyleChange((e.target as HTMLSelectElement).value)}
			class="px-3 py-1 border border-gray-300 rounded-md text-sm w-28"
		>
			<option value="unordered">• 목록</option>
			<option value="ordered">1. 번호</option>
		</select>
	</div>

	<div class="space-y-2">
		{#each block.items as item, index}
			<div class="flex items-center gap-3">
				<span class="text-sm text-gray-500 w-6 flex-shrink-0">
					{#if block.style === 'ordered'}
						{index + 1}.
					{:else}
						•
					{/if}
				</span>
				<Input
					value={item}
					placeholder="목록 항목을 입력하세요..."
					class="flex-1 border-none p-0 focus-visible:ring-0 focus-visible:ring-offset-0"
					oninput={(e) => handleItemChange(index, (e.target as HTMLInputElement).value)}
					onkeydown={(e) => handleKeyDown(e, index)}
				/>
				{#if block.items.length > 1}
					<Button
						variant="ghost"
						size="sm"
						class="h-6 w-6 p-0 text-red-500 hover:text-red-700"
						onclick={() => removeItem(index)}
					>
						<Minus class="h-3 w-3" />
					</Button>
				{/if}
			</div>
		{/each}
	</div>

	<Button
		variant="ghost"
		size="sm"
		onclick={addItem}
		class="text-sm text-gray-500 hover:text-gray-700"
	>
		<Plus class="mr-1 h-3 w-3" />
		항목 추가
	</Button>
</div>