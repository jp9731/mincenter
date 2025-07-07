<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Badge } from '$lib/components/ui/badge';
	import { List, Grid3x3 } from 'lucide-svelte';
	import { API_URL } from '$lib/config';
	import {
		Card,
		CardContent,
		CardDescription,
		CardFooter,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import {
		posts,
		categories,
		boards,
		tags,
		postFilter,
		isLoading,
		error,
		pagination,
		fetchPosts,
		fetchBoards,
		fetchCategories,
		fetchTags
	} from '$lib/stores/community';
	import { user, isAuthenticated } from '$lib/stores/auth';
	import { 
		canCreatePost, 
		canListBoard, 
		canWritePost, 
		shouldShowSearch, 
		shouldShowAuthorName,
		shouldShowRecommend,
		shouldShowDisrecommend
	} from '$lib/utils/permissions';
	import type { Post, PostFilter, Board } from '$lib/types/community';

	// 상태 변수들
	let innerWidth = $state(typeof window !== 'undefined' ? window.innerWidth : 1024);
	let isMobile = $derived(innerWidth < 768);
	let searchQuery = $state('');
	let selectedBoard = $state('');
	let selectedTags = $state<string[]>([]);
	let viewMode = $state<'list' | 'card'>(isMobile ? 'card' : 'list');
	$effect(() => {
		if (isMobile) viewMode = 'card';
	});

	// 파생 상태들
	let currentBoard = $derived(
		selectedBoard ? $boards.find((b: Board) => b.id === selectedBoard) : null
	);
	
	let canWriteInCurrentBoard = $derived(
		currentBoard ? canWritePost(currentBoard) : canCreatePost()
	);
	
	let canListCurrentBoard = $derived(
		currentBoard ? canListBoard(currentBoard) : true
	);
	
	let showSearch = $derived(
		currentBoard ? shouldShowSearch(currentBoard) : true
	);
	
	let showAuthorName = $derived(
		currentBoard ? shouldShowAuthorName(currentBoard) : true
	);
	
	let showRecommend = $derived(
		currentBoard ? shouldShowRecommend(currentBoard) : true
	);
	
	let showDisrecommend = $derived(
		currentBoard ? shouldShowDisrecommend(currentBoard) : false
	);

	let fontSizeClass = $derived(fontSizeClasses[fontSizeIndex]);
	let fontSizeMetaClass = $derived(fontSizeClasses[Math.max(fontSizeIndex-1,0)]);
	let fontSizeBadgeClass = $derived(fontSizeClasses[Math.max(fontSizeIndex-3,0)]);
	let leadingClass = $derived(leadingClasses[fontSizeIndex]);
	let leadingMetaClass = $derived(leadingClasses[Math.max(fontSizeIndex-1,0)]);
	let leadingBadgeClass = $derived(leadingClasses[Math.max(fontSizeIndex-3,0)]);

	// 신규글과 핫한글 판단 함수
	function isNewPost(post: Post): boolean {
		const now = new Date();
		const postDate = new Date(post.created_at);
		const diffInHours = (now.getTime() - postDate.getTime()) / (1000 * 60 * 60);
		return diffInHours < 24; // 24시간 이내
	}

	function isHotPost(post: Post): boolean {
		return (post.views || 0) >= 100 || (post.likes || 0) >= 10 || (post.comment_count || 0) >= 5;
	}

	// 첫 번째 이미지 URL 추출 함수 (썸네일 우선 사용)
	function getFirstImageUrl(post: Post, context: string = 'card'): string | null {
		// 썸네일 URL이 있으면 우선 사용
		if (post.thumbnail_urls) {
			let thumbnailUrl: string | undefined;
			
			// 컨텍스트에 따른 썸네일 선택
			switch (context) {
				case 'list':
					thumbnailUrl = post.thumbnail_urls.thumb;
					break;
				case 'card':
					thumbnailUrl = post.thumbnail_urls.card;
					break;
				case 'detail':
					thumbnailUrl = post.thumbnail_urls.large;
					break;
			}
			
			if (thumbnailUrl) {
				return getFullFileUrl(thumbnailUrl);
			}
			
			// 요청한 크기가 없으면 다른 크기 사용 (fallback)
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
			for (const fileUrl of post.attached_files) {
				if (isImageFile(fileUrl)) {
					return getFullFileUrl(fileUrl);
				}
			}
		}
		
		// 콘텐츠에서 img 태그 찾기 (HTML 콘텐츠가 있는 경우)
		if (post.content) {
			const imgMatch = post.content.match(/<img[^>]+src="([^"]+)"/);
			if (imgMatch && imgMatch[1]) {
				return getFullFileUrl(imgMatch[1]);
			}
		}
		
		return null;
	}

	// 이미지 파일 여부 확인
	function isImageFile(fileUrl: string): boolean {
		const extension = fileUrl.split('.').pop()?.toLowerCase();
		return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].includes(extension || '');
	}

	// 완전한 파일 URL 생성
	function getFullFileUrl(fileUrl: string): string {
		if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
			return fileUrl;
		}
		return `${API_URL}${fileUrl.startsWith('/') ? '' : '/'}${fileUrl}`;
	}

	// 텍스트에서 HTML 태그 제거
	function stripHtml(html: string | null | undefined): string {
		if (!html) return '';
		return html.replace(/<[^>]*>/g, '').trim();
	}

	function increaseFontSize() {
		if (fontSizeIndex < maxFontSizeIndex) fontSizeIndex += 1;
	}
	function decreaseFontSize() {
		if (fontSizeIndex > minFontSizeIndex) fontSizeIndex -= 1;
	}

	// 페이지네이션 관련 함수들
	function goToPage(page: number) {
		currentPage = page;
		postFilter.update((filter: PostFilter) => ({
			...filter,
			page: page
		}));
		fetchPosts($postFilter);
	}

	function goToNextPage() {
		if (currentPage < getTotalPages()) {
			goToPage(currentPage + 1);
		}
	}

	function goToPrevPage() {
		if (currentPage > 1) {
			goToPage(currentPage - 1);
		}
	}

	function getTotalPages(): number {
		// 실제 pagination 정보 사용
		if ($pagination) {
			return $pagination.total_pages;
		}
		// fallback: 현재 게시글 수로 계산 (임시)
		return Math.ceil($posts.length / 10);
	}

	function getCurrentPage(): number {
		// 실제 pagination 정보 사용
		if ($pagination) {
			return $pagination.page;
		}
		// fallback: 로컬 상태 사용
		return currentPage;
	}

	function getPageNumbers(): number[] {
		const totalPages = getTotalPages();
		const pages: number[] = [];
		const maxVisiblePages = 5;
		
		if (totalPages <= maxVisiblePages) {
			// 총 페이지가 5개 이하면 모든 페이지 표시
			for (let i = 1; i <= totalPages; i++) {
				pages.push(i);
			}
		} else {
			// 현재 페이지를 중심으로 5개 페이지 표시
			let start = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
			let end = Math.min(totalPages, start + maxVisiblePages - 1);
			
			// 끝에 가까우면 시작점 조정
			if (end === totalPages) {
				start = Math.max(1, end - maxVisiblePages + 1);
			}
			
			for (let i = start; i <= end; i++) {
				pages.push(i);
			}
		}
		
		return pages;
	}

	// 부수효과들
	$effect(() => {
		// 초기 데이터 로드
		loadInitialData();
	});

	async function loadInitialData() {
		await Promise.all([
			fetchPosts({
				search: '',
				board_id: '',
				tags: [],
				sort: 'latest',
				page: 1,
				limit: 10
			}),
			fetchBoards(),
			fetchTags()
		]);
	}

	function handleSearch() {
		currentPage = 1; // 페이지 리셋
		postFilter.update((filter: PostFilter) => ({
			...filter,
			search: searchQuery,
			board_id: selectedBoard,
			tags: selectedTags,
			page: 1
		}));
		fetchPosts($postFilter);
	}

	function handleSortChange(value: string) {
		currentPage = 1; // 페이지 리셋
		postFilter.update((filter: PostFilter) => ({
			...filter,
			sort: value as 'latest' | 'popular' | 'comments',
			page: 1
		}));
		fetchPosts($postFilter);
	}

	function handleBoardChange(value: string) {
		selectedBoard = value;
		handleSearch();
	}

	function handleTagClick(tagId: string) {
		if (selectedTags.includes(tagId)) {
			selectedTags = selectedTags.filter((id) => id !== tagId);
		} else {
			selectedTags = [...selectedTags, tagId];
		}
		handleSearch();
	}

	function getSortLabel(sort: string) {
		switch (sort) {
			case 'latest':
				return '최신순';
			case 'popular':
				return '인기순';
			case 'comments':
				return '댓글순';
			default:
				return '정렬 기준';
		}
	}

	function getBoardLabel(boardId: string) {
		if (!boardId) return '전체 게시판';
		const board = $boards.find((b) => b.id === boardId);
		return board ? board.name : '게시판 선택';
	}
