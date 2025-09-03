<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import { Label } from '$lib/components/ui/label';
	import RichTextEditor from '$lib/components/editor/RichTextEditor.svelte';
	import FileUpload from '$lib/components/upload/FileUpload.svelte';
	import { getBoards, getBoardCategories } from '$lib/api/admin';
	import { uploadFile as uploadFileApi } from '$lib/api/admin';
	import type { Post } from '$lib/types/admin';

	// Props
	export let mode: 'create' | 'edit' = 'create';
	export let post: Post | null = null;
	export let onSubmit: (data: any) => Promise<void>;
	export let onCancel: () => void;
	export let loading = false;
	export let saving = false;
	export let error = '';

	// Form data
	let title = '';
	let content = '';
	let boardId = '';
	let categoryId = '';
	let isNotice = false;
	let createdAt = '';
	let boards: any[] = [];
	let categories: any[] = [];
	let categoriesLoading = false;
	let attachedFiles: File[] = [];
	let uploadedFiles: string[] = [];

	// 이미지 업로드 핸들러
	async function handleImageUpload(file: File): Promise<string> {
		try {
			const url = await uploadFileApi(file, 'posts', 'editorimage');
			return url;
		} catch (error) {
			console.error('이미지 업로드 실패:', error);
			throw error;
		}
	}

	// post 데이터가 변경될 때 폼 데이터 업데이트
	$: if (mode === 'edit' && post) {
		console.log('PostForm: post 데이터 업데이트됨', post);
		title = post.title || '';
		content = post.content || '';
		boardId = post.board_id || '';
		categoryId = post.category_id || '';
		isNotice = post.is_notice || false;
		createdAt = post.created_at ? new Date(post.created_at).toISOString().slice(0, 16) : '';
		
		console.log('PostForm: 폼 데이터 설정됨', { title, content, boardId, categoryId, isNotice, createdAt });
		
		// 게시판이 선택되어 있으면 카테고리 로드
		if (boardId) {
			loadCategories(boardId);
		}
	}

	onMount(async () => {
		try {
			// 게시판 목록 로드
			boards = await getBoards();
			
			if (mode === 'create') {
				// 작성 모드: 기본 등록일을 현재 시간으로 설정
				createdAt = new Date().toISOString().slice(0, 16);
			}
		} catch (err) {
			error = mode === 'edit' ? '게시글을 불러오는 중 오류가 발생했습니다.' : '게시판 목록을 불러오는 중 오류가 발생했습니다.';
			console.error('Failed to load data:', err);
		}
	});

	// loading 상태가 변경될 때 로컬 loading 상태 업데이트
	$: localLoading = loading;

	// 게시판 변경 시 카테고리 로드
	async function handleBoardChange() {
		if (boardId) {
			await loadCategories(boardId);
		} else {
			categories = [];
			categoryId = '';
		}
	}

	// 카테고리 로드
	async function loadCategories(boardId: string) {
		try {
			categoriesLoading = true;
			categories = await getBoardCategories(boardId);
		} catch (err) {
			console.error('카테고리 로드 실패:', err);
			categories = [];
		} finally {
			categoriesLoading = false;
		}
	}

	// 파일 업로드 핸들러
	async function handleFileUpload(file: File): Promise<string> {
		try {
			const url = await uploadFileApi(file, 'posts', 'attachment');
			return url;
		} catch (error) {
			console.error('파일 업로드 실패:', error);
			throw error;
		}
	}

	// 파일 변경 핸들러
	function handleFilesChange(event: CustomEvent) {
		attachedFiles = event.detail.files;
	}

	// 업로드 완료 핸들러
	function handleUploadComplete(event: CustomEvent) {
		const { file, url } = event.detail;
		uploadedFiles = [...uploadedFiles, url];
		console.log('파일 업로드 완료:', file.name, url);
	}

	async function handleSubmit() {
		if (!title.trim()) {
			error = '제목을 입력해주세요.';
			return;
		}
		if (!content.trim()) {
			error = '내용을 입력해주세요.';
			return;
		}
		if (!boardId) {
			error = '게시판을 선택해주세요.';
			return;
		}

		try {
			error = '';
			
			const postData = {
				title: title.trim(),
				content: content.trim(),
				board_id: boardId,
				category_id: categoryId || null,
				is_notice: isNotice,
				attached_files: uploadedFiles.length > 0 ? uploadedFiles : null,
				created_at: mode === 'create' ? (createdAt || null) : null
			};

			await onSubmit(postData);
		} catch (err) {
			error = mode === 'edit' ? '게시글 수정 중 오류가 발생했습니다.' : '게시글 작성 중 오류가 발생했습니다.';
			console.error('Failed to save post:', err);
		}
	}
