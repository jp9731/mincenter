<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Icon, Bars3, XMark, User, ArrowRightOnRectangle } from 'svelte-hero-icons';
	import { user, isAuthenticated, logout } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { getSiteMenus, type MenuTree, DEFAULT_MENUS } from '$lib/api/site.js';
	import { User as UserIcon, LogOut, CreditCard, Settings } from 'lucide-svelte';
	import {
		DropdownMenu,
		DropdownMenuContent,
		DropdownMenuItem,
		DropdownMenuSeparator,
		DropdownMenuTrigger
	} from '$lib/components/ui/dropdown-menu';

	let mobileMenuOpen = false;
	let menus: MenuTree[] = [];
	let loading = true;
	let error: string | null = null;

	onMount(async () => {
		try {
			const response = await getSiteMenus();
			if (response.success && response.data) {
				menus = response.data.menus;
				console.log('메뉴 로드 성공:', menus.length, '개 메뉴');
			} else {
				console.warn('API 응답이 성공이지만 데이터가 없습니다. 기본 메뉴를 사용합니다.');
				menus = DEFAULT_MENUS;
			}
		} catch (error) {
			console.error('메뉴 로드 실패:', error);
			error = error instanceof Error ? error.message : '알 수 없는 오류';
			
			// 오류가 발생해도 기본 메뉴를 사용하여 사이트가 정상 작동하도록 함
			menus = DEFAULT_MENUS;
			console.log('기본 메뉴를 사용합니다:', menus.length, '개 메뉴');
		} finally {
			loading = false;
		}
	});

	// 로그아웃 처리
	async function handleLogout() {
		// console.log('handleLogout');
		await logout();
		goto('/');
	}

	function getMenuUrl(menu: MenuTree): string {
		if (menu.url) {
			return menu.url;
		}
		if (menu.menu_type.toLowerCase() === 'board' && menu.slug) {
			return `/community/${menu.slug}`;
		}
		if (menu.menu_type.toLowerCase() === 'page' && menu.slug) {
			return `/pages/${menu.slug}`;
		}
		if (menu.menu_type.toLowerCase() === 'calendar') {
			return '/calendar';
		}
		return '#';
	}

	function isActiveMenu(menu: MenuTree): boolean {
		const menuUrl = getMenuUrl(menu);
		return $page.url.pathname.startsWith(menuUrl);
	}
</script>

