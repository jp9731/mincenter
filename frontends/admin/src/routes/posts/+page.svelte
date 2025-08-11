<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
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
	import { Badge } from '$lib/components/ui/badge';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { loadPosts, posts, postsPagination, hidePost } from '$lib/stores/admin';
	import type { Post } from '$lib/types/admin';

	let searchQuery = '';
	let boardFilter = '';
	let statusFilter = '';
	let currentPage = 1;

	// 관리 메뉴 관련 상태
	let showManagementMenu = $state<Record<string, boolean>>({});
	let showMoveModal = $state(false);
	let showHideModal = $state(false);
	let selectedPostId = $state<string | null>(null);
	let boardsWithCategories = $state<any[]>([]);
	let selectedBoardId = $state<number | null>(null);
	let selectedCategoryId = $state<number | null>(null);
	let moveReason = $state('');
	let hideCategory = $state('');
	let hideReason = $state('');
	let hideTags = $state('');
	let isMoving = $state(false);
	let isHiding = $state(false);
	let isLoading = $state(false);

	// API URL 가져오기
	const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:18080';

	// 완전한 파일 URL 생성 (site와 동일한 방식)
	function getFullFileUrl(fileUrl: string): string {
		if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
			return fileUrl;
		}
		return `${API_BASE}${fileUrl.startsWith('/') ? '' : '/'}${fileUrl}`;
	}

	// 첫 번째 이미지 URL 추출 함수
	function getFirstImageUrl(post: Post): string | null {
		// 썸네일 URL이 있으면 우선 사용
		if (post.thumbnail_urls) {
			if (post.thumbnail_urls.card) {
				return getFullFileUrl(post.thumbnail_urls.card);
			} else if (post.thumbnail_urls.thumb) {
				return getFullFileUrl(post.thumbnail_urls.thumb);
			} else if (post.thumbnail_urls.large) {
				return getFullFileUrl(post.thumbnail_urls.large);
			}
		}
		
		// 썸네일이 없으면 첨부파일에서 이미지 찾기
		if (post.attached_files && post.attached_files.length > 0) {
			for (const file of post.attached_files) {
				if (file.mime_type && file.mime_type.startsWith('image/')) {
					return getFullFileUrl(file.file_path);
				}
			}
		}
		
		return null;
	}

	// 관리 메뉴 토글
	function toggleManagementMenu(postId: string) {
		showManagementMenu[postId] = !showManagementMenu[postId];
		showManagementMenu = { ...showManagementMenu };
	}

	// 게시판과 카테고리 목록 로드
	async function loadBoardsWithCategories() {
		try {
			const res = await fetch(`${API_BASE}/api/community/boards-with-categories`, {
				headers: {
					'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
				}
			});
			const result = await res.json();
			if (result.success) {
				boardsWithCategories = result.data;
			}
		} catch (error) {
			console.error('게시판과 카테고리 로드 실패:', error);
		}
	}

	// 게시글 이동 처리
	async function handleMovePost() {
		if (!selectedPostId || !selectedBoardId) return;

		isMoving = true;
		try {
			const res = await fetch(`${API_BASE}/api/admin/posts/move`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
				},
				body: JSON.stringify({
					post_id: selectedPostId,
					moved_board_id: selectedBoardId,
					moved_category_id: selectedCategoryId,
					move_reason: moveReason || undefined
				})
			});

			if (res.ok) {
				showMoveModal = false;
				alert('게시글이 성공적으로 이동되었습니다.');
				loadPosts({ page: currentPage, limit: 20, search: searchQuery, board_id: boardFilter, status: statusFilter });
			} else {
				throw new Error('게시글 이동에 실패했습니다.');
			}
		} catch (error) {
			console.error('게시글 이동 실패:', error);
			alert('게시글 이동에 실패했습니다.');
		} finally {
			isMoving = false;
		}
	}

	// 게시글 숨김 처리
	async function handleHidePost(postId: string) {
		if (confirm('정말로 이 게시글을 숨기시겠습니까?')) {
			try {
				const res = await fetch(`${API_BASE}/api/admin/posts/hide`, {
					method: 'POST',
					headers: {
						'Content-Type': 'application/json',
						'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
					},
					body: JSON.stringify({
						post_id: postId,
						hide_category: 'quick_hide',
						hide_reason: '관리자에 의한 빠른 숨김'
					})
				});

				if (res.ok) {
					alert('게시글이 성공적으로 숨겨졌습니다.');
					// 현재 페이지의 게시글 목록만 새로고침
					loadPosts({ page: currentPage, limit: 20, search: searchQuery, board_id: boardFilter, status: statusFilter });
				} else {
					throw new Error('게시글 숨김에 실패했습니다.');
				}
			} catch (error) {
				console.error('게시글 숨김 실패:', error);
				alert('게시글 숨김에 실패했습니다.');
			}
		}
	}

	// 게시글 숨김 처리 (모달)
	async function handleHidePostModal() {
		if (!selectedPostId || !hideCategory) return;

		isHiding = true;
		try {
			const tags = hideTags ? hideTags.split(',').map(tag => tag.trim()).filter(tag => tag) : undefined;
			
			const res = await fetch(`${API_BASE}/api/admin/posts/hide`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json',
					'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
				},
				body: JSON.stringify({
					post_id: selectedPostId,
					hide_category: hideCategory,
					hide_reason: hideReason || undefined,
					hide_tags: tags
				})
			});

			if (res.ok) {
				showHideModal = false;
				alert('게시글이 성공적으로 숨겨졌습니다.');
				loadPosts({ page: currentPage, limit: 20, search: searchQuery, board_id: boardFilter, status: statusFilter });
			} else {
				throw new Error('게시글 숨김에 실패했습니다.');
			}
		} catch (error) {
			console.error('게시글 숨김 실패:', error);
			alert('게시글 숨김에 실패했습니다.');
		} finally {
			isHiding = false;
		}
	}

	// 게시글 숨김 해제 처리
	async function handleUnhidePost(postId: string) {
		if (confirm('정말로 이 게시글을 공개하시겠습니까?')) {
			try {
				const res = await fetch(`${API_BASE}/api/admin/posts/unhide`, {
					method: 'POST',
					headers: {
						'Content-Type': 'application/json',
						'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
					},
					body: JSON.stringify({
						post_id: postId
					})
				});

				if (res.ok) {
					alert('게시글이 성공적으로 공개되었습니다.');
					loadPosts({ page: currentPage, limit: 20, search: searchQuery, board_id: boardFilter, status: statusFilter });
				} else {
					throw new Error('게시글 공개에 실패했습니다.');
				}
			} catch (error) {
				console.error('게시글 공개 실패:', error);
				alert('게시글 공개에 실패했습니다.');
			}
		}
	}

	// 게시글 삭제 처리
	async function handleDeletePost(postId: string) {
		if (confirm('정말로 이 게시글을 삭제하시겠습니까?\n\n⚠️ 이 작업은 되돌릴 수 없습니다!')) {
			try {
				const res = await fetch(`${API_BASE}/api/admin/posts/${postId}/delete`, {
					method: 'DELETE',
					headers: {
						'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
					}
				});

				if (res.ok) {
					alert('게시글이 성공적으로 삭제되었습니다.');
					loadPosts({ page: currentPage, limit: 20, search: searchQuery, board_id: boardFilter, status: statusFilter });
				} else {
					throw new Error('게시글 삭제에 실패했습니다.');
				}
			} catch (error) {
				console.error('게시글 삭제 실패:', error);
				alert('게시글 삭제에 실패했습니다.');
			}
		}
	}

	// 이동 모달 열기
	function openMoveModal(postId: string) {
		selectedPostId = postId;
		showMoveModal = true;
		showManagementMenu[postId] = false;
		showManagementMenu = { ...showManagementMenu };
	}

	// 숨김 모달 열기
	function openHideModal(postId: string) {
		selectedPostId = postId;
		showHideModal = true;
		showManagementMenu[postId] = false;
		showManagementMenu = { ...showManagementMenu };
	}

	// 모달 상태 초기화
	function resetModalStates() {
		showMoveModal = false;
		showHideModal = false;
		selectedPostId = null;
		selectedBoardId = null;
		selectedCategoryId = null;
		moveReason = '';
		hideCategory = '';
		hideReason = '';
		hideTags = '';
	}

	// 모달 외부 클릭 시 닫기
	function handleModalBackdropClick(event: MouseEvent) {
		if (event.target === event.currentTarget) {
			resetModalStates();
		}
	}

	// ESC 키로 모달 닫기
	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Escape') {
			resetModalStates();
		}
	}

	onMount(() => {
		loadPosts({ page: 1, limit: 20 });
		loadBoardsWithCategories();
	});

	function handleSearch() {
		currentPage = 1;
		loadPosts({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			board_id: boardFilter,
			status: statusFilter
		});
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadPosts({
			page: currentPage,
			limit: 20,
			search: searchQuery,
			board_id: boardFilter,
			status: statusFilter
		});
	}

	function getStatusBadge(status: string) {
		switch (status) {
			case 'published':
				return { variant: 'default', text: '공개' };
			case 'hidden':
				return { variant: 'destructive', text: '숨김' };
			case 'draft':
				return { variant: 'secondary', text: '임시저장' };
			default:
				return { variant: 'outline', text: status };
		}
	}

	function truncateText(text: string, maxLength: number = 100) {
		if (text.length <= maxLength) return text;
		return text.substring(0, maxLength) + '...';
	}

