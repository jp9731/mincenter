<script lang="ts">
	import { Button } from '$lib/components/ui/button';
</script>

<section class="from-primary-600 to-primary-800 relative bg-gradient-to-r text-white">
	<div class="absolute inset-0 overflow-hidden">
		<div class="absolute inset-0 bg-black/30"></div>
		<img
			src="/images/hero_bg.jpeg"
			alt="장애인 자립생활 지원 활동"
			class="h-full w-full object-cover"
		/>
	</div>

	<div class="relative mx-auto max-w-7xl px-4 py-24 sm:px-6 md:py-32 lg:px-8">
		<div class="max-w-3xl">
			<h1 class="mb-6 text-4xl font-bold leading-tight md:text-5xl lg:text-6xl">
				함께 만들어가는<br />
				<span class="text-secondary-400">자립생활의 미래</span>
			</h1>

			<p class="mb-8 text-lg text-gray-100 md:text-xl">
				민들레장애인자립생활센터는 장애인의 자립생활을 지원하고<br />
				함께하는 사회를 만들어갑니다.
			</p>

			<div class="flex flex-col gap-4 sm:flex-row">
				<!-- <Button size="lg" href="/participate/volunteer" variant="secondary">봉사하기</Button> -->
				<Button
					size="lg"
					href="/donation"
					variant="outline"
					class="bg-white/10 hover:bg-white/20"
				>
					청기후원신청하기
				</Button>
			</div>
		</div>
	</div>
</section>
