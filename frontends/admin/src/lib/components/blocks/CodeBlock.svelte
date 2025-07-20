<script lang="ts">
	import { Textarea } from '$lib/components/ui/textarea';
	import { Input } from '$lib/components/ui/input';
	import type { CodeBlock } from '$lib/types/blocks';

	interface Props {
		block: CodeBlock;
		onupdate?: (data: Partial<CodeBlock>) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, ondelete }: Props = $props();

	function handleContentChange(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		onupdate?.({ content: target.value });
	}

	function handleLanguageChange(event: Event) {
		const target = event.target as HTMLInputElement;
		onupdate?.({ language: target.value });
	}
</script>

<div class="space-y-3">
	<Input
		value={block.language || ''}
		placeholder="언어 (예: javascript, python, html)"
		class="text-sm"
		oninput={handleLanguageChange}
	/>
	
	<div class="bg-gray-100 rounded-md p-3">
		<Textarea
			value={block.content}
			placeholder="코드를 입력하세요..."
			rows={6}
			class="bg-transparent border-none p-0 resize-none focus-visible:ring-0 focus-visible:ring-offset-0 font-mono text-sm"
			oninput={handleContentChange}
		/>
	</div>
</div>