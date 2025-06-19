<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { adminUser } from '$lib/stores/admin';
	import { Button } from '$lib/components/ui/button';
	import { BellIcon, UserIcon, LogOutIcon, MenuIcon } from 'lucide-svelte';
	import { goto } from '$app/navigation';

	let showUserMenu = false;
	const dispatch = createEventDispatcher();

	function handleLogout() {
		localStorage.removeItem('admin_token');
		localStorage.removeItem('admin_user');
		adminUser.set(null);
		goto('/login');
	}
	function handleSidebarToggle() {
		dispatch('toggleSidebar');
	}
</script>

<header class="border-b border-gray-200 bg-white shadow-sm">
	<div class="flex h-16 items-center justify-between px-6">
		<!-- 햄버거 + 로고/타이틀 -->
		<div class="flex items-center gap-4">
			<button
				type="button"
				class="-ml-2 rounded-lg p-2 text-gray-600 hover:bg-gray-100 md:hidden"
				on:click={handleSidebarToggle}
				aria-label="메뉴 열기"
			>
				<MenuIcon class="h-6 w-6" />
			</button>
		</div>

		<!-- 우측 메뉴 -->
		<div class="flex items-center gap-4">
			<button
				type="button"
				class="rounded-lg p-2 text-gray-600 hover:bg-gray-100"
				aria-label="알림"
			>
				<BellIcon class="h-6 w-6" />
			</button>

			<!-- 사용자 메뉴 -->
			<div class="relative">
				<button
					type="button"
					class="flex items-center gap-2 rounded-lg p-2 text-gray-600 hover:bg-gray-100"
					on:click={() => (showUserMenu = !showUserMenu)}
					aria-label="사용자 메뉴"
				>
					<UserIcon class="h-6 w-6" />
					<span class="hidden md:inline">{$adminUser?.name || '관리자'}</span>
				</button>

				{#if showUserMenu}
					<div
						class="absolute right-0 top-full z-50 mt-1 w-48 rounded-lg border bg-white py-1 shadow-lg"
						on:click={() => (showUserMenu = false)}
					>
						<button
							class="flex w-full items-center gap-2 px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100"
							on:click={handleLogout}
						>
							<LogOutIcon class="h-4 w-4" />
							로그아웃
						</button>
					</div>
				{/if}
			</div>
		</div>
	</div>
</header>

<!-- 배경 클릭시 메뉴 닫기 -->
{#if showUserMenu}
	<div class="fixed inset-0 z-40" on:click={() => (showUserMenu = false)}></div>
{/if}
