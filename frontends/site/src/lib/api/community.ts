import type { Board, Category, Post, PostDetail, Comment, CommentDetail, BoardStats, ApiResponse } from '../types/community.js';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// 인증 토큰 가져오기
function getAuthHeaders(): HeadersInit {
  const token = localStorage.getItem('access_token');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
}

export async function fetchBoards(): Promise<Board[]> {
  const res = await fetch(`${API_BASE}/api/community/boards`);
  const json: ApiResponse<Board[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function fetchCategories(boardId: string): Promise<Category[]> {
  const res = await fetch(`${API_BASE}/api/community/boards/${boardId}/categories`);
  const json: ApiResponse<Category[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function fetchPosts(params: {
  search?: string;
  board_id?: string;
  category_id?: string;
  tags?: string;
  sort?: string;
  page?: number;
  limit?: number
}): Promise<PostDetail[]> {
  const url = new URL(`${API_BASE}/api/community/posts`, window.location.origin);
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
  });
  const res = await fetch(url.toString().replace(window.location.origin, ''));
  const json: ApiResponse<PostDetail[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function fetchPost(post_id: string): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}`);
  const json: ApiResponse<PostDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function createPost(data: Partial<Post>): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/posts`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(data)
  });
  const json: ApiResponse<PostDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function updatePost(post_id: string, data: Partial<Post>): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(data)
  });
  const json: ApiResponse<PostDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function deletePost(post_id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

export async function fetchComments(post_id: string): Promise<CommentDetail[]> {
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}/comments`);
  const json: ApiResponse<CommentDetail[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function createComment(data: Partial<Comment>): Promise<CommentDetail> {
  const res = await fetch(`${API_BASE}/api/community/comments`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(data)
  });
  const json: ApiResponse<CommentDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function updateComment(comment_id: string, data: Partial<Comment>): Promise<CommentDetail> {
  const res = await fetch(`${API_BASE}/api/community/comments/${comment_id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(data)
  });
  const json: ApiResponse<CommentDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function deleteComment(comment_id: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/community/comments/${comment_id}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
} 