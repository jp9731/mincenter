<script lang="ts">
	import '../app.css';
	import AdminSidebar from '$lib/components/admin/layout/AdminSidebar.svelte';
	import AdminHeader from '$lib/components/admin/layout/AdminHeader.svelte';
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';

	let isLoggedIn = false;
	let isLoginPage = false;
	let sidebarOpen = false;
	let sidebarCollapsed = false;

	onMount(() => {
		if (browser) {
			const token = localStorage.getItem('admin_token');
			isLoggedIn = !!token;
			isLoginPage = window.location.pathname === '/login';
			// 저장된 사이드바 상태 복원
			sidebarCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
		}
	});

	function handleToggleSidebar() {
		sidebarOpen = !sidebarOpen;
	}
	function handleCloseSidebar() {
		sidebarOpen = false;
	}
</script>

{#if isLoggedIn && !isLoginPage}
	<div class="flex min-h-screen bg-gray-50">
		<!-- 사이드바 -->
		<AdminSidebar {sidebarOpen} {sidebarCollapsed} on:closeSidebar={handleCloseSidebar} />

		<!-- 메인 콘텐츠 -->
		<div
			class="flex flex-1 flex-col transition-all duration-200 ease-in-out
			{sidebarCollapsed ? 'lg:ml-20' : 'lg:ml-64'}
			md:ml-20"
		>
			<AdminHeader on:toggleSidebar={handleToggleSidebar} />

			<main class="flex-1 p-6">
				<slot />
			</main>
		</div>
	</div>
{:else}
	<!-- 로그인 페이지 또는 로딩 상태 -->
	<slot />
{/if}
