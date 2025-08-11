<script lang="ts">
	import '../app.css';
	import Header from '$lib/components/layout/Header.svelte';
	import Footer from '$lib/components/layout/Footer.svelte';
	import GlobalAlertDialog from '$lib/components/GlobalAlertDialog.svelte';

	import { onMount } from 'svelte';
	import { user, isAuthenticated } from '$lib/stores/auth';
	import type { LayoutData } from './$types';

	export let data: LayoutData;

	// 서버에서 로드한 사용자 정보를 스토어에 동기화
	$: if (data.user) {
		user.set(data.user);
		isAuthenticated.set(data.isAuthenticated);
	} else if (data.isAuthenticated === false) {
		user.set(null);
		isAuthenticated.set(false);
	}

	// 페이지 로드 시 인증 상태 재확인 (클라이언트 사이드에서)
	onMount(() => {
		// 서버에서 사용자 정보가 없었다면 클라이언트에서 다시 확인
		if (!data.user) {
			import('$lib/stores/auth').then(({ initializeAuth }) => {
				initializeAuth();
			});
		}
	});
</script>

<div class="flex min-h-screen flex-col">
	<Header />
	<main class="flex-1">
		<slot />
	</main>
	<Footer />
	
	<!-- 전역 AlertDialog -->
	<GlobalAlertDialog />
</div>

<style>
	:global(html) {
		scroll-behavior: smooth;
	}
</style>
