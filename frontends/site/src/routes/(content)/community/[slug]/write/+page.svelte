<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount, onDestroy } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import RichTextEditor from '$lib/components/editor/RichTextEditor.svelte';
	import FileUpload from '$lib/components/upload/FileUpload.svelte';
	import {
		createPost,
		createPostBySlug,
		uploadFile,
		categories,
		boards,
		loadCategories,
		loadBoards,
		isLoading,
		error
	} from '$lib/stores/community';
	import { uploadFile as uploadFileApi } from '$lib/api/community';
	import { isAuthenticated } from '$lib/stores/auth';
	import type { Board, Category } from '$lib/types/community.ts';
	import { get } from 'svelte/store';
	import { Editor } from '@tadashi/svelte-editor-quill';
	import Quill from 'quill';
	import { setQuillInstance, getQuillInstance, clearQuillInstance } from '$lib/stores/quill';

	const { data } = $props();
	
	// 수정 모드 여부 확인
	const isEditMode = $derived(data.isEditMode || false);
	const postData = $derived(data.postData || null);
	
	let title = $state(isEditMode && postData ? postData.title : '');
	let content = $state(isEditMode && postData ? postData.content : '');
	let text = $state('');
	let selectedCategory = $state(isEditMode && postData ? postData.category_id || '' : '');
	let selectedSlug = $state(data.slug);
	let uploadedFiles = $state<string[]>(isEditMode && postData ? postData.attached_files || [] : []);
	let attachedFiles = $state<File[]>([]);
	let isNotice = $state(isEditMode && postData ? postData.is_notice || false : false);
	let categoriesLoading = $state(false);
	let quillInstance: any = null;
	const quillRef = { set: (q: any) => { 
		console.log('quillRef.set() 호출됨:', q);
		quillInstance = q;
		// Svelte 스토어에도 저장
		setQuillInstance(q);
	} };

	// 반응형 변수로 boardSettings 설정
	const boardsList = $derived($boards);
	const categoriesList = $derived($categories);
	const boardSettings = $derived(boardsList.find((b: Board) => b.slug === selectedSlug) || null);
	const boardName = $derived(boardSettings?.name || '게시판');
	
	// Quill 에디터 옵션
	const quillOptions = {
		theme: 'snow',
		plainclipboard: true,
		formats: ['header', 'bold', 'italic', 'underline', 'strike', 'color', 'background', 'list', 'align', 'link', 'image', 'video'],
		modules: {
			toolbar: {
				container: [
					[{ 'header': [1, 2, 3, false] }],
					['bold', 'italic', 'underline', 'strike'],
					[{ 'color': [] }, { 'background': [] }],
					[{ 'list': 'ordered'}, { 'list': 'bullet' }],
					[{ 'align': [] }],
					['link', 'image', 'video'],
					['clean']
				],
				handlers: {
					image: function(this: any) {
						console.log('Quill 옵션에서 이미지 핸들러 호출됨');
						
						// Svelte 스토어에서 Quill 인스턴스 찾기
						const quill = this.quill || getQuillInstance();
						if (!quill) {
							console.error('Quill 인스턴스를 찾을 수 없음');
							return;
						}
						
						const input = document.createElement('input');
						input.setAttribute('type', 'file');
						input.setAttribute('accept', 'image/*');
						input.style.display = 'none';
						document.body.appendChild(input);
						
						input.onchange = async (event) => {
							const target = event.target as HTMLInputElement;
							const file = target.files?.[0];
							
							if (file) {
								console.log('파일 선택됨:', file.name, file.size);
								
								try {
									console.log('이미지 업로드 시작:', file.name, file.size);
									
									// API 함수 사용하여 업로드 (에디터 이미지용)
									const imageUrl = await uploadFileApi(file, 'posts', 'editorimage');
									console.log('업로드 성공:', imageUrl);
									
									const range = quill.getSelection();
									if (range) {
										quill.insertEmbed(range.index, 'image', imageUrl);
										console.log('이미지 삽입됨:', imageUrl);
									} else {
										quill.insertEmbed(quill.getLength(), 'image', imageUrl);
										console.log('이미지 끝에 삽입됨:', imageUrl);
									}
								} catch (error) {
									console.error('이미지 업로드 오류:', error);
									alert('이미지 업로드에 실패했습니다.');
								} finally {
									// input 요소 정리
									document.body.removeChild(input);
								}
							}
						};
						
						input.click();
					}
				}
			}
		},
		placeholder: '내용을 입력하세요'
	};
	
	// Quill 에디터 콜백
	const onTextChange = (markup: string, plaintext: string) => {
		content = markup
		text = plaintext
	}

	// 컴포넌트 언마운트 시 정리
	onDestroy(() => {
		// Quill 인스턴스 스토어 정리
		clearQuillInstance();
	});

	

	onMount(async () => {
		// 인증 확인
		const authenticated = get(isAuthenticated);
		if (!authenticated) {
			alert('로그인이 필요합니다.');
			goto('/auth/login');
			return;
		}

		// 게시판 목록 새로 로드
		await loadBoards();
		
		// 카테고리 정보 강제 새로 로드
		categoriesLoading = true;
		try {
			await loadCategories(selectedSlug);
		} catch (error) {
			console.error('카테고리 로딩 실패:', error);
		} finally {
			categoriesLoading = false;
		}

		
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();

		// 인증 재확인
		const authenticated = get(isAuthenticated);
		if (!authenticated) {
			alert('로그인이 필요합니다.');
			goto('/auth/login');
			return;
		}

		if (!selectedSlug) {
			alert('게시판을 선택해주세요.');
			return;
		}

		

		try {
			let post;
			
			if (isEditMode && postData) {
				// 수정 모드
				post = await updatePost(postData.id, {
					category_id: selectedCategory || undefined,
					title,
					content,
					attached_files: uploadedFiles,
					is_notice: isNotice
				});
			} else {
				// 새 글쓰기 모드
				post = await createPostBySlug(selectedSlug, {
					category_id: selectedCategory || undefined,
					title,
					content,
					attached_files: uploadedFiles,
					is_notice: isNotice
				});
			}

			if (post) {
				goto(`/community/${post.board_slug}/${post.id}`);
			}
		} catch (err) {
			console.error('글쓰기 실패:', err);
			if (err instanceof Error && err.message.includes('401')) {
				alert('로그인이 만료되었습니다. 다시 로그인해주세요.');
				goto('/auth/login');
			} else {
				alert('글쓰기에 실패했습니다. 다시 시도해주세요.');
			}
		}
	}

	async function handleBoardChange(value: string) {
		selectedSlug = value;
		selectedCategory = '';
		
		// 카테고리 정보 강제 새로 로드
		categoriesLoading = true;
		try {
			await loadCategories(value);
		} catch (error) {
			console.error('카테고리 로딩 실패:', error);
		} finally {
			categoriesLoading = false;
		}
	}

	function getBoardLabel(boardId: string) {
		if (!boardId) return '게시판을 선택하세요';
		const board = $boards.find((b: any) => b.slug === boardId);
		return board ? board.name : '게시판을 선택하세요';
	}

	function getCategoryLabel(categoryId: string) {
		if (!categoryId) return '카테고리를 선택하세요 (선택사항)';
		const category = $categories.find((c: any) => c.id === categoryId);
		return category ? category.name : '카테고리를 선택하세요 (선택사항)';
	}

	// 실제 파일 업로드 핸들러
	async function handleFileUpload(file: File): Promise<string> {
		try {
			const url = await uploadFile(file, 'posts');
			console.log('파일 업로드 성공:', url);
			return url;
		} catch (error) {
			console.error('파일 업로드 실패:', error);
			throw error;
		}
	}

	function handleFilesChange(event: CustomEvent) {
		attachedFiles = event.detail.files;
	}

	function handleUploadComplete(event: CustomEvent) {
		const { url } = event.detail;
		uploadedFiles = [...uploadedFiles, url];
		console.log('업로드된 파일 URL:', url);
		console.log('전체 업로드된 파일들:', uploadedFiles);
	}
</script>

<svelte:head>
	<link
		rel="stylesheet"
		href="https://unpkg.com/quill@2.0.3/dist/quill.snow.css"
		crossorigin="anonymous"
	/>
</svelte:head>

	<div class="py-8">
	<div class="mx-auto max-w-4xl">
		<h1 class="mb-8 text-3xl font-bold">{boardName} {isEditMode ? '수정' : '글쓰기'}</h1>

		<form onsubmit={handleSubmit} class="space-y-6">
			<div>
				<label for="title" class="mb-1 block text-sm font-medium text-gray-700">제목</label>
				<Input id="title" bind:value={title} required placeholder="제목을 입력하세요" />
			</div>

			<!-- <div>
				<label class="mb-1 block text-sm font-medium text-gray-700">게시판</label>
				<div class="rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-900">
					{boardName}
				</div>
			</div> -->

			{#if selectedSlug}
				<div>
					<label for="category" class="mb-1 block text-sm font-medium text-gray-700">
						카테고리
					</label>
					{#if categoriesLoading}
						<div class="rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-500">
							카테고리 로딩 중...
						</div>
					{:else if $categories.length > 0}
						<Select
							type="single"
							value={selectedCategory}
							onValueChange={(value: string) => (selectedCategory = value)}
						>
							<SelectTrigger>
								{getCategoryLabel(selectedCategory)}
							</SelectTrigger>
							<SelectContent>
								<SelectItem value="">카테고리 없음</SelectItem>
								{#each categoriesList as category}
									<SelectItem value={category.id}>{category.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					{:else}
						<div class="rounded-md border border-gray-300 bg-gray-50 px-3 py-2 text-sm text-gray-500">
							사용 가능한 카테고리가 없습니다
						</div>
					{/if}
				</div>
			{/if}

			<div>
				<label for="content" class="mb-1 block text-sm font-medium text-gray-700">내용</label>
				{#if boardSettings?.allow_rich_text}
					<!-- Rich Text Editor -->
					<div class="min-h-[300px] w-full">
						<Editor
							quillRef={quillRef}
							options={quillOptions}
							{onTextChange}
							class="w-full "
						>{@html $state.snapshot(content)}</Editor>
					</div>
				{:else}
					<!-- Plain Text Editor -->
					<textarea
						id="content"
						bind:value={content}
						required
						placeholder="내용을 입력하세요"
						class="min-h-[300px] w-full rounded-md border border-gray-300 p-3 focus:border-transparent focus:ring-2 focus:ring-blue-500"
					></textarea>
				{/if}
			</div>

			{#if boardSettings?.allow_notice}
				<div class="flex items-center space-x-2">
					<input
						type="checkbox"
						id="isNotice"
						bind:checked={isNotice}
						class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
					/>
					<label for="isNotice" class="text-sm font-medium text-gray-700">
						공지로 등록
					</label>
				</div>
			{/if}

			{#if boardSettings?.allow_file_upload}
				<div>
					<div class="mb-1 block text-sm font-medium text-gray-700">첨부파일</div>
					<FileUpload
						bind:files={attachedFiles}
						maxFiles={boardSettings?.max_files || 5}
						maxFileSize={boardSettings?.max_file_size || 10 * 1024 * 1024}
						allowedTypes={boardSettings?.allowed_file_types || null}
						onUpload={handleFileUpload}
						onUploadComplete={handleUploadComplete}
					/>
				</div>
			{/if}

			{#if $error}
				<div class="text-sm text-red-500">{$error}</div>
			{/if}

			<div class="flex justify-end gap-4">
				<Button type="button" variant="outline" onclick={() => goto('/community')}>취소</Button>
				<Button type="submit" disabled={$isLoading}>
					{$isLoading ? (isEditMode ? '수정 중...' : '작성 중...') : (isEditMode ? '수정하기' : '작성하기')}
				</Button>
			</div>
		</form>
	</div>
</div>

<style>
	/* Quill 에디터 내부 편집 영역 최소 높이 설정 */
	:global(.ql-editor) {
		min-height: 250px !important;
	}
	
	/* Quill 에디터 컨테이너 높이 자동 조절 */
	:global(.ql-container) {
		height: auto !important;
	}

	/* Quill 에디터 포커스 개선 */
	:global(.ql-editor:focus) {
		outline: none !important;
		border-color: transparent !important;
	}

	/* 툴바 버튼 클릭 시 포커스 유지 */
	:global(.ql-toolbar button:focus) {
		outline: none !important;
	}

	/* 색상 선택기 개선 */
	:global(.ql-color .ql-picker-options),
	:global(.ql-background .ql-picker-options) {
		z-index: 1000 !important;
	}

	/* 에디터 선택 영역 개선 */
	:global(.ql-editor ::selection) {
		background: rgba(0, 123, 255, 0.3) !important;
	}

	/* 링크 스타일 개선 */
	:global(.ql-editor a) {
		color: #007bff !important;
		text-decoration: underline !important;
	}

	/* 에디터 내부 포커스 시 테두리 제거 */
	:global(.ql-container.ql-snow) {
		border: 1px solid #ccc !important;
	}

	:global(.ql-container.ql-snow:focus-within) {
		border-color: #007bff !important;
		box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25) !important;
	}
</style>
