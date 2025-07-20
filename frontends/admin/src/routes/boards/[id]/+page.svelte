<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '$lib/components/ui/card';
	import { Tabs, TabsContent, TabsList, TabsTrigger } from '$lib/components/ui/tabs';
	import { Switch } from '$lib/components/ui/switch';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Separator } from '$lib/components/ui/separator';
	import { Badge } from '$lib/components/ui/badge';
	import { adminApi } from '$lib/api/admin';
	import type { Board, Category } from '$lib/types/admin';

	let board: Board | null = null;
	let categories: Category[] = [];
	let loading = true;
	let saving = false;
	let error = '';
	let success = '';

	// 폼 데이터
	let formData: any = {
		name: '',
		slug: '',
		description: '',
		display_order: 0,
		allow_file_upload: true,
		max_files: 5,
		max_file_size: 10485760,
		allowed_file_types: [] as string[],
		allow_rich_text: true,
		require_category: false,
		allow_comments: true,
		allow_likes: true,
		write_permission: 'member',
		list_permission: 'guest',
		read_permission: 'guest',
		reply_permission: 'member',
		comment_permission: 'member',
		download_permission: 'member',
		hide_list: false,
		editor_type: 'rich',
		allow_search: true,
		allow_recommend: true,
		allow_disrecommend: false,
		show_author_name: true,
		show_ip: false,
		edit_comment_limit: 0,
		delete_comment_limit: 0,
		use_sns: false,
		use_captcha: false,
		title_length: 200,
		posts_per_page: 20,
		read_point: 0,
		write_point: 0,
		comment_point: 0,
		download_point: 0,
		is_public: true,
		allow_anonymous: false,
		category: '',
		allowed_iframe_domains: ''
	};

	// UI용 문자열 변수
	let allowedIframeDomainsStr = '';

	// 카테고리 관리
	let newCategory = {
		name: '',
		description: '',
		display_order: 0,
		is_active: true
	};

	// 카테고리 수정 관련
	let editingCategory: Category | null = null;
	let showEditModal = false;
	let editCategoryData = {
		name: '',
		description: '',
		display_order: 0,
		is_active: true
	};

	// 파일 타입 관리
	let newFileType = '';

	// 기본 파일 타입 옵션들
	const defaultFileTypes = [
		{ value: 'image/*', label: '이미지 파일 (모든 형식)' },
		{ value: 'image/jpeg', label: 'JPEG 이미지' },
		{ value: 'image/png', label: 'PNG 이미지' },
		{ value: 'image/gif', label: 'GIF 이미지' },
		{ value: 'image/webp', label: 'WebP 이미지' },
		{ value: 'application/pdf', label: 'PDF 문서' },
		{ value: 'application/msword', label: 'Word 문서 (.doc)' },
		{ value: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', label: 'Word 문서 (.docx)' },
		{ value: 'application/vnd.ms-excel', label: 'Excel 파일 (.xls)' },
		{ value: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', label: 'Excel 파일 (.xlsx)' },
		{ value: 'text/plain', label: '텍스트 파일 (.txt)' },
		{ value: 'text/csv', label: 'CSV 파일' },
		{ value: 'application/zip', label: 'ZIP 압축파일' },
		{ value: 'video/*', label: '비디오 파일 (모든 형식)' },
		{ value: 'audio/*', label: '오디오 파일 (모든 형식)' }
	];

	const permissionOptions = [
		{ value: 'guest', label: '게스트' },
		{ value: 'member', label: '회원' },
		{ value: 'admin', label: '관리자' }
	];

	const editorOptions = [
		{ value: 'rich', label: '리치 텍스트' },
		{ value: 'simple', label: '간단 텍스트' },
		{ value: 'markdown', label: '마크다운' }
	];

	onMount(async () => {
		const boardId = $page.params.id;
		if (boardId === 'create') {
			loading = false;
			return;
		}

		try {
			board = await adminApi.getBoard(boardId);
			loadFormData();
			await loadCategories();
		} catch (err) {
			error = '게시판 정보를 불러오는데 실패했습니다.';
			console.error(err);
		} finally {
			loading = false;
		}
	});

	function loadFormData() {
		if (!board) return;
		
		formData = {
			name: board.name,
			slug: board.slug,
			description: board.description || '',
			display_order: board.display_order,
			allow_file_upload: board.allow_file_upload,
			max_files: board.max_files,
			max_file_size: board.max_file_size,
			allowed_file_types: board.allowed_file_types || [],
			allow_rich_text: board.allow_rich_text,
			require_category: board.require_category,
			allow_comments: board.allow_comments,
			allow_likes: board.allow_likes,
			write_permission: board.write_permission,
			list_permission: board.list_permission,
			read_permission: board.read_permission,
			reply_permission: board.reply_permission,
			comment_permission: board.comment_permission,
			download_permission: board.download_permission,
			hide_list: board.hide_list,
			editor_type: board.editor_type,
			allow_search: board.allow_search,
			allow_recommend: board.allow_recommend,
			allow_disrecommend: board.allow_disrecommend,
			show_author_name: board.show_author_name,
			show_ip: board.show_ip,
			edit_comment_limit: board.edit_comment_limit,
			delete_comment_limit: board.delete_comment_limit,
			use_sns: board.use_sns,
			use_captcha: board.use_captcha,
			title_length: board.title_length,
			posts_per_page: board.posts_per_page,
			read_point: board.read_point,
			write_point: board.write_point,
			comment_point: board.comment_point,
			download_point: board.download_point,
			is_public: board.is_public,
			allow_anonymous: board.allow_anonymous,
			category: board.category || '',
			allowed_iframe_domains: Array.isArray(board.allowed_iframe_domains) 
				? board.allowed_iframe_domains.join(', ') 
				: (board.allowed_iframe_domains || '')
		};
	}

	async function loadCategories() {
		if (!board) return;
		try {
			categories = await adminApi.getBoardCategories(board.id);
		} catch (err) {
			console.error('카테고리 로드 실패:', err);
		}
	}

	async function saveBoard(event?: Event) {
		if (event) {
			event.preventDefault();
		}
		
		saving = true;
		error = '';
		success = '';

		try {
			// allowed_iframe_domains를 배열로 변환 (빈 값이면 undefined)
			const { allowed_file_types, allowed_iframe_domains, ...restFormData } = formData;
			
			
			// allowed_iframe_domains를 문자열에서 배열로 변환
			const allowed_iframe_domains_arr = allowed_iframe_domains && typeof allowed_iframe_domains === 'string'
				? allowed_iframe_domains.split(',').map((domain: string) => domain.trim()).filter((domain: string) => domain.length > 0)
				: [];
			
			
			const dataToSend = {
				...restFormData,
				allowed_iframe_domains: allowed_iframe_domains_arr, // 빈 배열도 전송하여 기존 내용 삭제
				// allowed_file_types: 빈 배열이면 undefined, 아니면 1차원 배열로 평탄화
				...(allowed_file_types && allowed_file_types.length > 0 ? { allowed_file_types: allowed_file_types.flat() } : {})
			};


			if ($page.params.id === 'create') {
				await adminApi.createBoard(dataToSend);
				success = '게시판이 생성되었습니다.';
			} else {
				await adminApi.updateBoard($page.params.id, dataToSend);
				success = '게시판이 수정되었습니다.';
			}
			
			setTimeout(() => {
				goto('/boards');
			}, 1500);
		} catch (err: any) {
			error = err.message || '저장에 실패했습니다.';
		} finally {
			saving = false;
		}
	}

	function addFileType() {
		if (newFileType && !formData.allowed_file_types.includes(newFileType)) {
			formData.allowed_file_types = [...formData.allowed_file_types, newFileType];
			newFileType = '';
		}
	}

	function removeFileType(type: string) {
		formData.allowed_file_types = formData.allowed_file_types.filter(t => t !== type);
	}

	async function addCategory() {
		if (!board || !newCategory.name) return;
		
		try {
			await adminApi.createCategory(board.id, newCategory);
			await loadCategories();
			newCategory = { name: '', description: '', display_order: 0, is_active: true };
		} catch (err: any) {
			error = err.message || '카테고리 추가에 실패했습니다.';
		}
	}

	async function deleteCategory(categoryId: string) {
		if (!board) return;
		
		if (!confirm('카테고리를 삭제하시겠습니까?')) return;
		
		try {
			await adminApi.deleteCategory(board.id, categoryId);
			await loadCategories();
		} catch (err: any) {
			error = err.message || '카테고리 삭제에 실패했습니다.';
		}
	}

	async function updateCategory() {
		if (!board || !editingCategory) return;
		
		try {
			await adminApi.updateCategory(board.id, editingCategory.id, editCategoryData);
			await loadCategories();
			closeEditModal();
		} catch (err: any) {
			error = err.message || '카테고리 수정에 실패했습니다.';
		}
	}

	function closeEditModal() {
		showEditModal = false;
		editingCategory = null;
		editCategoryData = {
			name: '',
			description: '',
			display_order: 0,
			is_active: true
		};
	}

	function formatFileSize(bytes: number): string {
		if (bytes === 0) return '0 Bytes';
		const k = 1024;
		const sizes = ['Bytes', 'KB', 'MB', 'GB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
	}
</script>

<svelte:head>
	<title>{$page.params.id === 'create' ? '게시판 생성' : `게시판 수정 - ${board?.name || '로딩 중...'}`} - 관리자</title>
</svelte:head>

<div class="container mx-auto py-6 space-y-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">
				{$page.params.id === 'create' ? '게시판 생성' : `게시판 수정 - ${board?.name || '로딩 중...'}`}
			</h1>
			<p class="text-muted-foreground">
				게시판의 상세 설정을 관리합니다.
			</p>
		</div>
		<Button variant="outline" onclick={() => goto('/boards')}>
			목록으로
		</Button>
	</div>

	{#if error}
		<div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
			{error}
		</div>
	{/if}

	{#if success}
		<div class="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
			{success}
		</div>
	{/if}

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="text-center">
				<div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto"></div>
				<p class="mt-2 text-muted-foreground">로딩 중...</p>
			</div>
		</div>
	{:else}
		<form onsubmit={saveBoard} class="space-y-6">
			<Tabs value="basic" class="w-full">
				<TabsList class="grid w-full grid-cols-6">
					<TabsTrigger value="basic">기본 정보</TabsTrigger>
					<TabsTrigger value="permissions">권한 설정</TabsTrigger>
					<TabsTrigger value="display">표시 설정</TabsTrigger>
					<TabsTrigger value="files">파일 설정</TabsTrigger>
					<TabsTrigger value="points">포인트 설정</TabsTrigger>
					<TabsTrigger value="categories">카테고리</TabsTrigger>
				</TabsList>

				<!-- 기본 정보 탭 -->
				<TabsContent value="basic" class="space-y-6">
					<Card>
						<CardHeader>
							<CardTitle>기본 정보</CardTitle>
							<CardDescription>게시판의 기본적인 정보를 설정합니다.</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="name">게시판명 *</Label>
									<Input
										id="name"
										bind:value={formData.name}
										placeholder="게시판명을 입력하세요"
										required
									/>
								</div>
								<div class="space-y-2">
									<Label for="slug">슬러그 *</Label>
									<Input
										id="slug"
										bind:value={formData.slug}
										placeholder="board-slug"
										required
									/>
								</div>
							</div>
							<div class="space-y-2">
								<Label for="description">설명</Label>
								<Textarea
									id="description"
									bind:value={formData.description}
									placeholder="게시판에 대한 설명을 입력하세요"
									rows="3"
								/>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="display_order">표시 순서</Label>
									<Input
										id="display_order"
										type="number"
										bind:value={formData.display_order}
										min="0"
									/>
								</div>
								<div class="flex items-center space-x-2">
									<Switch id="require_category" bind:checked={formData.require_category} />
									<Label for="require_category">카테고리 사용</Label>
								</div>
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<!-- 나머지 탭들은 별도 컴포넌트로 분리 -->
				<TabsContent value="permissions" class="space-y-6">
					<Card>
						<CardHeader>
							<CardTitle>권한 설정</CardTitle>
							<CardDescription>각 기능에 대한 접근 권한을 설정합니다.</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div class="grid grid-cols-2 gap-4">
								<div class="flex items-center space-x-2">
									<Switch id="is_public" bind:checked={formData.is_public} />
									<Label for="is_public">공개 게시판</Label>
								</div>
								<div class="flex items-center space-x-2">
									<Switch id="allow_anonymous" bind:checked={formData.allow_anonymous} />
									<Label for="allow_anonymous">익명 작성 허용</Label>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="write_permission">글쓰기 권한</Label>
									<Select type="single" bind:value={formData.write_permission}>
										<SelectTrigger>
											{permissionOptions.find(p => p.value === formData.write_permission)?.label || '권한 선택'}
										</SelectTrigger>
										<SelectContent>
											{#each permissionOptions as option}
												<SelectItem value={option.value}>{option.label}</SelectItem>
											{/each}
										</SelectContent>
									</Select>
								</div>
								<div class="space-y-2">
									<Label for="list_permission">목록보기 권한</Label>
									<Select type="single" bind:value={formData.list_permission}>
										<SelectTrigger>
											{permissionOptions.find(p => p.value === formData.list_permission)?.label || '권한 선택'}
										</SelectTrigger>
										<SelectContent>
											{#each permissionOptions as option}
												<SelectItem value={option.value}>{option.label}</SelectItem>
											{/each}
										</SelectContent>
									</Select>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="read_permission">글읽기 권한</Label>
									<Select type="single" bind:value={formData.read_permission}>
										<SelectTrigger>
											{permissionOptions.find(p => p.value === formData.read_permission)?.label || '권한 선택'}
										</SelectTrigger>
										<SelectContent>
											{#each permissionOptions as option}
												<SelectItem value={option.value}>{option.label}</SelectItem>
											{/each}
										</SelectContent>
									</Select>
								</div>
								<div class="space-y-2">
									<Label for="reply_permission">글답변 권한</Label>
									<Select type="single" bind:value={formData.reply_permission}>
										<SelectTrigger>
											{permissionOptions.find(p => p.value === formData.reply_permission)?.label || '권한 선택'}
										</SelectTrigger>
										<SelectContent>
											{#each permissionOptions as option}
												<SelectItem value={option.value}>{option.label}</SelectItem>
											{/each}
										</SelectContent>
									</Select>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="comment_permission">댓글쓰기 권한</Label>
									<Select type="single" bind:value={formData.comment_permission}>
										<SelectTrigger>
											{permissionOptions.find(p => p.value === formData.comment_permission)?.label || '권한 선택'}
										</SelectTrigger>
										<SelectContent>
											{#each permissionOptions as option}
												<SelectItem value={option.value}>{option.label}</SelectItem>
											{/each}
										</SelectContent>
									</Select>
								</div>
								<div class="space-y-2">
									<Label for="download_permission">다운로드 권한</Label>
									<Select type="single" bind:value={formData.download_permission}>
										<SelectTrigger>
											{permissionOptions.find(p => p.value === formData.download_permission)?.label || '권한 선택'}
										</SelectTrigger>
										<SelectContent>
											{#each permissionOptions as option}
												<SelectItem value={option.value}>{option.label}</SelectItem>
											{/each}
										</SelectContent>
									</Select>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="edit_comment_limit">수정 제한 (댓글 수)</Label>
									<Input
										id="edit_comment_limit"
										type="number"
										bind:value={formData.edit_comment_limit}
										min="0"
										placeholder="0 = 제한 없음"
									/>
								</div>
								<div class="space-y-2">
									<Label for="delete_comment_limit">삭제 제한 (댓글 수)</Label>
									<Input
										id="delete_comment_limit"
										type="number"
										bind:value={formData.delete_comment_limit}
										min="0"
										placeholder="0 = 제한 없음"
									/>
								</div>
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="display" class="space-y-6">
					<Card>
						<CardHeader>
							<CardTitle>표시 설정</CardTitle>
							<CardDescription>게시판과 게시글의 표시 방식을 설정합니다.</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div class="grid grid-cols-2 gap-4">
								<div class="flex items-center space-x-2">
									<Switch id="allow_rich_text" bind:checked={formData.allow_rich_text} />
									<Label for="allow_rich_text">리치 텍스트 허용</Label>
								</div>
								<div class="flex items-center space-x-2">
									<Switch id="allow_search" bind:checked={formData.allow_search} />
									<Label for="allow_search">검색 허용</Label>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="flex items-center space-x-2">
									<Switch id="allow_recommend" bind:checked={formData.allow_recommend} />
									<Label for="allow_recommend">추천 사용</Label>
								</div>
								<div class="flex items-center space-x-2">
									<Switch id="allow_disrecommend" bind:checked={formData.allow_disrecommend} />
									<Label for="allow_disrecommend">비추천 사용</Label>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="flex items-center space-x-2">
									<Switch id="show_author_name" bind:checked={formData.show_author_name} />
									<Label for="show_author_name">작성자 이름 표시</Label>
								</div>
								<div class="flex items-center space-x-2">
									<Switch id="show_ip" bind:checked={formData.show_ip} />
									<Label for="show_ip">IP 주소 표시</Label>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="flex items-center space-x-2">
									<Switch id="use_sns" bind:checked={formData.use_sns} />
									<Label for="use_sns">SNS 공유 사용</Label>
								</div>
								<div class="flex items-center space-x-2">
									<Switch id="use_captcha" bind:checked={formData.use_captcha} />
									<Label for="use_captcha">캡챠 사용</Label>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="title_length">제목 길이 제한</Label>
									<Input
										id="title_length"
										type="number"
										bind:value={formData.title_length}
										min="1"
										max="500"
									/>
								</div>
								<div class="space-y-2">
									<Label for="posts_per_page">페이지당 게시글 수</Label>
									<Input
										id="posts_per_page"
										type="number"
										bind:value={formData.posts_per_page}
										min="1"
										max="100"
									/>
								</div>
							</div>
							<div class="space-y-2">
								<Label for="editor_type">에디터 타입</Label>
								<Select type="single" bind:value={formData.editor_type}>
									<SelectTrigger>
										{editorOptions.find(e => e.value === formData.editor_type)?.label || '에디터 선택'}
									</SelectTrigger>
									<SelectContent>
										{#each editorOptions as option}
											<SelectItem value={option.value}>{option.label}</SelectItem>
										{/each}
									</SelectContent>
								</Select>
							</div>
							<div class="space-y-2">
								<Label for="allowed_iframe_domains">영상 임베드 허용 도메인(쉼표로 구분)</Label>
								<Input
									id="allowed_iframe_domains"
									bind:value={formData.allowed_iframe_domains}
									placeholder="예: youtube.com, vimeo.com"
								/>
								<p class="text-sm text-muted-foreground">
									예시: youtube.com, youtu.be, vimeo.com (쉼표로 구분)
								</p>
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="files" class="space-y-6">
					<Card>
						<CardHeader>
							<CardTitle>파일 업로드 설정</CardTitle>
							<CardDescription>파일 업로드 관련 설정을 관리합니다.</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div class="flex items-center space-x-2">
								<Switch id="allow_file_upload" bind:checked={formData.allow_file_upload} />
								<Label for="allow_file_upload">파일 업로드 허용</Label>
							</div>
							{#if formData.allow_file_upload}
								<div class="grid grid-cols-2 gap-4">
									<div class="space-y-2">
										<Label for="max_files">최대 파일 수</Label>
										<Input
											id="max_files"
											type="number"
											bind:value={formData.max_files}
											min="1"
											max="20"
										/>
									</div>
									<div class="space-y-2">
										<Label for="max_file_size">최대 파일 크기 (바이트)</Label>
										<Input
											id="max_file_size"
											type="number"
											bind:value={formData.max_file_size}
											min="1024"
										/>
										<p class="text-sm text-muted-foreground">
											현재: {formatFileSize(formData.max_file_size)}
										</p>
									</div>
								</div>
								<div class="space-y-2">
									<Label>허용된 파일 타입</Label>
									<div class="space-y-4">
										<!-- 기본 파일 타입 선택 -->
										<div>
											<Label class="text-sm font-medium">기본 파일 타입 선택</Label>
											<div class="flex gap-2 mt-2">
												<Select type="single" bind:value={newFileType}>
													<SelectTrigger class="w-80">
														{newFileType ? defaultFileTypes.find(t => t.value === newFileType)?.label || newFileType : '파일 타입 선택'}
													</SelectTrigger>
													<SelectContent>
														{#each defaultFileTypes as option}
															<SelectItem value={option.value}>{option.label}</SelectItem>
														{/each}
													</SelectContent>
												</Select>
												<Button type="button" variant="outline" onclick={addFileType}>
													추가
												</Button>
											</div>
										</div>
										
										<!-- 수동 입력 -->
										<div>
											<Label class="text-sm font-medium">수동 입력</Label>
											<div class="flex gap-2 mt-2">
												<Input
													bind:value={newFileType}
													placeholder="예: image/*, application/pdf"
													onkeydown={(e) => e.key === 'Enter' && (e.preventDefault(), addFileType())}
												/>
												<Button type="button" variant="outline" onclick={addFileType}>
													추가
												</Button>
											</div>
										</div>
									</div>
									<div class="flex flex-wrap gap-2 mt-2">
										{#each formData.allowed_file_types as type}
											<Badge variant="secondary" class="cursor-pointer" onclick={() => removeFileType(type)}>
												{type} ×
											</Badge>
										{/each}
									</div>
								</div>
							{/if}
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="points" class="space-y-6">
					<Card>
						<CardHeader>
							<CardTitle>포인트 설정</CardTitle>
							<CardDescription>각 기능 사용 시 차감될 포인트를 설정합니다.</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="read_point">글읽기 차감 포인트</Label>
									<Input
										id="read_point"
										type="number"
										bind:value={formData.read_point}
										min="0"
									/>
								</div>
								<div class="space-y-2">
									<Label for="write_point">글쓰기 차감 포인트</Label>
									<Input
										id="write_point"
										type="number"
										bind:value={formData.write_point}
										min="0"
									/>
								</div>
							</div>
							<div class="grid grid-cols-2 gap-4">
								<div class="space-y-2">
									<Label for="comment_point">댓글쓰기 차감 포인트</Label>
									<Input
										id="comment_point"
										type="number"
										bind:value={formData.comment_point}
										min="0"
									/>
								</div>
								<div class="space-y-2">
									<Label for="download_point">다운로드 차감 포인트</Label>
									<Input
										id="download_point"
										type="number"
										bind:value={formData.download_point}
										min="0"
									/>
								</div>
							</div>
						</CardContent>
					</Card>
				</TabsContent>

				<TabsContent value="categories" class="space-y-6">
					<Card>
						<CardHeader>
							<CardTitle>카테고리 관리</CardTitle>
							<CardDescription>게시판 내 카테고리를 관리합니다.</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							{#if board}
								<div class="space-y-4">
									<div class="grid grid-cols-4 gap-2">
										<Input
											bind:value={newCategory.name}
											placeholder="카테고리명"
										/>
										<Input
											bind:value={newCategory.description}
											placeholder="설명"
										/>
										<Input
											type="number"
											bind:value={newCategory.display_order}
											placeholder="순서"
										/>
										<Button type="button" onclick={addCategory}>
											카테고리 추가
										</Button>
									</div>
									
									<Separator />
									
									<div class="space-y-2">
										{#each categories as category}
											<div class="flex items-center justify-between p-3 border rounded-lg">
												<div>
													<h4 class="font-medium">{category.name}</h4>
													{#if category.description}
														<p class="text-sm text-muted-foreground">{category.description}</p>
													{/if}
												</div>
												<div class="flex items-center gap-2">
													<Badge variant={category.is_active ? 'default' : 'secondary'}>
														{category.is_active ? '활성' : '비활성'}
													</Badge>
													<Badge variant="outline">순서: {category.display_order}</Badge>
													<Button
														type="button"
														variant="outline"
														size="sm"
														onclick={() => {
															editingCategory = category;
															editCategoryData = { ...category };
															showEditModal = true;
														}}
													>
														수정
													</Button>
													<Button
														type="button"
														variant="destructive"
														size="sm"
														onclick={() => deleteCategory(category.id)}
													>
														삭제
													</Button>
												</div>
											</div>
										{/each}
									</div>
								</div>
							{:else}
								<p class="text-muted-foreground">게시판을 먼저 저장한 후 카테고리를 관리할 수 있습니다.</p>
							{/if}
						</CardContent>
					</Card>
				</TabsContent>
			</Tabs>

			<div class="flex justify-end gap-2">
				<Button type="button" variant="outline" onclick={() => goto('/boards')}>
					취소
				</Button>
				<Button type="submit" disabled={saving}>
					{saving ? '저장 중...' : ($page.params.id === 'create' ? '생성' : '수정')}
				</Button>
			</div>
		</form>
	{/if}

	<!-- 카테고리 수정 모달 -->
	{#if showEditModal && editingCategory}
		<div class="fixed inset-0 z-50 flex items-center justify-center">
			<div class="fixed inset-0 bg-black bg-opacity-30 backdrop-blur-sm" onclick={closeEditModal}></div>
			<div class="relative mx-4 w-full max-w-md overflow-y-auto rounded-lg bg-white shadow-xl">
				<div class="flex items-center justify-between border-b px-6 py-4">
					<h3 class="text-lg font-semibold">카테고리 수정</h3>
					<Button variant="ghost" size="sm" onclick={closeEditModal}>×</Button>
				</div>
				<div class="space-y-4 px-6 py-4">
					<div class="space-y-2">
						<Label for="edit-category-name">카테고리명 *</Label>
						<Input
							id="edit-category-name"
							bind:value={editCategoryData.name}
							placeholder="카테고리명을 입력하세요"
							required
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-category-description">설명</Label>
						<Input
							id="edit-category-description"
							bind:value={editCategoryData.description}
							placeholder="카테고리 설명을 입력하세요"
						/>
					</div>
					<div class="space-y-2">
						<Label for="edit-category-order">표시 순서</Label>
						<Input
							id="edit-category-order"
							type="number"
							bind:value={editCategoryData.display_order}
							min="0"
						/>
					</div>
					<div class="flex items-center space-x-2">
						<Switch id="edit-category-active" bind:checked={editCategoryData.is_active} />
						<Label for="edit-category-active">활성 상태</Label>
					</div>
				</div>
				<div class="flex justify-end gap-2 border-t px-6 py-4">
					<Button variant="outline" onclick={closeEditModal}>
						취소
					</Button>
					<Button onclick={updateCategory}>
						수정
					</Button>
				</div>
			</div>
		</div>
	{/if}
</div> 