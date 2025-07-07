<script lang="ts">
	import { onMount } from 'svelte';
	import { Calendar } from '@fullcalendar/core';
	import dayGridPlugin from '@fullcalendar/daygrid';
	import timeGridPlugin from '@fullcalendar/timegrid';
	import interactionPlugin from '@fullcalendar/interaction';
	import listPlugin from '@fullcalendar/list';
	import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '$lib/components/ui/card/index.js';
	import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '$lib/components/ui/dialog/index.js';

	let calendarEl: HTMLDivElement;
	let calendar: Calendar | null = null;

	// 공개 일정 데이터
	let events: any[] = [];
	
	// 모달 상태
	let showModal = false;
	let selectedEvent: any = null;

	// 공개 일정 목록 불러오기
	async function loadPublicEvents() {
		try {
			const response = await fetch('/api/calendar/events');
			const data = await response.json();
			if (data.success) {
				events = data.data;
				if (calendar) {
					calendar.removeAllEvents();
					calendar.addEventSource(events.map(ev => ({
						id: ev.id,
						title: ev.title,
						start: ev.start_at,
						end: ev.end_at,
						allDay: ev.all_day,
						color: ev.color,
						extendedProps: ev
					})));
				}
			}
		} catch (error) {
			console.error('일정을 불러오는데 실패했습니다:', error);
		}
	}

	// 일정 클릭 시 모달 열기
	function handleEventClick(info: any) {
		selectedEvent = {
			title: info.event.title,
			description: info.event.extendedProps.description || '설명이 없습니다.',
			start: info.event.start,
			end: info.event.end,
			allDay: info.event.allDay,
			color: info.event.backgroundColor
		};
		showModal = true;
	}

	// 날짜 포맷팅 함수
	function formatDate(date: Date, includeTime: boolean = true): string {
		const options: Intl.DateTimeFormatOptions = {
			year: 'numeric',
			month: 'long',
			day: 'numeric'
		};
		
		if (includeTime && !selectedEvent?.allDay) {
			options.hour = '2-digit';
			options.minute = '2-digit';
		}
		
		return date.toLocaleDateString('ko-KR', options);
	}

	onMount(async () => {
		calendar = new Calendar(calendarEl, {
			plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin, listPlugin],
			initialView: 'dayGridMonth',
			headerToolbar: {
				left: 'prev,next today',
				center: 'title',
				right: 'dayGridMonth,timeGridWeek,timeGridDay,listWeek'
			},
			locale: 'ko',
			selectable: false, // 사이트에서는 일정 추가 불가
			eventClick: handleEventClick
		});
		calendar.render();
		await loadPublicEvents();
	});
</script>

	<div class="py-8">
	<div class="mb-8 flex items-center justify-between">
		<div>
		<h1 class="text-3xl font-bold">일정</h1>
		<p class="text-gray-600 mt-2">선터의 주요 일정을 확인하세요</p>
	</div>
	</div>

	<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
		<!-- 달력 뷰 -->
		<div class="lg:col-span-2">
			<Card>
				<CardHeader>
					<CardTitle class="text-center">
						📅 일정 달력
					</CardTitle>
					<CardDescription class="text-center">년, 월, 일, 시 탭으로 구분해서 볼 수 있습니다</CardDescription>
				</CardHeader>
				<CardContent>
					<div bind:this={calendarEl} class="rounded-lg bg-white" style="min-height: 500px;"></div>
				</CardContent>
			</Card>
		</div>

		<!-- 최근 일정 목록 -->
		<div>
			<Card>
				<CardHeader>
					<CardTitle>최근 일정</CardTitle>
					<CardDescription>다가오는 공개 일정 목록</CardDescription>
				</CardHeader>
				<CardContent>
					<div class="space-y-4">
						{#each events as event}
							<div 
								class="py-2 pl-4 cursor-pointer hover:bg-gray-50 rounded-r transition-colors"
								style="border-left: 4px solid {event.color || '#3b82f6'};"
								role="button"
								tabindex="0"
								onclick={() => {
									selectedEvent = {
										title: event.title,
										description: event.description || '설명이 없습니다.',
										start: new Date(event.start_at),
										end: event.end_at ? new Date(event.end_at) : null,
										allDay: event.all_day,
										color: event.color
									};
									showModal = true;
								}}
								onkeydown={(e) => {
									if (e.key === 'Enter' || e.key === ' ') {
										e.preventDefault();
										selectedEvent = {
											title: event.title,
											description: event.description || '설명이 없습니다.',
											start: new Date(event.start_at),
											end: event.end_at ? new Date(event.end_at) : null,
											allDay: event.all_day,
											color: event.color
										};
										showModal = true;
									}
								}}
							>
								<h4 class="font-medium text-gray-900">{event.title}</h4>
								<p class="text-sm text-gray-600">
									{new Date(event.start_at).toLocaleDateString('ko-KR')} 
									{new Date(event.start_at).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })}
								</p>
								{#if event.description}
									<p class="text-sm text-gray-500 truncate">{event.description}</p>
								{/if}
								{#if event.user_name}
									<p class="text-xs text-gray-400">등록자: {event.user_name}</p>
								{/if}
							</div>
						{:else}
							<p class="text-gray-500 text-center py-4">등록된 일정이 없습니다.</p>
						{/each}
					</div>
				</CardContent>
			</Card>
		</div>
	</div>
</div>

<!-- 일정 상세 모달 -->
<Dialog bind:open={showModal}>
	<DialogContent class="max-w-md mx-auto">
		<DialogHeader>
			<DialogTitle class="flex items-center gap-2">
				{#if selectedEvent?.color}
					<div class="w-3 h-3 rounded-full" style="background-color: {selectedEvent.color};"></div>
				{/if}
				{selectedEvent?.title}
			</DialogTitle>
			<DialogDescription>
				{#if selectedEvent?.allDay}
					전일 일정
				{:else}
					시간 일정
				{/if}
			</DialogDescription>
		</DialogHeader>
		
		<div class="space-y-4">
			<!-- 기간 정보 -->
			<div class="bg-gray-50 rounded-lg p-3">
				<h4 class="font-medium text-gray-900 mb-2">📅 기간</h4>
				<div class="text-sm text-gray-600">
					{#if selectedEvent?.allDay}
						{formatDate(selectedEvent.start, false)}
						{#if selectedEvent?.end && selectedEvent.end.getTime() !== selectedEvent.start.getTime()}
							<br>~ {formatDate(selectedEvent.end, false)}
						{/if}
					{:else}
						{formatDate(selectedEvent.start)}
						{#if selectedEvent?.end}
							<br>~ {formatDate(selectedEvent.end)}
						{/if}
					{/if}
				</div>
			</div>

			<!-- 내용 -->
			<div>
				<h4 class="font-medium text-gray-900 mb-2">📝 내용</h4>
				<p class="text-sm text-gray-600 whitespace-pre-wrap">{selectedEvent?.description}</p>
			</div>
		</div>
	</DialogContent>
</Dialog> 