</script>
<svelte:window bind:innerWidth />

<div class="py-8">
	<div class="mb-8 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">커뮤니티</h1>
			<p class="mt-2 text-gray-600">게시글 {$posts.length}개</p>
		</div>
		<div class="flex items-center gap-4">
			<!-- 뷰 모드 토글 -->
			<div class="flex items-center gap-1 rounded-lg border border-gray-200 p-1" class:hidden={isMobile}>
				<Button
					variant={viewMode === 'list' ? 'default' : 'ghost'}
					size="sm"
					onclick={() => viewMode = 'list'}
					class="h-8 w-8 p-0"
				>
					<List class="h-4 w-4" />
				</Button>
				<Button
					variant={viewMode === 'card' ? 'default' : 'ghost'}
					size="sm"
					onclick={() => viewMode = 'card'}
					class="h-8 w-8 p-0"
				>
					<Grid3x3 class="h-4 w-4" />
				</Button>
			</div>
			<!-- 글씨 크기 조절 버튼 -->
			<div class="flex items-center gap-1 rounded-lg border border-gray-200 p-1">
				<Button size="sm" variant="ghost" class="h-8 w-8 p-0" onclick={decreaseFontSize} disabled={fontSizeIndex <= minFontSizeIndex} aria-label="글씨 작게">-</Button>
				<Button size="sm" variant="ghost" class="h-8 w-8 p-0" onclick={increaseFontSize} disabled={fontSizeIndex >= maxFontSizeIndex} aria-label="글씨 크게">+</Button>
			</div>
			{#if $isAuthenticated && canWriteInCurrentBoard}
				<Button asChild>
					<a href="/community/general/write">글쓰기</a>
				</Button>
			{:else if !$isAuthenticated}
				<Button variant="outline" asChild>
					<a href="/auth/login">로그인하여 글쓰기</a>
				</Button>
			{/if}
		</div>
	</div>

	<!-- 검색 및 필터 -->
	{#if showSearch}
		<div class="mb-8 space-y-4">
			<div class="flex gap-4">
				<Input
					type="text"
					placeholder="검색어를 입력하세요"
					bind:value={searchQuery}
					onkeydown={(e) => e.key === 'Enter' && handleSearch()}
					class="flex-1"
				/>
				<Button onclick={handleSearch}>검색</Button>
			</div>

			<div class="flex items-center gap-4">
				<Select type="single" value={$postFilter.sort} onValueChange={handleSortChange}>
					<SelectTrigger class="w-[180px]">
						{getSortLabel($postFilter.sort)}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="latest">최신순</SelectItem>
						<SelectItem value="popular">인기순</SelectItem>
						<SelectItem value="comments">댓글순</SelectItem>
					</SelectContent>
				</Select>

				<Select type="single" value={selectedBoard} onValueChange={handleBoardChange}>
					<SelectTrigger class="w-[180px]">
						{getBoardLabel(selectedBoard)}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="">전체 게시판</SelectItem>
						{#each $boards as board}
							{#if canListBoard(board)}
								<SelectItem value={board.id}>{board.name}</SelectItem>
							{/if}
						{/each}
					</SelectContent>
				</Select>
			</div>

			<div class="flex flex-wrap gap-2">
				{#each $tags as tag}
					<Badge
						variant={selectedTags.includes(tag.id) ? 'default' : 'outline'}
						class="cursor-pointer"
						onclick={() => handleTagClick(tag.id)}
					>
						{tag.name} ({tag.postCount})
					</Badge>
				{/each}
			</div>
		</div>
	{/if}

	<!-- 게시글 목록 -->
	{#if $isLoading}
		<div class="py-8 text-center">로딩 중...</div>
	{:else if $error}
		<div class="py-8 text-center text-red-500">{$error}</div>
	{:else if $posts.length === 0}
		<div class="py-8 text-center">게시글이 없습니다.</div>
	{:else if viewMode === 'list' && !isMobile}
		<!-- 목록 형태 -->
		<div>
			{#each $posts as post, index}
				{@const thumbnailUrl = getFirstImageUrl(post, viewMode === 'list' ? 'list' : 'card')}
				<div class="flex items-center gap-4 p-4 hover:bg-gray-50 transition-colors {index < $posts.length - 1 ? 'border-b border-gray-200' : ''}">
					<!-- 썸네일 이미지 -->
					{#if thumbnailUrl}
						<div class="flex-shrink-0">
							<a href="/community/{post.board_slug}/{post.id}">
								<img
									src={thumbnailUrl}
									alt={post.title}
									class="h-16 w-16 object-cover"
								/>
							</a>
						</div>
					{/if}
					<!-- 제목 및 메타 정보 -->
					<div class="flex-1 min-w-0">
						<div class="flex items-center gap-2 mb-1">
							{#if post.is_notice}
								<Badge variant="secondary" class={`${fontSizeBadgeClass} ${leadingBadgeClass}`}>공지</Badge>
							{/if}
							<a href="/community/{post.board_slug}/{post.id}" class={`text-gray-900 hover:text-blue-600 transition-colors font-medium truncate ${fontSizeClass} ${leadingClass}`}>
								{post.category_name ? `[${post.category_name}] ` : ''}{post.title}
							</a>
							<!-- 신규글 배지 -->
							{#if isNewPost(post)}
								<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-blue-600 border-blue-600`}>신규</Badge>
							{/if}
							<!-- 핫한글 배지 -->
							{#if isHotPost(post)}
								<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-orange-600 border-orange-600`}>핫</Badge>
							{/if}
						</div>
						<div class={`flex items-center gap-4 text-gray-500 ${fontSizeMetaClass} ${leadingMetaClass}`}>
							<span>
								{#if showAuthorName}
									{post.user_name || '익명'}
								{:else}
									익명
								{/if}
							</span>
							<span>•</span>
							<span>{new Date(post.created_at).toLocaleDateString()}</span>
							<span>•</span>
							<span>조회 {post.views || 0}</span>
							{#if showRecommend}
								<span>•</span>
								<span>좋아요 {post.likes || 0}</span>
							{/if}
							<span>•</span>
							<span>댓글 {post.comment_count || 0}</span>
							<span>•</span>
							<a href="/community/{post.board_slug}" class="text-blue-600 hover:underline">
								{post.board_name}
							</a>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<!-- 카드 형태 (메이슨리 레이아웃) -->
		<div class="masonry-container">
			{#each $posts as post}
				{@const thumbnailUrl = getFirstImageUrl(post, viewMode === 'list' ? 'list' : 'card')}
				<Card class="masonry-item hover:shadow-lg transition-all duration-200 hover:-translate-y-1 overflow-hidden mt-4 {thumbnailUrl ? 'pt-0' : ''}">
					<!-- 카드 헤더 이미지 -->
					{#if thumbnailUrl}
						<div class="overflow-hidden">
							<a href="/community/{post.board_slug}/{post.id}">
								<img
									src={thumbnailUrl}
									alt={post.title}
									class="w-full h-auto object-contain"
								/>
							</a>
						</div>
					{/if}
					<CardHeader class={thumbnailUrl ? "pb-3 pt-0 px-6" : "pb-3"}>
						<div class="flex items-start justify-between">
							<div class="flex items-center gap-2 flex-1 min-w-0">
								<CardTitle class={`leading-tight line-clamp-2 ${fontSizeClass} ${leadingClass}`}>
									<a href="/community/{post.board_slug}/{post.id}" class="hover:text-blue-600 transition-colors">
										{post.category_name ? `[${post.category_name}] ` : ''}{post.title}
									</a>
								</CardTitle>
								<!-- 신규글 배지 -->
								{#if isNewPost(post)}
									<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-blue-600 border-blue-600 flex-shrink-0`}>신규</Badge>
								{/if}
								<!-- 핫한글 배지 -->
								{#if isHotPost(post)}
									<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-orange-600 border-orange-600 flex-shrink-0`}>핫</Badge>
								{/if}
							</div>
							{#if post.is_notice}
								<Badge variant="secondary" class={`${fontSizeBadgeClass} ${leadingBadgeClass}`}>공지</Badge>
							{/if}
						</div>
						<div class={`flex items-center gap-4 text-gray-500 ${fontSizeMetaClass} ${leadingMetaClass}`}> 
							<span>{new Date(post.created_at).toLocaleDateString()}</span>
							<span>•</span>
							<a href="/community/{post.board_slug}" class="text-blue-600 hover:underline">
								{post.board_name}
							</a>
						</div>
					</CardHeader>
					<CardContent class={thumbnailUrl ? "pt-0 pb-4 px-6" : "pt-0 pb-4"}>
						<p class={`text-gray-600 line-clamp-3 mb-4 ${fontSizeMetaClass} ${leadingMetaClass}`}> {stripHtml(post.content)} </p>
						<!-- 통계 정보 -->
						<div class={`flex items-center justify-between text-xs text-gray-500 ${fontSizeMetaClass} ${leadingMetaClass}`}> 
							<div class="flex items-center gap-3">
								<span>조회 {post.views || 0}</span>
								{#if showRecommend}
									<span>좋아요 {post.likes || 0}</span>
								{/if}
								<span>댓글 {post.comment_count || 0}</span>
							</div>
						</div>
					</CardContent>
					<CardFooter class={thumbnailUrl ? "pt-0 px-6" : "pt-0"}>
						<div class={`flex items-center justify-between w-full text-sm ${fontSizeMetaClass} ${leadingMetaClass}`}> 
							<div class="flex items-center gap-2">
								<div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-300">
									<span class="text-xs text-gray-600">{post.user_name?.[0] || 'U'}</span>
								</div>
								{#if showAuthorName}
									<span class="text-gray-500">{post.user_name || '익명'}</span>
								{:else}
									<span class="text-gray-500">익명</span>
								{/if}
							</div>
							<span class="text-gray-400 text-xs">
								{new Date(post.created_at).toLocaleDateString()}
							</span>
						</div>
					</CardFooter>
				</Card>
			{/each}
		</div>
	{/if}

	<!-- 페이지네이션 -->
	{#if $posts.length > 0 && getTotalPages() > 1}
		<div class="mt-8 flex items-center justify-center">
			<nav class="flex items-center gap-2">
				<!-- 이전 페이지 버튼 -->
				<Button
					variant="outline"
					size="sm"
					onclick={goToPrevPage}
					disabled={currentPage <= 1}
					class="px-3 py-2"
				>
					이전
				</Button>

				<!-- 페이지 번호들 -->
				{#each getPageNumbers() as pageNum}
					<Button
						variant={pageNum === currentPage ? 'default' : 'outline'}
						size="sm"
						onclick={() => goToPage(pageNum)}
						class="px-3 py-2"
					>
						{pageNum}
					</Button>
				{/each}

				<!-- 다음 페이지 버튼 -->
				<Button
					variant="outline"
					size="sm"
					onclick={goToNextPage}
					disabled={currentPage >= getTotalPages()}
					class="px-3 py-2"
				>
					다음
				</Button>
			</nav>
		</div>
	{/if}
</div>

<style>
	.masonry-container {
		column-count: 1;
		column-gap: 1.5rem;
		column-fill: balance;
	}

	@media (min-width: 768px) {
		.masonry-container {
			column-count: 2;
		}
	}

	@media (min-width: 1024px) {
		.masonry-container {
			column-count: 3;
		}
	}

	.masonry-item {
		break-inside: avoid;
		margin-bottom: 1.5rem;
		display: inline-block;
		width: 100%;
	}
</style>
