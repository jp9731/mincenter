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
	import { Checkbox } from '$lib/components/ui/checkbox';
	import {
		Dialog,
		DialogContent,
		DialogDescription,
		DialogHeader,
		DialogTitle,
		DialogTrigger
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
		ShieldIcon,
		UsersIcon
	} from 'lucide-svelte';
	import { 
		getRoles, 
		getPermissions, 
		createRole, 
		updateRole, 
		deleteRole,
		createPermission,
		updatePermission,
		deletePermission
	} from '$lib/api/admin';

	interface Role {
		id: string;
		name: string;
		description?: string;
		is_active: boolean;
		created_at: string;
		updated_at: string;
	}

	interface Permission {
		id: string;
		name: string;
		description?: string;
		resource: string;
		action: string;
		is_active: boolean;
	}

	interface RoleDetail {
		role: Role;
		permissions: Permission[];
	}

	let roles: Role[] = [];
	let permissions: Permission[] = [];
	let loading = true;
	let errorMessage: string | null = null;
	let showCreateDialog = false;
	let showEditDialog = false;
	let selectedRole: RoleDetail | null = null;

	// 폼 데이터
	let formData = {
		name: '',
		description: '',
		permissions: [] as string[]
	};

	// 권한 그룹화
	$: permissionGroups = permissions.reduce((groups, permission) => {
		const resource = permission.resource;
		if (!groups[resource]) {
			groups[resource] = [];
		}
		groups[resource].push(permission);
		return groups;
	}, {} as Record<string, Permission[]>);

	onMount(async () => {
		await loadData();
	});

	async function loadData() {
		loading = true;
		try {
			errorMessage = null;
			const [rolesData, permissionsData] = await Promise.all([
				getRoles(),
				getPermissions()
			]);
			roles = rolesData;
			permissions = permissionsData;
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
			permissions: []
		};
		showCreateDialog = true;
	}

	function openEditDialog(role: RoleDetail) {
		selectedRole = role;
		formData = {
			name: role.role.name,
			description: role.role.description || '',
			permissions: role.permissions.map(p => p.id)
		};
		showEditDialog = true;
	}

	async function handleCreateRole() {
		try {
			await createRole({
				name: formData.name,
				description: formData.description || undefined,
				permissions: formData.permissions
			});
			showCreateDialog = false;
			await loadData();
			alert('역할이 성공적으로 생성되었습니다.');
		} catch (error) {
			console.error('역할 생성 실패:', error);
			alert('역할 생성에 실패했습니다.');
		}
	}

	async function handleUpdateRole() {
		if (!selectedRole) return;
		
		try {
			await updateRole(selectedRole.role.id, {
				name: formData.name,
				description: formData.description || undefined,
				permissions: formData.permissions
			});
			showEditDialog = false;
			selectedRole = null;
			await loadData();
			alert('역할이 성공적으로 수정되었습니다.');
		} catch (error) {
			console.error('역할 수정 실패:', error);
			alert('역할 수정에 실패했습니다.');
		}
	}

	async function handleDeleteRole(roleId: string) {
		try {
			await deleteRole(roleId);
			await loadData();
			alert('역할이 성공적으로 삭제되었습니다.');
		} catch (error) {
			console.error('역할 삭제 실패:', error);
			alert('역할 삭제에 실패했습니다.');
		}
	}

	function togglePermission(permissionId: string) {
		const index = formData.permissions.indexOf(permissionId);
		if (index > -1) {
			formData.permissions = formData.permissions.filter(id => id !== permissionId);
		} else {
			formData.permissions = [...formData.permissions, permissionId];
		}
	}

	function getResourceDisplayName(resource: string): string {
		const resourceNames: Record<string, string> = {
			'users': '사용자 관리',
			'boards': '게시판 관리',
			'posts': '게시글 관리',
			'comments': '댓글 관리',
			'settings': '사이트 설정',
			'menus': '메뉴 관리',
			'pages': '페이지 관리',
			'calendar': '일정 관리',
			'roles': '역할 관리',
			'permissions': '권한 관리'
		};
		return resourceNames[resource] || resource;
	}

	function getActionDisplayName(action: string): string {
		const actionNames: Record<string, string> = {
			'read': '조회',
			'create': '생성',
			'update': '수정',
			'delete': '삭제',
			'moderate': '중재',
			'roles': '역할 관리',
			'assign': '할당'
		};
		return actionNames[action] || action;
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">역할 및 권한 관리</h1>
			<p class="text-gray-600">시스템 역할을 생성하고 각 역할에 대한 권한을 할당합니다.</p>
		</div>
		<Button onclick={openCreateDialog}>
			<PlusIcon class="mr-2 h-4 w-4" />
			새 역할 생성
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
		<!-- 역할 목록 -->
		<div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
			{#each roles as role}
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<ShieldIcon class="h-5 w-5" />
							{role.name}
						</CardTitle>
						<CardDescription>
							{role.description || '설명 없음'}
						</CardDescription>
					</CardHeader>
					<CardContent>
						<div class="flex items-center justify-between">
							<span class="text-sm text-gray-500">
								상태: {role.is_active ? '활성' : '비활성'}
							</span>
							<div class="flex items-center gap-2">
								<Button
									variant="outline"
									size="sm"
									onclick={() => openEditDialog({ role, permissions: [] })}
								>
									<EditIcon class="h-4 w-4" />
								</Button>
								{#if role.name !== 'super_admin' && role.name !== 'admin'}
																	<AlertDialog>
									<AlertDialogTrigger>
										<Button variant="outline" size="sm" class="text-red-600">
											<TrashIcon class="h-4 w-4" />
										</Button>
									</AlertDialogTrigger>
										<AlertDialogContent>
											<AlertDialogHeader>
												<AlertDialogTitle>역할 삭제</AlertDialogTitle>
												<AlertDialogDescription>
													정말로 "{role.name}" 역할을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.
												</AlertDialogDescription>
											</AlertDialogHeader>
											<AlertDialogFooter>
												<AlertDialogCancel>취소</AlertDialogCancel>
												<AlertDialogAction onclick={() => handleDeleteRole(role.id)}>
													삭제
												</AlertDialogAction>
											</AlertDialogFooter>
										</AlertDialogContent>
									</AlertDialog>
								{/if}
							</div>
						</div>
					</CardContent>
				</Card>
			{/each}
		</div>
	{/if}
</div>

<!-- 역할 생성 다이얼로그 -->
<Dialog bind:open={showCreateDialog}>
	<DialogContent class="max-w-2xl max-h-[80vh] flex flex-col">
		<DialogHeader>
			<DialogTitle>새 역할 생성</DialogTitle>
			<DialogDescription>
				새로운 역할을 생성하고 권한을 할당합니다.
			</DialogDescription>
		</DialogHeader>
		<div class="flex-1 overflow-y-auto space-y-4 pr-2">
			<div>
				<Label for="role-name">역할명</Label>
				<Input
					id="role-name"
					bind:value={formData.name}
					placeholder="역할명을 입력하세요"
				/>
			</div>
			<div>
				<Label for="role-description">설명</Label>
				<Input
					id="role-description"
					bind:value={formData.description}
					placeholder="역할에 대한 설명을 입력하세요"
				/>
			</div>
			<div>
				<Label>권한 할당</Label>
				<div class="mt-2 space-y-4">
					{#each Object.entries(permissionGroups) as [resource, perms]}
						<div class="rounded-lg border p-4">
							<h4 class="font-medium mb-2">{getResourceDisplayName(resource)}</h4>
							<div class="grid grid-cols-2 gap-2">
								{#each perms as permission}
									<div class="flex items-center space-x-2">
										<Checkbox
											id={`perm-${permission.id}`}
											checked={formData.permissions.includes(permission.id)}
											onchange={() => togglePermission(permission.id)}
										/>
										<Label for={`perm-${permission.id}`} class="text-sm">
											{getActionDisplayName(permission.action)}
										</Label>
									</div>
								{/each}
							</div>
						</div>
					{/each}
				</div>
			</div>
		</div>
		<div class="flex justify-end gap-2 pt-4 border-t">
			<Button variant="outline" onclick={() => showCreateDialog = false}>
				취소
			</Button>
			<Button onclick={handleCreateRole}>
				생성
			</Button>
		</div>
	</DialogContent>
</Dialog>

<!-- 역할 수정 다이얼로그 -->
<Dialog bind:open={showEditDialog}>
	<DialogContent class="max-w-2xl max-h-[80vh] flex flex-col">
		<DialogHeader>
			<DialogTitle>역할 수정</DialogTitle>
			<DialogDescription>
				역할 정보와 권한을 수정합니다.
			</DialogDescription>
		</DialogHeader>
		<div class="flex-1 overflow-y-auto space-y-4 pr-2">
			<div>
				<Label for="edit-role-name">역할명</Label>
				<Input
					id="edit-role-name"
					bind:value={formData.name}
					placeholder="역할명을 입력하세요"
				/>
			</div>
			<div>
				<Label for="edit-role-description">설명</Label>
				<Input
					id="edit-role-description"
					bind:value={formData.description}
					placeholder="역할에 대한 설명을 입력하세요"
				/>
			</div>
			<div>
				<Label>권한 할당</Label>
				<div class="mt-2 space-y-4">
					{#each Object.entries(permissionGroups) as [resource, perms]}
						<div class="rounded-lg border p-4">
							<h4 class="font-medium mb-2">{getResourceDisplayName(resource)}</h4>
							<div class="grid grid-cols-2 gap-2">
								{#each perms as permission}
									<div class="flex items-center space-x-2">
										<Checkbox
											id={`edit-perm-${permission.id}`}
											checked={formData.permissions.includes(permission.id)}
											onchange={() => togglePermission(permission.id)}
										/>
										<Label for={`edit-perm-${permission.id}`} class="text-sm">
											{getActionDisplayName(permission.action)}
										</Label>
									</div>
								{/each}
							</div>
						</div>
					{/each}
				</div>
			</div>
		</div>
		<div class="flex justify-end gap-2 pt-4 border-t">
			<Button variant="outline" onclick={() => showEditDialog = false}>
				취소
			</Button>
			<Button onclick={handleUpdateRole}>
				수정
			</Button>
		</div>
	</DialogContent>
</Dialog>
