<script lang="ts">
	// 필요시 import만 유지
</script>

<main class="flex-1">
	<div class="max-w-6xl mx-auto px-4">
		<slot />
	</div>
</main>

<style>
	:global(html) {
		scroll-behavior: smooth;
	}
</style> 