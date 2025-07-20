<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';
	import RichTextEditor from '$lib/components/editor/RichTextEditor.svelte';
	import FileUpload from '$lib/components/upload/FileUpload.svelte';
	import { user } from '$lib/stores/auth';
	import { canCreateReplyInBoard } from '$lib/utils/permissions';
	import { createReplyBySlug, uploadFile as uploadFileApi } from '$lib/api/community';
	import { getPostDetail, getBoardBySlug } from '$lib/api/community';
	import type { PostDetail, Board, CreateReplyRequest } from '$lib/types/community';
	import { Editor } from '@tadashi/svelte-editor-quill';
	import Quill from 'quill';
	import { setQuillInstance, getQuillInstance, clearQuillInstance } from '$lib/stores/quill';

	// 라우트 매개변수
	const slug = $page.params.slug;
	const parentId = $page.params.parent_id;

	// 상태 변수
	let parentPost: PostDetail | null = null;
	let board: Board | null = null;
	let loading = true;
	let submitting = false;
	let title = '';
	let content = '';
	let text = '';
	let error = '';
	let uploadedFiles = $state<string[]>([]);
	let attachedFiles = $state<File[]>([]);
	let quillInstance: any = null;
	const quillRef = { set: (q: any) => { 
		console.log('quillRef.set() 호출됨:', q);
		quillInstance = q;
		// Svelte 스토어에도 저장
		setQuillInstance(q);
	} };

	// 권한 체크
	let canCreateReply = $derived(board && $user ? canCreateReplyInBoard(board, $user) : false);

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
		try {
			// 부모 게시글과 게시판 정보 로드
			const [postData, boardData] = await Promise.all([
				getPostDetail(parentId),
				getBoardBySlug(slug)
			]);
			
			parentPost = postData;
			board = boardData;

			// 답글 제목 기본값 설정 (Re: 원제목)
			if (parentPost) {
				const originalTitle = parentPost.title.startsWith('Re: ') 
					? parentPost.title 
					: `Re: ${parentPost.title}`;
				title = originalTitle;
			}

			// 권한 체크 (board가 로드된 후에 수행)
			if (board && $user) {
				const hasPermission = canCreateReplyInBoard(board, $user);
				if (!hasPermission) {
					error = '답글 작성 권한이 없습니다.';
					return;
				}
			}

		} catch (err) {
			console.error('데이터 로드 실패:', err);
			error = '페이지를 불러오는데 실패했습니다.';
		} finally {
			loading = false;
		}
	});

	async function handleSubmit() {
		if (!board || !$user) {
			alert('권한 정보를 확인할 수 없습니다.');
			return;
		}

		const hasPermission = canCreateReplyInBoard(board, $user);
		if (!hasPermission) {
			alert('답글 작성 권한이 없습니다.');
			return;
		}

		if (!title.trim() || !content.trim()) {
			alert('제목과 내용을 모두 입력해주세요.');
			return;
		}

		if (!parentPost) {
			alert('부모 게시글 정보를 찾을 수 없습니다.');
			return;
		}

		submitting = true;
		try {
			// 첨부파일 업로드 처리
			const uploadedFileUrls: string[] = [];
			for (const file of attachedFiles) {
				try {
					const fileUrl = await uploadFileApi(file, 'posts', 'attachment');
					uploadedFileUrls.push(fileUrl);
				} catch (error) {
					console.error('파일 업로드 실패:', error);
					alert(`파일 "${file.name}" 업로드에 실패했습니다.`);
					return;
				}
			}

			const replyData: CreateReplyRequest = {
				parent_id: parentPost.id,
				title: title.trim(),
				content: content.trim(),
				attached_files: uploadedFileUrls
			};

			const reply = await createReplyBySlug(slug, replyData);
			alert('답글이 성공적으로 작성되었습니다.');
			goto(`/community/${slug}/${reply.id}`);
		} catch (err) {
			console.error('답글 작성 실패:', err);
			alert('답글 작성에 실패했습니다.');
		} finally {
			submitting = false;
		}
	}

	function handleCancel() {
		if (parentPost) {
			goto(`/community/${slug}/${parentPost.id}`);
		} else {
			goto(`/community/${slug}`);
		}
	}

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleString('ko-KR');
	}
