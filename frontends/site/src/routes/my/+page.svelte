<script lang="ts">
	import { user, isAuthenticated } from '$lib/stores/auth';
	import { Button } from '$lib/components/ui/button';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import {
		Icon,
		User,
		Calendar,
		Star,
		DocumentText,
		Heart,
		HandRaised,
		Gift,
		Bell,
		Trash
	} from 'svelte-hero-icons';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	onMount(() => {
		if (!$isAuthenticated) {
			goto('/auth/login');
		}
	});

	const menuItems = [
		{
			title: '프로필 관리',
			description: '개인정보 수정 및 프로필 관리',
			icon: User,
			href: '/my/profile'
		},
		{
			title: '내 활동',
			description: '참여한 봉사활동 및 활동 내역',
			icon: Calendar,
			href: '/my/activities'
		},
		{
			title: '포인트 내역',
			description: '포인트 적립 및 사용 내역',
			icon: Star,
			href: '/my/points'
		},
		{
			title: '내 게시글',
			description: '작성한 게시글 및 댓글 관리',
			icon: DocumentText,
			href: '/my/posts'
		},
		{
			title: '좋아요 목록',
			description: '좋아요한 게시글 및 댓글',
			icon: Heart,
			href: '/my/likes'
		},
		{
			title: '봉사신청 내역',
			description: '신청한 봉사활동 내역',
			icon: HandRaised,
			href: '/my/volunteer-history'
		},
		{
			title: '후원 내역',
			description: '후원 내역 및 영수증',
			icon: Gift,
			href: '/my/donations'
		},
		{
			title: '알림 설정',
			description: '알림 및 메시지 설정',
			icon: Bell,
			href: '/my/notifications'
		},
		{
			title: '회원 탈퇴',
			description: '계정 삭제 및 탈퇴',
			icon: Trash,
			href: '/my/delete-account'
		}
	];
</script>

<div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
	<div class="mb-8">
		<h1 class="text-3xl font-bold text-gray-900">마이페이지</h1>
		<p class="mt-2 text-gray-600">내 정보와 활동을 관리하세요</p>
	</div>

	{#if $user}
		<!-- 사용자 정보 카드 -->
		<Card class="mb-8">
			<CardHeader>
				<CardTitle class="flex items-center space-x-2">
					<Icon src={User} class="h-5 w-5" />
					<span>내 정보</span>
				</CardTitle>
			</CardHeader>
			<CardContent>
				<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
					<div>
						<div class="text-sm font-medium text-gray-500">이름</div>
						<p class="text-lg font-semibold text-gray-900">{$user.name}</p>
					</div>
					<div>
						<div class="text-sm font-medium text-gray-500">이메일</div>
						<p class="text-lg font-semibold text-gray-900">{$user.email}</p>
					</div>
					<div>
						<div class="text-sm font-medium text-gray-500">가입일</div>
						<p class="text-lg font-semibold text-gray-900">
							{new Date($user.created_at).toLocaleDateString('ko-KR')}
						</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<!-- 메뉴 그리드 -->
		<div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
			{#each menuItems as item}
				<Card class="cursor-pointer transition-shadow hover:shadow-lg">
					<a href={item.href} class="block">
						<CardHeader>
							<CardTitle class="flex items-center space-x-2">
								<Icon src={item.icon} class="text-primary-600 h-5 w-5" />
								<span>{item.title}</span>
							</CardTitle>
							<CardDescription>{item.description}</CardDescription>
						</CardHeader>
					</a>
				</Card>
			{/each}
		</div>
	{:else}
		<div class="py-12 text-center">
			<p class="text-gray-600">로그인이 필요합니다.</p>
			<Button href="/auth/login" class="mt-4">로그인하기</Button>
		</div>
	{/if}
</div>
