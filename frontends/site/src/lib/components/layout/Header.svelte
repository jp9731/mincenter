<script lang="ts">
	import { page } from '$app/stores';
	import { Button } from '$lib/components/ui/button';
	import { Menu, X } from 'lucide-svelte';

	let mobileMenuOpen = false;

	const navigation = [
		{ name: '센터소개', href: '/about' },
		{ name: '사업안내', href: '/services' },
		{ name: '커뮤니티', href: '/community' },
		{ name: '갤러리', href: '/gallery' },
		{ name: '참여하기', href: '/participate' }
	];
</script>

<header class="sticky top-0 z-50 border-b bg-white shadow-sm">
	<nav class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8" aria-label="메인 내비게이션">
		<div class="flex h-16 justify-between">
			<!-- 로고 -->
			<div class="flex flex-shrink-0 items-center">
				<a href="/" class="text-primary-600 text-xl font-bold"> 민들레장애인자립생활센터 </a>
			</div>

			<!-- 데스크톱 메뉴 -->
			<div class="hidden md:flex md:items-center md:space-x-8">
				{#each navigation as item}
					<a
						href={item.href}
						class="hover:text-primary-600 px-3 py-2 text-sm font-medium text-gray-700"
						class:border-b-2={$page.url.pathname.startsWith(item.href)}
						class:border-primary-600={$page.url.pathname.startsWith(item.href)}
					>
						{item.name}
					</a>
				{/each}

				<div class="flex items-center space-x-4">
					<Button variant="ghost" href="/auth/login">로그인</Button>
					<Button href="/auth/register">회원가입</Button>
				</div>
			</div>

			<!-- 모바일 메뉴 버튼 -->
			<div class="flex items-center md:hidden">
				<button
					type="button"
					class="hover:text-primary-600 focus:ring-primary-500 inline-flex items-center justify-center rounded-md p-2 text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset"
					aria-controls="mobile-menu"
					aria-expanded={mobileMenuOpen}
					on:click={() => (mobileMenuOpen = !mobileMenuOpen)}
				>
					<span class="sr-only">메뉴 열기</span>
					{#if mobileMenuOpen}
						<X class="block h-6 w-6" aria-hidden="true" />
					{:else}
						<Menu class="block h-6 w-6" aria-hidden="true" />
					{/if}
				</button>
			</div>
		</div>

		<!-- 모바일 메뉴 -->
		{#if mobileMenuOpen}
			<div class="md:hidden" id="mobile-menu">
				<div class="space-y-1 pb-3 pt-2">
					{#each navigation as item}
						<a
							href={item.href}
							class="hover:text-primary-600 block px-3 py-2 text-base font-medium text-gray-700 hover:bg-gray-50"
							class:bg-primary-50={$page.url.pathname.startsWith(item.href)}
							class:text-primary-600={$page.url.pathname.startsWith(item.href)}
						>
							{item.name}
						</a>
					{/each}
				</div>
				<div class="border-t border-gray-200 pb-3 pt-4">
					<div class="flex items-center px-5">
						<div class="flex-shrink-0">
							<Button variant="ghost" href="/auth/login" class="w-full">로그인</Button>
						</div>
						<div class="ml-3">
							<Button href="/auth/register" class="w-full">회원가입</Button>
						</div>
					</div>
				</div>
			</div>
		{/if}
	</nav>
</header>
