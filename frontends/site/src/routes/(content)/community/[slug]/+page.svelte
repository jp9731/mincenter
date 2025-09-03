<script lang="ts">
	import { onMount, tick } from 'svelte';
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
		isLoading,
		error,
		pagination,
		fetchPostsBySlug,
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
	import { dev } from '$app/environment';

	// Props 인터페이스 및 선언
	interface Props {
		data: {
			slug: string;
		};
	}
	let { data }: Props = $props();

	// 상태 변수들
	let searchQuery = $state('');
	let selectedTags = $state<string[]>([]);
	let currentSort = $state('latest');
	let currentPage = $state(1);

	const fontSizeClasses = ['text-sm', 'text-base', 'text-lg', 'text-xl', 'text-2xl', 'text-3xl', 'text-4xl', 'text-5xl'];
	const leadingClasses = ['leading-normal', 'leading-normal', 'leading-normal', 'leading-normal', 'leading-normal', 'leading-normal', 'leading-normal', 'leading-normal'];
	const minFontSizeIndex = 0;
	const maxFontSizeIndex = fontSizeClasses.length - 1;

	// --- [1] 폰트 크기 로컬스토리지 연동 ---
	function getInitialFontSizeIndex() {
		if (typeof window === 'undefined') return 4;
		const saved = localStorage.getItem('community-font-size-index');
		const idx = Number(saved);
		if (!isNaN(idx) && idx >= minFontSizeIndex && idx <= maxFontSizeIndex) return idx;
		return 4;
	}
	let fontSizeIndex = $state(getInitialFontSizeIndex());
	$effect(() => {
		if (typeof window !== 'undefined') {
			localStorage.setItem('community-font-size-index', String(fontSizeIndex));
		}
	});

	// --- [2] 뷰 모드 로컬스토리지 연동 ---
	let innerWidth = $state(typeof window !== 'undefined' ? window.innerWidth : 1024);
	let isMobile = $derived(innerWidth < 768);
	function getInitialViewMode() {
		if (typeof window === 'undefined') return isMobile ? 'card' : 'list';
		const saved = localStorage.getItem('community-view-mode');
		if (saved === 'list' || saved === 'card') return saved;
		return isMobile ? 'card' : 'list';
	}
	let viewMode = $state<'list' | 'card'>(getInitialViewMode());
	$effect(() => {
		if (typeof window !== 'undefined') {
			localStorage.setItem('community-view-mode', viewMode);
		}
	});
	$effect(() => {
		if (isMobile) viewMode = 'card';
	});

	// 파생 상태들
	let boardName = $derived(
		$boards.find((board: Board) => board.slug === data.slug)?.name || '게시판'
	);
	
	let currentBoard = $derived(
		$boards.find((board: Board) => board.slug === data.slug)
	);
	
	let canWriteInCurrentBoard = $derived(
		currentBoard && !$isLoading ? canWritePost(currentBoard, $user) : false
	);
	
	let canListCurrentBoard = $derived(
		currentBoard ? canListBoard(currentBoard, $user) : true
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

	// 부수효과들
	$effect(() => {
		// 초기 데이터 로드
		loadInitialData();
	});

	async function loadInitialData() {
		const slug = data.slug;
		await Promise.all([
			fetchPostsBySlug(slug, {
				search: '',
				tags: [],
				sort: 'latest',
				page: 1,
				limit: 10
			}),
			fetchBoards(),
			fetchCategories(),
			fetchTags()
		]);
	}

	function handleSearch() {
		currentPage = 1; // 페이지 리셋
		const slug = data.slug;
		fetchPostsBySlug(slug, {
			search: searchQuery,
			tags: selectedTags,
			sort: currentSort,
			page: 1,
			limit: 10
		});
	}

	function handleSortChange(value: string) {
		currentPage = 1; // 페이지 리셋
		currentSort = value;
		const slug = data.slug;
		fetchPostsBySlug(slug, {
			search: searchQuery,
			tags: selectedTags,
			sort: value as 'latest' | 'popular' | 'comments',
			page: 1,
			limit: 10
		});
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

	let fontSizeClass = $derived(fontSizeClasses[fontSizeIndex]);
	let fontSizeMetaClass = $derived(fontSizeClasses[Math.max(fontSizeIndex-2,0)]);
	let fontSizeBadgeClass = $derived(fontSizeClasses[Math.max(fontSizeIndex-3,0)]);
	let leadingClass = $derived(leadingClasses[fontSizeIndex]);
	let leadingMetaClass = $derived(leadingClasses[Math.max(fontSizeIndex-2,0)]);
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

	// 페이지네이션 관련 함수들
	function goToPage(page: number) {
		currentPage = page;
		const slug = data.slug;
		fetchPostsBySlug(slug, {
			search: searchQuery,
			tags: selectedTags,
			sort: currentSort,
			page: page,
			limit: 10
		});
	}

	function goToNextPage() {
		if (currentPage < getTotalPages()) {
			currentPage += 1;
			const slug = data.slug;
			fetchPostsBySlug(slug, {
				search: searchQuery,
				tags: selectedTags,
				sort: currentSort,
				page: currentPage,
				limit: 10
			}, true); // append=true로 호출
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

	let observer: IntersectionObserver | null = null;
	
	// IntersectionObserver 설정 함수
	async function setupIntersectionObserver() {
		// 기존 observer 정리
		if (observer) {
			observer.disconnect();
			observer = null;
		}
		
		// DOM 렌더링 완료 대기
		await tick();
		
		// 모바일 카드 뷰에서만 IntersectionObserver 설정
		if (isMobile && viewMode === 'card' && $posts.length > 0) {
			// 마지막 카드를 DOM에서 직접 찾기
			const cards = document.querySelectorAll('.masonry-item');
			const lastCardElement = cards[cards.length - 1];
			
			console.log('찾은 카드 개수:', cards.length);
			console.log('마지막 카드 요소:', lastCardElement);
			
			if (lastCardElement && lastCardElement instanceof Element) {
				console.log('IntersectionObserver 설정됨:', lastCardElement);
				observer = new IntersectionObserver(([entry]) => {
					console.log('IntersectionObserver 감지:', entry.isIntersecting);
					if (entry.isIntersecting && currentPage < getTotalPages()) {
						goToNextPage();
					}
				}, { threshold: 0.5 });
				observer.observe(lastCardElement);
				console.log('lastCard 관찰 시작:', lastCardElement);
			} else {
				console.log('마지막 카드 요소를 찾을 수 없음');
			}
		} else {
			console.log('IntersectionObserver 설정 조건 미충족:', {
				isMobile,
				viewMode,
				postsLength: $posts.length
			});
		}
	}
	
	// 모바일 상태나 뷰 모드 변경 시 observer 재설정
	$effect(() => {
		console.log('$effect 실행:', { isMobile, viewMode, postsLength: $posts.length });
		if (isMobile && viewMode === 'card') {
			setupIntersectionObserver();
		}
	});
	
	// 새로 추가된 게시글 추적
	let previousPostsLength = $state(0);
	let newPostsStartIndex = $state(0);
	
	// posts 배열 변경 시에도 observer 재설정
	$effect(() => {
	dev && console.log('posts 변경됨:', $posts.length);
		
		// 새 게시글이 추가되었는지 확인
		if ($posts.length > previousPostsLength) {
			newPostsStartIndex = previousPostsLength;
			previousPostsLength = $posts.length;
			
			// 새 게시글들에 페이드인 효과 적용을 위한 지연
			setTimeout(() => {
				const newCards = document.querySelectorAll('.masonry-item.fade-in');
				newCards.forEach((card, index) => {
					setTimeout(() => {
						card.classList.remove('fade-in');
						card.classList.add('fade-in-visible');
					}, index * 100); // 각 카드마다 100ms씩 지연
				});
			}, 50);
		} else {
			previousPostsLength = $posts.length;
		}
		
		if (isMobile && viewMode === 'card' && $posts.length > 0) {
			// 약간의 지연 후 observer 재설정
			setTimeout(() => {
				setupIntersectionObserver();
			}, 100);
		}
	});
	
	// 컴포넌트 언마운트 시 observer 정리
	onMount(() => {
		return () => {
			if (observer) {
				observer.disconnect();
			}
		};
	});
</script>
<svelte:window bind:innerWidth={innerWidth} />

<div class="py-8">
	<div class="mb-8 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">{boardName}</h1>
			<p class="mt-2 text-gray-600">게시글 {$posts.length}개</p>
			
			<!-- 디버그 정보 -->
			{#if import.meta.env.DEV}
				<div class="mt-2 text-xs text-gray-500 bg-gray-50 p-2 rounded">
					<strong>디버그:</strong>
					사용자: {$user?.email || '비로그인'} (역할: {$user?.role || 'none'}) |
					게시판: {currentBoard?.name || '없음'} |
					글쓰기 권한: {currentBoard?.write_permission || '없음'} |
					글쓰기 가능: {canWriteInCurrentBoard ? 'Yes' : 'No'} |
					로딩: {$isLoading ? 'Yes' : 'No'}
				</div>
			{/if}
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
					<a href="/community/{data.slug}/write">글쓰기</a>
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
					class="w-80"
				/>
				<Button onclick={handleSearch}>검색</Button>
			</div>

			<div class="flex items-center gap-4">
				<Select type="single" value={currentSort} onValueChange={handleSortChange}>
					<SelectTrigger class="w-[180px]">
						{getSortLabel(currentSort)}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="latest">최신순</SelectItem>
						<SelectItem value="popular">인기순</SelectItem>
						<SelectItem value="comments">댓글순</SelectItem>
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
				{@const indentLevel = (post.depth || 0) * 24} <!-- 답글 들여쓰기 계산 -->
				<div class="flex justify-between items-center gap-4 p-4 sm:px-8 px-4 hover:bg-gray-50 transition-colors {index < $posts.length - 1 ? 'border-b border-gray-200' : ''}" style="margin-left: {indentLevel}px;">
					<!-- 답글 표시 아이콘 -->
					{#if post.depth && post.depth > 0}
						<div class="flex-shrink-0 text-gray-400">
							{'└'.repeat(post.depth)} ↳
						</div>
					{/if}
					<!-- 왼쪽: 섬네일 + 제목/배지/카테고리 -->
					<div class="flex items-center gap-3 min-w-0 flex-1">
						<!-- 섬네일 이미지 -->
						{#if thumbnailUrl}
							<div class="flex-shrink-0">
								<a href="/community/{data.slug}/{post.short_id}">
									<img
										src={thumbnailUrl}
										alt={post.title}
										class="w-16 h-16 object-cover rounded-md"
									/>
								</a>
							</div>
						{/if}
						<!-- 제목/배지/카테고리 -->
						<div class="flex items-center gap-2 min-w-0 flex-wrap">
							{#if post.is_notice}
								<Badge variant="secondary" class={`${fontSizeBadgeClass} ${leadingBadgeClass}`}>공지</Badge>
							{/if}
							<a href="/community/{data.slug}/{post.short_id}" class={`text-gray-900 hover:text-blue-600 transition-colors font-medium truncate ${fontSizeClass} ${leadingClass}`}>
								{post.category_name ? `[${post.category_name}] ` : ''}{post.title}
							</a>
							{#if isNewPost(post)}
								<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-blue-600 border-blue-600`}>신규</Badge>
							{/if}
							{#if isHotPost(post)}
								<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-orange-600 border-orange-600`}>핫</Badge>
							{/if}
						</div>
					</div>
					<!-- 오른쪽: 메타데이터 -->
					<div class="flex flex-col gap-0.5 text-gray-500 flex-shrink-0 text-right">
						<!-- 첫 번째 줄: 작성자, 날짜 -->
						<div class="flex items-center gap-2 justify-end">
							<span class={`${fontSizeBadgeClass} leading-tight`}>{post.user_name || '익명'}</span>
							<span class={`${fontSizeBadgeClass} leading-tight`}>·</span>
							<span class={`${fontSizeBadgeClass} leading-tight`}>{new Date(post.created_at).toLocaleDateString()}</span>
						</div>
						<!-- 두 번째 줄: 조회, 좋아요, 댓글 -->
						<div class="flex items-center gap-2 justify-end">
							<span class={`${fontSizeBadgeClass} leading-tight`}>조회 {post.views || 0}</span>
							<span class={`${fontSizeBadgeClass} leading-tight`}>·</span>
							<span class={`${fontSizeBadgeClass} leading-tight`}>좋아요 {post.likes || 0}</span>
							<span class={`${fontSizeBadgeClass} leading-tight`}>·</span>
							<span class={`${fontSizeBadgeClass} leading-tight`}>댓글 {post.comment_count || 0}</span>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<!-- 카드 형태 (메이슨리 레이아웃) -->
		<div class="masonry-container">
			{#each $posts as post, idx (post.id)}
				{@const thumbnailUrl = getFirstImageUrl(post, viewMode === 'list' ? 'list' : 'card')}
				{@const isNewCard = idx >= newPostsStartIndex}
				{@const indentLevel = (post.depth || 0) * 16} <!-- 카드뷰에서는 작은 들여쓰기 -->
				<Card
					class="masonry-item hover:shadow-lg transition-all duration-200 hover:-translate-y-1 overflow-hidden mt-4 {thumbnailUrl ? 'pt-0' : ''} {isNewCard ? 'fade-in' : ''}"
					style="margin-left: {indentLevel}px;"
				>
					<!-- 카드 헤더 이미지 -->
					{#if thumbnailUrl}
						<div class="overflow-hidden">
							<a href="/community/{data.slug}/{post.short_id}">
								<img
									src={thumbnailUrl}
									alt={post.title}
									class="w-full h-auto object-contain"
								/>
							</a>
						</div>
					{/if}
					<CardHeader class={thumbnailUrl ? "pb-3 pt-0 px-6 relative" : "pb-3 relative"}>
						<div class="flex items-start justify-between">
							<div class="flex-1 min-w-0">
								<CardTitle class={`leading-tight break-words whitespace-pre-line pr-10 sm:pr-24 ${fontSizeClass} ${leadingClass}`}> <!-- 우측 패딩 추가 -->
									<a href="/community/{data.slug}/{post.short_id}" class="hover:text-blue-600 transition-colors">
										{#if post.depth && post.depth > 0}
											<span class="text-gray-400 mr-1">{'└'.repeat(post.depth)} ↳</span>
										{/if}
										{post.category_name ? `[${post.category_name}] ` : ''}{post.title}
									</a>
								</CardTitle>
							</div>
							<!-- 우측 배지 레이어 -->
							<div class="badge-layer absolute right-0 mr-2 top-0 flex flex-col gap-1 items-end min-w-[56px]">
								{#if post.is_notice}
									<Badge variant="secondary" class={`${fontSizeBadgeClass} ${leadingBadgeClass}`}>공지</Badge>
								{/if}
								{#if isNewPost(post)}
									<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-blue-600 border-blue-600`}>신규</Badge>
								{/if}
								{#if isHotPost(post)}
									<Badge variant="outline" class={`${fontSizeBadgeClass} ${leadingBadgeClass} text-orange-600 border-orange-600`}>핫</Badge>
								{/if}
							</div>
						</div>
						<div class={`flex items-center gap-4 text-gray-500 ${fontSizeMetaClass} ${leadingMetaClass}`}> 
							<span>{new Date(post.created_at).toLocaleDateString()}</span>
							<!-- 필요시 작성자 등 추가 -->
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
					disabled={getCurrentPage() <= 1}
					class="px-3 py-2"
				>
					이전
				</Button>

				<!-- 페이지 번호들 -->
				{#each getPageNumbers() as pageNum}
					<Button
						variant={pageNum === getCurrentPage() ? 'default' : 'outline'}
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
					disabled={getCurrentPage() >= getTotalPages()}
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
	
	/* 페이드인 효과 */
	.fade-in {
		opacity: 0;
		transform: translateY(20px);
		transition: opacity 0.6s ease-out, transform 0.6s ease-out;
	}
	
	.fade-in-visible {
		opacity: 1;
		transform: translateY(0);
	}
</style>
