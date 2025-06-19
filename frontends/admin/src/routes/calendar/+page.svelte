<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { CalendarIcon, PlusIcon } from 'lucide-svelte';

	// 임시 일정 데이터
	const events = [
		{
			id: 1,
			title: '봉사활동 - 노인정 방문',
			date: '2024-01-25',
			time: '14:00',
			location: '행복노인정',
			type: 'volunteer'
		},
		{
			id: 2,
			title: '후원자 감사 모임',
			date: '2024-01-28',
			time: '19:00',
			location: '본사 강당',
			type: 'donation'
		},
		{
			id: 3,
			title: '직원 교육',
			date: '2024-02-01',
			time: '10:00',
			location: '교육실',
			type: 'internal'
		}
	];
</script>

<div class="space-y-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">일정 관리</h1>
			<p class="text-gray-600">달력에 표시할 일정을 관리하세요</p>
		</div>
		<Button>
			<PlusIcon class="mr-2 h-4 w-4" />
			일정 추가
		</Button>
	</div>

	<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
		<!-- 달력 뷰 -->
		<div class="lg:col-span-2">
			<Card>
				<CardHeader>
					<CardTitle class="flex items-center">
						<CalendarIcon class="mr-2 h-5 w-5" />
						달력 보기
					</CardTitle>
					<CardDescription>년, 월, 일, 시 탭으로 구분해서 볼 수 있습니다</CardDescription>
				</CardHeader>
				<CardContent>
					<div class="rounded-lg bg-gray-100 p-8 text-center">
						<CalendarIcon class="mx-auto mb-4 h-16 w-16 text-gray-400" />
						<p class="text-gray-600">달력 컴포넌트가 여기에 표시됩니다</p>
						<p class="mt-2 text-sm text-gray-500">년/월/일/시 탭으로 구분된 뷰</p>
					</div>
				</CardContent>
			</Card>
		</div>

		<!-- 일정 목록 -->
		<div>
			<Card>
				<CardHeader>
					<CardTitle>최근 일정</CardTitle>
					<CardDescription>다가오는 일정 목록</CardDescription>
				</CardHeader>
				<CardContent>
					<div class="space-y-4">
						{#each events as event}
							<div class="border-l-4 border-blue-500 py-2 pl-4">
								<h4 class="font-medium text-gray-900">{event.title}</h4>
								<p class="text-sm text-gray-600">{event.date} {event.time}</p>
								<p class="text-sm text-gray-500">{event.location}</p>
							</div>
						{/each}
					</div>
				</CardContent>
			</Card>
		</div>
	</div>
</div>