</script>

<svelte:head>
	<title>답글 작성 - {board?.name || ''}</title>
</svelte:head>

<div class="container mx-auto px-4 py-8">
	{#if loading}
		<div class="flex justify-center items-center py-12">
			<div class="text-lg">로딩 중...</div>
		</div>
	{:else if error}
		<div class="max-w-2xl mx-auto">
			<Card>
				<CardContent class="pt-6">
					<div class="text-center text-red-600">
						<p class="text-lg font-medium mb-4">{error}</p>
						<Button onclick={() => goto(`/community/${slug}`)}>
							게시판으로 돌아가기
						</Button>
					</div>
				</CardContent>
			</Card>
		</div>
	{:else}
		<div class="max-w-4xl mx-auto space-y-6">
			<!-- 헤더 -->
			<div class="flex items-center justify-between">
				<div>
					<h1 class="text-2xl font-bold text-gray-900">답글 작성</h1>
					<p class="text-gray-600 mt-1">{board?.name}</p>
				</div>
			</div>

			<!-- 원글 정보 -->
			{#if parentPost}
				<Card>
					<CardHeader>
						<CardTitle class="text-lg">원글 정보</CardTitle>
					</CardHeader>
					<CardContent>
						<div class="space-y-3">
							<div class="flex items-center gap-2">
								{#if parentPost.is_notice}
									<Badge variant="secondary">공지</Badge>
								{/if}
								<h3 class="font-medium text-gray-900">{parentPost.title}</h3>
							</div>
							<div class="text-sm text-gray-600">
								<span>작성자: {parentPost.user_name}</span>
								<span class="mx-2">•</span>
								<span>작성일: {formatDate(parentPost.created_at)}</span>
								<span class="mx-2">•</span>
								<span>조회: {parentPost.views || 0}</span>
							</div>
							<div class="text-sm text-gray-700 line-clamp-3">
								{parentPost.content?.replace(/<[^>]*>/g, '').substring(0, 200)}...
							</div>
						</div>
					</CardContent>
				</Card>
			{/if}

			<!-- 답글 작성 폼 -->
			<Card>
				<CardHeader>
					<CardTitle>답글 작성</CardTitle>
				</CardHeader>
				<CardContent>
					<form on:submit|preventDefault={handleSubmit} class="space-y-4">
						<!-- 제목 -->
						<div class="space-y-2">
							<Label for="title">제목</Label>
							<Input
								id="title"
								bind:value={title}
								placeholder="답글 제목을 입력하세요"
								required
								disabled={submitting}
							/>
						</div>

						<!-- 내용 (Rich Text Editor) -->
						<div class="space-y-2">
							<Label for="content">내용</Label>
							<div class="border rounded-md">
								<Editor
									quillRef={quillRef}
									options={quillOptions}
									onTextChange={onTextChange}
									content={content}
									disabled={submitting}
								/>
							</div>
						</div>

						<!-- 첨부파일 -->
						{#if board?.allow_file_upload}
							<div class="space-y-2">
								<Label>첨부파일</Label>
								<FileUpload
									bind:attachedFiles
									maxFiles={board.max_files || 5}
									maxFileSize={board.max_file_size || 10485760}
									allowedTypes={board.allowed_file_types || ['*']}
									disabled={submitting}
								/>
							</div>
						{/if}

						<!-- 버튼 -->
						<div class="flex gap-2 justify-end pt-4">
							<Button
								type="button"
								variant="outline"
								onclick={handleCancel}
								disabled={submitting}
							>
								취소
							</Button>
							<Button
								type="submit"
								disabled={submitting || !board || !$user}
							>
								{submitting ? '작성 중...' : '답글 작성'}
							</Button>
						</div>
					</form>
				</CardContent>
			</Card>
		</div>
	{/if}
</div>