<header class="sticky top-0 z-50 border-b bg-white shadow-sm">
	<nav class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" aria-label="메인 내비게이션">
		<div class="flex h-16 justify-between">
			<!-- 로고 -->
			<div class="flex flex-shrink-0 items-center">
				<a href="/" class="text-primary-600 text-xl font-bold">
					<img
						src="/images/mincenter_logo.png"
						alt="민들레장애인자립생활센터"
						class="mb-2 h-12 w-auto"
					/>
				</a>
			</div>

			<!-- 데스크톱 메뉴 -->
			<div class="hidden md:flex md:items-center md:space-x-8">
				{#if !loading}
					{#each menus as menu}
						<div class="group relative">
							<a
								href={getMenuUrl(menu)}
								class="hover:text-primary-600 px-3 py-2 text-sm font-medium text-gray-700"
								class:border-b-2={isActiveMenu(menu)}
								class:border-primary-600={isActiveMenu(menu)}
							>
								{menu.name}
							</a>
							{#if menu.children && menu.children.length > 0}
								<div
									class="invisible absolute left-0 z-50 mt-2 w-48 rounded-md bg-white opacity-0 shadow-lg transition-all duration-200 group-hover:visible group-hover:opacity-100"
								>
									<div class="py-1">
										{#each menu.children as child}
											<a
												href={getMenuUrl(child)}
												class="hover:text-primary-600 block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
												class:bg-primary-50={isActiveMenu(child)}
												class:text-primary-600={isActiveMenu(child)}
											>
												{child.name}
											</a>
										{/each}
									</div>
								</div>
							{/if}
						</div>
					{/each}
				{/if}

				<div class="flex items-center">
					{#if $isAuthenticated && $user}
						<!-- 로그인 상태: PC 드롭다운/모바일 기존 방식 -->
						<DropdownMenu>
							<DropdownMenuTrigger asChild>
								<button class="flex items-center gap-2 rounded-md px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 focus:outline-none">
									{#if $user.profile_image}
										<img src="{$user.profile_image}" alt="프로필 이미지" class="w-8 h-8 rounded-full object-cover border" />
									{:else}
										<UserIcon class="w-6 h-6" />
									{/if}
									<span>{$user.name} 님</span>
								</button>
							</DropdownMenuTrigger>
							<DropdownMenuContent class="w-56">
								<div class="px-2 py-1.5 text-sm text-gray-600">
									포인트: {($user.points ?? 0).toLocaleString()}
								</div>
								<DropdownMenuSeparator />
								<DropdownMenuItem asChild>
									<a href="/my" class="flex items-center gap-2">
										<Settings class="h-4 w-4" />
										마이페이지
									</a>
								</DropdownMenuItem>
								<DropdownMenuItem onclick={handleLogout} class="flex items-center gap-2 text-red-600 focus:text-red-600">
									<LogOut class="h-4 w-4" />
									로그아웃
								</DropdownMenuItem>
							</DropdownMenuContent>
						</DropdownMenu>
						<div class="flex md:hidden items-center gap-2">
							<span>안녕하세요, {$user.name}님</span>
							<div class="text-sm text-gray-600">포인트: {($user.points ?? 0).toLocaleString()}</div>
							<a href="/my" class="flex items-center gap-1">
								<Settings class="h-4 w-4" />
								마이페이지
							</a>
							<button type="button" onclick={handleLogout} class="flex items-center gap-1">
								<LogOut class="h-4 w-4" />
								로그아웃
							</button>
						</div>
					{:else}
						<!-- 비로그인 상태: 로그인/회원가입 버튼 -->
						<div class="flex items-center gap-2">
							<Button variant="ghost" href="/auth/login">로그인</Button>
							<Button href="/auth/register">회원가입</Button>
						</div>
					{/if}
				</div>
			</div>

			<!-- 모바일 메뉴 버튼 -->
			<div class="flex items-center md:hidden">
				<button
					type="button"
					class="hover:text-primary-600 focus:ring-primary-500 inline-flex items-center justify-center rounded-md p-2 text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset"
					aria-controls="mobile-menu"
					aria-expanded={mobileMenuOpen}
					onclick={() => (mobileMenuOpen = !mobileMenuOpen)}
				>
					<span class="sr-only">메뉴 열기</span>
					{#if mobileMenuOpen}
						<Icon src={XMark} class="block h-6 w-6" aria-hidden="true" />
					{:else}
						<Icon src={Bars3} class="block h-6 w-6" aria-hidden="true" />
					{/if}
				</button>
			</div>
		</div>

		<!-- 모바일 메뉴 -->
		{#if mobileMenuOpen}
			<div class="md:hidden" id="mobile-menu">
				<div class="space-y-1 pb-3 pt-2">
					{#if !loading}
						{#each menus as menu}
							<div>
								<a
									href={getMenuUrl(menu)}
									class="hover:text-primary-600 block px-3 py-2 text-base font-medium text-gray-700 hover:bg-gray-50"
									class:bg-primary-50={isActiveMenu(menu)}
									class:text-primary-600={isActiveMenu(menu)}
								>
									{menu.name}
								</a>
								{#if menu.children && menu.children.length > 0}
									<div class="ml-4 space-y-1">
										{#each menu.children as child}
											<a
												href={getMenuUrl(child)}
												class="hover:text-primary-600 block px-3 py-2 text-sm text-gray-600 hover:bg-gray-50"
												class:bg-primary-50={isActiveMenu(child)}
												class:text-primary-600={isActiveMenu(child)}
											>
												{child.name}
											</a>
										{/each}
									</div>
								{/if}
							</div>
						{/each}
					{/if}
				</div>
				<div class="border-t border-gray-200 pb-3 pt-4">
					{#if $isAuthenticated && $user}
						<!-- 로그인된 상태 (모바일) -->
						<div class="px-5 py-3">
							<div class="mb-3 text-sm text-gray-700">안녕하세요, {$user.name}님</div>
							<div class="space-y-2">
								<!-- 포인트 정보 -->
								<div class="px-3 py-2 text-sm text-gray-600 bg-gray-50 rounded-md">
									<div class="flex items-center justify-between">
										<span class="flex items-center gap-2">
											<CreditCard class="h-4 w-4" />
											포인트
										</span>
										<span class="font-semibold text-primary-600">{$user.points || 0}P</span>
									</div>
								</div>
								<Button variant="ghost" href="/my" class="w-full justify-start">
									{#if $user.profile_image}
										<img src="{$user.profile_image}" alt="프로필 이미지" class="w-6 h-6 rounded-full object-cover border mr-2" />
									{:else}
										<Settings class="mr-2 h-4 w-4" />
									{/if}
									마이페이지
								</Button>
								<Button variant="outline" onclick={handleLogout} class="w-full justify-start text-red-600 hover:text-red-600">
									<LogOut class="mr-2 h-4 w-4" />
									로그아웃
								</Button>
							</div>
						</div>
					{:else}
						<!-- 로그인되지 않은 상태 (모바일) -->
						<div class="flex items-center px-5">
							<div class="flex-shrink-0">
								<Button variant="ghost" href="/auth/login" class="w-full">로그인</Button>
							</div>
							<div class="ml-3">
								<Button href="/auth/register" class="w-full">회원가입</Button>
							</div>
						</div>
					{/if}
				</div>
			</div>
		{/if}
	</nav>
</header>
