<script lang="ts">
	import { Card } from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';

	// 임시 데이터 (실제로는 API에서 가져올 예정)
	const posts = [
		{
			id: 1,
			title: '2024년 봄맞이 봉사활동 모집',
			category: '공지사항',
			date: '2024-03-15',
			image: '/images/posts/volunteer-spring.jpg'
		},
		{
			id: 2,
			title: '자립생활지원사 양성교육 안내',
			category: '교육',
			date: '2024-03-10',
			image: '/images/posts/training.jpg'
		},
		{
			id: 3,
			title: '장애인 문화예술 축제 개최',
			category: '행사',
			date: '2024-03-05',
			image: '/images/posts/festival.jpg'
		}
	];
</script>

<section class="py-16 md:py-24">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-16 text-center">
			<h2 class="mb-4 text-3xl font-bold text-gray-900 md:text-4xl">최근 소식</h2>
			<p class="mx-auto max-w-3xl text-lg text-gray-600">
				민들레장애인자립생활센터의 최신 소식과 활동을 확인하세요.
			</p>
		</div>

		<div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
			{#each posts as post}
				<Card class="overflow-hidden transition-shadow hover:shadow-lg">
					<div class="aspect-w-16 aspect-h-9">
						<img src={post.image} alt={post.title} class="h-full w-full object-cover" />
					</div>
					<div class="p-6">
						<div class="mb-2 flex items-center gap-2">
							<span class="text-primary-600 text-sm font-medium">
								{post.category}
							</span>
							<span class="text-sm text-gray-500">
								{post.date}
							</span>
						</div>
						<h3 class="mb-2 text-xl font-semibold text-gray-900">
							{post.title}
						</h3>
						<Button variant="ghost" href={`/community/posts/${post.id}`}>자세히 보기</Button>
					</div>
				</Card>
			{/each}
		</div>

		<div class="mt-12 text-center">
			<Button href="/community" variant="outline">더 많은 소식 보기</Button>
		</div>
	</div>
</section>
