<script lang="ts">
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import Footer from '$lib/components/layout/Footer.svelte';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { initializeAuth } from '$lib/stores/auth';

	// 페이지 로드 시 인증 상태 초기화
	onMount(() => {
		initializeAuth();
	});
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
