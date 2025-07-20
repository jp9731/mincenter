<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Heart, ThumbsUp, MessageCircle, Send, Download } from 'lucide-svelte';
	import { user } from '$lib/stores/auth';
	import { canEditPost, canDeletePost, canCreateCommentInBoard, canCreateReplyInBoard, canDownloadFile } from '$lib/utils/permissions';
	import { togglePostLike, toggleCommentLike, createComment, loadComments, comments as commentsStore, getPostLikeStatus, getCommentLikeStatus } from '$lib/stores/community';
	import { checkThumbnailStatus } from '$lib/api/community';
	import { goto } from '$app/navigation';
	import { deletePost } from '$lib/stores/community';

	// Props 인터페이스 및 선언
	interface Props {
		data: {
			slug: string;
			postId: string;
			post?: any;
			board?: any;
		};
	}
	let { data }: Props = $props();

	let postLiked = $state(false);
	let commentLikes = $state<Record<string, boolean>>({});
	let newComment = $state('');
	let isSubmitting = $state(false);
	let fontSize = $state(1.0); // 기본 1.0em
	
	// 대댓글 관련 상태
	let showReplyForm = $state<Record<string, boolean>>({});
	let replyContent = $state<Record<string, string>>({});
	let editingComment = $state<Record<string, boolean>>({});
	let editContent = $state<Record<string, string>>({});
	function increaseFont() { fontSize = Math.min(fontSize + 0.1, 2.0); }
	function decreaseFont() { fontSize = Math.max(fontSize - 0.1, 0.8); }

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleString('ko-KR');
	}

	// 권한 체크
	let canEditCurrentPost = $derived(data.post ? canEditPost(data.post, $user) : false);
	let canDeleteCurrentPost = $derived(data.post ? canDeletePost(data.post, $user) : false);
	let canCreateComment = $derived(data.board ? canCreateCommentInBoard(data.board, $user) : false);
	let canCreateReply = $derived(data.board ? canCreateReplyInBoard(data.board, $user) : false);
	let canDownloadFiles = $derived(data.board ? canDownloadFile(data.board, $user) : false);



	async function handlePostLike() {
		if (!$user) {
			alert('로그인이 필요합니다.');
			return;
		}
		
		try {
			await togglePostLike(data.postId);
			postLiked = !postLiked;
		} catch (error) {
			console.error('좋아요 처리 실패:', error);
		}
	}

	async function handleCommentLike(commentId: string) {
		if (!$user) {
			alert('로그인이 필요합니다.');
			return;
		}
		
		try {
			await toggleCommentLike(commentId);
			commentLikes[commentId] = !commentLikes[commentId];
		} catch (error) {
			console.error('댓글 좋아요 처리 실패:', error);
		}
	}

	async function loadCommentsData() {
		try {
			await loadComments(data.postId);
		} catch (error) {
			console.error('댓글 로드 실패:', error);
		}
	}

	async function handleSubmitComment() {
		if (!newComment.trim()) return;
		if (!$user) {
			alert('로그인이 필요합니다.');
			return;
		}

		isSubmitting = true;
		try {
			await createComment({ post_id: data.postId, content: newComment });
			newComment = '';
			await loadCommentsData(); // 댓글 목록 새로고침
		} catch (error) {
			console.error('댓글 작성 실패:', error);
			alert('댓글 작성에 실패했습니다.');
		} finally {
			isSubmitting = false;
		}
	}

	async function handleDeletePost() {
		if (!confirm('정말로 이 글을 삭제하시겠습니까?')) return;
		try {
			await deletePost(data.post.id);
			alert('글이 삭제되었습니다.');
			goto(`/community/${data.slug}`);
		} catch (error) {
			alert('글 삭제에 실패했습니다.');
			console.error(error);
		}
	}

	// 대댓글 생성
	async function handleCreateReply(parentId: string) {
		if (!replyContent[parentId]?.trim()) return;
		if (!$user) {
			alert('로그인이 필요합니다.');
			return;
		}

		try {
			await createComment({ 
				post_id: data.postId, 
				parent_id: parentId,
				content: replyContent[parentId] 
			});
			replyContent[parentId] = '';
			showReplyForm[parentId] = false;
			await loadCommentsData(); // 댓글 목록 새로고침
		} catch (error) {
			console.error('답글 작성 실패:', error);
			alert('답글 작성에 실패했습니다.');
		}
	}

	// 댓글 수정
	async function handleUpdateComment(commentId: string) {
		if (!editContent[commentId]?.trim()) return;
		if (!$user) {
			alert('로그인이 필요합니다.');
			return;
		}

		try {
			// API 호출로 댓글 수정
			const response = await fetch(`${import.meta.env.VITE_API_URL}/api/community/comments/${commentId}`, {
				method: 'PUT',
				headers: {
					'Content-Type': 'application/json',
					'Authorization': `Bearer ${localStorage.getItem('token') || localStorage.getItem('auth_token')}`
				},
				body: JSON.stringify({ content: editContent[commentId] })
			});

			if (!response.ok) {
				throw new Error('댓글 수정 실패');
			}

			editingComment[commentId] = false;
			await loadCommentsData(); // 댓글 목록 새로고침
		} catch (error) {
			console.error('댓글 수정 실패:', error);
			alert('댓글 수정에 실패했습니다.');
		}
	}

	// 댓글 삭제
	async function handleDeleteComment(commentId: string) {
		if (!confirm('정말로 이 댓글을 삭제하시겠습니까?')) return;
		if (!$user) {
			alert('로그인이 필요합니다.');
			return;
		}

		try {
			// API 호출로 댓글 삭제
			const response = await fetch(`${import.meta.env.VITE_API_URL}/api/community/comments/${commentId}`, {
				method: 'DELETE',
				headers: {
					'Authorization': `Bearer ${localStorage.getItem('token') || localStorage.getItem('auth_token')}`
				}
			});

			if (!response.ok) {
				throw new Error('댓글 삭제 실패');
			}

			await loadCommentsData(); // 댓글 목록 새로고침
		} catch (error) {
			console.error('댓글 삭제 실패:', error);
			alert('댓글 삭제에 실패했습니다.');
		}
	}

	// 페이지 로드 시 댓글 가져오기 및 좋아요 상태 초기화
	$effect(() => {
		if (data.postId) {
			loadCommentsData();
			// API에서 받은 게시글 좋아요 상태 사용
			if (data.post?.is_liked !== undefined) {
				postLiked = data.post.is_liked;
			}
		}
	});

	// 댓글이 로드된 후 좋아요 상태 확인 및 수정용 내용 초기화
	$effect(() => {
		if ($commentsStore.length > 0) {
			// API에서 받은 댓글 좋아요 상태 사용
			$commentsStore.forEach((comment) => {
				if (comment.is_liked !== undefined) {
					commentLikes[comment.id] = comment.is_liked;
				}
				// 수정용 내용 초기화
				editContent[comment.id] = comment.content;
			});
		}
	});

	const API_URL = import.meta.env.VITE_API_URL;
	function getFileUrl(file_path: string) {
		if (!file_path) return '';
		return file_path.startsWith('http') ? file_path : API_URL + file_path;
	}
