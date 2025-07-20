<script lang="ts">
	import type { Block } from '$lib/types/blocks';
	import ParagraphBlock from './ParagraphBlock.svelte';
	import HeadingBlock from './HeadingBlock.svelte';
	import ImageBlock from './ImageBlock.svelte';
	import ListBlock from './ListBlock.svelte';
	import QuoteBlock from './QuoteBlock.svelte';
	import CodeBlock from './CodeBlock.svelte';
	import MapBlock from './MapBlock.svelte';
	import GridBlock from './GridBlock.svelte';
	import PostListBlock from './PostListBlock.svelte';
	import DividerBlock from './DividerBlock.svelte';
	import HtmlBlock from './HtmlBlock.svelte';

	interface Props {
		block: Block;
		isSelected?: boolean;
		onupdate?: (data: Partial<Block>) => void;
		onkeydown?: (event: KeyboardEvent) => void;
		ondelete?: () => void;
		onselect?: () => void;
		onTemplateSelect?: (template: any, columnId?: string) => void;
	}

	let { block, isSelected = false, onupdate, onkeydown, ondelete, onselect, onTemplateSelect }: Props = $props();

	function handleUpdate(data: Partial<Block>) {
		onupdate?.(data);
	}

	function handleKeyDown(event: KeyboardEvent) {
		onkeydown?.(event);
	}

	function handleDelete() {
		ondelete?.();
	}
</script>

{#if block.type === 'paragraph'}
	<ParagraphBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		onkeydown={handleKeyDown}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'heading'}
	<HeadingBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		onkeydown={handleKeyDown}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'image'}
	<ImageBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'list'}
	<ListBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		onkeydown={handleKeyDown}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'quote'}
	<QuoteBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		onkeydown={handleKeyDown}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'code'}
	<CodeBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'map'}
	<MapBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'grid'}
	<GridBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		ondelete={handleDelete}
		onselect={onselect}
		onTemplateSelect={onTemplateSelect}
	/>
{:else if block.type === 'post-list'}
	<PostListBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{:else if block.type === 'divider'}
	<DividerBlock 
		{isSelected}
		ondelete={handleDelete} 
		onselect={onselect}
	/>
{:else if block.type === 'html'}
	<HtmlBlock
		{block}
		{isSelected}
		onupdate={handleUpdate}
		ondelete={handleDelete}
		onselect={onselect}
	/>
{/if}