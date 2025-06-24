<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Badge } from '$lib/components/ui/badge';
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
		fetchPostsBySlug,
		fetchBoards,
		fetchCategories,
		fetchTags
	} from '$lib/stores/community';
	import { user, isAuthenticated } from '$lib/stores/auth';
	import { canCreatePost } from '$lib/utils/permissions';
	import type { Post, PostFilter } from '$lib/types/community';

	export let data;
	let searchQuery = '';
	let selectedTags: string[] = [];
	let currentSort = 'latest';

	// 게시판 이름을 반응형으로 계산
	$: boardName = $boards.find((board: any) => board.slug === data.slug)?.name || '게시판';

	onMount(async () => {
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
	});

	function handleSearch() {
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
</script>

<div class="container mx-auto px-4 py-8">
	<div class="mb-8 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">{boardName}</h1>
			<p class="mt-2 text-gray-600">게시글 {posts.length}개</p>
		</div>
		{#if $isAuthenticated && canCreatePost()}
			<Button asChild>
				<a href="/community/{data.slug}/write">글쓰기</a>
			</Button>
		{:else if !$isAuthenticated}
			<Button variant="outline" asChild>
				<a href="/auth/login">로그인하여 글쓰기</a>
			</Button>
		{/if}
	</div>

	<!-- 검색 및 필터 -->
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

	<!-- 게시글 목록 -->
	{#if $isLoading}
		<div class="py-8 text-center">로딩 중...</div>
	{:else if $error}
		<div class="py-8 text-center text-red-500">{$error}</div>
	{:else if $posts.length === 0}
		<div class="py-8 text-center">게시글이 없습니다.</div>
	{:else}
		<div class="grid gap-6">
			{#each $posts as post}
				<Card>
					<CardHeader>
						<div class="flex items-start justify-between">
							<div>
								<CardTitle>
									<a href="/community/{data.slug}/{post.id}" class="hover:underline">
										{post.title}
									</a>
								</CardTitle>
								<CardDescription>
									{new Date(post.created_at).toLocaleDateString()}
								</CardDescription>
							</div>
							<div class="flex items-center gap-4 text-sm text-gray-500">
								<span>조회 {post.views || 0}</span>
								<span>좋아요 {post.likes || 0}</span>
								<span>댓글 {post.comment_count || 0}</span>
							</div>
						</div>
					</CardHeader>
					<CardContent>
						<p class="line-clamp-2 text-gray-600">{post.content}</p>
					</CardContent>
					<CardFooter>
						<div class="flex items-center gap-2">
							<div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-300">
								<span class="text-xs text-gray-600">{post.user_name?.[0] || 'U'}</span>
							</div>
							<span class="text-sm text-gray-500">{post.user_name || '익명'}</span>
						</div>
						<div class="ml-auto flex gap-2">
							{#if post.is_notice}
								<Badge variant="secondary">공지</Badge>
							{/if}
						</div>
					</CardFooter>
				</Card>
			{/each}
		</div>
	{/if}
</div>
