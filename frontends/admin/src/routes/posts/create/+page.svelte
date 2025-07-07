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
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import { Label } from '$lib/components/ui/label';
	import { getBoards, createPost } from '$lib/api/admin';

	let title = '';
	let content = '';
	let boardId = '';
	let isNotice = false;
	let boards: any[] = [];
	let loading = false;
	let error = '';

	onMount(async () => {
		try {
			boards = await getBoards();
		} catch (err) {
			error = '게시판 목록을 불러오는 중 오류가 발생했습니다.';
			console.error('Failed to load boards:', err);
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
			loading = true;
			error = '';
			
			await createPost({
				title: title.trim(),
				content: content.trim(),
				board_id: boardId,
				is_notice: isNotice
			});

			alert('게시글이 성공적으로 작성되었습니다.');
			goto('/posts');
		} catch (err) {
			error = '게시글 작성 중 오류가 발생했습니다.';
			console.error('Failed to create post:', err);
		} finally {
			loading = false;
		}
	}

	function handleCancel() {
		if (title || content) {
			if (confirm('작성 중인 내용이 있습니다. 정말로 나가시겠습니까?')) {
				goto('/posts');
			}
		} else {
			goto('/posts');
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div class="flex items-center space-x-4">
			<Button variant="outline" onclick={handleCancel}>
				← 목록으로
			</Button>
			<div>
				<h1 class="text-3xl font-bold text-gray-900">새 게시글 작성</h1>
				<p class="mt-2 text-gray-600">새로운 게시글을 작성합니다.</p>
			</div>
		</div>
	</div>

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
				<CardDescription>게시글의 기본 정보를 입력합니다.</CardDescription>
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
					<Button type="submit" disabled={loading}>
						{loading ? '작성 중...' : '게시글 작성'}
					</Button>
				</div>
			</CardContent>
		</Card>
	</form>
</div> 