</script>

<div class="space-y-6">
	{#if localLoading}
		<Card>
			<CardContent class="pt-6">
				<div class="flex items-center justify-center py-8">
					<div class="text-gray-500">로딩 중...</div>
				</div>
			</CardContent>
		</Card>
	{:else if error}
		<Card>
			<CardContent class="pt-6">
				<div class="bg-red-50 border border-red-200 rounded-lg p-4">
					<div class="text-red-700">{error}</div>
				</div>
			</CardContent>
		</Card>
	{:else}
		{#if error}
			<Card>
				<CardContent class="pt-6">
					<div class="bg-red-50 border border-red-200 rounded-lg p-4">
						<div class="text-red-700">{error}</div>
					</div>
				</CardContent>
			</Card>
		{/if}

		<form on:submit|preventDefault={handleSubmit}>
			<Card>
				<CardHeader>
					<CardTitle>게시글 정보</CardTitle>
					<CardDescription>{mode === 'edit' ? '게시글의 기본 정보를 수정합니다.' : '게시글의 기본 정보를 입력합니다.'}</CardDescription>
				</CardHeader>
				<CardContent class="space-y-6">
					<!-- 제목 -->
					<div class="space-y-2">
						<Label for="title">제목 *</Label>
						<Input
							id="title"
							type="text"
							placeholder="게시글 제목을 입력하세요"
							bind:value={title}
							required
						/>
					</div>

					<!-- 게시판 선택 -->
					<div class="space-y-2">
						<Label for="board">게시판 *</Label>
						<Select
							type="single"
							value={boardId}
							onValueChange={(value: any) => {
								boardId = value;
								handleBoardChange();
							}}
						>
							<SelectTrigger>
								{boardId ? boards.find(b => b.id === boardId)?.name : '게시판을 선택하세요'}
							</SelectTrigger>
							<SelectContent>
								{#each boards as board}
									<SelectItem value={board.id}>{board.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>

					<!-- 카테고리 선택 -->
					{#if boardId}
						<div class="space-y-2">
							<Label for="category">카테고리</Label>
							<Select
								type="single"
								value={categoryId}
								onValueChange={(value: any) => {
									categoryId = value;
								}}
							>
								<SelectTrigger>
									{categoryId ? categories.find(c => c.id === categoryId)?.name : '카테고리를 선택하세요 (선택사항)'}
								</SelectTrigger>
								<SelectContent>
									{#if categoriesLoading}
										<SelectItem value="" disabled>카테고리 로딩 중...</SelectItem>
									{:else if categories.length === 0}
										<SelectItem value="" disabled>사용 가능한 카테고리가 없습니다</SelectItem>
									{:else}
										<SelectItem value="">카테고리 없음</SelectItem>
										{#each categories as category}
											<SelectItem value={category.id}>{category.name}</SelectItem>
										{/each}
									{/if}
								</SelectContent>
							</Select>
						</div>
					{/if}

					<!-- 공지사항 여부 -->
					<div class="flex items-center space-x-2">
						<Checkbox
							id="is-notice"
							bind:checked={isNotice}
						/>
						<Label for="is-notice">공지사항으로 설정</Label>
					</div>

					<!-- 등록일 (작성 모드에서만 표시) -->
					{#if mode === 'create'}
						<div class="space-y-2">
							<Label for="created-at">등록일</Label>
							<Input
								id="created-at"
								type="datetime-local"
								bind:value={createdAt}
							/>
						</div>
					{/if}

					<!-- 내용 -->
					<div class="space-y-2">
						<Label for="content">내용 *</Label>
						<div class="min-h-[300px] w-full">
							<RichTextEditor
								bind:value={content}
								placeholder="내용을 입력하세요..."
								onImageUpload={handleImageUpload}
							/>
						</div>
					</div>

					<!-- 파일 업로드 -->
					<div class="space-y-2">
						<Label>첨부파일</Label>
						<FileUpload
							bind:files={attachedFiles}
							onUpload={handleFileUpload}
							onUploadComplete={handleUploadComplete}
							on:filesChange={handleFilesChange}
							maxFiles={5}
							maxFileSize={20 * 1024 * 1024}
							allowedTypes={['*/*']}
						/>
					</div>

					<!-- 버튼 -->
					<div class="flex justify-end space-x-2">
						<Button type="button" variant="outline" onclick={onCancel}>
							취소
						</Button>
						<Button type="submit" disabled={saving}>
							{saving ? (mode === 'edit' ? '수정 중...' : '작성 중...') : (mode === 'edit' ? '게시글 수정' : '게시글 작성')}
						</Button>
					</div>
				</CardContent>
			</Card>
		</form>
	{/if}
</div>
