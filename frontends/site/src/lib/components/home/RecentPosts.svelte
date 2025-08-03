<script lang="ts">
	import { onMount } from 'svelte';
	import { Card } from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { getRecentPosts } from '$lib/api/community';
	import type { PostDetail } from '$lib/types/community';

	// Props - 슬러그와 글 수를 설정할 수 있도록 개선
	const { slugs = 'notice,volunteer-review,community', limit = 3 } = $props<{
		slugs?: string; // 쉼표로 구분된 게시판 슬러그 목록 (예: "notice,community,event")
		limit?: number; // 가져올 게시글 수
	}>();

	// 상태
	let posts: PostDetail[] = [];
	let loading = $state(true);
	let error: string | null = $state(null);

	// 첫 번째 이미지 URL 추출 함수
	function getFirstImageUrl(post: PostDetail): string | null {
		console.log('Getting first image for post:', post.title);
		console.log('Thumbnail URLs:', post.thumbnail_urls);
		
		// 썸네일 URL이 있으면 우선 사용
		if (post.thumbnail_urls) {
			if (post.thumbnail_urls.card) {
				console.log('Using card thumbnail:', post.thumbnail_urls.card);
				return post.thumbnail_urls.card;
			} else if (post.thumbnail_urls.thumb) {
				console.log('Using thumb thumbnail:', post.thumbnail_urls.thumb);
				return post.thumbnail_urls.thumb;
			} else if (post.thumbnail_urls.large) {
				console.log('Using large thumbnail:', post.thumbnail_urls.large);
				return post.thumbnail_urls.large;
			}
		}
		
		// 콘텐츠에서 img 태그 찾기 (HTML 콘텐츠가 있는 경우)
		if (post.content) {
			const imgMatch = post.content.match(/<img[^>]+src="([^"]+)"/);
			if (imgMatch && imgMatch[1]) {
				console.log('Using content image:', imgMatch[1]);
				return imgMatch[1];
			}
		}
		
		console.log('No image found for post:', post.title);
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
		const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';
		return `${API_BASE}${fileUrl.startsWith('/') ? '' : '/'}${fileUrl}`;
	}

	// 텍스트에서 HTML 태그 제거
	function stripHtml(html: string | null | undefined): string {
		if (!html) return '';
		return html.replace(/<[^>]*>/g, '').trim();
	}

	// 날짜 포맷팅
	function formatDate(dateString: string): string {
		return new Date(dateString).toLocaleDateString('ko-KR');
	}

	// 최근 게시글 로드
	async function loadRecentPosts() {
		try {
			loading = true;
			error = null;
			console.log('Loading recent posts with params:', { slugs, limit });
			posts = await getRecentPosts({ slugs, limit });
			console.log('Successfully loaded posts:', posts);
		} catch (err) {
			console.error('최근 게시글 로드 실패:', err);
			error = err instanceof Error ? err.message : '최근 게시글을 불러오는데 실패했습니다.';
		} finally {
			loading = false;
		}
	}

	onMount(() => {
		loadRecentPosts();
	});
</script>

<section class="py-16 md:py-24">
	<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
		<div class="mb-16 text-center">
			<h2 class="mb-4 text-3xl font-bold text-gray-900 md:text-4xl">최근 소식</h2>
			<p class="mx-auto max-w-3xl text-lg text-gray-600">
				민들레장애인자립생활센터의 최신 소식과 활동을 확인하세요.
			</p>
		</div>

		{#if loading}
			<div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
				{#each Array(limit) as _}
					<Card class="overflow-hidden">
						<div class="aspect-w-16 aspect-h-9 bg-gray-200 animate-pulse"></div>
						<div class="p-6">
							<div class="mb-2 flex items-center gap-2">
								<div class="h-4 w-16 bg-gray-200 rounded animate-pulse"></div>
								<div class="h-4 w-20 bg-gray-200 rounded animate-pulse"></div>
							</div>
							<div class="mb-2 h-6 bg-gray-200 rounded animate-pulse"></div>
							<div class="h-4 w-24 bg-gray-200 rounded animate-pulse"></div>
						</div>
					</Card>
				{/each}
			</div>
		{:else if error}
			<div class="text-center py-8">
				<p class="text-red-600">{error}</p>
				<Button onclick={loadRecentPosts} class="mt-4">다시 시도</Button>
			</div>
		{:else if posts.length === 0}
			<div class="text-center py-8">
				<p class="text-gray-600">등록된 게시글이 없습니다.</p>
			</div>
		{:else}
			<div class="grid grid-cols-1 gap-8 md:grid-cols-2 lg:grid-cols-3">
				{#each posts as post}
					{@const imageUrl = getFirstImageUrl(post)}
					<Card class="overflow-hidden transition-shadow hover:shadow-lg !py-0">
						{#if imageUrl}
							<div class="aspect-w-16 aspect-h-9">
								<img 
									src={getFullFileUrl(imageUrl)} 
									alt={post.title} 
									class="h-full w-full object-cover"
									loading="lazy"
								/>
							</div>
						{:else}
							<div class="aspect-w-16 aspect-h-9 bg-gray-100 flex items-center justify-center">
								<img src="/images/min_logo.png" alt="기본 이미지" class=" object-contain opacity-40" />
							</div>
						{/if}
						<div class="px-6 pb-6">
							<div class="mb-2 flex items-center gap-2">
								<span class="text-primary-600 text-sm font-medium">
									{post.category_name || post.board_name}
								</span>
								<span class="text-sm text-gray-500">
									{formatDate(post.created_at)}
								</span>
							</div>
							<h3 class="mb-2 text-xl font-semibold text-gray-900 line-clamp-2">
								{post.title}
							</h3>
							{#if post.content}
								<p class="mb-4 text-sm text-gray-600 line-clamp-3">
									{stripHtml(post.content)}
								</p>
							{/if}
							<div class="flex items-center justify-between">
								<Button variant="ghost" asChild>
									<a href="/community/{post.board_slug}/{post.id}">자세히 보기</a>
								</Button>
								<div class="flex items-center gap-4 text-xs text-gray-500">
									<span>조회 {post.views || 0}</span>
									<span>댓글 {post.comment_count || 0}</span>
								</div>
							</div>
						</div>
					</Card>
				{/each}
			</div>
		{/if}


	</div>
</section>
