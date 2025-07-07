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
		Select,
		SelectContent,
		SelectItem,
		SelectTrigger
	} from '$lib/components/ui/select';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import {
		PlusIcon,
		EditIcon,
		ShieldIcon,
		UserIcon,
		UsersIcon,
		SearchIcon,
		XIcon,
		CheckIcon
	} from 'lucide-svelte';
	import { 
		getUsers, 
		getRoles, 
		getUserPermissions, 
		assignUserRoles 
	} from '$lib/api/admin';

	interface User {
		id: string;
		email: string;
		name: string;
		phone?: string;
		role?: string;
		is_active: boolean;
		created_at: string;
	}

	interface Role {
		id: string;
		name: string;
		description?: string;
		is_active: boolean;
	}

	interface UserPermissions {
		user_id: string;
		roles: Role[];
		permissions: any[];
	}

	let users: User[] = [];
	let filteredUsers: User[] = [];
	let roles: Role[] = [];
	let loading = true;
	let errorMessage: string | null = null;
	let showAssignDialog = false;
	let selectedUser: User | null = null;
	let selectedUserPermissions: UserPermissions | null = null;

	// 검색 관련 상태
	let searchQuery = '';
	let searchType = 'all'; // 'all', 'name', 'email', 'phone'
	let searchTimeout: number | null = null;

	// 폼 데이터
	let selectedRoleIds: string[] = [];

	onMount(async () => {
		await loadData();
	});

	async function loadData() {
		loading = true;
		try {
			errorMessage = null;
			const [usersData, rolesData] = await Promise.all([
				getUsers(),
				getRoles()
			]);
			users = usersData.users || usersData;
			filteredUsers = [...users];
			roles = rolesData;
			console.log('로드된 역할 목록:', roles);
		} catch (error) {
			console.error('데이터 로드 실패:', error);
			errorMessage = error instanceof Error ? error.message : '데이터를 불러오는데 실패했습니다.';
		} finally {
			loading = false;
		}
	}

	async function searchUsers() {
		if (!searchQuery.trim()) {
			await loadData();
			return;
		}

		loading = true;
		try {
			errorMessage = null;
			const [usersData, rolesData] = await Promise.all([
				getUsers({ search: searchQuery }),
				getRoles()
			]);
			users = usersData.users || usersData;
			filteredUsers = [...users];
			roles = rolesData;
		} catch (error) {
			console.error('검색 실패:', error);
			errorMessage = error instanceof Error ? error.message : '검색에 실패했습니다.';
		} finally {
			loading = false;
		}
	}

	function handleSearchInput() {
		// 이전 타이머 취소
		if (searchTimeout) {
			clearTimeout(searchTimeout);
		}

		// 500ms 후에 검색 실행 (디바운싱)
		searchTimeout = setTimeout(() => {
			searchUsers();
		}, 500);
	}

	function clearSearch() {
		searchQuery = '';
		searchType = 'all';
		if (searchTimeout) {
			clearTimeout(searchTimeout);
			searchTimeout = null;
		}
		loadData();
	}

	async function openAssignDialog(user: User) {
		selectedUser = user;
		try {
			selectedUserPermissions = await getUserPermissions(user.id);
			if (selectedUserPermissions) {
				selectedRoleIds = selectedUserPermissions.roles.map(role => role.id);
				console.log('현재 사용자 역할:', selectedUserPermissions.roles);
				console.log('폼 데이터 초기화:', selectedRoleIds);
			} else {
				selectedRoleIds = [];
			}
			showAssignDialog = true;
		} catch (error) {
			console.error('사용자 권한 조회 실패:', error);
			alert('사용자 권한을 조회하는데 실패했습니다.');
		}
	}

	async function handleAssignRoles() {
		if (!selectedUser) return;
		
		try {
			console.log('역할 할당 시작:', {
				userId: selectedUser.id,
				roleIds: selectedRoleIds
			});
			
			const result = await assignUserRoles(selectedUser.id, selectedRoleIds);
			console.log('역할 할당 결과:', result);
			
			showAssignDialog = false;
			selectedUser = null;
			selectedUserPermissions = null;
			selectedRoleIds = [];
			await loadData();
			alert('사용자 역할이 성공적으로 할당되었습니다.');
		} catch (error) {
			console.error('역할 할당 실패:', error);
			alert(`역할 할당에 실패했습니다: ${error instanceof Error ? error.message : '알 수 없는 오류'}`);
		}
	}

	function toggleRole(roleId: string) {
		console.log('역할 토글:', roleId, '현재 선택된 역할들:', selectedRoleIds);
		const index = selectedRoleIds.indexOf(roleId);
		if (index !== -1) {
			// 이미 선택된 역할이면 제거
			selectedRoleIds = selectedRoleIds.filter(id => id !== roleId);
		} else {
			// 선택되지 않은 역할이면 추가
			selectedRoleIds = [...selectedRoleIds, roleId];
		}
		console.log('토글 후 선택된 역할들:', selectedRoleIds);
	}

	function getRoleDisplayName(roleName: string): string {
		const roleNames: Record<string, string> = {
			'super_admin': '시스템 관리자',
			'admin': '관리자',
			'moderator': '중재자',
			'editor': '편집자',
			'viewer': '조회자'
		};
		return roleNames[roleName] || roleName;
	}

	function getStatusBadgeClass(isActive: boolean): string {
		return isActive 
			? 'bg-green-100 text-green-800' 
			: 'bg-red-100 text-red-800';
	}

	// 검색 쿼리 변경 시 자동 검색 실행 (디바운싱 적용)
	$: if (searchQuery !== undefined) {
		handleSearchInput();
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">관리자 설정</h1>
			<p class="text-gray-600">사용자에게 관리자 역할을 할당하거나 제거합니다.</p>
		</div>
	</div>

	<!-- 검색 섹션 -->
	<Card>
		<CardHeader>
			<CardTitle class="flex items-center gap-2">
				<SearchIcon class="h-5 w-5" />
				회원 검색
			</CardTitle>
			<CardDescription>
				이름, 이메일, 연락처로 회원을 검색할 수 있습니다.
			</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="flex flex-col gap-4 sm:flex-row sm:items-end">
				<!-- 검색 타입 선택 -->
				<div class="flex-1">
					<Label for="search-type" class="block mb-2">검색 범위</Label>
					<Select type="single" bind:value={searchType}>
						<SelectTrigger>
							{#if searchType === 'all'}
								전체
							{:else if searchType === 'name'}
								이름
							{:else if searchType === 'email'}
								이메일
							{:else if searchType === 'phone'}
								연락처
							{:else}
								전체
							{/if}
						</SelectTrigger>
						<SelectContent>
							<SelectItem value="all">전체</SelectItem>
							<SelectItem value="name">이름</SelectItem>
							<SelectItem value="email">이메일</SelectItem>
							<SelectItem value="phone">연락처</SelectItem>
						</SelectContent>
					</Select>
				</div>

				<!-- 검색어 입력 -->
				<div class="flex-1">
					<Label for="search-query" class="block mb-2">검색어</Label>
					<div class="relative">
						<SearchIcon class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
						<Input
							id="search-query"
							bind:value={searchQuery}
							placeholder="검색어를 입력하세요..."
							class="pl-10"
							oninput={handleSearchInput}
						/>
						{#if searchQuery}
							<Button
								variant="ghost"
								size="sm"
								class="absolute right-1 top-1/2 h-6 w-6 -translate-y-1/2 p-0"
								onclick={clearSearch}
							>
								<XIcon class="h-4 w-4" />
							</Button>
						{/if}
					</div>
				</div>

				<!-- 검색 결과 표시 -->
				<div class="text-sm text-gray-500">
					총 {filteredUsers.length}명의 회원
				</div>
			</div>
		</CardContent>
	</Card>

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
		<!-- 사용자 목록 -->
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center gap-2">
					<UsersIcon class="h-5 w-5" />
					사용자 목록
				</CardTitle>
				<CardDescription>
					시스템에 등록된 모든 사용자와 그들의 역할을 관리합니다.
				</CardDescription>
			</CardHeader>
			<CardContent>
				{#if filteredUsers.length === 0}
					<div class="text-center py-8">
						<SearchIcon class="mx-auto h-12 w-12 text-gray-400" />
						<h3 class="mt-2 text-sm font-medium text-gray-900">검색 결과가 없습니다</h3>
						<p class="mt-1 text-sm text-gray-500">
							{#if searchQuery}
								"{searchQuery}"에 대한 검색 결과가 없습니다.
							{:else}
								등록된 사용자가 없습니다.
							{/if}
						</p>
						{#if searchQuery}
							<Button variant="outline" class="mt-4" onclick={clearSearch}>
								검색 초기화
							</Button>
						{/if}
					</div>
				{:else}
					<Table>
						<TableHeader>
							<TableRow>
								<TableHead>사용자</TableHead>
								<TableHead>이메일</TableHead>
								<TableHead>연락처</TableHead>
								<TableHead>현재 역할</TableHead>
								<TableHead>상태</TableHead>
								<TableHead>가입일</TableHead>
								<TableHead>관리</TableHead>
							</TableRow>
						</TableHeader>
						<TableBody>
							{#each filteredUsers as user}
								<TableRow>
									<TableCell>
										<div class="flex items-center gap-2">
											<UserIcon class="h-4 w-4 text-gray-500" />
											<span class="font-medium">{user.name}</span>
										</div>
									</TableCell>
									<TableCell>{user.email}</TableCell>
									<TableCell>
										{#if user.phone}
											{user.phone}
										{:else}
											<span class="text-gray-500">-</span>
										{/if}
									</TableCell>
									<TableCell>
										{#if user.role}
											<span class="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-1 text-xs font-medium text-blue-800">
												<ShieldIcon class="h-3 w-3" />
												{getRoleDisplayName(user.role)}
											</span>
										{:else}
											<span class="text-gray-500">역할 없음</span>
										{/if}
									</TableCell>
									<TableCell>
										<span class="inline-flex items-center rounded-full px-2 py-1 text-xs font-medium {getStatusBadgeClass(user.is_active)}">
											{user.is_active ? '활성' : '비활성'}
										</span>
									</TableCell>
									<TableCell>
										{new Date(user.created_at).toLocaleDateString('ko-KR')}
									</TableCell>
									<TableCell>
										<Button
											variant="outline"
											size="sm"
											onclick={() => openAssignDialog(user)}
										>
											<EditIcon class="mr-1 h-3 w-3" />
											역할 관리
										</Button>
									</TableCell>
								</TableRow>
							{/each}
						</TableBody>
					</Table>
				{/if}
			</CardContent>
		</Card>
	{/if}
</div>

<!-- 역할 할당 다이얼로그 -->
<Dialog bind:open={showAssignDialog}>
	<DialogContent class="max-w-2xl">
		<DialogHeader>
			<DialogTitle>사용자 역할 할당</DialogTitle>
			<DialogDescription>
				{selectedUser?.name}님의 역할을 관리합니다.
			</DialogDescription>
		</DialogHeader>
		{#if selectedUser && selectedUserPermissions}
			<div class="space-y-4">
				<!-- 사용자 정보 -->
				<div class="rounded-lg border p-4">
					<h4 class="font-medium mb-2">사용자 정보</h4>
					<div class="grid grid-cols-2 gap-4 text-sm">
						<div>
							<span class="text-gray-500">이름:</span>
							<span class="ml-2 font-medium">{selectedUser.name}</span>
						</div>
						<div>
							<span class="text-gray-500">이메일:</span>
							<span class="ml-2 font-medium">{selectedUser.email}</span>
						</div>
						{#if selectedUser.phone}
							<div>
								<span class="text-gray-500">연락처:</span>
								<span class="ml-2 font-medium">{selectedUser.phone}</span>
							</div>
						{/if}
					</div>
				</div>

				<!-- 현재 역할 -->
				<div class="rounded-lg border p-4">
					<h4 class="font-medium mb-2">현재 역할</h4>
					{#if selectedUserPermissions.roles.length > 0}
						<div class="flex flex-wrap gap-2">
							{#each selectedUserPermissions.roles as role}
								<span class="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-1 text-xs font-medium text-blue-800">
									<ShieldIcon class="h-3 w-3" />
									{getRoleDisplayName(role.name)}
								</span>
							{/each}
						</div>
					{:else}
						<p class="text-gray-500 text-sm">할당된 역할이 없습니다.</p>
					{/if}
				</div>

				<!-- 역할 할당 -->
				<div class="rounded-lg border p-4">
					<h4 class="font-medium mb-2">역할 할당</h4>
					<div class="space-y-2">
						{#each roles as role}
							<div class="flex items-center space-x-2">
								<Button
									variant={selectedRoleIds.includes(role.id) ? "default" : "outline"}
									size="sm"
									onclick={() => toggleRole(role.id)}
									class="w-full justify-start"
								>
									{#if selectedRoleIds.includes(role.id)}
										<CheckIcon class="mr-2 h-4 w-4" />
									{/if}
									<span class="font-medium">{getRoleDisplayName(role.name)}</span>
									{#if role.description}
										<span class="ml-1 text-sm opacity-80">- {role.description}</span>
									{/if}
								</Button>
							</div>
						{/each}
					</div>
				</div>
			</div>
			<div class="flex justify-end gap-2">
				<Button variant="outline" onclick={() => showAssignDialog = false}>
					취소
				</Button>
				<Button onclick={handleAssignRoles}>
					역할 할당
				</Button>
			</div>
		{/if}
	</DialogContent>
</Dialog>
