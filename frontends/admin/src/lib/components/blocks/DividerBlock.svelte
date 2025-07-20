<script lang="ts">
	interface Props {
		ondelete?: () => void;
	}

	let { ondelete }: Props = $props();
</script>

<div class="flex items-center justify-center py-4">
	<hr class="flex-1 border-gray-300" />
	<span class="px-4 text-sm text-gray-500">구분선</span>
	<hr class="flex-1 border-gray-300" />
</div>