</script>

<div class="container mx-auto px-4 py-8">
	<div class="mb-4 flex items-center justify-between">
		<a href="/community/{data.slug}" class="text-lime-700 hover:text-lime-800 hover:underline flex-1">
			← 목록보기
		</a>
		<!-- 메타데이터 우측 배치 -->
		{#if data.post}
			<div class="flex items-center gap-3 text-gray-500 text-sm flex-shrink-0">
				<span>조회 {data.post.views || 0}</span>
				<div class="flex items-center gap-1">
					{#if data.post.user_id !== $user?.id}
						<Button variant="ghost" size="sm" onclick={handlePostLike} class="p-1 h-auto">
							{#if postLiked}
								<Heart class="h-4 w-4 fill-red-500 text-red-500" />
							{:else}
								<Heart class="h-4 w-4" />
							{/if}
							<span>{data.post.likes || 0}</span>
						</Button>
					{:else}
						<div class="flex items-center gap-1 p-1 text-gray-400">
							<Heart class="h-4 w-4" />
							<span>{data.post.likes || 0}</span>
						</div>
					{/if}
				</div>
				<span>댓글 {$commentsStore.length}</span>
			</div>
		{/if}
	</div>

	{#if data.post}
		<article>
			<header class="mb-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
				<h1 class="text-2xl font-bold text-gray-900 break-words">{data.post.title || '제목 없음'}</h1>
				<!-- 글자 크기 조절 버튼 -->
				<div class="flex gap-1 items-center self-end">
					<button aria-label="글자 작게" class="px-2 py-1 border rounded text-xs" onclick={decreaseFont}>A-</button>
					<button aria-label="글자 크게" class="px-2 py-1 border rounded text-xs" onclick={increaseFont}>A+</button>
				</div>
			</header>

			<!-- 첨부파일 표시 -->
		{#if data.post.attached_files && data.post.attached_files.length > 0}
			<div class="mt-6 space-y-4 flex flex-col gap-2 mb-6">
				<!-- <h4 class="font-semibold text-gray-700">첨부파일</h4> -->
				{#each data.post.attached_files as file}
					{#if file.mime_type && file.mime_type.startsWith('image/')}
						<!-- 이미지 미리보기 (썸네일 상태 확인) -->
						{#await checkThumbnailStatus(file.id)}
							<!-- 로딩 중 -->
							<div class="relative group">
								<img 
									src={getFileUrl(file.file_path)} 
									alt={file.original_name} 
									class="max-w-2xl rounded shadow cursor-pointer hover:opacity-90 transition-opacity" 
									
								/>
								<!-- 다운로드 버튼 (마우스 오버 시 표시) -->
								<div class="absolute bottom-2 left-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
									<a 
										href={`/api/upload/files/${file.id}/download`}
										download={file.original_name}
										class="bg-black bg-opacity-75 text-white p-2 rounded-full hover:bg-opacity-90 transition-all flex items-center justify-center"
										title="원본 다운로드"
										style="min-width: 36px; min-height: 36px;"
									>
										<Download class="h-4 w-4" />
									</a>
								</div>
							</div>
						{:then thumbnailData}
							<!-- 썸네일 상태 확인 완료 -->
							<div class="relative group">
								<img 
									src={thumbnailData.has_thumbnail ? getFileUrl(thumbnailData.thumbnail_url) : getFileUrl(file.file_path)} 
									alt={file.original_name} 
									class="max-w-2xl rounded shadow cursor-pointer hover:opacity-90 transition-opacity" 
									onclick={() => window.open(getFileUrl(file.file_path), '_blank')}
								/>
								<!-- 다운로드 버튼 (마우스 오버 시 표시) -->
								<div class="absolute bottom-2 left-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
									<a 
										href={`/api/upload/files/${file.id}/download`}
										download={file.original_name}
										class="bg-black bg-opacity-75 text-white p-2 rounded-full hover:bg-opacity-90 transition-all flex items-center justify-center"
										title="원본 다운로드"
										style="min-width: 36px; min-height: 36px;"
									>
										<Download class="h-4 w-4" />
									</a>
								</div>
							</div>
						{:catch error}
							<!-- 에러 발생 시 원본 표시 -->
							<div class="relative group">
								<img 
									src={getFileUrl(file.file_path)} 
									alt={file.original_name} 
									class="max-w-2xl rounded shadow cursor-pointer hover:opacity-90 transition-opacity" 
									onclick={() => window.open(getFileUrl(file.file_path), '_blank')}
								/>
								<!-- 다운로드 버튼 (마우스 오버 시 표시) -->
								<div class="absolute bottom-2 left-2 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
									<a 
										href={`/api/upload/files/${file.id}/download`}
										download={file.original_name}
										class="bg-black bg-opacity-75 text-white p-2 rounded-full hover:bg-opacity-90 transition-all flex items-center justify-center"
										title="원본 다운로드"
										style="min-width: 36px; min-height: 36px;"
									>
										<Download class="h-4 w-4" />
									</a>
								</div>
							</div>
						{/await}
					{:else if file.mime_type === 'application/pdf'}
						<!-- PDF 미리보기 -->
						<iframe src={getFileUrl(file.file_path)} class="w-full h-96 border rounded" title="첨부 PDF"></iframe>
						{#if canDownloadFiles}
							<a href={getFileUrl(file.file_path)} download class="text-blue-600 underline block mt-1">PDF 다운로드</a>
						{:else}
							<span class="text-gray-500 block mt-1">다운로드 권한이 없습니다</span>
						{/if}
					{:else}
						<!-- 일반 파일 다운로드 -->
						{#if canDownloadFiles}
							<a href={getFileUrl(file.file_path)} download class="text-blue-600 underline">
								{file.original_name}
							</a>
						{:else}
							<span class="text-gray-500">{file.original_name} (다운로드 권한 없음)</span>
						{/if}
					{/if}
				{/each}
			</div>
		{/if}

			<div class="prose max-w-none mb-6" style="font-size: {fontSize}em;">
				{@html data.post.content || '내용 없음'}
			</div>

			<footer class="flex items-center gap-2 pt-4 border-t border-gray-100">
				<div class="flex h-8 w-8 items-center justify-center rounded-full bg-gray-300">
					<span class="text-sm text-gray-600">{data.post.user_name?.[0] || 'U'}</span>
				</div>
				<span class="text-gray-500">{data.post.user_name || '익명'}</span>
				{#if data.post.is_notice}
					<Badge variant="secondary">공지</Badge>
				{/if}
			</footer>
		</article>

		<!-- 게시글 액션 버튼들 -->
		{#if canEditCurrentPost || canDeleteCurrentPost || canCreateReply}
			<div class="flex gap-2 mt-4">
				{#if canCreateReply}
					<Button 
						variant="outline" 
						onclick={() => goto(`/community/${data.slug}/reply/${data.post.id}`)} 
						size="sm"
					>
						답글 작성
					</Button>
				{/if}
				{#if canEditCurrentPost}
					<Button onclick={() => goto(`/community/${data.slug}/edit/${data.post.id}`)} size="sm">수정</Button>
				{/if}
				{#if canDeleteCurrentPost}
					<Button variant="destructive" onclick={handleDeletePost} size="sm">삭제</Button>
				{/if}
			</div>
		{/if}

		

		<!-- 댓글 섹션 -->
		<div class="mt-8">
			<h3 class="text-lg font-semibold mb-4 flex items-center gap-2">
				<MessageCircle class="h-5 w-5" />
				댓글 ({$commentsStore.length})
			</h3>

			<!-- 댓글 작성 폼 -->
			{#if canCreateComment}
				<div class="bg-gray-50 rounded-lg mb-6 sm:p-4 p-2">
					<Textarea
						bind:value={newComment}
						placeholder="댓글을 입력하세요..."
						class="w-full mb-2"
						rows="3"
					/>
					<div class="sm:flex sm:justify-end">
						<Button 
							onclick={handleSubmitComment}
							disabled={isSubmitting || !newComment.trim()}
							class="sm:w-auto w-full"
						>
							<Send class="h-4 w-4" />
						</Button>
					</div>
				</div>
			{:else}
				<div class="text-center py-4 text-gray-500">
					댓글 작성 권한이 없습니다.
				</div>
			{/if}

			<!-- 댓글 목록 -->
			<div class="space-y-4">
				{#each $commentsStore as comment (comment.id)}
					{@const indentLevel = (comment.depth || 0) * 32}
					<div class="border-b border-gray-100 pb-4" style="margin-left: {indentLevel}px;">
						<!-- 대댓글 표시 아이콘 -->
						{#if comment.depth && comment.depth > 0}
							<div class="text-gray-400 text-sm mb-2">
								{'└'.repeat(comment.depth)} ↳ 답글
							</div>
						{/if}
						
						<div class="flex items-start justify-between">
							<div class="flex-1">
								<div class="flex items-center gap-2 mb-2">
									<div class="flex h-6 w-6 items-center justify-center rounded-full bg-gray-200 text-xs">
										{comment.user_name?.[0] || 'U'}
									</div>
									<span class="text-sm font-medium">{comment.user_name || '익명'}</span>
									<span class="text-xs text-gray-500">{formatDate(comment.created_at)}</span>
								</div>
								<div class="text-sm text-gray-700">
									{comment.content}
								</div>
							</div>
						</div>
						
						<div class="flex items-center gap-4 mt-2 flex-wrap">
							{#if $user}
								<Button 
									variant="ghost" 
									size="sm" 
									onclick={() => handleCommentLike(comment.id)}
									class="flex items-center gap-1 p-1 h-auto"
								>
									{#if commentLikes[comment.id]}
										<Heart class="h-3 w-3 fill-red-500 text-red-500" />
									{:else}
										<Heart class="h-3 w-3" />
									{/if}
									<span class="text-xs">{comment.likes || 0}</span>
								</Button>
								
								<!-- 답글 작성 버튼 (최대 깊이 제한) -->
								{#if canCreateReply && (!comment.depth || comment.depth < 3)}
									<Button 
										variant="ghost" 
										size="sm" 
										onclick={() => showReplyForm[comment.id] = !showReplyForm[comment.id]}
										class="flex items-center gap-1 p-1 h-auto text-blue-600"
									>
										<MessageCircle class="h-3 w-3" />
										<span class="text-xs">답글</span>
									</Button>
								{/if}
								
								<!-- 수정/삭제 버튼 (작성자 본인만) -->
								{#if comment.user_id === $user?.id}
									<Button 
										variant="ghost" 
										size="sm" 
										onclick={() => editingComment[comment.id] = !editingComment[comment.id]}
										class="flex items-center gap-1 p-1 h-auto text-gray-600"
									>
										<span class="text-xs">수정</span>
									</Button>
									<Button 
										variant="ghost" 
										size="sm" 
										onclick={() => handleDeleteComment(comment.id)}
										class="flex items-center gap-1 p-1 h-auto text-red-600"
									>
										<span class="text-xs">삭제</span>
									</Button>
								{/if}
							{:else}
								<div class="flex items-center gap-1 p-1 h-auto text-gray-400">
									<Heart class="h-3 w-3" />
									<span class="text-xs">{comment.likes || 0}</span>
								</div>
							{/if}
						</div>
						
						<!-- 답글 작성 폼 -->
						{#if showReplyForm[comment.id] && $user}
							<div class="mt-4 bg-gray-50 rounded-lg p-4 border-l-4 border-blue-200">
								<Textarea
									bind:value={replyContent[comment.id]}
									placeholder="답글을 입력하세요..."
									class="w-full mb-2"
									rows="3"
								/>
								<div class="flex gap-2">
									<Button 
										size="sm" 
										onclick={() => handleCreateReply(comment.id)}
										disabled={!replyContent[comment.id]?.trim()}
									>
										<Send class="h-3 w-3 mr-1" />
										답글 작성
									</Button>
									<Button 
										variant="outline" 
										size="sm" 
										onclick={() => {
											showReplyForm[comment.id] = false;
											replyContent[comment.id] = '';
										}}
									>
										취소
									</Button>
								</div>
							</div>
						{/if}
						
						<!-- 댓글 수정 폼 -->
						{#if editingComment[comment.id] && $user && comment.user_id === $user?.id}
							<div class="mt-4 bg-gray-50 rounded-lg p-4 border-l-4 border-yellow-200">
								<Textarea
									bind:value={editContent[comment.id]}
									class="w-full mb-2"
									rows="3"
								/>
								<div class="flex gap-2">
									<Button 
										size="sm" 
										onclick={() => handleUpdateComment(comment.id)}
										disabled={!editContent[comment.id]?.trim()}
									>
										수정 완료
									</Button>
									<Button 
										variant="outline" 
										size="sm" 
										onclick={() => {
											editingComment[comment.id] = false;
											editContent[comment.id] = comment.content;
										}}
									>
										취소
									</Button>
								</div>
							</div>
						{/if}
					</div>
				{/each}
			</div>

			{#if $commentsStore.length === 0}
				<div class="text-center py-8 text-gray-500">
					아직 댓글이 없습니다.
				</div>
			{/if}
		</div>
	{:else}
		<div class="text-center py-8">
			<p>게시글을 불러올 수 없습니다.</p>
		</div>
	{/if}
</div>

