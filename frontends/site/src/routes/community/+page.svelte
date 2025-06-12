<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import {
		Select,
		SelectContent,
		SelectItem,
		SelectTrigger,
		SelectValue
	} from '$lib/components/ui/select';
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
		tags,
		postFilter,
		isLoading,
		error,
		fetchPosts,
		fetchCategories,
		fetchTags
	} from '$lib/stores/community';
	import type { Post } from '$lib/types/community';

	let searchQuery = '';
	let selectedCategory = '';
	let selectedTags: string[] = [];

	onMount(async () => {
		await Promise.all([fetchPosts({ sort: 'latest' }), fetchCategories(), fetchTags()]);
	});

	function handleSearch() {
		postFilter.update((filter) => ({
			...filter,
			search: searchQuery,
			category: selectedCategory,
			tags: selectedTags
		}));
		fetchPosts($postFilter);
	}

	function handleSortChange(value: string) {
		postFilter.update((filter) => ({
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
</script>

<div class="container mx-auto py-8">
	<div class="mb-8 flex items-center justify-between">
		<h1 class="text-3xl font-bold">커뮤니티</h1>
		<Button href="/community/write">글쓰기</Button>
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
					<SelectValue placeholder="정렬 기준" />
				</SelectTrigger>
				<SelectContent>
					<SelectItem value="latest">최신순</SelectItem>
					<SelectItem value="popular">인기순</SelectItem>
					<SelectItem value="comments">댓글순</SelectItem>
				</SelectContent>
			</Select>

			<Select value={selectedCategory} onValueChange={handleCategoryChange}>
				<SelectTrigger class="w-[180px]">
					<SelectValue placeholder="카테고리" />
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
									<a href="/community/{post.id}" class="hover:underline">
										{post.title}
									</a>
								</CardTitle>
								<CardDescription>
									{post.category} · {new Date(post.createdAt).toLocaleDateString()}
								</CardDescription>
							</div>
							<div class="flex items-center gap-2">
								<span class="text-sm text-gray-500">
									조회 {post.views}
								</span>
								<span class="text-sm text-gray-500">
									좋아요 {post.likes}
								</span>
								<span class="text-sm text-gray-500">
									댓글 {post.comments}
								</span>
							</div>
						</div>
					</CardHeader>
					<CardContent>
						<p class="line-clamp-2 text-gray-600">{post.content}</p>
					</CardContent>
					<CardFooter>
						<div class="flex items-center gap-2">
							<img
								src={post.author.avatar || '/default-avatar.png'}
								alt={post.author.name}
								class="h-6 w-6 rounded-full"
							/>
							<span class="text-sm text-gray-500">{post.author.name}</span>
						</div>
						<div class="ml-auto flex gap-2">
							{#each post.tags as tag}
								<Badge variant="secondary">{tag}</Badge>
							{/each}
						</div>
					</CardFooter>
				</Card>
			{/each}
		</div>
	{/if}
</div>
