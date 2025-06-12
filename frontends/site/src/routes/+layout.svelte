<script lang="ts">
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import Footer from '$lib/components/layout/Footer.svelte';
	import { page } from '$app/stores';
</script>

<div class="flex min-h-screen flex-col">
	<Header />
	<main class="flex-1">
		<slot />
	</main>
	<Footer />
</div>

<style>
	:global(html) {
		scroll-behavior: smooth;
	}
</style>
