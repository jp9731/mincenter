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
		postFilter,
		isLoading,
		error,
		fetchPosts,
		fetchBoards,
		fetchCategories,
		fetchTags
	} from '$lib/stores/community';
	import { user, isAuthenticated } from '$lib/stores/auth';
	import { canCreatePost } from '$lib/utils/permissions';
	import type { Post, PostFilter } from '$lib/types/community';

	let searchQuery = '';
	let selectedCategory = '';
	let selectedTags: string[] = [];

	onMount(async () => {
		await Promise.all([
			fetchPosts({
				search: '',
				category: '',
				tags: [],
				sort: 'latest',
				page: 1,
				limit: 10
			}),
			fetchCategories(),
			fetchBoards(),
			fetchTags()
		]);
	});

	function handleSearch() {
		postFilter.update((filter: PostFilter) => ({
			...filter,
			search: searchQuery,
			category: selectedCategory,
			tags: selectedTags
		}));
		fetchPosts($postFilter);
	}

	function handleSortChange(value: string) {
		postFilter.update((filter: PostFilter) => ({
			...filter,
			sort: value as 'latest' | 'popular' | 'comments'
		}));
		fetchPosts($postFilter);
	}

	function handleCategoryChange(value: string) {
		selectedCategory = value;
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

	function getCategoryLabel(categoryId: string) {
		if (!categoryId) return '전체';
		const category = $categories.find((c) => c.id === categoryId);
		return category ? category.name : '카테고리';
	}
</script>

<div class="container mx-auto px-4 py-8">
	<div class="mb-8 flex items-center justify-between">
		<h1 class="text-3xl font-bold">커뮤니티</h1>
		{#if $isAuthenticated && canCreatePost()}
			<Button asChild>
				<a href="/community/write">글쓰기</a>
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
				on:keydown={(e) => e.key === 'Enter' && handleSearch()}
				class="flex-1"
			/>
			<Button on:click={handleSearch}>검색</Button>
		</div>

		<div class="flex items-center gap-4">
			<Select value={$postFilter.sort} onValueChange={handleSortChange}>
				<SelectTrigger class="w-[180px]">
					{getSortLabel($postFilter.sort)}
				</SelectTrigger>
				<SelectContent>
					<SelectItem value="latest">최신순</SelectItem>
					<SelectItem value="popular">인기순</SelectItem>
					<SelectItem value="comments">댓글순</SelectItem>
				</SelectContent>
			</Select>

			<Select value={selectedCategory} onValueChange={handleCategoryChange}>
				<SelectTrigger class="w-[180px]">
					{getCategoryLabel(selectedCategory)}
				</SelectTrigger>
				<SelectContent>
					<SelectItem value="">전체</SelectItem>
					{#each $categories as category}
						<SelectItem value={category.id}>{category.name}</SelectItem>
					{/each}
				</SelectContent>
			</Select>
		</div>

		<div class="flex flex-wrap gap-2">
			{#each $tags as tag}
				<Badge
					variant={selectedTags.includes(tag.id) ? 'default' : 'outline'}
					class="cursor-pointer"
					on:click={() => handleTagClick(tag.id)}
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
									<a href="/community/{post.board_id}/{post.id}" class="hover:underline">
										{post.title}
									</a>
								</CardTitle>
								<CardDescription>
									<a href="/community/{post.board_id}" class="text-blue-600 hover:underline">
										{post.board_name}
									</a>
									· {new Date(post.created_at).toLocaleDateString()}
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
