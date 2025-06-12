<script lang="ts">
	import { Button } from '$lib/components/ui/button';
</script>

<section class="bg-primary-600 text-white">
	<div class="mx-auto max-w-7xl px-4 py-16 sm:px-6 md:py-24 lg:px-8">
		<div class="text-center">
			<h2 class="mb-6 text-3xl font-bold md:text-4xl">
				함께 만들어가는<br />
				따뜻한 세상
			</h2>

			<p class="text-primary-100 mx-auto mb-8 max-w-3xl text-lg md:text-xl">
				여러분의 작은 관심과 참여가 장애인의 자립생활을 위한 큰 힘이 됩니다.<br />
				지금 바로 참여하세요.
			</p>

			<div class="flex flex-col justify-center gap-4 sm:flex-row">
				<Button size="lg" href="/participate/volunteer" variant="secondary">봉사자 신청하기</Button>
				<Button
					size="lg"
					href="/participate/donate"
					variant="outline"
					class="bg-white/10 hover:bg-white/20"
				>
					후원하기
				</Button>
			</div>
		</div>
	</div>
</section>
