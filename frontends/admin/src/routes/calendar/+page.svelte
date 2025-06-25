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

	import { onMount } from 'svelte';
	import { Calendar } from '@fullcalendar/core';
	import dayGridPlugin from '@fullcalendar/daygrid';
	import timeGridPlugin from '@fullcalendar/timegrid';
	import interactionPlugin from '@fullcalendar/interaction';
	import listPlugin from '@fullcalendar/list';

	import {
		getCalendarEvents,
		createCalendarEvent,
		updateCalendarEvent,
		deleteCalendarEvent
	} from '$lib/api/admin';

	import * as Dialog from '$lib/components/ui/dialog';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import * as Select from '$lib/components/ui/select';

	let calendarEl: HTMLDivElement;
	let calendar: Calendar | null = null;

	// 일정 데이터
	let events: any[] = [];

	let showModal = false;
	let modalMode: 'create' | 'edit' = 'create';
	let modalEvent: any = {};

	const colorOptions = [
		{ value: '', label: '기본' },
		{ value: '#2563eb', label: '파랑' },
		{ value: '#22c55e', label: '초록' },
		{ value: '#f59e42', label: '주황' },
		{ value: '#ef4444', label: '빨강' },
		{ value: '#a855f7', label: '보라' },
	];

	function openCreateModal(dateInfo?: any) {
		modalMode = 'create';
		modalEvent = {
			title: '',
			description: '',
			color: '',
			start_at: dateInfo?.startStr || '',
			end_at: dateInfo?.endStr || '',
			all_day: dateInfo?.allDay || false,
			is_public: true // 기본값은 공개
		};
		showModal = true;
	}

	function openEditModal(eventInfo: any) {
		modalMode = 'edit';
		
		// 날짜 형식을 datetime-local 입력에 맞게 변환
		const formatDateForInput = (dateString: string) => {
			if (!dateString) return '';
			const date = new Date(dateString);
			const year = date.getFullYear();
			const month = String(date.getMonth() + 1).padStart(2, '0');
			const day = String(date.getDate()).padStart(2, '0');
			const hours = String(date.getHours()).padStart(2, '0');
			const minutes = String(date.getMinutes()).padStart(2, '0');
			return `${year}-${month}-${day}T${hours}:${minutes}`;
		};

		modalEvent = {
			id: eventInfo.event?.id || eventInfo.id,
			title: eventInfo.event?.title || eventInfo.title,
			description: eventInfo.event?.extendedProps?.description || eventInfo.description || '',
			color: eventInfo.event?.backgroundColor || eventInfo.color || '',
			start_at: formatDateForInput(eventInfo.event?.startStr || eventInfo.start_at),
			end_at: formatDateForInput(eventInfo.event?.endStr || eventInfo.end_at),
			all_day: eventInfo.event?.allDay || eventInfo.all_day || false,
			is_public: eventInfo.event?.extendedProps?.is_public ?? eventInfo.is_public ?? true,
			user_name: eventInfo.event?.extendedProps?.user_name || eventInfo.user_name || '알 수 없음'
		};
		showModal = true;
	}

	async function handleModalSave() {
		// 날짜를 ISO 8601 형식으로 변환
		const formatDateToISO = (dateString: string) => {
			if (!dateString) return null;
			const date = new Date(dateString);
			return date.toISOString();
		};

		const eventData = {
			title: modalEvent.title,
			description: modalEvent.description || null,
			start_at: formatDateToISO(modalEvent.start_at),
			end_at: formatDateToISO(modalEvent.end_at),
			all_day: modalEvent.all_day || false,
			color: modalEvent.color || null,
			is_public: modalEvent.is_public ?? true
		};

		if (modalMode === 'create') {
			await createCalendarEvent(eventData);
		} else if (modalMode === 'edit') {
			await updateCalendarEvent(modalEvent.id, eventData);
		}
		showModal = false;
		await loadEvents();
	}

	async function handleModalDelete() {
		if (modalMode === 'edit' && modalEvent.id) {
			await deleteCalendarEvent(modalEvent.id);
			showModal = false;
			await loadEvents();
		}
	}

	// 일정 목록 불러오기
	async function loadEvents() {
		events = await getCalendarEvents();
		if (calendar) {
			calendar.removeAllEvents();
			calendar.addEventSource(events.map(ev => ({
				id: ev.id,
				title: ev.title,
				start: ev.start_at,
				end: ev.end_at,
				allDay: ev.all_day,
				color: ev.color,
				extendedProps: {
					...ev,
					is_public: ev.is_public
				}
			})));
		}
	}

	// 일정 추가
	async function handleDateSelect(info: any) {
		// 날짜 형식을 datetime-local 입력에 맞게 변환
		const startDate = new Date(info.startStr);
		const endDate = new Date(info.endStr);
		
		// YYYY-MM-DDTHH:mm 형식으로 변환
		const formatDateForInput = (date: Date) => {
			const year = date.getFullYear();
			const month = String(date.getMonth() + 1).padStart(2, '0');
			const day = String(date.getDate()).padStart(2, '0');
			const hours = String(date.getHours()).padStart(2, '0');
			const minutes = String(date.getMinutes()).padStart(2, '0');
			return `${year}-${month}-${day}T${hours}:${minutes}`;
		};

		openCreateModal({
			startStr: formatDateForInput(startDate),
			endStr: formatDateForInput(endDate),
			allDay: info.allDay
		});
		calendar?.unselect();
	}

	// 일정 클릭(수정/삭제)
	async function handleEventClick(info: any) {
		openEditModal(info);
	}

	// 최근 일정 목록에서 일정 클릭 시 모달 열기
	function openEventFromList(event: any) {
		openEditModal(event);
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
			selectable: true,
			select: handleDateSelect,
			eventClick: handleEventClick
		});
		calendar.render();
		await loadEvents();
	});
