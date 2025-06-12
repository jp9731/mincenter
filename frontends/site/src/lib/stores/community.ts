import { writable } from 'svelte/store';
import type { Post, Comment, Category, Tag, PostFilter } from '$lib/types/community';
import { API_URL } from '$lib/config';

// 게시글 목록
export const posts = writable<Post[]>([]);
export const currentPost = writable<Post | null>(null);
export const comments = writable<Comment[]>([]);
export const categories = writable<Category[]>([]);
export const tags = writable<Tag[]>([]);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// 게시글 필터
export const postFilter = writable<PostFilter>({
  sort: 'latest'
});

// 게시글 목록 조회
export async function fetchPosts(filter: PostFilter) {
  isLoading.set(true);
  error.set(null);

  try {
    const queryParams = new URLSearchParams();
    if (filter.category) queryParams.append('category', filter.category);
    if (filter.tags?.length) queryParams.append('tags', filter.tags.join(','));
    if (filter.search) queryParams.append('search', filter.search);
    queryParams.append('sort', filter.sort);

    const response = await fetch(`${API_URL}/api/posts?${queryParams}`);
    if (!response.ok) throw new Error('게시글을 불러오는데 실패했습니다.');

    const data = await response.json();
    posts.set(data);
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 상세 조회
export async function fetchPost(id: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/posts/${id}`);
    if (!response.ok) throw new Error('게시글을 불러오는데 실패했습니다.');

    const data = await response.json();
    currentPost.set(data);
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 작성
export async function createPost(post: Omit<Post, 'id' | 'author' | 'likes' | 'comments' | 'views' | 'createdAt' | 'updatedAt'>) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/posts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(post)
    });

    if (!response.ok) throw new Error('게시글 작성에 실패했습니다.');

    const data = await response.json();
    posts.update(posts => [data, ...posts]);
    return data;
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// 댓글 작성
export async function createComment(comment: Omit<Comment, 'id' | 'author' | 'likes' | 'createdAt' | 'updatedAt'>) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/comments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(comment)
    });

    if (!response.ok) throw new Error('댓글 작성에 실패했습니다.');

    const data = await response.json();
    comments.update(comments => [data, ...comments]);
    return data;
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
    return null;
  } finally {
    isLoading.set(false);
  }
}

// 게시글 좋아요
export async function likePost(postId: string) {
  try {
    const response = await fetch(`${API_URL}/api/posts/${postId}/like`, {
      method: 'POST'
    });

    if (!response.ok) throw new Error('좋아요 처리에 실패했습니다.');

    const data = await response.json();
    currentPost.update(post => post ? { ...post, likes: data.likes } : null);
    posts.update(posts =>
      posts.map(post => post.id === postId ? { ...post, likes: data.likes } : post)
    );
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
  }
}

// 카테고리 목록 조회
export async function fetchCategories() {
  try {
    const response = await fetch(`${API_URL}/api/categories`);
    if (!response.ok) throw new Error('카테고리를 불러오는데 실패했습니다.');

    const data = await response.json();
    categories.set(data);
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
  }
}

// 태그 목록 조회
export async function fetchTags() {
  try {
    const response = await fetch(`${API_URL}/api/tags`);
    if (!response.ok) throw new Error('태그를 불러오는데 실패했습니다.');

    const data = await response.json();
    tags.set(data);
  } catch (e) {
    error.set(e instanceof Error ? e.message : '알 수 없는 오류가 발생했습니다.');
  }
}