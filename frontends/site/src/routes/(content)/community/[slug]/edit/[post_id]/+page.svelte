<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount, onDestroy } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import RichTextEditor from '$lib/components/editor/RichTextEditor.svelte';
	import FileUpload from '$lib/components/upload/FileUpload.svelte';
	import {
		currentPost,
		fetchPost,
		updatePost,
		uploadFile,
		categories,
		boards,
		loadCategories,
		loadBoards,
		isLoading,
		error
	} from '$lib/stores/community';
	import { uploadFile as uploadFileApi } from '$lib/api/community';
	import { deletePostAttachment } from '$lib/api/community';
	import { user } from '$lib/stores/auth';
	import type { Board, Category } from '$lib/types/community.ts';
	import { get } from 'svelte/store';
	import { Editor } from '@tadashi/svelte-editor-quill';
	import Quill from 'quill';
	import { setQuillInstance, getQuillInstance, clearQuillInstance } from '$lib/stores/quill';

	const { data } = $props();
	
	let title = $state('');
	let content = $state('');
	let text = $state('');
	let selectedCategory = $state('');
	let selectedSlug = $state(data.slug);
	let uploadedFiles = $state<string[]>([]);
	let attachedFiles = $state<File[]>([]);
	let isNotice = $state(false);
	let categoriesLoading = $state(false);
	let quillInstance: any = null;
	const quillRef = { set: (q: any) => { 
		console.log('quillRef.set() 호출됨:', q);
		quillInstance = q;
		setQuillInstance(q);
		
		// Quill 인스턴스가 설정된 후 초기 내용 설정
		if (q && content) {
			setTimeout(() => {
				q.root.innerHTML = content;
				console.log('Quill 에디터에 초기 내용 설정됨 (quillRef):', content);
			}, 50);
		}
	} };

	// 반응형 변수로 boardSettings 설정
	const boardsList = $derived($boards);
	const categoriesList = $derived($categories);
	const boardSettings = $derived(boardsList.find((b: Board) => b.slug === selectedSlug) || null);
	const boardName = $derived(boardSettings?.name || '게시판');
	
	// content가 변경될 때 Quill 에디터에 반영
	$effect(() => {
		if (quillInstance && content && !quillInstance.root.innerHTML) {
			quillInstance.root.innerHTML = content;
			console.log('Quill 에디터에 content 변경 반영됨:', content);
		}
	});
	
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
		clearQuillInstance();
	});

	onMount(async () => {
		// 인증 확인
		const currentUser = get(user);
		if (!currentUser) {
			alert('로그인이 필요합니다.');
			goto('/auth/login');
			return;
		}

		try {
			// 게시글 정보 로드
			await fetchPost(data.postId);
			const post = get(currentPost);
			
			if (!post) {
				alert('게시글을 찾을 수 없습니다.');
				goto('/community');
				return;
			}

			// 권한 확인 (작성자만 수정 가능)
			const currentUser = get(user);
			
			// 문자열로 변환하여 비교 (타입 불일치 문제 해결)
			const canEdit = String(post.user_id) === String(currentUser?.id);
			
			if (!canEdit) {
				alert('수정 권한이 없습니다.');
				goto(`/community/${data.slug}/${data.postId}`);
				return;
			}

			// 기존 데이터로 폼 초기화
			title = post.title;
			content = post.content;
			selectedCategory = post.category_id || '';
			
			// 첨부파일 처리
			console.log('원본 post.attached_files:', post.attached_files);
			uploadedFiles = getAttachedFiles(post);
			console.log('처리된 uploadedFiles:', uploadedFiles);
			
			isNotice = post.is_notice || false;

			// 게시판 목록 로드
			await loadBoards();
			
			// 카테고리 정보 로드
			categoriesLoading = true;
			try {
				await loadCategories(selectedSlug);
			} catch (error) {
				console.error('카테고리 로딩 실패:', error);
			} finally {
				categoriesLoading = false;
			}

			// Quill 에디터에 초기 내용 설정 (약간의 지연 후)
			setTimeout(() => {
				if (quillInstance && content) {
					quillInstance.root.innerHTML = content;
					console.log('Quill 에디터에 초기 내용 설정됨:', content);
				}
			}, 100);

		} catch (err) {
			console.error('게시글 로드 실패:', err);
			alert('게시글을 불러오는데 실패했습니다.');
			goto('/community');
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();

		// 인증 재확인
		const currentUser = get(user);
		if (!currentUser) {
			alert('로그인이 필요합니다.');
			goto('/auth/login');
			return;
		}

		try {
			const post = await updatePost(data.postId, {
				category_id: selectedCategory || undefined,
				title,
				content,
				attached_files: uploadedFiles,
				is_notice: isNotice
			});

			if (post) {
				goto(`/community/${post.board_slug}/${post.id}`);
			}
		} catch (err) {
			console.error('글 수정 실패:', err);
			if (err instanceof Error && err.message.includes('401')) {
				alert('로그인이 만료되었습니다. 다시 로그인해주세요.');
				goto('/auth/login');
			} else {
				alert('글 수정에 실패했습니다. 다시 시도해주세요.');
			}
		}
	}

	async function handleBoardChange(value: string) {
		selectedSlug = value;
		selectedCategory = '';
		
		categoriesLoading = true;
		try {
			await loadCategories(value);
		} catch (error) {
			console.error('카테고리 로딩 실패:', error);
		} finally {
			categoriesLoading = false;
		}
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

	// 첨부파일 처리 함수 추가
	function getAttachedFiles(post: any): string[] {
		if (!post.attached_files || post.attached_files.length === 0) {
			return [];
		}
		
		// attached_files가 문자열 배열인 경우
		if (Array.isArray(post.attached_files) && typeof post.attached_files[0] === 'string') {
			return post.attached_files;
		}
		
		// attached_files가 객체 배열인 경우
		if (Array.isArray(post.attached_files) && typeof post.attached_files[0] === 'object') {
			return post.attached_files.map((file: any) => file.file_path || file.url || file);
		}
		
		return [];
	}

	// 첨부파일 이름 추출
	function getFileName(fileUrl: string): string {
		const parts = fileUrl.split('/');
		return parts[parts.length - 1] || '파일';
	}

	// 첨부파일 삭제 함수
	async function removeFile(index: number) {
		const fileUrl = uploadedFiles[index];
		
		try {
			// 파일 URL에서 파일 ID 추출 시도
			// URL 패턴: /uploads/posts/images/filename 또는 /uploads/posts/documents/filename
			const urlParts = fileUrl.split('/');
			const filename = urlParts[urlParts.length - 1];
			
			// 파일명에서 UUID 부분 추출 (UUID_timestamp_originalname.ext 형태)
			const filenameParts = filename.split('_');
			if (filenameParts.length >= 2) {
				const uuidPart = filenameParts[0];
				
				// UUID 형식인지 확인
				if (uuidPart.length === 36) {
					// 게시글 첨부파일 삭제 API 호출
					await deletePostAttachment(data.postId, uuidPart);
					console.log('첨부파일 삭제 성공:', fileUrl);
				} else {
					console.warn('파일 ID를 추출할 수 없습니다:', fileUrl);
				}
			} else {
				console.warn('파일명 형식이 올바르지 않습니다:', filename);
			}
			
			// 프론트엔드에서도 제거
			uploadedFiles = uploadedFiles.filter((_, i) => i !== index);
		} catch (error) {
			console.error('첨부파일 삭제 실패:', error);
			alert('첨부파일 삭제에 실패했습니다.');
		}
	}

	const API_URL = import.meta.env.VITE_API_URL;
	function getFileUrl(file_path: string) {
		if (!file_path) return '';
		return file_path.startsWith('http') ? file_path : API_URL + file_path;
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
		<div class="mb-4">
			<div class="flex items-center justify-between">
				<div>
					<a href="/community/{data.slug}/{data.postId}" class="text-blue-600 hover:underline">
						← 게시글로 돌아가기
					</a>
				</div>
				<h1 class="text-2xl font-bold">{boardName} 수정</h1>
			</div>
		</div>

		<form onsubmit={handleSubmit} class="space-y-6">
			<div>
				<label for="title" class="mb-1 block text-sm font-medium text-gray-700">제목</label>
				<Input id="title" bind:value={title} required placeholder="제목을 입력하세요" />
			</div>

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

			{#if uploadedFiles && uploadedFiles.length > 0}
				<div class="mt-6 space-y-4">
					<div class="mb-2 text-sm font-medium text-gray-700">기존 첨부파일</div>
					<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
						{#each uploadedFiles as file, index}
							<div class="border rounded-lg p-3 bg-gray-50">
								{#if file.match(/\.(jpe?g|png|gif|webp)$/i)}
									<!-- 이미지 파일 -->
									<div class="relative">
										<img src={getFileUrl(file)} alt="첨부 이미지" class="w-full h-32 object-cover rounded" />
										<button
											type="button"
											onclick={() => removeFile(index)}
											class="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600"
										>
											×
										</button>
									</div>
									<div class="mt-2 text-sm text-gray-600 truncate">{getFileName(file)}</div>
								{:else if file.match(/\.pdf$/i)}
									<!-- PDF 파일 -->
									<div class="relative">
										<div class="w-full h-32 bg-red-100 flex items-center justify-center rounded">
											<span class="text-red-600 text-2xl">📄</span>
										</div>
										<button
											type="button"
											onclick={() => removeFile(index)}
											class="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600"
										>
											×
										</button>
									</div>
									<div class="mt-2 text-sm text-gray-600 truncate">{getFileName(file)}</div>
									<a href={getFileUrl(file)} target="_blank" class="text-blue-600 text-xs hover:underline">미리보기</a>
								{:else}
									<!-- 기타 파일 -->
									<div class="relative">
										<div class="w-full h-32 bg-gray-100 flex items-center justify-center rounded">
											<span class="text-gray-600 text-2xl">📎</span>
										</div>
										<button
											type="button"
											onclick={() => removeFile(index)}
											class="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600"
										>
											×
										</button>
									</div>
									<div class="mt-2 text-sm text-gray-600 truncate">{getFileName(file)}</div>
									<a href={getFileUrl(file)} download class="text-blue-600 text-xs hover:underline">다운로드</a>
								{/if}
							</div>
						{/each}
					</div>
				</div>
			{/if}

			{#if $error}
				<div class="text-sm text-red-500">{$error}</div>
			{/if}

			<div class="flex justify-end gap-4">
				<Button type="button" variant="outline" onclick={() => goto(`/community/${data.slug}/${data.postId}`)}>취소</Button>
				<Button type="submit" disabled={$isLoading}>
					{$isLoading ? '수정 중...' : '수정하기'}
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