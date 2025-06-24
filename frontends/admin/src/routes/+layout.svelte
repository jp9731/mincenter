<script lang="ts">
	import '../app.css';
	import AdminSidebar from '$lib/components/admin/layout/AdminSidebar.svelte';
	import AdminHeader from '$lib/components/admin/layout/AdminHeader.svelte';
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import { isAdminAuthenticated, initializeAdminAuth } from '$lib/stores/admin';
	import { page } from '$app/stores';

	let sidebarOpen = false;
	let sidebarCollapsed = false;
	let isMobile = false;
	let isTablet = false;

	onMount(async () => {
		if (browser) {
			await initializeAdminAuth();

			const mediaQueryMobile = window.matchMedia('(max-width: 767px)');
			const mediaQueryTablet = window.matchMedia('(min-width: 768px) and (max-width: 1023px)');

			isMobile = mediaQueryMobile.matches;
			isTablet = mediaQueryTablet.matches;

			// 태블릿에서는 기본적으로 축소된 상태로 시작
			if (isTablet) {
				sidebarCollapsed = true;
			} else {
				sidebarCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
			}

			// 화면 크기 변경 감지
			mediaQueryMobile.addEventListener('change', (e) => {
				isMobile = e.matches;
				if (e.matches) {
					sidebarCollapsed = false;
					sidebarOpen = false;
				}
			});

			mediaQueryTablet.addEventListener('change', (e) => {
				isTablet = e.matches;
				if (e.matches) {
					sidebarCollapsed = true;
					sidebarOpen = false;
				} else {
					// 데스크톱으로 변경 시 저장된 설정 사용
					sidebarCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
				}
			});
		}
	});

	function handleToggleSidebar() {
		sidebarOpen = !sidebarOpen;
	}

	function handleCloseSidebar() {
		sidebarOpen = false;
	}

	function handleToggleCollapse() {
		sidebarCollapsed = !sidebarCollapsed;
		if (!isTablet) {
			localStorage.setItem('sidebarCollapsed', sidebarCollapsed.toString());
		}
	}

	$: isLoginPage = $page.url.pathname === '/login';

	$: mainMargin = (() => {
		if (isMobile) return '0';
		if (sidebarCollapsed) return '4rem';
		return '16rem';
	})();
</script>

{#if $isAdminAuthenticated && !isLoginPage}
	<div class="min-h-screen bg-gray-50">
		<AdminSidebar {sidebarOpen} {sidebarCollapsed} {handleCloseSidebar} />

		<div class="transition-all duration-300 ease-in-out" style="margin-left: {mainMargin};">
			<AdminHeader {sidebarCollapsed} {handleToggleSidebar} {handleToggleCollapse} />
			<main class="p-6">
				<slot />
			</main>
		</div>
	</div>
{:else}
	<slot />
{/if}