</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">게시글 관리</h1>
			<p class="mt-2 text-gray-600">시스템의 모든 게시글을 관리합니다.</p>
		</div>
		<Button onclick={() => goto('/posts/create')}>새 게시글 작성</Button>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardHeader>
			<CardTitle>검색 및 필터</CardTitle>
			<CardDescription>게시글을 검색하고 필터링합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="grid grid-cols-1 gap-4 md:grid-cols-4">
				<Input
					type="text"
					placeholder="제목, 내용, 작성자로 검색"
					bind:value={searchQuery}
					onkeydown={(e: any) => e.key === 'Enter' && handleSearch()}
				/>
				<Select
					type="single"
					value={boardFilter}
					onValueChange={(value: any) => {
						boardFilter = value;
						handleSearch();
					}}
				>
					<SelectTrigger>
						{boardFilter || '게시판 선택'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체</SelectItem>
						<SelectItem value="notice">공지사항</SelectItem>
						<SelectItem value="free">자유게시판</SelectItem>
						<SelectItem value="volunteer">봉사활동</SelectItem>
					</SelectContent>
				</Select>
				<Select
					type="single"
					value={statusFilter}
					onValueChange={(value: any) => {
						statusFilter = value;
						handleSearch();
					}}
				>
					<SelectTrigger>
						{statusFilter || '상태 선택'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체</SelectItem>
						<SelectItem value="published">공개</SelectItem>
						<SelectItem value="hidden">숨김</SelectItem>
						<SelectItem value="draft">임시저장</SelectItem>
					</SelectContent>
				</Select>
				<Button onclick={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 게시글 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>게시글 목록</CardTitle>
			<CardDescription>총 {$postsPagination?.total ?? 0}개의 게시글이 있습니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>썸네일</TableHead>
						<TableHead>제목</TableHead>
						<TableHead>작성자</TableHead>
						<TableHead>게시판</TableHead>
						<TableHead>상태</TableHead>
						<TableHead>작성일</TableHead>
						<TableHead>조회수</TableHead>
						<TableHead>댓글</TableHead>
						<TableHead>액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#if isLoading}
						<TableRow>
							<TableCell colspan="9" class="text-center py-8">
								게시글 목록을 불러오는 중입니다...
							</TableCell>
						</TableRow>
					{:else if $posts.length === 0}
						<TableRow>
							<TableCell colspan="9" class="text-center py-8">
								검색 결과나 필터링 결과에 해당하는 게시글이 없습니다.
							</TableCell>
						</TableRow>
					{/if}
					{#each $posts as post}
						<TableRow>
							<TableCell>
								<div class="w-16 h-12 flex items-center justify-center">
									{#if getFirstImageUrl(post)}
										<img 
											src={getFirstImageUrl(post)} 
											alt="썸네일" 
											class="w-full h-full object-cover rounded"
										/>
									{:else}
										<img 
											src="/images/min_logo.png" 
											alt="기본 이미지" 
											class="w-full h-full object-contain opacity-40"
										/>
									{/if}
								</div>
							</TableCell>
							<TableCell>
								<div class="max-w-xs">
									<p class="truncate font-medium text-gray-900">
										{#if post.is_notice}<Badge variant="secondary" class="mr-2">공지</Badge>{/if}
										{post.title}
									</p>
									<p class="truncate text-sm text-gray-500">
										{truncateText(post.content)}
									</p>
								</div>
							</TableCell>
							<TableCell>
								<div class="flex items-center space-x-2">
									<div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-300">
										<span class="text-xs font-medium text-gray-700">
											{post.user_name?.[0] || 'U'}
										</span>
									</div>
									<span class="text-sm">{post.user_name}</span>
								</div>
							</TableCell>
							<TableCell>
								<Badge variant="outline">{post.board_name}</Badge>
							</TableCell>
							<TableCell>
								{@const statusBadge = getStatusBadge(post.status)}
								<Badge variant={statusBadge.variant as any}>{statusBadge.text}</Badge>
							</TableCell>
							<TableCell>
								{new Date(post.created_at).toLocaleDateString('ko-KR')}
							</TableCell>
							<TableCell>{post.views.toLocaleString()}</TableCell>
							<TableCell>{post.comment_count}</TableCell>
							<TableCell>
								<div class="flex space-x-2">
									{#if post.status === 'published'}
										<Button variant="outline" size="sm" onclick={() => handleHidePost(post.id)}>
											숨기기
										</Button>
									{:else if post.status === 'hidden'}
										<Button variant="outline" size="sm" onclick={() => handleUnhidePost(post.id)}>
											공개
										</Button>
									{/if}
									<Button variant="outline" size="sm" onclick={() => goto(`/posts/${post.id}`)}>
										상세보기
									</Button>
									<Button variant="outline" size="sm" onclick={() => goto(`/posts/${post.id}/edit`)}>
										수정
									</Button>
									<Button variant="outline" size="sm" onclick={() => handleDeletePost(post.id)}>
										삭제
									</Button>
									<div class="relative">
										<Button variant="outline" size="sm" onclick={() => toggleManagementMenu(post.id)}>
											관리
										</Button>
										{#if showManagementMenu[post.id]}
											<div class="absolute right-0 top-full mt-1 w-48 bg-white border border-gray-200 rounded-md shadow-lg z-10">
												<div class="py-1">
													<button
														class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
														onclick={() => openMoveModal(post.id)}
													>
														게시글 이동
													</button>
													<button
														class="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
														onclick={() => openHideModal(post.id)}
													>
														게시글 숨김
													</button>
													<button
														class="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50"
														onclick={() => {
															if (confirm('정말로 이 게시글을 삭제하시겠습니까?')) {
																handleDeletePost(post.id);
															}
														}}
													>
														게시글 삭제
													</button>
												</div>
											</div>
										{/if}
									</div>
								</div>
							</TableCell>
						</TableRow>
					{/each}
				</TableBody>
			</Table>

			<!-- 페이지네이션 -->
			{#if $postsPagination?.totalPages > 1}
				<div class="mt-6 flex justify-center">
					<div class="flex space-x-2">
						{#if currentPage > 1}
							<Button variant="outline" size="sm" onclick={() => handlePageChange(currentPage - 1)}>
								이전
							</Button>
						{/if}

						{#each Array.from({ length: $postsPagination?.totalPages ?? 0 }, (_, i) => i + 1) as pageNum}
							<Button
								variant={currentPage === pageNum ? 'default' : 'outline'}
								size="sm"
								onclick={() => handlePageChange(pageNum)}
							>
								{pageNum}
							</Button>
						{/each}

						{#if currentPage < ($postsPagination?.totalPages ?? 0)}
							<Button variant="outline" size="sm" onclick={() => handlePageChange(currentPage + 1)}>
								다음
							</Button>
						{/if}
					</div>
				</div>
			{/if}
		</CardContent>
	</Card>

	<!-- 게시글 이동 모달 -->
	{#if showMoveModal}
		<div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onclick={handleModalBackdropClick}>
			<div class="bg-white rounded-lg p-6 w-full max-w-md" onkeydown={handleKeydown}>
				<h3 class="text-lg font-semibold mb-4">게시글 이동</h3>
				<div class="space-y-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">이동할 게시판</label>
						<Select
							type="single"
							value={selectedBoardId?.toString() || ''}
							onValueChange={(value: any) => {
								if (value) {
									const boardId = parseInt(value);
									selectedBoardId = isNaN(boardId) ? null : boardId;
								} else {
									selectedBoardId = null;
								}
								selectedCategoryId = null;
							}}
						>
							<SelectTrigger>
								{selectedBoardId ? boardsWithCategories.find(b => b.id === selectedBoardId)?.name || '게시판 선택' : '게시판 선택'}
							</SelectTrigger>
							<SelectContent>
								{#each boardsWithCategories as board}
									<SelectItem value={board.id.toString()}>{board.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>
					
					{#if selectedBoardId && boardsWithCategories.find(b => b.id === selectedBoardId)?.categories?.length > 0}
						<div>
							<label class="block text-sm font-medium text-gray-700 mb-2">이동할 카테고리 (선택사항)</label>
							<Select
								type="single"
								value={selectedCategoryId?.toString() || ''}
								onValueChange={(value: any) => {
									if (value) {
										const categoryId = parseInt(value);
										selectedCategoryId = isNaN(categoryId) ? null : categoryId;
									} else {
										selectedCategoryId = null;
									}
								}}
							>
								<SelectTrigger>
									{selectedCategoryId ? boardsWithCategories.find(b => b.id === selectedBoardId)?.categories?.find((c: any) => c.id === selectedCategoryId)?.name || '카테고리 선택' : '카테고리 선택'}
								</SelectTrigger>
								<SelectContent>
									<SelectItem value="">카테고리 없음</SelectItem>
									{#each boardsWithCategories.find(b => b.id === selectedBoardId)?.categories || [] as category}
										<SelectItem value={category.id.toString()}>{category.name}</SelectItem>
									{/each}
								</SelectContent>
							</Select>
						</div>
					{/if}
					
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">이동 사유 (선택사항)</label>
						<Input
							type="text"
							placeholder="이동 사유를 입력하세요"
							bind:value={moveReason}
						/>
					</div>
				</div>
				
				<div class="flex justify-end space-x-3 mt-6">
					<Button variant="outline" onclick={resetModalStates}>취소</Button>
					<Button onclick={handleMovePost} disabled={isMoving || !selectedBoardId}>
						{isMoving ? '이동 중...' : '이동'}
					</Button>
				</div>
			</div>
		</div>
	{/if}

	<!-- 게시글 숨김 모달 -->
	{#if showHideModal}
		<div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onclick={handleModalBackdropClick}>
			<div class="bg-white rounded-lg p-6 w-full max-w-md" onkeydown={handleKeydown}>
				<h3 class="text-lg font-semibold mb-4">게시글 숨김</h3>
				<div class="space-y-4">
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">숨김 카테고리 *</label>
						<Select
							type="single"
							value={hideCategory}
							onValueChange={(value: any) => {
								hideCategory = value;
							}}
						>
							<SelectTrigger>
								{hideCategory || '숨김 카테고리 선택'}
							</SelectTrigger>
							<SelectContent>
								<SelectItem value="inappropriate">부적절한 내용</SelectItem>
								<SelectItem value="spam">스팸/광고</SelectItem>
								<SelectItem value="duplicate">중복 게시글</SelectItem>
								<SelectItem value="violation">이용약관 위반</SelectItem>
								<SelectItem value="other">기타</SelectItem>
							</SelectContent>
						</Select>
					</div>
					
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">숨김 사유 (선택사항)</label>
						<Input
							type="text"
							placeholder="숨김 사유를 입력하세요"
							bind:value={hideReason}
						/>
					</div>
					
					<div>
						<label class="block text-sm font-medium text-gray-700 mb-2">태그 (선택사항)</label>
						<Input
							type="text"
							placeholder="쉼표로 구분하여 입력 (예: 부적절, 광고)"
							bind:value={hideTags}
						/>
						<p class="text-xs text-gray-500 mt-1">쉼표로 구분하여 여러 태그를 입력할 수 있습니다.</p>
					</div>
				</div>
				
				<div class="flex justify-end space-x-3 mt-6">
					<Button variant="outline" onclick={resetModalStates}>취소</Button>
					<Button onclick={handleHidePostModal} disabled={isHiding || !hideCategory}>
						{isHiding ? '숨김 중...' : '숨기기'}
					</Button>
				</div>
			</div>
		</div>
	{/if}
</div>
