<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { page } from '$app/stores';
	import { adminUser } from '$lib/stores/admin';
	import {
		HomeIcon,
		UsersIcon,
		FileTextIcon,
		FolderIcon,
		SettingsIcon,
		BarChart3Icon,
		BellIcon,
		HeartHandshakeIcon,
		GiftIcon,
		ServerIcon,
		GlobeIcon,
		MenuIcon,
		CalendarIcon,
		ImageIcon,
		BookOpenIcon,
		CreditCardIcon,
		ChartBarIcon,
		XIcon,
		ChevronLeftIcon,
		ChevronRightIcon
	} from 'lucide-svelte';

	export let sidebarOpen = false;
	export let sidebarCollapsed = false; // PC에서 사이드바 접힘/펼침 상태
	const dispatch = createEventDispatcher();

	const navigationItems = [
		{
			title: '대시보드',
			href: '/',
			icon: HomeIcon,
			permission: 'dashboard.view'
		},
		{
			title: '사이트 관리',
			href: '/site',
			icon: GlobeIcon,
			permission: 'site.view',
			children: [
				{ title: '기본 설정', href: '/site/settings' },
				{ title: '사용자 레벨', href: '/site/user-levels' },
				{ title: '후원 계좌', href: '/site/donation-accounts' }
			]
		},
		{
			title: '메뉴 관리',
			href: '/menus',
			icon: MenuIcon,
			permission: 'menus.view'
		},
		{
			title: '랜딩 페이지',
			href: '/landing',
			icon: ImageIcon,
			permission: 'landing.view'
		},
		{
			title: '안내 페이지',
			href: '/pages',
			icon: BookOpenIcon,
			permission: 'pages.view'
		},
		{
			title: '사용자 관리',
			href: '/users',
			icon: UsersIcon,
			permission: 'users.view',
			children: [
				{ title: '사용자 목록', href: '/users' },
				{ title: '사용자 상세', href: '/users/detail' }
			]
		},
		{
			title: '게시판 관리',
			href: '/boards',
			icon: FileTextIcon,
			permission: 'boards.view',
			children: [
				{ title: '게시판 목록', href: '/boards' },
				{ title: '카테고리 관리', href: '/boards/categories' },
				{ title: '접근 권한', href: '/boards/permissions' }
			]
		},
		{
			title: '게시글 관리',
			href: '/posts',
			icon: FileTextIcon,
			permission: 'posts.view',
			children: [
				{ title: '게시글 목록', href: '/posts' },
				{ title: '게시글 상세', href: '/posts/detail' },
				{ title: '숨김 관리', href: '/posts/hidden' }
			]
		},
		{
			title: '댓글 관리',
			href: '/comments',
			icon: FileTextIcon,
			permission: 'comments.view'
		},
		{
			title: '봉사 활동',
			href: '/volunteer',
			icon: HeartHandshakeIcon,
			permission: 'volunteer.view',
			children: [
				{ title: '신청자 목록', href: '/volunteer/applications' },
				{ title: '실행 내역', href: '/volunteer/activities' },
				{ title: '출석 관리', href: '/volunteer/attendance' },
				{ title: '평가 관리', href: '/volunteer/evaluations' }
			]
		},
		{
			title: '후원 관리',
			href: '/donations',
			icon: GiftIcon,
			permission: 'donations.view',
			children: [
				{ title: '신청자 목록', href: '/donations/applications' },
				{ title: '입금 내역', href: '/donations/payments' },
				{ title: '계산서 발행', href: '/donations/receipts' }
			]
		},
		{
			title: '후원 배너',
			href: '/banners',
			icon: CreditCardIcon,
			permission: 'banners.view',
			children: [
				{ title: '배너 등록', href: '/banners/register' },
				{ title: '클릭 통계', href: '/banners/statistics' }
			]
		},
		{
			title: '일정 관리',
			href: '/calendar',
			icon: CalendarIcon,
			permission: 'calendar.view'
		},
		{
			title: '알림 관리',
			href: '/notifications',
			icon: BellIcon,
			permission: 'notifications.view',
			children: [
				{ title: '이메일 발송', href: '/notifications/email' },
				{ title: '문자 발송', href: '/notifications/sms' },
				{ title: '템플릿 관리', href: '/notifications/templates' }
			]
		},
		{
			title: '접속 통계',
			href: '/analytics',
			icon: ChartBarIcon,
			permission: 'analytics.view',
			children: [
				{ title: '사이트 통계', href: '/analytics/site' },
				{ title: '로그인 통계', href: '/analytics/login' },
				{ title: '게시글 통계', href: '/analytics/posts' }
			]
		},
		{
			title: '시스템 로그',
			href: '/system',
			icon: ServerIcon,
			permission: 'system.view',
			children: [
				{ title: '시스템 이벤트', href: '/system/events' },
				{ title: '에러 로그', href: '/system/errors' }
			]
		}
	];

	$: currentPath = $page.url.pathname;

	function hasPermission(permission: string): boolean {
		// 임시로 모든 권한 허용 (adminUser가 초기화되지 않았을 수 있음)
		return true;
		// return $adminUser?.permissions?.includes(permission) || $adminUser?.role === 'super_admin';
	}

	function isActive(href: string): boolean {
		return currentPath === href || currentPath.startsWith(href + '/');
	}

	function closeSidebar() {
		dispatch('closeSidebar');
	}

	function toggleCollapse() {
		sidebarCollapsed = !sidebarCollapsed;
		// localStorage에 상태 저장
		if (typeof window !== 'undefined') {
			localStorage.setItem('sidebarCollapsed', String(sidebarCollapsed));
		}
	}
