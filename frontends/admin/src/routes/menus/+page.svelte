<script lang="ts">
	import { onMount } from 'svelte';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { Badge } from '$lib/components/ui/badge';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Switch } from '$lib/components/ui/switch';
	import {
		AlertDialog,
		AlertDialogAction,
		AlertDialogCancel,
		AlertDialogContent,
		AlertDialogDescription,
		AlertDialogFooter,
		AlertDialogHeader,
		AlertDialogTitle,
		AlertDialogTrigger
	} from '$lib/components/ui/alert-dialog';
	import { PlusIcon, EditIcon, TrashIcon, ChevronDownIcon, ChevronRightIcon } from 'lucide-svelte';
	import { getMenus, saveMenus, getBoards, getPages } from '$lib/api/admin';

	interface Menu {
		id: string;
		name: string;
		description?: string;
		menu_type: 'page' | 'board' | 'url' | 'calendar' | 'Page' | 'Board' | 'Url' | 'Calendar';
		target_id?: string;
		url?: string;
		display_order: number;
		is_active: boolean;
		parent_id?: string;
		children?: Menu[];
	}

	interface Board {
		id: string;
		name: string;
		description?: string;
	}

	interface Page {
		id: string;
		title: string;
		slug: string;
	}

	let menus: Menu[] = [];
	let boards: Board[] = [];
	let pages: Page[] = [];
	let loading = true;
	let showCreateForm = false;
	let editingMenu: Menu | null = null;
	let errorMessage: string | null = null;
	let deletingMenu: Menu | null = null;
	let showDeleteModal = false;

	// 폼 데이터
	let formData = {
		name: '',
		description: '',
		menu_type: 'page' as 'page' | 'board' | 'url' | 'calendar',
		target_id: '',
		url: '',
		display_order: 1,
		is_active: true,
		parent_id: ''
	};

	// Select values
	let selectedMenuType = 'page';
	let selectedParentId = '';
	let selectedTargetId = '';

	// 메뉴 타입 변경 시 처리
	$: {
		const normalizedType = selectedMenuType?.toLowerCase();
		if (normalizedType === 'calendar') {
			formData.url = '/calendar';
		}
		// 타입이 변경되면 기존 target_id 초기화
		if (normalizedType !== 'page' && normalizedType !== 'board') {
			selectedTargetId = '';
		}
	}

	onMount(async () => {
		await loadMenus();
		await loadBoards();
		await loadPages();
	});

	async function loadMenus() {
		try {
			loading = true;
			errorMessage = null;
			menus = await getMenus();
		} catch (error) {
			console.error('메뉴 로드 실패:', error);
			errorMessage = error instanceof Error ? error.message : '메뉴를 불러오는데 실패했습니다.';
		} finally {
			loading = false;
		}
	}

	async function loadBoards() {
		try {
			boards = await getBoards();
		} catch (error) {
			console.error('게시판 로드 실패:', error);
		}
	}

	async function loadPages() {
		try {
			const result = await getPages();
			pages = result.pages;
		} catch (error) {
			console.error('페이지 로드 실패:', error);
			errorMessage = error instanceof Error ? error.message : '페이지를 불러오는데 실패했습니다.';
		}
	}

	function resetForm() {
		formData = {
			name: '',
			description: '',
			menu_type: 'page',
			target_id: '',
			url: '',
			display_order: 1,
			is_active: true,
			parent_id: ''
		};
		selectedMenuType = 'page';
		selectedParentId = '';
		selectedTargetId = '';
		editingMenu = null;
		showCreateForm = false;
	}

	function editMenu(menu: Menu) {
		editingMenu = menu;
		const normalizedMenuType = menu.menu_type.toLowerCase() as 'page' | 'board' | 'url' | 'calendar';
		formData = {
			name: menu.name,
			description: menu.description || '',
			menu_type: normalizedMenuType,
			target_id: menu.target_id || '',
			url: menu.url || '',
			display_order: menu.display_order,
			is_active: menu.is_active,
			parent_id: menu.parent_id || ''
		};
		selectedMenuType = normalizedMenuType;
		selectedParentId = menu.parent_id || '';
		selectedTargetId = menu.target_id || '';
		showCreateForm = true;
	}

	async function saveMenu() {
		// Update formData with selected values
		formData.menu_type = selectedMenuType as 'page' | 'board' | 'url' | 'calendar';
		formData.parent_id = selectedParentId || '';
		formData.target_id = selectedTargetId || '';

		try {
			errorMessage = null;

			if (editingMenu) {
				// 수정 로직 - 현재 API에 updateMenu가 없으므로 전체 메뉴 배열을 업데이트
				const updatedMenus = menus.map((menu) =>
					menu.id === editingMenu!.id ? { ...menu, ...formData } : menu
				);
				await saveMenus(updatedMenus);
			} else {
				// 추가 로직 - 새 메뉴를 배열에 추가
				const newMenu: Menu = {
					id: crypto.randomUUID(), // UUID 생성
					...formData,
					parent_id: formData.parent_id || undefined,
					target_id: formData.target_id || undefined
				};
				const updatedMenus = [...menus, newMenu];
				await saveMenus(updatedMenus);
			}

			await loadMenus();
			resetForm();
		} catch (error) {
			console.error('메뉴 저장 실패:', error);
			errorMessage = error instanceof Error ? error.message : '저장 중 오류가 발생했습니다.';
		}
	}

	function confirmDelete(menu: Menu) {
		deletingMenu = menu;
		showDeleteModal = true;
	}

	async function deleteMenu() {
		if (!deletingMenu) return;

		try {
			errorMessage = null;
			const updatedMenus = menus.filter((menu) => menu.id !== deletingMenu!.id);
			await saveMenus(updatedMenus);
			await loadMenus();
			deletingMenu = null;
			showDeleteModal = false;
		} catch (error) {
			console.error('메뉴 삭제 실패:', error);
			errorMessage = error instanceof Error ? error.message : '삭제 중 오류가 발생했습니다.';
		}
	}

	function cancelDelete() {
		deletingMenu = null;
		showDeleteModal = false;
	}

	function getTypeLabel(type: string) {
		const normalizedType = type.toLowerCase();
		switch (normalizedType) {
			case 'page':
				return '안내페이지';
			case 'board':
				return '게시판';
			case 'url':
				return '외부링크';
			case 'calendar':
				return '일정';
			default:
				return type;
		}
	}

	function getMenuTypeLabel(type: string) {
		return getTypeLabel(type);
	}

	function getSelectedParentName(parentId: string) {
		if (!parentId) return '1단 메뉴 선택 (2단 메뉴인 경우)';
		if (parentId === '') return '1단 메뉴';
		const parent = menus.find(m => m.id === parentId);
		return parent?.name || '알 수 없음';
	}

	function getSelectedTargetName(targetId: string, menuType: string) {
		if (!targetId) return '';
		
		if (menuType === 'page') {
			const page = pages.find(p => p.id === targetId);
			return page?.title || '알 수 없음';
		} else if (menuType === 'board') {
			const board = boards.find(b => b.id === targetId);
			return board?.name || '알 수 없음';
		}
		
		return '';
	}

	// 반응형 함수로 변경 - boards와 pages가 변경되면 자동으로 재계산
	$: getTargetName = (menu: Menu) => {
		const normalizedType = menu.menu_type.toLowerCase();
		
		if (normalizedType === 'board' && menu.target_id) {
			if (boards.length === 0) {
				return '로딩 중...';
			}
			
			const board = boards.find((b) => b.id === menu.target_id);
			if (board) {
				return board.name;
			} else {
				return '게시판 (알 수 없음)';
			}
		} else if (normalizedType === 'page' && menu.target_id) {
			if (pages.length === 0) {
				return '로딩 중...';
			}
			
			const page = pages.find((p) => p.id === menu.target_id);
			if (page) {
				return page.title;
			} else {
				return '페이지 (알 수 없음)';
			}
		} else if (normalizedType === 'calendar') {
			return '/calendar';
		} else if (normalizedType === 'url' && menu.url) {
			return menu.url;
		}
		return '-';
	};

	// 1단 메뉴만 필터링
	$: rootMenus = menus.filter((menu) => !menu.parent_id);
	
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">메뉴 관리</h1>
			<p class="text-gray-600">사이트 상단 메뉴를 설정하세요 (1단 메뉴 + 2단 메뉴)</p>
		</div>
		<Button
			onclick={() => {
				resetForm();
				showCreateForm = true;
			}}
		>
			<PlusIcon class="mr-2 h-4 w-4" />
			메뉴 추가
		</Button>
	</div>

	<!-- 에러 메시지 -->
	{#if errorMessage}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4">
			<p class="text-red-600">{errorMessage}</p>
		</div>
	{/if}

	<!-- 메뉴 생성/수정 폼 -->
	{#if showCreateForm}
		<Card>
			<CardHeader>
				<CardTitle>{editingMenu ? '메뉴 수정' : '메뉴 추가'}</CardTitle>
				<CardDescription>메뉴 정보를 입력하세요</CardDescription>
			</CardHeader>
			<CardContent class="space-y-4">
				<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
					<div class="space-y-2">
						<Label for="name">메뉴명 *</Label>
						<Input id="name" bind:value={formData.name} placeholder="메뉴명을 입력하세요" />
					</div>
					<div class="space-y-2">
						<Label for="description">설명</Label>
						<Input
							id="description"
							bind:value={formData.description}
							placeholder="메뉴 설명 (선택사항)"
						/>
					</div>
					<div class="space-y-2">
						<Label for="menu_type">메뉴 타입 *</Label>
						<Select 
							type="single" 
							bind:value={selectedMenuType}
						>
							<SelectTrigger>
								{selectedMenuType ? getMenuTypeLabel(selectedMenuType) : '메뉴 타입을 선택하세요'}
							</SelectTrigger>
							<SelectContent>
								<SelectItem value="page">안내페이지</SelectItem>
								<SelectItem value="board">게시판</SelectItem>
								<SelectItem value="calendar">일정</SelectItem>
								<SelectItem value="url">외부링크</SelectItem>
							</SelectContent>
						</Select>
					</div>
					<div class="space-y-2">
						<Label for="parent_id">상위 메뉴</Label>
						<Select 
							type="single" 
							bind:value={selectedParentId}
						>
							<SelectTrigger>
								{getSelectedParentName(selectedParentId)}
							</SelectTrigger>
							<SelectContent>
								<SelectItem value="">1단 메뉴</SelectItem>
								{#each rootMenus as menu}
									<SelectItem value={menu.id}>{menu.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
					<div class="space-y-2">
						<Label for="display_order">표시 순서</Label>
						<Input id="display_order" type="number" bind:value={formData.display_order} min="1" />
					</div>
					<div class="space-y-2">
						<Label for="is_active">활성 상태</Label>
						<div class="flex items-center space-x-2">
							<Switch bind:checked={formData.is_active} />
							<span class="text-sm">{formData.is_active ? '활성' : '비활성'}</span>
						</div>
					</div>
				</div>

				<!-- 타입별 추가 필드 -->
				{#if selectedMenuType?.toLowerCase() === 'page'}
					<div class="space-y-2">
						<Label for="target_id">페이지 선택</Label>
						<Select 
							type="single" 
							bind:value={selectedTargetId}
						>
							<SelectTrigger>
								{selectedTargetId ? getSelectedTargetName(selectedTargetId, 'page') : '페이지를 선택하세요'}
							</SelectTrigger>
							<SelectContent>
								{#each pages as page}
									<SelectItem value={page.id}>{page.title}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
				{:else if selectedMenuType?.toLowerCase() === 'board'}
					<div class="space-y-2">
						<Label for="target_id">게시판 선택</Label>
						<Select 
							type="single" 
							bind:value={selectedTargetId}
						>
							<SelectTrigger>
								{selectedTargetId ? getSelectedTargetName(selectedTargetId, 'board') : '게시판을 선택하세요'}
							</SelectTrigger>
							<SelectContent>
								{#each boards as board}
									<SelectItem value={board.id}>{board.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
				{:else if selectedMenuType?.toLowerCase() === 'url'}
					<div class="space-y-2">
						<Label for="url">외부 URL</Label>
						<Input id="url" bind:value={formData.url} placeholder="https://example.com" />
					</div>
				{:else if selectedMenuType?.toLowerCase() === 'calendar'}
					<div class="space-y-2">
						<Label for="url">일정 페이지 URL</Label>
						<Input id="url" bind:value={formData.url} placeholder="/calendar" readonly />
						<p class="text-sm text-gray-500">일정 메뉴는 자동으로 /calendar 경로로 설정됩니다.</p>
					</div>
				{/if}

				<div class="flex justify-end space-x-2">
					<Button variant="outline" onclick={resetForm}>취소</Button>
					<Button onclick={saveMenu}>{editingMenu ? '수정' : '추가'}</Button>
				</div>
			</CardContent>
		</Card>
	{/if}

	<!-- 메뉴 테이블 -->
	<Card>
		<CardHeader>
			<CardTitle>메뉴 목록</CardTitle>
			<CardDescription>사이트 상단에 표시되는 메뉴들을 관리합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			{#if loading}
				<div class="py-8 text-center">로딩 중...</div>
			{:else if menus.length === 0}
				<div class="py-8 text-center text-gray-500">등록된 메뉴가 없습니다.</div>
			{:else}
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>순서</TableHead>
							<TableHead>메뉴명</TableHead>
							<TableHead>타입</TableHead>
							<TableHead>대상</TableHead>
							<TableHead>상태</TableHead>
							<TableHead class="text-right">액션</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{#each rootMenus as menu}
							<TableRow>
								<TableCell>{menu.display_order}</TableCell>
								<TableCell class="font-medium">{menu.name}</TableCell>
								<TableCell>
									<Badge variant="outline">{getTypeLabel(menu.menu_type)}</Badge>
								</TableCell>
								<TableCell>{getTargetName(menu)}</TableCell>
								<TableCell>
									<Badge variant={menu.is_active ? 'default' : 'secondary'}>
										{menu.is_active ? '활성' : '비활성'}
									</Badge>
								</TableCell>
								<TableCell class="text-right">
									<div class="flex items-center justify-end space-x-2">
										<Button variant="ghost" size="sm" onclick={() => editMenu(menu)}>
											<EditIcon class="h-4 w-4" />
										</Button>
										<Button
											variant="ghost"
											size="sm"
											class="text-red-600"
											onclick={() => confirmDelete(menu)}
										>
											<TrashIcon class="h-4 w-4" />
										</Button>
									</div>
								</TableCell>
							</TableRow>
							<!-- 2단 메뉴 -->
							{#each menus.filter((m) => m.parent_id === menu.id) as subMenu}
								<TableRow class="bg-gray-50">
									<TableCell class="pl-8">└ {subMenu.display_order}</TableCell>
									<TableCell class="pl-8 font-medium">{subMenu.name}</TableCell>
									<TableCell>
										<Badge variant="outline">{getTypeLabel(subMenu.menu_type)}</Badge>
									</TableCell>
									<TableCell>{getTargetName(subMenu)}</TableCell>
									<TableCell>
										<Badge variant={subMenu.is_active ? 'default' : 'secondary'}>
											{subMenu.is_active ? '활성' : '비활성'}
										</Badge>
									</TableCell>
									<TableCell class="text-right">
										<div class="flex items-center justify-end space-x-2">
											<Button variant="ghost" size="sm" onclick={() => editMenu(subMenu)}>
												<EditIcon class="h-4 w-4" />
											</Button>
											<Button
												variant="ghost"
												size="sm"
												class="text-red-600"
												onclick={() => confirmDelete(subMenu)}
											>
												<TrashIcon class="h-4 w-4" />
											</Button>
										</div>
									</TableCell>
								</TableRow>
							{/each}
						{/each}
					</TableBody>
				</Table>
			{/if}
		</CardContent>
	</Card>

	<!-- 삭제 확인 모달 -->
	<AlertDialog bind:open={showDeleteModal}>
		<AlertDialogContent>
			<AlertDialogHeader>
				<AlertDialogTitle>메뉴 삭제 확인</AlertDialogTitle>
				<AlertDialogDescription>
					정말로 <strong>{deletingMenu?.name}</strong> 메뉴를 삭제하시겠습니까?
					<br />
					이 작업은 되돌릴 수 없습니다.
				</AlertDialogDescription>
			</AlertDialogHeader>
			<AlertDialogFooter>
				<AlertDialogCancel onclick={cancelDelete}>취소</AlertDialogCancel>
				<AlertDialogAction onclick={deleteMenu} class="bg-red-600 hover:bg-red-700">
					삭제
				</AlertDialogAction>
			</AlertDialogFooter>
		</AlertDialogContent>
	</AlertDialog>
</div>
