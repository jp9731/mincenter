<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Switch } from '$lib/components/ui/switch';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { Plus, Edit, Trash2, Settings } from 'lucide-svelte';
	import {
		getBoards,
		createBoard as apiCreateBoard,
		updateBoard as apiUpdateBoard,
		deleteBoard as apiDeleteBoard
	} from '$lib/api/admin';

	// Mock 데이터
	let boards = [];

	let showCreateModal = false;
	let showEditModal = false;
	let selectedBoard = null;
	let loading = false;

	// 새 게시판 폼
	let newBoard = {
		name: '',
		description: '',
		allow_file_upload: true,
		max_files: 5,
		max_file_size: 10 * 1024 * 1024,
		allowed_file_types: ['image/*'],
		allow_rich_text: true,
		require_category: false
	};

	// 파일 크기 MB 단위 변수 (UI용)
	let newBoardMaxFileSizeMB = 10;
	let selectedBoardMaxFileSizeMB = 10;

	// 파일 타입 옵션
	const fileTypeOptions = [
		{ value: 'image/*', label: '이미지 파일' },
		{ value: 'video/*', label: '비디오 파일' },
		{ value: 'audio/*', label: '오디오 파일' },
		{ value: 'application/pdf', label: 'PDF 파일' },
		{ value: 'text/*', label: '텍스트 파일' },
		{ value: 'application/msword', label: 'Word 문서' },
		{
			value: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
			label: 'Word 문서 (.docx)'
		},
		{ value: 'application/vnd.ms-excel', label: 'Excel 파일' },
		{
			value: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
			label: 'Excel 파일 (.xlsx)'
		},
		{ value: 'application/zip', label: 'ZIP 파일' },
		{ value: '*/*', label: '모든 파일' }
	];

	function formatFileSize(bytes: number): string {
		if (bytes === 0) return '0 Bytes';
		const k = 1024;
		const sizes = ['Bytes', 'KB', 'MB', 'GB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
	}

	function getFileTypeLabel(type: string): string {
		const option = fileTypeOptions.find((opt) => opt.value === type);
		return option ? option.label : type;
	}

	function openCreateModal() {
		showCreateModal = true;
		newBoard = {
			name: '',
			description: '',
			allow_file_upload: true,
			max_files: 5,
			max_file_size: 10 * 1024 * 1024,
			allowed_file_types: ['image/*'],
			allow_rich_text: true,
			require_category: false
		};
		newBoardMaxFileSizeMB = 10;
	}

	function openEditModal(board: any) {
		selectedBoard = { ...board };
		selectedBoardMaxFileSizeMB = Math.round(board.max_file_size / (1024 * 1024));
		showEditModal = true;
	}

	function closeModals() {
		showCreateModal = false;
		showEditModal = false;
		selectedBoard = null;
	}

	// 파일 크기 MB를 바이트로 변환
	function convertMBToBytes(mb: number): number {
		return mb * 1024 * 1024;
	}

	// 바이트를 MB로 변환
	function convertBytesToMB(bytes: number): number {
		return Math.round(bytes / (1024 * 1024));
	}

	onMount(async () => {
		loading = true;
		try {
			boards = await getBoards();
		} catch (e) {
			console.error('게시판 목록 불러오기 실패:', e);
		} finally {
			loading = false;
		}
	});

	async function createBoard() {
		loading = true;
		try {
			const boardData = {
				...newBoard,
				max_file_size: convertMBToBytes(newBoardMaxFileSizeMB)
			};
			const board = await apiCreateBoard(boardData);
			boards = [...boards, board];
			closeModals();
		} catch (error) {
			console.error('게시판 생성 실패:', error);
		} finally {
			loading = false;
		}
	}

	async function updateBoard() {
		loading = true;
		try {
			const boardData = {
				...selectedBoard,
				max_file_size: convertMBToBytes(selectedBoardMaxFileSizeMB)
			};
			const updated = await apiUpdateBoard(selectedBoard.id, boardData);
			boards = boards.map((board) => (board.id === updated.id ? updated : board));
			closeModals();
		} catch (error) {
			console.error('게시판 수정 실패:', error);
		} finally {
			loading = false;
		}
	}

	async function deleteBoard(id: string) {
		if (!confirm('정말로 이 게시판을 삭제하시겠습니까?')) return;
		try {
			await apiDeleteBoard(id);
			boards = boards.filter((board) => board.id !== id);
		} catch (error) {
			console.error('게시판 삭제 실패:', error);
		}
	}

	function handleFileTypeChange(value: string) {
		if (selectedBoard) {
			if (selectedBoard.allowed_file_types.includes(value)) {
				selectedBoard.allowed_file_types = selectedBoard.allowed_file_types.filter(
					(type) => type !== value
				);
			} else {
				selectedBoard.allowed_file_types = [...selectedBoard.allowed_file_types, value];
			}
			selectedBoard = { ...selectedBoard };
		} else {
			if (newBoard.allowed_file_types.includes(value)) {
				newBoard.allowed_file_types = newBoard.allowed_file_types.filter((type) => type !== value);
			} else {
				newBoard.allowed_file_types = [...newBoard.allowed_file_types, value];
			}
			newBoard = { ...newBoard };
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">게시판 관리</h1>
			<p class="mt-2 text-gray-600">게시판 설정과 파일 업로드 옵션을 관리합니다.</p>
		</div>
		<Button onclick={openCreateModal}>
			<Plus class="mr-2 h-4 w-4" />
			새 게시판
		</Button>
	</div>

	<!-- 게시판 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>게시판 목록</CardTitle>
			<CardDescription>총 {boards.length}개의 게시판이 있습니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>게시판명</TableHead>
						<TableHead>설명</TableHead>
						<TableHead>파일 업로드</TableHead>
						<TableHead>리치 텍스트</TableHead>
						<TableHead>카테고리 필수</TableHead>
						<TableHead>생성일</TableHead>
						<TableHead>액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#each boards as board}
						<TableRow>
							<TableCell>
								<div class="font-medium">{board.name}</div>
							</TableCell>
							<TableCell>
								<div class="max-w-xs truncate text-sm text-gray-500">
									{board.description}
								</div>
							</TableCell>
							<TableCell>
								{#if board.allow_file_upload}
									<Badge variant="default">활성화</Badge>
									<div class="mt-1 text-xs text-gray-500">
										최대 {board.max_files}개, {formatFileSize(board.max_file_size)}
									</div>
								{:else}
									<Badge variant="secondary">비활성화</Badge>
								{/if}
							</TableCell>
							<TableCell>
								<Badge variant={board.allow_rich_text ? 'default' : 'secondary'}>
									{board.allow_rich_text ? '활성화' : '비활성화'}
								</Badge>
							</TableCell>
							<TableCell>
								<Badge variant={board.require_category ? 'default' : 'secondary'}>
									{board.require_category ? '필수' : '선택'}
								</Badge>
							</TableCell>
							<TableCell>
								{new Date(board.created_at).toLocaleDateString('ko-KR')}
							</TableCell>
							<TableCell>
								<div class="flex space-x-2">
									<Button variant="outline" size="sm" onclick={() => openEditModal(board)}>
										<Edit class="h-4 w-4" />
									</Button>
									<Button variant="outline" size="sm" onclick={() => deleteBoard(board.id)}>
										<Trash2 class="h-4 w-4" />
									</Button>
								</div>
							</TableCell>
						</TableRow>
					{/each}
				</TableBody>
			</Table>
		</CardContent>
	</Card>
</div>

<!-- 새 게시판 모달 -->
{#if showCreateModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center">
		<div class="fixed inset-0 bg-black bg-opacity-50" onclick={closeModals}></div>
		<div
			class="relative mx-4 max-h-screen w-full max-w-2xl overflow-y-auto rounded-lg bg-white shadow-xl"
		>
			<div class="border-b border-gray-200 px-6 py-4">
				<h3 class="text-lg font-medium text-gray-900">새 게시판 생성</h3>
			</div>

			<div class="space-y-4 px-6 py-4">
				<div>
					<label class="mb-1 block text-sm font-medium text-gray-700">게시판명</label>
					<Input bind:value={newBoard.name} placeholder="게시판명을 입력하세요" />
				</div>

				<div>
					<label class="mb-1 block text-sm font-medium text-gray-700">설명</label>
					<Textarea bind:value={newBoard.description} placeholder="게시판 설명을 입력하세요" />
				</div>

				<div class="space-y-4">
					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-gray-700">파일 업로드 허용</label>
						<Switch bind:checked={newBoard.allow_file_upload} />
					</div>

					{#if newBoard.allow_file_upload}
						<div class="grid grid-cols-2 gap-4">
							<div>
								<label class="mb-1 block text-sm font-medium text-gray-700">최대 파일 개수</label>
								<Input type="number" bind:value={newBoard.max_files} min="1" max="20" />
							</div>
							<div>
								<label class="mb-1 block text-sm font-medium text-gray-700"
									>최대 파일 크기 (MB)</label
								>
								<Input type="number" bind:value={newBoardMaxFileSizeMB} min="1" max="100" />
							</div>
						</div>

						<div>
							<label class="mb-2 block text-sm font-medium text-gray-700">허용 파일 형식</label>
							<div class="grid grid-cols-2 gap-2">
								{#each fileTypeOptions as option}
									<label class="flex items-center space-x-2">
										<input
											type="checkbox"
											checked={newBoard.allowed_file_types.includes(option.value)}
											onchange={() => handleFileTypeChange(option.value)}
										/>
										<span class="text-sm">{option.label}</span>
									</label>
								{/each}
							</div>
						</div>
					{/if}

					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-gray-700">리치 텍스트 에디터 사용</label>
						<Switch bind:checked={newBoard.allow_rich_text} />
					</div>

					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-gray-700">카테고리 필수</label>
						<Switch bind:checked={newBoard.require_category} />
					</div>
				</div>
			</div>

			<div class="flex justify-end space-x-3 border-t border-gray-200 px-6 py-4">
				<Button variant="outline" onclick={closeModals} disabled={loading}>취소</Button>
				<Button onclick={createBoard} disabled={loading}>
					{loading ? '생성 중...' : '생성'}
				</Button>
			</div>
		</div>
	</div>
{/if}

<!-- 게시판 수정 모달 -->
{#if showEditModal && selectedBoard}
	<div class="fixed inset-0 z-50 flex items-center justify-center">
		<div class="fixed inset-0 bg-black bg-opacity-50" onclick={closeModals}></div>
		<div
			class="relative mx-4 max-h-screen w-full max-w-2xl overflow-y-auto rounded-lg bg-white shadow-xl"
		>
			<div class="border-b border-gray-200 px-6 py-4">
				<h3 class="text-lg font-medium text-gray-900">게시판 수정</h3>
			</div>

			<div class="space-y-4 px-6 py-4">
				<div>
					<label class="mb-1 block text-sm font-medium text-gray-700">게시판명</label>
					<Input bind:value={selectedBoard.name} placeholder="게시판명을 입력하세요" />
				</div>

				<div>
					<label class="mb-1 block text-sm font-medium text-gray-700">설명</label>
					<Textarea bind:value={selectedBoard.description} placeholder="게시판 설명을 입력하세요" />
				</div>

				<div class="space-y-4">
					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-gray-700">파일 업로드 허용</label>
						<Switch bind:checked={selectedBoard.allow_file_upload} />
					</div>

					{#if selectedBoard.allow_file_upload}
						<div class="grid grid-cols-2 gap-4">
							<div>
								<label class="mb-1 block text-sm font-medium text-gray-700">최대 파일 개수</label>
								<Input type="number" bind:value={selectedBoard.max_files} min="1" max="20" />
							</div>
							<div>
								<label class="mb-1 block text-sm font-medium text-gray-700"
									>최대 파일 크기 (MB)</label
								>
								<Input type="number" bind:value={selectedBoardMaxFileSizeMB} min="1" max="100" />
							</div>
						</div>

						<div>
							<label class="mb-2 block text-sm font-medium text-gray-700">허용 파일 형식</label>
							<div class="grid grid-cols-2 gap-2">
								{#each fileTypeOptions as option}
									<label class="flex items-center space-x-2">
										<input
											type="checkbox"
											checked={selectedBoard.allowed_file_types.includes(option.value)}
											onchange={() => handleFileTypeChange(option.value)}
										/>
										<span class="text-sm">{option.label}</span>
									</label>
								{/each}
							</div>
						</div>
					{/if}

					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-gray-700">리치 텍스트 에디터 사용</label>
						<Switch bind:checked={selectedBoard.allow_rich_text} />
					</div>

					<div class="flex items-center justify-between">
						<label class="text-sm font-medium text-gray-700">카테고리 필수</label>
						<Switch bind:checked={selectedBoard.require_category} />
					</div>
				</div>
			</div>

			<div class="flex justify-end space-x-3 border-t border-gray-200 px-6 py-4">
				<Button variant="outline" onclick={closeModals} disabled={loading}>취소</Button>
				<Button onclick={updateBoard} disabled={loading}>
					{loading ? '수정 중...' : '수정'}
				</Button>
			</div>
		</div>
	</div>
{/if}
