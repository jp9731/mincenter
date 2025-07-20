<script lang="ts">
	import { Textarea } from '$lib/components/ui/textarea';
	import { Button } from '$lib/components/ui/button';
	import { Eye, Code } from 'lucide-svelte';
	import type { HtmlBlock } from '$lib/types/blocks';

	interface Props {
		block: HtmlBlock;
		onupdate?: (data: Partial<HtmlBlock>) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, ondelete }: Props = $props();

	let showPreview = $state(false);

	function handleContentChange(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		onupdate?.({ content: target.value });
	}

	function togglePreview() {
		showPreview = !showPreview;
	}
</script>

<div class="space-y-3">
	<div class="flex items-center justify-between">
		<span class="text-sm font-medium">HTML 코드</span>
		<Button
			variant="outline"
			size="sm"
			onclick={togglePreview}
		>
			{#if showPreview}
				<Code class="mr-1 h-3 w-3" />
				편집
			{:else}
				<Eye class="mr-1 h-3 w-3" />
				미리보기
			{/if}
		</Button>
	</div>

	{#if showPreview}
		<div class="border rounded-md p-4 bg-gray-50">
			{#if block.content.trim()}
				{@html block.content}
			{:else}
				<p class="text-gray-500 text-sm">HTML 코드를 입력하면 여기에 미리보기가 표시됩니다.</p>
			{/if}
		</div>
	{:else}
		<div class="bg-gray-100 rounded-md p-3">
			<Textarea
				value={block.content}
				placeholder="HTML 코드를 입력하세요..."
				rows={6}
				class="bg-transparent border-none p-0 resize-none focus-visible:ring-0 focus-visible:ring-offset-0 font-mono text-sm"
				oninput={handleContentChange}
			/>
		</div>
	{/if}
</div>