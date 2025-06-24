<script lang="ts">
	import { page } from '$app/stores';
	import { writable } from 'svelte/store';
	import { sineIn } from 'svelte/easing';
	import { slide } from 'svelte/transition';
	import { cn } from '$lib/utils';
	import {
		Home,
		Users,
		FileText,
		Folder,
		Settings,
		BarChart3,
		Bell,
		Heart,
		Gift,
		Server,
		Globe,
		Menu as MenuIcon,
		Calendar,
		ImageIcon,
		BookOpen,
		ChevronDown,
		ChevronRight
	} from 'lucide-svelte';

	export let sidebarOpen = false;
	export let sidebarCollapsed = false;
	export let handleCloseSidebar: () => void;

	const menus = [
		{ title: '대시보드', href: '/', icon: Home },
		{
			title: '사이트 관리',
			icon: Globe,
			children: [
				{ title: '사이트 설정', href: '/site/settings' },
				{ title: '관리자 설정', href: '/site/admins' },
				{ title: '역할 및 권한', href: '/site/roles' }
			]
		},
		{ title: '메뉴 관리', href: '/menus', icon: MenuIcon },
		{ title: '랜딩 페이지', href: '/landing', icon: ImageIcon },
		{ title: '안내 페이지', href: '/pages', icon: BookOpen },
		{ title: '사용자 관리', href: '/users', icon: Users },
		{ title: '게시판 관리', href: '/boards', icon: Folder },
		{ title: '게시글 관리', href: '/posts', icon: FileText },
		{ title: '댓글 관리', href: '/comments', icon: FileText },
		{ title: '봉사 활동', href: '/volunteer', icon: Heart },
		{ title: '후원 관리', href: '/donations', icon: Gift },
		{ title: '일정 관리', href: '/calendar', icon: Calendar },
		{ title: '알림 관리', href: '/notifications', icon: Bell },
		{ title: '접속 통계', href: '/analytics', icon: BarChart3 },
		{ title: '시스템 관리', href: '/system', icon: Server }
	];

	let expandedMenus = writable<Set<string>>(new Set());
	let activeFlyout = writable<string | null>(null);
	let isTablet = false;

	// Detect tablet state
	$: {
		if (typeof window !== 'undefined') {
			const mediaQuery = window.matchMedia('(min-width: 768px) and (max-width: 1023px)');
			isTablet = mediaQuery.matches;
		}
	}

	// Auto-expand menu on page load based on current URL
	$: {
		const newExpanded = new Set<string>();
		const currentPath = $page.url.pathname;
		for (const menu of menus) {
			if (menu.children) {
				for (const child of menu.children) {
					if (currentPath.startsWith(child.href)) {
						newExpanded.add(menu.title);
						break;
					}
				}
			}
		}
		expandedMenus.set(newExpanded);
	}

	// Close flyout on navigation
	page.subscribe(() => {
		activeFlyout.set(null);
	});

	function toggleMenu(title: string) {
		expandedMenus.update((set) => {
			if (set.has(title)) {
				set.delete(title);
			} else {
				set.add(title);
			}
			return set;
		});
	}

	function handleParentMenuClick(title: string) {
		if (sidebarCollapsed && isTablet) {
			// Tablet collapsed mode: toggle dropdown
			activeFlyout.update((current) => (current === title ? null : title));
		} else {
			// Desktop/expanded mode: toggle inline submenu
			toggleMenu(title);
		}
	}

	function handleMenuClick(href: string) {
		if (sidebarCollapsed && isTablet) {
			activeFlyout.set(null);
		}
		handleCloseSidebar();
	}
</script>

