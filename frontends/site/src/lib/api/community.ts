import type { Board, Category, Post, PostDetail, Comment, CommentDetail, BoardStats, ApiResponse } from '../types/community.js';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:18080';

// 인증 토큰 가져오기
function getAuthHeaders(): HeadersInit {
  const token = localStorage.getItem('token') || localStorage.getItem('auth_token');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
}

function parseCsvOption(val: string[] | string | undefined | null): string[] {
  if (Array.isArray(val)) return val;
  if (typeof val === 'string') return val.split(',').map(s => s.trim()).filter(Boolean);
  return [];
}

export async function fetchBoards(): Promise<Board[]> {
  const res = await fetch(`${API_BASE}/api/community/boards`);
  const json: ApiResponse<Board[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return (json.data || []).map(board => ({
    ...board,
    allowed_file_types: parseCsvOption(board.allowed_file_types),
    allowed_iframe_domains: parseCsvOption((board as any).allowed_iframe_domains),
  }));
}

export async function fetchCategories(boardSlug: string): Promise<Category[]> {
  const res = await fetch(`${API_BASE}/api/community/boards/${boardSlug}/categories`);
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
}): Promise<{ data: PostDetail[]; pagination?: { page: number; limit: number; total: number; total_pages: number } }> {
  const url = new URL(`${API_BASE}/api/community/posts`, window.location.origin);
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
  });
  const res = await fetch(url.toString().replace(window.location.origin, ''));
  const json: ApiResponse<PostDetail[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return {
    data: json.data,
    pagination: json.pagination
  };
}

export async function fetchPost(post_id: string): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}`);
  const json: ApiResponse<PostDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function createPost(data: Partial<Board>): Promise<PostDetail> {
  const payload = {
    ...data,
    allowed_file_types: Array.isArray(data.allowed_file_types) ? data.allowed_file_types.join(',') : data.allowed_file_types,
    allowed_iframe_domains: Array.isArray(data.allowed_iframe_domains) ? data.allowed_iframe_domains.join(',') : data.allowed_iframe_domains,
  };
  const res = await fetch(`${API_BASE}/api/community/posts`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(payload)
  });
  const json: ApiResponse<PostDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

export async function updatePost(post_id: string, data: Partial<Board>): Promise<PostDetail> {
  const payload = {
    ...data,
    allowed_file_types: Array.isArray(data.allowed_file_types) ? data.allowed_file_types.join(',') : data.allowed_file_types,
    allowed_iframe_domains: Array.isArray(data.allowed_iframe_domains) ? data.allowed_iframe_domains.join(',') : data.allowed_iframe_domains,
  };
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(payload)
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

// slug 기반 API 함수들
export async function fetchBoardBySlug(slug: string): Promise<Board> {
  const res = await fetch(`${API_BASE}/api/community/boards/${slug}`);
  const json: ApiResponse<Board> = await res.json();
  if (!json.success) throw new Error(json.message);
  const board = json.data;
  return {
    ...board,
    allowed_file_types: parseCsvOption(board.allowed_file_types),
    allowed_iframe_domains: parseCsvOption((board as any).allowed_iframe_domains),
  };
}

export async function fetchPostsBySlug(slug: string, params: {
  search?: string;
  category_id?: string;
  tags?: string;
  sort?: string;
  page?: number;
  limit?: number
}): Promise<{ data: PostDetail[]; pagination?: { page: number; limit: number; total: number; total_pages: number } }> {
  const url = new URL(`${API_BASE}/api/community/boards/${slug}/posts`, window.location.origin);
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
  });
  const res = await fetch(url.toString().replace(window.location.origin, ''));
  const json: ApiResponse<PostDetail[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return {
    data: json.data,
    pagination: json.pagination
  };
}

export async function createPostBySlug(slug: string, data: Partial<Post>): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/boards/${slug}/posts`, {
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

// 파일 업로드 API 함수
export async function uploadFile(file: File, type: 'posts' | 'profiles' | 'site' = 'posts', purpose?: string): Promise<string> {
  const formData = new FormData();
  formData.append('file', file);
  
  let endpoint = '';
  switch (type) {
    case 'posts':
      endpoint = '/api/upload/posts';
      break;
    case 'profiles':
      endpoint = '/api/upload/profiles';
      break;
    case 'site':
      endpoint = '/api/upload/site';
      break;
  }

  const res = await fetch(`${API_BASE}${endpoint}`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: formData
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`Upload failed: ${res.status} ${errorText}`);
  }

  const json: ApiResponse<{ url: string }> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data.url;
}

// 파일 삭제 API
export async function deleteFile(fileId: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/upload/files/${fileId}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 게시글 첨부파일 삭제 API
export async function deletePostAttachment(postId: string, fileId: string): Promise<void> {
  const res = await fetch(`${API_BASE}/api/community/posts/${postId}/attachments/${fileId}`, {
    method: 'DELETE',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 좋아요 관련 API 함수들
export async function togglePostLike(postId: string): Promise<ApiResponse<{ liked: boolean; action: string }>> {
  const res = await fetch(`${API_BASE}/api/community/posts/${postId}/like`, {
    method: 'POST',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<{ liked: boolean; action: string }> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json;
}

export async function getPostLikeStatus(postId: string): Promise<ApiResponse<{ liked: boolean }>> {
  const res = await fetch(`${API_BASE}/api/community/posts/${postId}/like/status`, {
    headers: getAuthHeaders()
  });
  const json: ApiResponse<{ liked: boolean }> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json;
}

export async function toggleCommentLike(commentId: string): Promise<ApiResponse<{ liked: boolean; action: string }>> {
  const res = await fetch(`${API_BASE}/api/community/comments/${commentId}/like`, {
    method: 'POST',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<{ liked: boolean; action: string }> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json;
}

export async function getCommentLikeStatus(commentId: string): Promise<ApiResponse<{ liked: boolean }>> {
  const res = await fetch(`${API_BASE}/api/community/comments/${commentId}/like/status`, {
    headers: getAuthHeaders()
  });
  const json: ApiResponse<{ liked: boolean }> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json;
} 

// 최근 게시글 조회 (홈페이지용)
export async function getRecentPosts(params?: {
  slugs?: string; // 콤마로 구분된 slug 목록
  limit?: number; // 조회할 게시글 수
}): Promise<PostDetail[]> {
  const searchParams = new URLSearchParams();
  
  if (params?.slugs) {
    searchParams.append('slugs', params.slugs);
  }
  
  if (params?.limit) {
    searchParams.append('limit', params.limit.toString());
  }
  
  const url = `${API_BASE}/api/community/posts/recent${searchParams.toString() ? `?${searchParams.toString()}` : ''}`;
  
  console.log('getRecentPosts URL:', url);
  
  const res = await fetch(url);
  console.log('getRecentPosts response status:', res.status);
  
  const json: ApiResponse<PostDetail[]> = await res.json();
  console.log('getRecentPosts response data:', json);
  
  if (!json.success || !json.data) {
    throw new Error(json.message || '최근 게시글을 불러오는데 실패했습니다.');
  }
  
  return json.data;
} 