</script>

<Dialog.Root bind:open={showModal}>
	<Dialog.Content>
		<Dialog.Header>
			<Dialog.Title>{modalMode === 'create' ? '일정 추가' : '일정 수정'}</Dialog.Title>
			<Dialog.Description>일정의 상세 정보를 입력하세요.</Dialog.Description>
		</Dialog.Header>
		<div class="space-y-4 py-2">
			<Input placeholder="제목" bind:value={modalEvent.title} />
			<Textarea placeholder="설명" bind:value={modalEvent.description} />
			<div class="flex gap-2 items-center">
				<span>색상</span>
				<Select.Root bind:value={modalEvent.color} type="single">
					<Select.Trigger class="w-32">
						{#if modalEvent.color}
							<div class="flex items-center gap-2">
								<div class="w-4 h-4 rounded border" style="background-color: {modalEvent.color}"></div>
								{colorOptions.find(opt => opt.value === modalEvent.color)?.label || '기본'}
							</div>
						{:else}
							기본
						{/if}
					</Select.Trigger>
					<Select.Content>
						{#each colorOptions as opt}
							<Select.Item value={opt.value}>
								<div class="flex items-center gap-2">
									<div class="w-4 h-4 rounded border" style="background-color: {opt.value}"></div>
									{opt.label}
								</div>
							</Select.Item>
						{/each}
					</Select.Content>
				</Select.Root>
			</div>
			<div class="flex flex-col gap-2">
				<div class="flex gap-2 items-center">
					<span>시작</span>
					<Input type="datetime-local" bind:value={modalEvent.start_at} />
				</div>
				<div class="flex gap-2 items-center">
					<span>종료</span>
					<Input type="datetime-local" bind:value={modalEvent.end_at} />
				</div>
			</div>
			<label class="flex items-center gap-2">
				<input type="checkbox" bind:checked={modalEvent.all_day} /> 종일
			</label>
			<label class="flex items-center gap-2">
				<input type="checkbox" bind:checked={modalEvent.is_public} /> 공개
			</label>
			{#if modalMode === 'edit' && modalEvent.user_name}
				<div class="text-sm text-gray-500 border-t pt-2">
					등록자: {modalEvent.user_name}
				</div>
			{/if}
		</div>
		<Dialog.Footer>
			{#if modalMode === 'edit'}
				<Button variant="destructive" onclick={handleModalDelete}>삭제</Button>
			{/if}
			<Button onclick={handleModalSave}>{modalMode === 'create' ? '추가' : '수정'}</Button>
			<Button variant="ghost" onclick={() => (showModal = false)}>취소</Button>
		</Dialog.Footer>
	</Dialog.Content>
</Dialog.Root>

<div class="space-y-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">일정 관리</h1>
			<p class="text-gray-600">달력에 표시할 일정을 관리하세요</p>
		</div>
		<Button onclick={openCreateModal}>
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
					<div bind:this={calendarEl} class="rounded-lg bg-white" style="min-height: 500px;" />
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
							<div 
								class="py-2 pl-4 cursor-pointer hover:bg-gray-50 rounded-r transition-colors"
								style="border-left: 4px solid {event.color || '#3b82f6'};"
								onclick={() => openEventFromList(event)}
							>
								<div class="flex items-start justify-between">
									<div class="flex-1">
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
									<div class="ml-2">
										{#if event.is_public}
											<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
												공개
											</span>
										{:else}
											<span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
												비공개
											</span>
										{/if}
									</div>
								</div>
							</div>
						{/each}
					</div>
				</CardContent>
			</Card>
		</div>
	</div>
</div>
