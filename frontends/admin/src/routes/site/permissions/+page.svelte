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
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import {
		Select,
		SelectContent,
		SelectItem,
		SelectTrigger
	} from '$lib/components/ui/select';
	import {
		Dialog,
		DialogContent,
		DialogDescription,
		DialogHeader,
		DialogTitle
	} from '$lib/components/ui/dialog';
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
	import {
		PlusIcon,
		EditIcon,
		TrashIcon,
		ShieldIcon
	} from 'lucide-svelte';
	import { 
		getPermissions, 
		createPermission, 
		updatePermission, 
		deletePermission 
	} from '$lib/api/admin';

	interface Permission {
		id: string;
		name: string;
		description?: string;
		resource: string;
		action: string;
		is_active: boolean;
		created_at: string;
		updated_at: string;
	}

	let permissions: Permission[] = [];
	let loading = true;
	let errorMessage: string | null = null;
	let showCreateDialog = false;
	let showEditDialog = false;
	let selectedPermission: Permission | null = null;

	// 폼 데이터
	let formData = {
		name: '',
		description: '',
		resource: '',
		action: ''
	};

	// 리소스와 액션 옵션
	const resourceOptions = [
		{ value: 'users', label: '사용자 관리' },
		{ value: 'boards', label: '게시판 관리' },
		{ value: 'posts', label: '게시글 관리' },
		{ value: 'comments', label: '댓글 관리' },
		{ value: 'settings', label: '사이트 설정' },
		{ value: 'menus', label: '메뉴 관리' },
		{ value: 'pages', label: '페이지 관리' },
		{ value: 'calendar', label: '일정 관리' },
		{ value: 'roles', label: '역할 관리' },
		{ value: 'permissions', label: '권한 관리' }
	];

	const actionOptions = [
		{ value: 'read', label: '조회' },
		{ value: 'create', label: '생성' },
		{ value: 'update', label: '수정' },
		{ value: 'delete', label: '삭제' },
		{ value: 'moderate', label: '중재' },
		{ value: 'assign', label: '할당' }
	];

	onMount(async () => {
		await loadData();
	});

	async function loadData() {
		loading = true;
		try {
			errorMessage = null;
			permissions = await getPermissions();
		} catch (error) {
			console.error('데이터 로드 실패:', error);
			errorMessage = error instanceof Error ? error.message : '데이터를 불러오는데 실패했습니다.';
		} finally {
			loading = false;
		}
	}

	function openCreateDialog() {
		formData = {
			name: '',
			description: '',
			resource: '',
			action: ''
		};
		showCreateDialog = true;
	}

	function openEditDialog(permission: Permission) {
		selectedPermission = permission;
		formData = {
			name: permission.name,
			description: permission.description || '',
			resource: permission.resource,
			action: permission.action
		};
		showEditDialog = true;
	}

	async function handleCreatePermission() {
		try {
			await createPermission({
				name: formData.name,
				description: formData.description || undefined,
				resource: formData.resource,
				action: formData.action
			});
			showCreateDialog = false;
			await loadData();
			alert('권한이 성공적으로 생성되었습니다.');
		} catch (error) {
			console.error('권한 생성 실패:', error);
			alert('권한 생성에 실패했습니다.');
		}
	}

	async function handleUpdatePermission() {
		if (!selectedPermission) return;
		
		try {
			await updatePermission(selectedPermission.id, {
				name: formData.name,
				description: formData.description || undefined,
				resource: formData.resource,
				action: formData.action
			});
			showEditDialog = false;
			selectedPermission = null;
			await loadData();
			alert('권한이 성공적으로 수정되었습니다.');
		} catch (error) {
			console.error('권한 수정 실패:', error);
			alert('권한 수정에 실패했습니다.');
		}
	}

	async function handleDeletePermission(permissionId: string) {
		try {
			await deletePermission(permissionId);
			await loadData();
			alert('권한이 성공적으로 삭제되었습니다.');
		} catch (error) {
			console.error('권한 삭제 실패:', error);
			alert('권한 삭제에 실패했습니다.');
		}
	}

	function getResourceDisplayName(resource: string): string {
		const option = resourceOptions.find(opt => opt.value === resource);
		return option ? option.label : resource;
	}

	function getActionDisplayName(action: string): string {
		const option = actionOptions.find(opt => opt.value === action);
		return option ? option.label : action;
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">권한 관리</h1>
			<p class="text-gray-600">시스템 권한을 생성하고 관리합니다.</p>
		</div>
		<Button onclick={openCreateDialog}>
			<PlusIcon class="mr-2 h-4 w-4" />
			새 권한 생성
		</Button>
	</div>

	<!-- 에러 메시지 -->
	{#if errorMessage}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4">
			<p class="text-red-600">{errorMessage}</p>
		</div>
	{/if}

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="border-primary-600 h-8 w-8 animate-spin rounded-full border-b-2"></div>
		</div>
	{:else}
		<!-- 권한 목록 -->
		<div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
			{#each permissions as permission}
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<ShieldIcon class="h-5 w-5" />
							{permission.name}
						</CardTitle>
						<CardDescription>
							{permission.description || '설명 없음'}
						</CardDescription>
					</CardHeader>
					<CardContent>
						<div class="space-y-2">
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-500">리소스:</span>
								<span class="text-sm font-medium">{getResourceDisplayName(permission.resource)}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-500">액션:</span>
								<span class="text-sm font-medium">{getActionDisplayName(permission.action)}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-500">상태:</span>
								<span class="text-sm font-medium {permission.is_active ? 'text-green-600' : 'text-red-600'}">
									{permission.is_active ? '활성' : '비활성'}
								</span>
							</div>
						</div>
						<div class="flex items-center gap-2 mt-4">
							<Button
								variant="outline"
								size="sm"
								onclick={() => openEditDialog(permission)}
							>
								<EditIcon class="h-4 w-4" />
							</Button>
							<AlertDialog>
								<AlertDialogTrigger>
									<Button variant="outline" size="sm" class="text-red-600">
										<TrashIcon class="h-4 w-4" />
									</Button>
								</AlertDialogTrigger>
								<AlertDialogContent>
									<AlertDialogHeader>
										<AlertDialogTitle>권한 삭제</AlertDialogTitle>
										<AlertDialogDescription>
											정말로 "{permission.name}" 권한을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.
										</AlertDialogDescription>
									</AlertDialogHeader>
									<AlertDialogFooter>
										<AlertDialogCancel>취소</AlertDialogCancel>
										<AlertDialogAction onclick={() => handleDeletePermission(permission.id)}>
											삭제
										</AlertDialogAction>
									</AlertDialogFooter>
								</AlertDialogContent>
							</AlertDialog>
						</div>
					</CardContent>
				</Card>
			{/each}
		</div>
	{/if}
</div>

<!-- 권한 생성 다이얼로그 -->
<Dialog bind:open={showCreateDialog}>
	<DialogContent class="max-w-md">
		<DialogHeader>
			<DialogTitle>새 권한 생성</DialogTitle>
			<DialogDescription>
				새로운 권한을 생성합니다.
			</DialogDescription>
		</DialogHeader>
		<div class="space-y-4">
			<div>
				<Label for="permission-name">권한명</Label>
				<Input
					id="permission-name"
					bind:value={formData.name}
					placeholder="예: users.create"
				/>
			</div>
			<div>
				<Label for="permission-description">설명</Label>
				<Input
					id="permission-description"
					bind:value={formData.description}
					placeholder="권한에 대한 설명을 입력하세요"
				/>
			</div>
			<div>
				<Label for="permission-resource">리소스</Label>
				<Select type="single" bind:value={formData.resource}>
					<SelectTrigger>
						{formData.resource ? getResourceDisplayName(formData.resource) : '리소스를 선택하세요'}
					</SelectTrigger>
					<SelectContent>
						{#each resourceOptions as option}
							<SelectItem value={option.value}>{option.label}</SelectItem>
						{/each}
					</SelectContent>
				</Select>
			</div>
			<div>
				<Label for="permission-action">액션</Label>
				<Select type="single" bind:value={formData.action}>
					<SelectTrigger>
						{formData.action ? getActionDisplayName(formData.action) : '액션을 선택하세요'}
					</SelectTrigger>
					<SelectContent>
						{#each actionOptions as option}
							<SelectItem value={option.value}>{option.label}</SelectItem>
						{/each}
					</SelectContent>
				</Select>
			</div>
		</div>
		<div class="flex justify-end gap-2">
			<Button variant="outline" onclick={() => showCreateDialog = false}>
				취소
			</Button>
			<Button onclick={handleCreatePermission}>
				생성
			</Button>
		</div>
	</DialogContent>
</Dialog>

<!-- 권한 수정 다이얼로그 -->
<Dialog bind:open={showEditDialog}>
	<DialogContent class="max-w-md">
		<DialogHeader>
			<DialogTitle>권한 수정</DialogTitle>
			<DialogDescription>
				권한 정보를 수정합니다.
			</DialogDescription>
		</DialogHeader>
		<div class="space-y-4">
			<div>
				<Label for="edit-permission-name">권한명</Label>
				<Input
					id="edit-permission-name"
					bind:value={formData.name}
					placeholder="예: users.create"
				/>
			</div>
			<div>
				<Label for="edit-permission-description">설명</Label>
				<Input
					id="edit-permission-description"
					bind:value={formData.description}
					placeholder="권한에 대한 설명을 입력하세요"
				/>
			</div>
			<div>
				<Label for="edit-permission-resource">리소스</Label>
				<Select type="single" bind:value={formData.resource}>
					<SelectTrigger>
						{formData.resource ? getResourceDisplayName(formData.resource) : '리소스를 선택하세요'}
					</SelectTrigger>
					<SelectContent>
						{#each resourceOptions as option}
							<SelectItem value={option.value}>{option.label}</SelectItem>
						{/each}
					</SelectContent>
				</Select>
			</div>
			<div>
				<Label for="edit-permission-action">액션</Label>
				<Select type="single" bind:value={formData.action}>
					<SelectTrigger>
						{formData.action ? getActionDisplayName(formData.action) : '액션을 선택하세요'}
					</SelectTrigger>
					<SelectContent>
						{#each actionOptions as option}
							<SelectItem value={option.value}>{option.label}</SelectItem>
						{/each}
					</SelectContent>
				</Select>
			</div>
		</div>
		<div class="flex justify-end gap-2">
			<Button variant="outline" onclick={() => showEditDialog = false}>
				취소
			</Button>
			<Button onclick={handleUpdatePermission}>
				수정
			</Button>
		</div>
	</DialogContent>
</Dialog> 