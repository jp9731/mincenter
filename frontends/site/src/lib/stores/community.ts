import { writable, derived, get } from 'svelte/store';
import type { Post, Comment, Category, Tag, PostFilter, PostsResponse, PostDetail, CommentDetail, Board } from '$lib/types/community.js';
import * as api from '$lib/api/community.js';

const API_URL = import.meta.env.VITE_API_URL || 'https://api.mincenter.kr';

// 게시글 목록
export const posts = writable<PostDetail[]>([]);
export const currentPost = writable<PostDetail | null>(null);
export const comments = writable<CommentDetail[]>([]);
export const categories = writable<Category[]>([]);
export const tags = writable<Tag[]>([]);
export const boards = writable<Board[]>([]);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// 페이지네이션 정보
export const pagination = writable<{
  page: number;
  limit: number;
  total: number;
  total_pages: number;
} | null>(null);

// 게시글 필터
export const postFilter = writable<PostFilter>({
  search: '',
  board_id: '',
  category_id: '',
  tags: [],
  sort: 'latest',
  page: 1,
  limit: 10
});

// 게시글 목록 조회
export async function fetchPosts(filter?: PostFilter) {
  isLoading.set(true);
  error.set(null);

  try {
    const currentFilter = filter || get(postFilter);
    const params = {
      search: currentFilter.search,
      board_id: currentFilter.board_id,
      category_id: currentFilter.category_id,
      tags: currentFilter.tags.join(','),
      sort: currentFilter.sort,
      page: currentFilter.page,
      limit: currentFilter.limit
    };

    const response = await api.fetchPosts(params);
    posts.set(response.data || []);
    
    // 페이지네이션 정보 저장
    if (response.pagination) {
      pagination.set({
        page: response.pagination.page,
        limit: response.pagination.limit,
        total: response.pagination.total,
        total_pages: response.pagination.total_pages
      });
    } else {
      pagination.set(null);
    }
  } catch (e: any) {
    error.set(e.message || '게시글을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// slug 기반 게시글 목록 조회
export async function fetchPostsBySlug(slug: string, filter?: PostFilter, append: boolean = false) {
  isLoading.set(true);
  error.set(null);

  try {
    const currentFilter = filter || get(postFilter);
    const params = {
      search: currentFilter.search,
      board_id: currentFilter.board_id,
      category_id: currentFilter.category_id,
      tags: currentFilter.tags.join(','),
      sort: currentFilter.sort,
      page: currentFilter.page,
      limit: currentFilter.limit
    };

    const response = await api.fetchPostsBySlug(slug, params);
    if (append) {
      posts.update(prev => [...prev, ...(response.data || [])]);
    } else {
      posts.set(response.data || []);
    }
    // 페이지네이션 정보 저장
    if (response.pagination) {
      pagination.set({
        page: response.pagination.page,
        limit: response.pagination.limit,
        total: response.pagination.total,
        total_pages: response.pagination.total_pages
      });
    } else {
      pagination.set(null);
    }
  } catch (e: any) {
    error.set(e.message || '게시글을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 상세 조회
export async function fetchPost(id: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const data = await api.fetchPost(id);
    currentPost.set(data);
    await loadComments(id);
  } catch (e: any) {
    error.set(e.message || '게시글을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 작성
export async function createPost(post: Partial<Post>) {
  isLoading.set(true);
  error.set(null);

  try {
    const data = await api.createPost(post);
    posts.update(posts => [data, ...posts]);
    return data;
  } catch (e: any) {
    error.set(e.message || '게시글 작성에 실패했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// slug 기반 게시글 작성
export async function createPostBySlug(slug: string, post: Partial<Post>) {
  isLoading.set(true);
  error.set(null);

  try {
    const data = await api.createPostBySlug(slug, post);
    posts.update(posts => [data, ...posts]);
    return data;
  } catch (e: any) {
    error.set(e.message || '게시글 작성에 실패했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// 게시글 수정
export async function updatePost(postId: string, data: Partial<Post>) {
  isLoading.set(true);
  error.set(null);

  try {
    const updatedPost = await api.updatePost(postId, data);
    currentPost.set(updatedPost);

    // 목록에서도 업데이트
    posts.update(currentPosts =>
      currentPosts.map(post =>
        post.id === postId ? updatedPost : post
      )
    );

    return updatedPost;
  } catch (e: any) {
    error.set(e.message || '게시글 수정에 실패했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// 게시글 삭제
export async function deletePost(postId: string) {
  isLoading.set(true);
  error.set(null);

  try {
    await api.deletePost(postId);
    currentPost.set(null);

    // 목록에서도 제거
    posts.update(currentPosts =>
      currentPosts.filter(post => post.id !== postId)
    );
  } catch (e: any) {
    error.set(e.message || '게시글 삭제에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 댓글 목록 조회
export async function loadComments(postId: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const data = await api.fetchComments(postId);
    comments.set(data);
  } catch (e: any) {
    error.set(e.message || '댓글을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 댓글 작성
export async function createComment(data: Partial<Comment>) {
  isLoading.set(true);
  error.set(null);

  try {
    const comment = await api.createComment(data);
    await loadComments(data.post_id!);

    // 게시글의 댓글 수 업데이트
    currentPost.update(post => {
      if (post) {
        return { ...post, comment_count: (post.comment_count || 0) + 1 };
      }
      return post;
    });

    return comment;
  } catch (e: any) {
    error.set(e.message || '댓글 작성에 실패했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// 댓글 수정
export async function updateComment(commentId: string, data: Partial<Comment>) {
  isLoading.set(true);
  error.set(null);

  try {
    const comment = await api.updateComment(commentId, data);
    await loadComments(data.post_id!);
    return comment;
  } catch (e: any) {
    error.set(e.message || '댓글 수정에 실패했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// 댓글 삭제
export async function deleteComment(commentId: string, postId: string) {
  isLoading.set(true);
  error.set(null);

  try {
    await api.deleteComment(commentId);
    await loadComments(postId);

    // 게시글의 댓글 수 업데이트
    currentPost.update(post => {
      if (post) {
        return { ...post, comment_count: Math.max(0, (post.comment_count || 0) - 1) };
      }
      return post;
    });
  } catch (e: any) {
    error.set(e.message || '댓글 삭제에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 좋아요 토글
export async function togglePostLike(postId: string) {
  try {
    const response = await api.togglePostLike(postId);
    
    // 좋아요 상태에 따라 카운트 업데이트
    const isLiked = response.data?.liked;
    
    posts.update(currentPosts =>
      currentPosts.map(post =>
        post.id === postId ? { 
          ...post, 
          likes: isLiked ? (post.likes || 0) + 1 : Math.max(0, (post.likes || 0) - 1) 
        } : post
      )
    );

    currentPost.update(post => {
      if (post && post.id === postId) {
        return { 
          ...post, 
          likes: isLiked ? (post.likes || 0) + 1 : Math.max(0, (post.likes || 0) - 1) 
        };
      }
      return post;
    });

    return response.data;
  } catch (e: any) {
    error.set(e.message || '좋아요 처리에 실패했습니다.');
    throw e;
  }
}

// 게시글 좋아요 상태 확인
export async function getPostLikeStatus(postId: string) {
  try {
    const response = await api.getPostLikeStatus(postId);
    return response.data?.liked || false;
  } catch (e: any) {
    error.set(e.message || '좋아요 상태 확인에 실패했습니다.');
    return false;
  }
}

// 댓글 좋아요 토글
export async function toggleCommentLike(commentId: string) {
  try {
    const response = await api.toggleCommentLike(commentId);
    
    // 좋아요 상태에 따라 카운트 업데이트
    const isLiked = response.data?.liked;
    
    comments.update(currentComments =>
      currentComments.map(comment =>
        comment.id === commentId ? { 
          ...comment, 
          likes: isLiked ? (comment.likes || 0) + 1 : Math.max(0, (comment.likes || 0) - 1) 
        } : comment
      )
    );

    return response.data;
  } catch (e: any) {
    error.set(e.message || '댓글 좋아요 처리에 실패했습니다.');
    throw e;
  }
}

// 댓글 좋아요 상태 확인
export async function getCommentLikeStatus(commentId: string) {
  try {
    const response = await api.getCommentLikeStatus(commentId);
    return response.data?.liked || false;
  } catch (e: any) {
    error.set(e.message || '댓글 좋아요 상태 확인에 실패했습니다.');
    return false;
  }
}

// 게시판 목록 조회
export async function loadBoards() {
  try {
    const data = await api.fetchBoards();
    boards.set(data);
  } catch (e: any) {
    error.set(e.message || '게시판 목록을 불러오는데 실패했습니다.');
  }
}

// 게시판 목록 조회 (직접 반환)
export async function fetchBoards(): Promise<Board[]> {
  try {
    const data = await api.fetchBoards();
    boards.set(data);
    return data;
  } catch (e: any) {
    error.set(e.message || '게시판 목록을 불러오는데 실패했습니다.');
    throw e;
  }
}

// 카테고리 목록 조회
export async function loadCategories(boardId: string) {
  try {
    const data = await api.fetchCategories(boardId);
    categories.set(data);
  } catch (e: any) {
    error.set(e.message || '카테고리 목록을 불러오는데 실패했습니다.');
  }
}

// 카테고리 목록 조회 (기존 함수 - 호환성 유지)
export async function fetchCategories() {
  // 이 함수는 더 이상 사용되지 않음
  // loadCategories(boardId) 사용 권장
}

// 태그 목록 조회 (기존 함수 - 호환성 유지)
export async function fetchTags() {
  // 태그 기능은 현재 구현되지 않음
  tags.set([]);
}

// 파일 업로드
export async function uploadFile(file: File, type: 'posts' | 'profiles' | 'site' = 'posts'): Promise<string> {
  try {
    const url = await api.uploadFile(file, type);
    return url;
  } catch (e: any) {
    error.set(e.message || '파일 업로드에 실패했습니다.');
    throw e;
  }
}