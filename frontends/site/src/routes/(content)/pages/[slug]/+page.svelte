<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { getPageBySlug, type Page } from '$lib/api/site.js';
	import type { ApiResponse } from '$lib/types/community.js';

	export let data;
	let page: Page | null = null;
	let loading = true;
	let error: string | null = null;

	onMount(async () => {
		try {
			loading = true;
			const response: ApiResponse<Page> = await getPageBySlug(data.slug);
			
			if (response.success && response.data) {
				page = response.data;
			} else {
				error = response.message || '페이지를 찾을 수 없습니다.';
			}
		} catch (err) {
			console.error('페이지 로드 실패:', err);
			error = '페이지를 불러오는데 실패했습니다.';
		} finally {
			loading = false;
		}
	});

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleDateString('ko-KR');
	}
</script>

	<div class="py-8">
	{#if loading}
		<div class="py-12 text-center">
			<div class="text-lg">페이지를 불러오는 중...</div>
		</div>
	{:else if error}
		<div class="py-12 text-center">
			<div class="text-lg text-red-600 mb-4">{error}</div>
			<button
				onclick={() => goto('/')}
				class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
			>
				홈으로 돌아가기
			</button>
		</div>
	{:else if page}
		<article class="mx-auto max-w-4xl">
			<!-- 페이지 헤더 -->
			<header class="mb-8">
				<h1 class="text-4xl font-bold text-gray-900 mb-4">{page.title}</h1>
				{#if page.excerpt}
					<p class="text-lg text-gray-600 mb-4">{page.excerpt}</p>
				{/if}
				<div class="flex items-center gap-4 text-sm text-gray-500">
					<span>작성일: {formatDate(page.created_at)}</span>
					{#if page.updated_at !== page.created_at}
						<span>수정일: {formatDate(page.updated_at)}</span>
					{/if}
					<span>조회수: {page.view_count}</span>
				</div>
			</header>

			<!-- 페이지 내용 -->
			<div class="prose prose-lg max-w-none whitespace-pre-wrap">
				{@html page.content}
			</div>

			<!-- 메타 정보 -->
			{#if page.meta_title || page.meta_description}
				<footer class="mt-12 pt-8 border-t border-gray-200">
					{#if page.meta_title}
						<div class="mb-2">
							<strong class="text-gray-700">메타 제목:</strong> {page.meta_title}
						</div>
					{/if}
					{#if page.meta_description}
						<div>
							<strong class="text-gray-700">메타 설명:</strong> {page.meta_description}
						</div>
					{/if}
				</footer>
			{/if}
		</article>
	{:else}
		<div class="py-12 text-center">
			<div class="text-lg text-gray-600 mb-4">페이지를 찾을 수 없습니다.</div>
			<button
				onclick={() => goto('/')}
				class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
			>
				홈으로 돌아가기
			</button>
		</div>
	{/if}
</div>

<style>
	.prose {
		color: #111827;
	}

	.prose h1 {
		font-size: 1.875rem;
		font-weight: 700;
		margin-bottom: 1.5rem;
	}

	.prose h2 {
		font-size: 1.5rem;
		font-weight: 700;
		margin-bottom: 1rem;
		margin-top: 2rem;
	}

	.prose h3 {
		font-size: 1.25rem;
		font-weight: 700;
		margin-bottom: 0.75rem;
		margin-top: 1.5rem;
	}

	.prose p {
		margin-bottom: 1rem;
		line-height: 1.75;
	}

	.prose ul {
		margin-bottom: 1rem;
		padding-left: 1.5rem;
	}

	.prose ol {
		margin-bottom: 1rem;
		padding-left: 1.5rem;
	}

	.prose li {
		margin-bottom: 0.25rem;
	}

	.prose a {
		color: #2563eb;
		text-decoration: underline;
	}

	.prose a:hover {
		color: #1d4ed8;
	}

	.prose blockquote {
		border-left: 4px solid #d1d5db;
		padding-left: 1rem;
		font-style: italic;
		margin: 1rem 0;
	}

	.prose code {
		background-color: #f3f4f6;
		padding: 0.125rem 0.25rem;
		border-radius: 0.25rem;
		font-size: 0.875rem;
	}

	.prose pre {
		background-color: #f3f4f6;
		padding: 1rem;
		border-radius: 0.25rem;
		overflow-x: auto;
		margin: 1rem 0;
	}

	.prose img {
		max-width: 100%;
		height: auto;
		border-radius: 0.25rem;
		margin: 1rem 0;
	}

	.prose table {
		width: 100%;
		border-collapse: collapse;
		border: 1px solid #d1d5db;
		margin: 1rem 0;
	}

	.prose th {
		border: 1px solid #d1d5db;
		padding: 0.5rem 1rem;
		background-color: #f3f4f6;
		font-weight: 700;
	}

	.prose td {
		border: 1px solid #d1d5db;
		padding: 0.5rem 1rem;
	}
</style> 