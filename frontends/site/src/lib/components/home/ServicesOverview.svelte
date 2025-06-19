<script lang="ts">
	import { Card } from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Icon, UserGroup, Heart, Truck, ShieldCheck } from 'svelte-hero-icons';

	const services = [
		{
			title: '자립생활지원',
			description: '장애인의 자립생활을 위한 맞춤형 지원 서비스를 제공합니다.',
			icon: UserGroup,
			href: '/services/support'
		},
		{
			title: '활동지원서비스',
			description: '일상생활과 사회활동 참여를 위한 활동지원 서비스를 제공합니다.',
			icon: Heart,
			href: '/services/activity'
		},
		{
			title: '이동지원서비스',
			description: '장애인의 이동권 보장을 위한 이동지원 서비스를 제공합니다.',
			icon: Truck,
			href: '/services/mobility'
		},
		{
			title: '권익옹호활동',
			description: '장애인의 권리와 이익을 보호하고 옹호하는 활동을 합니다.',
			icon: ShieldCheck,
			href: '/services/advocacy'
		}
	];
</script>

<section class="bg-gray-50 py-16 md:py-24">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-16 text-center">
			<h2 class="mb-4 text-3xl font-bold text-gray-900 md:text-4xl">우리의 서비스</h2>
			<p class="mx-auto max-w-3xl text-lg text-gray-600">
				민들레장애인자립생활센터는 장애인의 자립생활을 위한 다양한 서비스를 제공합니다.
			</p>
		</div>

		<div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-4">
			{#each services as service}
				<Card class="p-6 transition-shadow hover:shadow-lg">
					<div class="flex flex-col items-center text-center">
						<div
							class="bg-primary-100 mb-4 flex h-12 w-12 items-center justify-center rounded-full"
						>
							<Icon src={service.icon} class="text-primary-600 h-6 w-6" />
						</div>
						<h3 class="mb-2 text-xl font-semibold text-gray-900">
							{service.title}
						</h3>
						<p class="mb-4 text-gray-600">
							{service.description}
						</p>
						<Button variant="ghost" href={service.href}>자세히 보기</Button>
					</div>
				</Card>
			{/each}
		</div>
	</div>
</section>
