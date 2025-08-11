import type { Board, Category, Post, PostDetail, Comment, CommentDetail, BoardStats, ApiResponse, CreateReplyRequest } from '../types/community.js';

// 업로드 응답 타입 정의
interface UploadResponse {
  filename: string;
  url: string;
  size: number;
  mime_type: string;
  file_info: {
    id: string;
    original_name: string;
    file_path: string;
    file_size: number;
    mime_type: string;
    file_type: string;
    url: string;
  };
  thumbnail_url?: string;
}

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:18080';

// 인증 토큰 가져오기
function getAuthHeaders(): HeadersInit {
  const token = localStorage.getItem('token') || localStorage.getItem('auth_token');
  console.log('🔐 인증 토큰 확인:', token ? '토큰 있음' : '토큰 없음');
  if (token) {
    console.log('🔐 토큰 길이:', token.length);
    console.log('🔐 토큰 시작 부분:', token.substring(0, 20) + '...');
  }
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
  console.log('🗑️ 게시글 삭제 시작:', post_id);
  console.log('🌐 API URL:', `${API_BASE}/api/community/posts/${post_id}`);
  
  const headers = getAuthHeaders();
  console.log('🔐 요청 헤더:', headers);
  
  const res = await fetch(`${API_BASE}/api/community/posts/${post_id}`, {
    method: 'DELETE',
    headers
  });
  
  console.log('📡 응답 상태:', res.status, res.statusText);
  
  if (!res.ok) {
    let errorMessage = `삭제 실패: ${res.status} ${res.statusText}`;
    
    try {
      const errorText = await res.text();
      console.error('❌ 삭제 실패 응답:', errorText);
      
      // JSON 응답인지 확인
      try {
        const errorJson = JSON.parse(errorText);
        if (errorJson.message) {
          errorMessage = errorJson.message;
        }
      } catch (parseError) {
        // JSON이 아닌 경우 그대로 텍스트 사용
        if (errorText.trim()) {
          errorMessage = errorText;
        }
      }
    } catch (textError) {
      console.error('응답 텍스트 읽기 실패:', textError);
    }
    
    throw new Error(errorMessage);
  }
  
  try {
    const json: ApiResponse<null> = await res.json();
    if (!json.success) {
      console.log('❌ API 응답:', json.message);
      throw new Error(json.message || '삭제 처리 중 오류가 발생했습니다.');
    }
    console.log('✅ 게시글 삭제 성공');
  } catch (jsonError) {
    console.error('JSON 파싱 실패:', jsonError);
    // 204 No Content 등의 경우 JSON이 없을 수 있으므로 성공으로 처리
    if (res.status === 204 || res.status === 200) {
      console.log('✅ 게시글 삭제 성공 (JSON 없음)');
      return;
    }
    throw new Error('응답 처리 중 오류가 발생했습니다.');
  }
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

// 답글 생성
export async function createReplyBySlug(slug: string, data: CreateReplyRequest): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/boards/${slug}/replies`, {
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

// 게시글 상세 조회
export async function getPostDetail(postId: string): Promise<PostDetail> {
  const res = await fetch(`${API_BASE}/api/community/posts/${postId}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<PostDetail> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

// 게시판 상세 조회 (slug 기반)
export async function getBoardBySlug(slug: string): Promise<Board> {
  const res = await fetch(`${API_BASE}/api/community/boards/${slug}`, {
    method: 'GET',
    headers: getAuthHeaders()
  });
  const json: ApiResponse<Board> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

// 파일 업로드 API 함수 (청크 단위 업로드)
export async function uploadFile(file: File, type: 'posts' | 'profiles' | 'site' = 'posts', purpose?: string): Promise<string> {
  // 파일 크기 제한 (50MB)
  const MAX_FILE_SIZE = 50 * 1024 * 1024;
  if (file.size > MAX_FILE_SIZE) {
    throw new Error(`파일 크기가 너무 큽니다. 최대 ${formatFileSize(MAX_FILE_SIZE)}까지 업로드 가능합니다.`);
  }
  
  console.log(`파일 업로드 시작: ${file.name} (${formatFileSize(file.size)})`);
  
  // 1MB 이상 파일은 청크 단위로 업로드
  if (file.size > 1024 * 1024) {
    return uploadFileInChunks(file, type, purpose);
  }
  
  // 작은 파일은 기존 방식 사용
  return uploadFileSimple(file, type, purpose);
}

// 파일 크기 포맷팅 함수
function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// 청크 단위 업로드 함수
async function uploadFileInChunks(file: File, type: 'posts' | 'profiles' | 'site' = 'posts', purpose?: string): Promise<string> {
  const CHUNK_SIZE = 512 * 1024; // 512KB 청크
  const totalChunks = Math.ceil(file.size / CHUNK_SIZE);
  
  console.log(`청크 업로드 시작: ${file.name} (${totalChunks}개 청크, 각 ${formatFileSize(CHUNK_SIZE)})`);
  
  // 임시 파일 ID 생성
  const tempFileId = `temp_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  
  for (let chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
    const start = chunkIndex * CHUNK_SIZE;
    const end = Math.min(start + CHUNK_SIZE, file.size);
    const chunk = file.slice(start, end);
    
    const formData = new FormData();
    formData.append('file', chunk, file.name);
    formData.append('chunkIndex', chunkIndex.toString());
    formData.append('totalChunks', totalChunks.toString());
    formData.append('tempFileId', tempFileId);
    formData.append('originalSize', file.size.toString());
    formData.append('originalName', file.name);
    
    let endpoint = '';
    switch (type) {
      case 'posts':
        endpoint = '/api/upload/posts/chunk';
        break;
      case 'profiles':
        endpoint = '/api/upload/profiles/chunk';
        break;
      case 'site':
        endpoint = '/api/upload/site/chunk';
        break;
    }

    console.log(`청크 ${chunkIndex + 1}/${totalChunks} 업로드 중... (${formatFileSize(chunk.size)})`);
    console.log(`요청 URL: ${API_BASE}${endpoint}`);
    console.log(`FormData 내용:`, {
      chunkIndex,
      totalChunks,
      tempFileId,
      originalSize: file.size,
      originalName: file.name,
      chunkSize: chunk.size
    });
    
    try {
      const res = await fetch(`${API_BASE}${endpoint}`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: formData
      });

      console.log(`응답 상태: ${res.status} ${res.statusText}`);
      
      if (!res.ok) {
        const errorText = await res.text();
        console.error(`서버 오류: ${errorText}`);
        throw new Error(`청크 업로드 실패: ${res.status} ${errorText}`);
      }

      const json: ApiResponse<UploadResponse> = await res.json();
      console.log(`서버 응답:`, json);
      
      if (!json.success) throw new Error(json.message);
      
      // 마지막 청크인 경우 URL 반환 (URL이 있고 빈 문자열이 아닌 경우)
      if (json.data.url && json.data.url.trim() !== '') {
        console.log(`청크 업로드 완료: ${file.name}`);
        return json.data.url;
      }
      
      console.log(`청크 ${chunkIndex + 1} 완료, 다음 청크 대기 중...`);
      
    } catch (error) {
      console.error(`청크 ${chunkIndex + 1} 업로드 실패:`, error);
      throw error;
    }
    
    // 청크 간 짧은 대기 (서버 부하 방지)
    await new Promise(resolve => setTimeout(resolve, 100));
  }
  
  console.error(`모든 청크 업로드 완료했지만 최종 URL을 받지 못함`);
  throw new Error('청크 업로드가 완료되지 않았습니다.');
}

// 기존 단순 업로드 함수
async function uploadFileSimple(file: File, type: 'posts' | 'profiles' | 'site' = 'posts', purpose?: string): Promise<string> {
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

  // 타임아웃 설정 (5분)
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 5 * 60 * 1000);

  try {
    const res = await fetch(`${API_BASE}${endpoint}`, {
      method: 'POST',
      headers: getAuthHeaders(),
      body: formData,
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`Upload failed: ${res.status} ${errorText}`);
    }

    const json: ApiResponse<{ url: string }> = await res.json();
    if (!json.success) throw new Error(json.message);
    return json.data.url;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error('Upload timeout: 파일 업로드가 시간 초과되었습니다.');
    }
    throw error;
  }
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

// 썸네일 상태 확인
export async function checkThumbnailStatus(fileId: string): Promise<{
  has_thumbnail: boolean;
  thumbnail_url?: string;
  processing_status?: string;
}> {
  const res = await fetch(`${API_BASE}/api/upload/files/${fileId}/thumbnail-status`);
  const json: ApiResponse<{
    has_thumbnail: boolean;
    thumbnail_url?: string;
    processing_status?: string;
  }> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
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
  const url = new URL(`${API_BASE}/api/community/posts/recent`, window.location.origin);
  Object.entries(params || {}).forEach(([k, v]) => {
    if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
  });
  const res = await fetch(url.toString().replace(window.location.origin, ''));
  const json: ApiResponse<PostDetail[]> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data;
}

// 게시글 이동과 숨김 관련 API 함수들

// 게시판과 카테고리 목록 조회
export async function getBoardsWithCategories(): Promise<any[]> {
  console.log('🌐 API 호출: /api/community/boards-with-categories');
  const res = await fetch(`${API_BASE}/api/community/boards-with-categories`, {
    headers: getAuthHeaders()
  });
  console.log('📡 응답 상태:', res.status, res.statusText);
  const json: ApiResponse<any[]> = await res.json();
  console.log('📄 응답 데이터:', json);
  if (!json.success) throw new Error(json.message);
  return json.data;
}

// 게시글 이동
export async function movePost(postId: string, data: {
  moved_board_id: string;
  moved_category_id?: string;
  move_reason?: string;
}): Promise<any> {
  console.log('🔄 게시글 이동 API 호출:', { postId, data });
  
  // 백엔드 API 형식에 맞게 데이터 변환 (UUID 문자열 사용)
  const requestData = {
    target_board_id: data.moved_board_id, // UUID 문자열 그대로 사용
    target_category_id: data.moved_category_id || null,
    move_reason: data.move_reason || null,
    move_location: "site"
    // post_id는 URL 경로에서 가져오므로 요청 본문에서 제거
  };
  
  console.log('📤 변환된 요청 데이터:', requestData);
  
  const res = await fetch(`${API_BASE}/api/site/posts/${postId}/move`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(requestData)
  });
  
  console.log('📡 응답 상태:', res.status, res.statusText);
  
  if (!res.ok) {
    let errorMessage = '게시글 이동에 실패했습니다.';
    try {
      const error = await res.json();
      console.error('❌ 이동 실패 응답:', error);
      errorMessage = error.message || errorMessage;
    } catch (e) {
      const errorText = await res.text();
      console.error('❌ 이동 실패 (텍스트 응답):', errorText);
      errorMessage = `서버 오류 (${res.status}): ${errorText}`;
    }
    throw new Error(errorMessage);
  }
  
  const json = await res.json();
  console.log('✅ 이동 성공 응답:', json);
  return json;
}

// 게시글 숨김
export async function hidePost(postId: string, data: {
  hide_category: string;
  hide_reason?: string;
  hide_tags?: string[];
}): Promise<any> {
  const res = await fetch(`${API_BASE}/api/site/posts/${postId}/hide`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...getAuthHeaders()
    },
    body: JSON.stringify(data)
  });
  
  if (!res.ok) {
    const error = await res.json();
    throw new Error(error.message || '게시글 숨김에 실패했습니다.');
  }
  
  return await res.json();
} 