<!-- Overlay for mobile -->
{#if sidebarOpen}
	<div class="fixed inset-0 z-40 bg-black bg-opacity-50 md:hidden" onclick={handleCloseSidebar} />
{/if}

<aside
	class={cn(
		'bg-card text-card-foreground fixed left-0 top-0 z-50 h-screen border-r transition-all duration-300',
		sidebarOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0',
		sidebarCollapsed ? 'w-16' : 'w-64'
	)}
>
	<div class="flex h-16 items-center justify-center border-b">
		<a href="/" onclick={handleCloseSidebar}>
			<img
				src={sidebarCollapsed ? '/images/min_logo.png' : '/images/mincenter_logo.png'}
				alt="Logo"
				class={cn('h-8 w-auto transition-all', sidebarCollapsed ? 'w-8' : 'w-32')}
			/>
		</a>
	</div>

	<nav class="flex flex-col space-y-1 p-2">
		{#each menus as menu (menu.title)}
			{#if !menu.children}
				<a
					href={menu.href}
					onclick={() => handleMenuClick(menu.href)}
					class={cn(
						'hover:bg-muted flex items-center rounded-md p-2 text-sm font-medium transition-colors',
						$page.url.pathname === menu.href
							? 'bg-primary text-primary-foreground'
							: 'text-muted-foreground',
						sidebarCollapsed && 'justify-center'
					)}
					title={sidebarCollapsed ? menu.title : ''}
				>
					<svelte:component this={menu.icon} class="h-6 w-6" />
					<span class={cn('ml-3', sidebarCollapsed && 'hidden')}>{menu.title}</span>
				</a>
			{:else}
				<div class="relative">
					<button
						onclick={() => handleParentMenuClick(menu.title)}
						class={cn(
							'hover:bg-muted text-muted-foreground flex w-full items-center rounded-md p-2 text-sm font-medium transition-colors',
							sidebarCollapsed && 'justify-center'
						)}
						title={sidebarCollapsed ? menu.title : ''}
					>
						<svelte:component this={menu.icon} class="h-6 w-6" />
						<span class={cn('ml-3', sidebarCollapsed && 'hidden')}>{menu.title}</span>
						{#if !sidebarCollapsed}
							<ChevronDown
								class={cn(
									'ml-auto h-4 w-4 transition-transform',
									$expandedMenus.has(menu.title) ? 'rotate-180' : ''
								)}
							/>
						{:else if isTablet}
							<ChevronRight class="ml-auto h-4 w-4" />
						{/if}
					</button>

					<!-- Dropdown for tablet collapsed mode -->
					{#if sidebarCollapsed && isTablet && $activeFlyout === menu.title}
						<div
							class="bg-card absolute left-full top-0 z-50 ml-2 w-48 rounded-md border p-2 shadow-lg"
							transition:slide={{ duration: 150, axis: 'x' }}
						>
							<div class="text-card-foreground mb-2 border-b px-2 py-1 font-semibold">
								{menu.title}
							</div>
							<div class="flex flex-col space-y-1">
								{#each menu.children as child (child.href)}
									<a
										href={child.href}
										onclick={() => handleMenuClick(child.href)}
										class={cn(
											'hover:bg-muted flex items-center rounded-md p-2 text-sm transition-colors',
											$page.url.pathname.startsWith(child.href)
												? 'bg-primary text-primary-foreground font-semibold'
												: 'text-card-foreground'
										)}
									>
										{child.title}
									</a>
								{/each}
							</div>
						</div>
					{/if}

					<!-- Inline submenu for desktop/expanded mode -->
					{#if !sidebarCollapsed && $expandedMenus.has(menu.title)}
						<div transition:slide={{ duration: 200, easing: sineIn }} class="mt-1 space-y-1 pl-6">
							{#each menu.children as child (child.href)}
								<a
									href={child.href}
									onclick={() => handleMenuClick(child.href)}
									class={cn(
										'hover:bg-muted flex items-center rounded-md p-2 text-sm transition-colors',
										$page.url.pathname.startsWith(child.href)
											? 'bg-muted text-primary font-semibold'
											: 'text-muted-foreground font-medium'
									)}
								>
									{child.title}
								</a>
							{/each}
						</div>
					{/if}
				</div>
			{/if}
		{/each}
	</nav>
</aside>
