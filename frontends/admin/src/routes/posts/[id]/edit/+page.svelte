<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
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
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import { Label } from '$lib/components/ui/label';
	import { getPost, getBoards, updatePost } from '$lib/api/admin';
	import type { Post } from '$lib/types/admin';

	let post: Post | null = null;
	let title = '';
	let content = '';
	let boardId = '';
	let isNotice = false;
	let boards: any[] = [];
	let loading = true;
	let saving = false;
	let error = '';

	onMount(async () => {
		const postId = $page.params.id;
		try {
			// 게시글 정보와 게시판 목록을 동시에 로드
			const [postData, boardsData] = await Promise.all([
				getPost(postId),
				getBoards()
			]);
			
			post = postData;
			boards = boardsData;
			
			// 폼 데이터 초기화
			if (post) {
				title = post.title || '';
				content = post.content || '';
				boardId = post.board_id || '';
				isNotice = post.is_notice || false;
			}
		} catch (err) {
			error = '게시글을 불러오는 중 오류가 발생했습니다.';
			console.error('Failed to load post:', err);
		} finally {
			loading = false;
		}
	});

	async function handleSubmit() {
		if (!title.trim()) {
			error = '제목을 입력해주세요.';
			return;
		}
		if (!content.trim()) {
			error = '내용을 입력해주세요.';
			return;
		}
		if (!boardId) {
			error = '게시판을 선택해주세요.';
			return;
		}

		try {
			saving = true;
			error = '';
			
			await updatePost($page.params.id, {
				title: title.trim(),
				content: content.trim(),
				board_id: boardId,
				is_notice: isNotice
			});

			alert('게시글이 성공적으로 수정되었습니다.');
			goto(`/posts/${$page.params.id}`);
		} catch (err) {
			error = '게시글 수정 중 오류가 발생했습니다.';
			console.error('Failed to update post:', err);
		} finally {
			saving = false;
		}
	}

	function handleCancel() {
		if (title !== post?.title || content !== post?.content || boardId !== post?.board_id || isNotice !== post?.is_notice) {
			if (confirm('수정 중인 내용이 있습니다. 정말로 나가시겠습니까?')) {
				goto(`/posts/${$page.params.id}`);
			}
		} else {
			goto(`/posts/${$page.params.id}`);
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div class="flex items-center space-x-4">
			<Button variant="outline" onclick={handleCancel}>
				← 상세보기로
			</Button>
			<div>
				<h1 class="text-3xl font-bold text-gray-900">게시글 수정</h1>
				<p class="mt-2 text-gray-600">게시글 정보를 수정합니다.</p>
			</div>
		</div>
	</div>

	{#if loading}
		<Card>
			<CardContent class="pt-6">
				<div class="flex items-center justify-center py-8">
					<div class="text-gray-500">로딩 중...</div>
				</div>
			</CardContent>
		</Card>
	{:else if error}
		<Card>
			<CardContent class="pt-6">
				<div class="bg-red-50 border border-red-200 rounded-lg p-4">
					<div class="text-red-700">{error}</div>
				</div>
			</CardContent>
		</Card>
	{:else if post}
		{#if error}
			<Card>
				<CardContent class="pt-6">
					<div class="bg-red-50 border border-red-200 rounded-lg p-4">
						<div class="text-red-700">{error}</div>
					</div>
				</CardContent>
			</Card>
		{/if}

		<form on:submit|preventDefault={handleSubmit}>
			<Card>
				<CardHeader>
					<CardTitle>게시글 정보</CardTitle>
					<CardDescription>게시글의 기본 정보를 수정합니다.</CardDescription>
				</CardHeader>
				<CardContent class="space-y-6">
					<!-- 제목 -->
					<div class="space-y-2">
						<Label for="title">제목 *</Label>
						<Input
							id="title"
							type="text"
							placeholder="게시글 제목을 입력하세요"
							bind:value={title}
							required
						/>
					</div>

					<!-- 게시판 선택 -->
					<div class="space-y-2">
						<Label for="board">게시판 *</Label>
						<Select
							type="single"
							value={boardId}
							onValueChange={(value: any) => {
								boardId = value;
							}}
						>
							<SelectTrigger>
								{boardId ? boards.find(b => b.id === boardId)?.name : '게시판을 선택하세요'}
							</SelectTrigger>
							<SelectContent>
								{#each boards as board}
									<SelectItem value={board.id}>{board.name}</SelectItem>
								{/each}
							</SelectContent>
						</Select>
					</div>

					<!-- 공지사항 여부 -->
					<div class="flex items-center space-x-2">
						<Checkbox
							id="is-notice"
							bind:checked={isNotice}
						/>
						<Label for="is-notice">공지사항으로 설정</Label>
					</div>

					<!-- 내용 -->
					<div class="space-y-2">
						<Label for="content">내용 *</Label>
						<Textarea
							id="content"
							placeholder="게시글 내용을 입력하세요"
							bind:value={content}
							rows={15}
							required
						/>
					</div>

					<!-- 버튼 -->
					<div class="flex justify-end space-x-2">
						<Button type="button" variant="outline" onclick={handleCancel}>
							취소
						</Button>
						<Button type="submit" disabled={saving}>
							{saving ? '수정 중...' : '게시글 수정'}
						</Button>
					</div>
				</CardContent>
			</Card>
		</form>
	{/if}
</div> 