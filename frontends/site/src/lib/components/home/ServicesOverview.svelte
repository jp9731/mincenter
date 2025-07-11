<script lang="ts">
	import { Card } from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Icon, UserGroup, Heart, Truck, ShieldCheck } from 'svelte-hero-icons';

	const services = [
		{
			title: 'IL사업',
			description: '동료상담, 권익옹호활동, 정보제공, 자조모임 등 다양한 사업기획 및 지원',
			icon: UserGroup,
			href: '/services'
		},
		{
			title: '자립지원사업',
			description: '탈시설 및 탈재가장애인의 자립생활전환으로 거주공간을 마련, 자립생활기술 습득',
			icon: Heart,
			href: '/services'
		},
		{
			title: '활동지원사업',
			description: '장애인이 지역사회에서 사회구성원으로 동등하게 살아갈 수 있도록 활동지원사 파견',
			icon: Truck,
			href: '/services'
		},
		{
			title: '기타',
			description: '차별상담전화, 보장구수리 및 점검, 회원교육, 명절행사, 투쟁활동참여',
			icon: ShieldCheck,
			href: '/services'
		}
	];
</script>

<section class="bg-gray-50 py-16 md:py-24">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-16 text-center">
			<h2 class="mb-4 text-3xl font-bold text-gray-900 md:text-4xl">우리의 서비스</h2>
			<p class="mx-auto max-w-3xl text-lg text-gray-600">
				민들레장애인자립생활센터는 장애인의 자립생활을 위한 다양한 사업을 진행하고 있습니다.
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