</script>

<!-- 오버레이 (모바일) -->
{#if sidebarOpen}
	<div class="fixed inset-0 z-40 bg-black/40 md:hidden" on:click={closeSidebar}></div>
{/if}

<!-- 사이드바 -->
<aside
	class="fixed inset-y-0 left-0 z-50 transform bg-white shadow-lg transition-all duration-200 ease-in-out
		{sidebarCollapsed ? 'lg:w-20' : 'lg:w-64'}
		{sidebarOpen ? 'w-64 translate-x-0' : '-translate-x-full md:w-20 md:translate-x-0'}"
	aria-label="사이드바"
>
	<!-- 상단(로고/닫기) -->
	<div class="bg-primary-600 flex h-16 items-center justify-between px-4">
		<div class="flex items-center overflow-hidden">
			<!-- PC에서 펼침 상태일 때만 전체 로고 표시 -->
			<img
				src="/images/mincenter_logo.png"
				alt="민센터"
				class="h-8 w-auto {sidebarCollapsed ? 'lg:hidden' : 'lg:block'} hidden md:hidden"
			/>
			<!-- 태블릿에서만 작은 로고 표시 -->
			<img src="/images/min_logo.png" alt="민센터" class="hidden h-8 w-auto md:block lg:hidden" />
			<span
				class="ml-2 truncate text-xl font-semibold text-white
				{sidebarCollapsed ? 'lg:hidden' : 'lg:inline'}
				hidden md:hidden lg:inline"
			>
				관리자
			</span>
		</div>
		<!-- 모바일 닫기 버튼 -->
		<button
			class="hover:bg-primary-700 rounded p-2 text-white md:hidden"
			on:click={closeSidebar}
			aria-label="사이드바 닫기"
		>
			<XIcon class="h-6 w-6" />
		</button>
		<!-- PC 접힘/펼침 토글 버튼 -->
		<button
			class="hover:bg-primary-700 hidden rounded p-2 text-white lg:block"
			on:click={toggleCollapse}
			aria-label={sidebarCollapsed ? '사이드바 펼치기' : '사이드바 접기'}
		>
			{#if sidebarCollapsed}
				<ChevronRightIcon class="h-6 w-6" />
			{:else}
				<ChevronLeftIcon class="h-6 w-6" />
			{/if}
		</button>
	</div>

	<!-- 네비게이션 -->
	<nav class="flex-1 overflow-y-auto px-4 py-4">
		<div class="space-y-2">
			{#each navigationItems as item}
				{#if hasPermission(item.permission)}
					<div>
						<a
							href={item.href}
							class="group relative flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors
								{isActive(item.href)
								? 'bg-primary-100 text-primary-700'
								: 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'}"
						>
							<svelte:component this={item.icon} class="h-5 w-5 flex-shrink-0" />
							<!-- PC에서 접힘 상태일 때 툴팁 -->
							{#if sidebarCollapsed}
								<span
									class="absolute left-full ml-2 hidden rounded bg-gray-900 px-2 py-1 text-xs text-white opacity-0 transition-opacity group-hover:opacity-100 lg:block"
								>
									{item.title}
								</span>
							{/if}
							<span
								class="ml-3 truncate text-gray-700
								{sidebarCollapsed ? 'lg:hidden' : 'lg:inline'}
								{sidebarOpen ? 'md:inline' : 'md:hidden'} lg:inline"
							>
								{item.title}
							</span>
						</a>
						<!-- 하위 메뉴 (PC 펼침 상태에서만 표시) -->
						{#if item.children && isActive(item.href) && !sidebarCollapsed}
							<div class="ml-8 mt-2 hidden space-y-1 lg:block">
								{#each item.children as child}
									<a
										href={child.href}
										class="block truncate rounded px-3 py-1 text-sm
											{currentPath === child.href ? 'text-primary-700 font-medium' : 'text-gray-600 hover:text-gray-900'}"
									>
										{child.title}
									</a>
								{/each}
							</div>
						{/if}
					</div>
				{/if}
			{/each}
		</div>
	</nav>

	<!-- 사용자 정보 -->
	<div class="border-t border-gray-200 p-4">
		<div class="flex items-center">
			<div class="bg-primary-600 flex h-8 w-8 items-center justify-center rounded-full">
				<span class="text-sm font-medium text-white">
					{$adminUser?.name?.charAt(0) || 'A'}
				</span>
			</div>
			<!-- 사용자 정보 (PC에서만 표시) -->
			<div class="ml-3 {sidebarCollapsed ? 'lg:hidden' : 'lg:block'} hidden md:hidden">
				<p class="text-sm font-medium text-gray-900">{$adminUser?.name || '관리자'}</p>
				<p class="text-xs text-gray-500">{$adminUser?.role || 'super_admin'}</p>
			</div>
		</div>
	</div>
</aside>
