<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { adminLogout } from '$lib/api/admin';
	import { adminUser } from '$lib/stores/admin';
	import { MenuIcon, ChevronRightIcon, ChevronLeftIcon, BellIcon, UserIcon, LogOutIcon } from 'lucide-svelte';

	const { sidebarCollapsed, handleToggleSidebar, handleToggleCollapse } = $props<{
		sidebarCollapsed: boolean;
		handleToggleSidebar: () => void;
		handleToggleCollapse: () => void;
	}>();

	let showUserMenu = $state(false);
	const dispatch = createEventDispatcher();

	async function handleLogout() {
		try {
			await adminLogout();
			alert('로그아웃 되었습니다.');
		} catch (error) {
			console.error('로그아웃 실패:', error);
			alert('로그아웃 중 오류가 발생했습니다.');
		}
	}

	function handleLogoutClick(e: MouseEvent) {
		e.preventDefault();
		e.stopPropagation();
		showUserMenu = false;
		handleLogout();
	}
</script>

<header
	class="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b bg-white px-6 shadow-sm"
>
	<div class="flex items-center gap-4">
		<!-- 모바일/태블릿용 사이드바 토글 버튼 -->
		<button
			type="button"
			class="-ml-2 rounded-lg p-2 text-gray-600 hover:bg-gray-100 lg:hidden"
			onclick={handleToggleSidebar}
			aria-label="메뉴 열기"
		>
			<MenuIcon class="h-6 w-6" />
		</button>

		<!-- PC용 사이드바 토글 버튼 -->
		<button
			type="button"
			class="hidden rounded-lg p-2 text-gray-600 hover:bg-gray-100 lg:block"
			onclick={handleToggleCollapse}
			aria-label="사이드바 토글"
		>
			{#if sidebarCollapsed}
				<ChevronRightIcon class="h-6 w-6" />
			{:else}
				<ChevronLeftIcon class="h-6 w-6" />
			{/if}
		</button>
	</div>

	<div class="flex items-center gap-4">
		<button type="button" class="rounded-lg p-2 text-gray-600 hover:bg-gray-100" aria-label="알림">
			<BellIcon class="h-6 w-6" />
		</button>

		<div class="relative">
			<button
				type="button"
				class="flex items-center gap-2 rounded-lg p-2 text-gray-600 hover:bg-gray-100"
				onclick={(e) => {
					showUserMenu = !showUserMenu;
				}}
				aria-label="사용자 메뉴"
			>
				<UserIcon class="h-6 w-6" />
				<span class="hidden md:inline">{$adminUser?.name || '관리자'}</span>
			</button>

			{#if showUserMenu}
				<div
					class="absolute right-0 top-full z-50 mt-1 w-48 rounded-lg border bg-white py-1 shadow-lg"
				>
					<button
						class="flex w-full items-center gap-2 px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100"
						onclick={(e) => {
							e.preventDefault();
							e.stopPropagation();
							showUserMenu = false;
							handleLogout();
						}}
					>
						<LogOutIcon class="h-4 w-4" />
						로그아웃
					</button>
				</div>
			{/if}
		</div>
	</div>
</header>

{#if showUserMenu}
	<div class="fixed inset-0 z-10" style="z-index: 10;" onclick={() => (showUserMenu = false)} />
{/if}
