<script lang="ts">
	import { user, isAuthenticated } from '$lib/stores/auth';
	import { onMount } from 'svelte';
	import { initializeAuth } from '$lib/stores/auth';
	import { redirectToLogin } from '$lib/utils/auth';

	onMount(() => {
		// 인증 상태 초기화
		initializeAuth();
	});

	// 인증 상태 확인
	$: if ($isAuthenticated === false) {
		redirectToLogin();
	}
</script>

{#if $user}
	<div class="min-h-screen bg-gray-50">
		<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
			<div class="mb-8">
				<h1 class="text-3xl font-bold text-gray-900">마이페이지</h1>
				<p class="mt-2 text-gray-600">안녕하세요, {$user.name}님!</p>
			</div>

			<div class="grid grid-cols-1 gap-8 lg:grid-cols-4">
				<!-- 사이드바 네비게이션 -->
				<nav class="lg:col-span-1">
					<div class="rounded-lg bg-white p-6 shadow">
						<h2 class="mb-4 text-lg font-semibold text-gray-900">메뉴</h2>
						<ul class="space-y-2">
							<li>
								<a
									href="/my"
									class="block rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>
									대시보드
								</a>
							</li>
							<li>
								<a
									href="/my/profile"
									class="block rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>
									프로필 관리
								</a>
							</li>
							<li>
								<a
									href="/my/activities"
									class="block rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>
									내 활동
								</a>
							</li>
							<li>
								<a
									href="/my/posts"
									class="block rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>
									내 게시글
								</a>
							</li>
							<li>
								<a
									href="/my/volunteer-history"
									class="block rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>
									봉사신청 내역
								</a>
							</li>
							<li>
								<a
									href="/my/donations"
									class="block rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
								>
									후원 내역
								</a>
							</li>
						</ul>
					</div>
				</nav>

				<!-- 메인 콘텐츠 -->
				<main class="lg:col-span-3">
					<div class="rounded-lg bg-white shadow">
						<slot />
					</div>
				</main>
			</div>
		</div>
	</div>
{:else}
	<div class="flex min-h-screen items-center justify-center">
		<div class="text-center">
			<div class="border-primary-600 mx-auto h-12 w-12 animate-spin rounded-full border-b-2"></div>
			<p class="mt-4 text-gray-600">인증 상태를 확인하는 중...</p>
		</div>
	</div>
{/if}
