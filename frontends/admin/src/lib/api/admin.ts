import type {
  AdminUser,
  ApiResponse
} from '$lib/types/admin';
import { authenticatedAdminFetch } from '$lib/stores/admin';

// 배열 ↔ 콤마 문자열 변환 유틸 함수
function parseCsvOption(val: string[] | string | undefined | null): string[] {
  if (Array.isArray(val)) return val;
  if (typeof val === 'string') return val.split(',').map(s => s.trim()).filter(Boolean);
  return [];
}

function convertArrayToCsv(arr: string[] | undefined | null): string | undefined {
  if (!arr || arr.length === 0) return undefined;
  return arr.join(',');
}

// 런타임 환경변수에서 API URL 가져오기
const API_BASE = (typeof window !== 'undefined' && (window as any).ENV?.API_URL) || 
                 import.meta.env.VITE_API_URL || 
                 'https://api.mincenter.kr';

// 관리자 로그인
export async function adminLogin(email: string, password: string): Promise<{
  access_token: string;
  refresh_token: string;
  user: AdminUser;
}> {
  const baseUrl = API_BASE || 'https://api.mincenter.kr';
  const res = await fetch(`${baseUrl}/api/admin/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      service_type: 'admin'
    })
  });
  const json: ApiResponse<{
    access_token: string;
    refresh_token: string;
    user: AdminUser;
  }> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 관리자 프로필 가져오기
export async function getAdminProfile(): Promise<AdminUser> {
  const res = await authenticatedAdminFetch('/api/admin/me');
  const json: ApiResponse<AdminUser> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 관리자 정보 조회
export async function getAdminMe(fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/me', {}, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 대시보드 통계
export async function getDashboardStats(fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/dashboard/stats', {}, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 사용자 목록
export async function getUsers(params?: {
  search?: string;
  status?: string;
  role?: string;
  page?: number;
  limit?: number;
}, fetchFn?: typeof fetch): Promise<{ users: any[]; pagination: any }> {
  const searchParams = new URLSearchParams();
  if (params?.search) searchParams.set('search', params.search);
  if (params?.status) searchParams.set('status', params.status);
  if (params?.role) searchParams.set('role', params.role);
  if (params?.page) searchParams.set('page', params.page.toString());
  if (params?.limit) searchParams.set('limit', params.limit.toString());
  const res = await authenticatedAdminFetch(`/api/admin/users?${searchParams}`, {}, fetchFn);
  const json: ApiResponse<{ users: any[]; pagination: any }> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 사용자 상세 정보 조회
export async function getUser(id: string, fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/users/${id}`, {}, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 사용자 정보 수정
export async function updateUser(id: string, data: {
  name?: string;
  email?: string;
  phone?: string;
  role?: string;
  status?: string;
}, fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  }, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 게시판 목록
export async function getBoards(fetchFn?: typeof fetch): Promise<any[]> {
  const res = await authenticatedAdminFetch('/api/admin/boards', {}, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  
  // API 응답에서 boards 배열 추출
  const boards = json.data.boards || [];
  
  // allowed_file_types, allowed_iframe_domains를 배열로 변환
  return boards.map(board => ({
    ...board,
    allowed_file_types: parseCsvOption(board.allowed_file_types),
    allowed_iframe_domains: parseCsvOption(board.allowed_iframe_domains),
  }));
}

// 게시판 생성
export async function createBoard(data: any): Promise<any> {
  // 배열을 그대로 전송 (변환하지 않음)
  const payload = {
    ...data,
    allowed_file_types: data.allowed_file_types,
    allowed_iframe_domains: data.allowed_iframe_domains,
  };
  
  const res = await authenticatedAdminFetch('/api/admin/boards', {
    method: 'POST',
    body: JSON.stringify(payload)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  
  // 응답에서도 배열로 변환
  return {
    ...json.data,
    allowed_file_types: parseCsvOption(json.data.allowed_file_types),
    allowed_iframe_domains: parseCsvOption(json.data.allowed_iframe_domains),
  };
}

// 게시판 수정
export async function updateBoard(id: string, data: any): Promise<any> {
  // 배열을 그대로 전송 (변환하지 않음)
  const payload = {
    ...data,
    allowed_file_types: data.allowed_file_types,
    allowed_iframe_domains: data.allowed_iframe_domains,
  };
  
  const res = await authenticatedAdminFetch(`/api/admin/boards/${id}`, {
    method: 'PUT',
    body: JSON.stringify(payload)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  
  // 응답에서도 배열로 변환
  return {
    ...json.data,
    allowed_file_types: parseCsvOption(json.data.allowed_file_types),
    allowed_iframe_domains: parseCsvOption(json.data.allowed_iframe_domains),
  };
}

// 게시판 삭제
export async function deleteBoard(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${id}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 게시판 상세 조회
export async function getBoard(id: string, fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${id}`, {}, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  
  // allowed_file_types, allowed_iframe_domains를 배열로 변환
  return {
    ...json.data,
    allowed_file_types: parseCsvOption(json.data.allowed_file_types),
    allowed_iframe_domains: parseCsvOption(json.data.allowed_iframe_domains),
  };
}

// 카테고리 목록 조회
export async function getBoardCategories(boardId: string, fetchFn?: typeof fetch): Promise<any[]> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${boardId}/categories`, {}, fetchFn);
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 카테고리 생성
export async function createCategory(boardId: string, data: {
  name: string;
  description?: string;
  display_order?: number;
  is_active?: boolean;
}): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${boardId}/categories`, {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 카테고리 수정
export async function updateCategory(boardId: string, categoryId: string, data: {
  name?: string;
  description?: string;
  display_order?: number;
  is_active?: boolean;
}): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${boardId}/categories/${categoryId}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 카테고리 삭제
export async function deleteCategory(boardId: string, categoryId: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${boardId}/categories/${categoryId}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 게시글 목록
export async function getPosts(params?: {
  search?: string;
  board_id?: string;
  status?: string;
  page?: number;
  limit?: number;
}, fetchFn?: typeof fetch): Promise<{ posts: any[]; pagination: any }> {
  const searchParams = new URLSearchParams();
  if (params?.search) searchParams.set('search', params.search);
  if (params?.board_id) searchParams.set('board', params.board_id);
  if (params?.status) searchParams.set('status', params.status);
  if (params?.page) searchParams.set('page', params.page.toString());
  if (params?.limit) searchParams.set('limit', params.limit.toString());
  const res = await authenticatedAdminFetch(`/api/admin/posts?${searchParams}`, {}, fetchFn);
  const json: ApiResponse<any[]> & { pagination: any } = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  
  // API 응답 구조: { success: true, data: [...posts], pagination: {...} }
  return {
    posts: json.data,
    pagination: json.pagination
  };
}

// 단일 게시글 조회
export async function getPost(id: string, fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/posts/${id}`, {}, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 게시글 숨김/보이기
export async function togglePostVisibility(id: string, hidden: boolean): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/posts/${id}/visibility`, {
    method: 'PUT',
    body: JSON.stringify({ hidden })
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 댓글 목록
export async function getComments(params?: {
  search?: string;
  post_id?: string;
  status?: string;
  page?: number;
  limit?: number;
}, fetchFn?: typeof fetch): Promise<{ comments: any[]; pagination: any }> {
  const searchParams = new URLSearchParams();
  if (params?.search) searchParams.set('search', params.search);
  if (params?.post_id) searchParams.set('post', params.post_id);
  if (params?.status) searchParams.set('status', params.status);
  if (params?.page) searchParams.set('page', params.page.toString());
  if (params?.limit) searchParams.set('limit', params.limit.toString());
  const res = await authenticatedAdminFetch(`/api/admin/comments?${searchParams}`, {}, fetchFn);
  const json: ApiResponse<{ comments: any[]; pagination: any }> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 댓글 숨김/보이기
export async function toggleCommentVisibility(id: string, hidden: boolean): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/comments/${id}/visibility`, {
    method: 'PUT',
    body: JSON.stringify({ hidden })
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 댓글 삭제
export async function deleteComment(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/comments/${id}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 사용자 상태 변경
export async function updateUserStatus(id: string, status: string): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/users/${id}/status`, {
    method: 'PUT',
    body: JSON.stringify({ status })
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 사용자 역할 변경
export async function updateUserRole(id: string, role: string): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/users/${id}/role`, {
    method: 'PUT',
    body: JSON.stringify({ role })
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 사이트 설정 조회
export async function getSiteSettings(): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/site/settings', {
    method: 'GET'
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 사이트 설정 저장
export async function saveSiteSettings(data: any): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/site/settings', {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 메뉴 목록
export async function getMenus(fetchFn?: typeof fetch): Promise<any[]> {
  const res = await authenticatedAdminFetch('/api/admin/menus', {}, fetchFn);
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 메뉴 저장
export async function saveMenus(data: any[]): Promise<any[]> {
  const res = await authenticatedAdminFetch('/api/admin/menus', {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 페이지 목록 조회
export async function getPages(params?: {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
}, fetchFn?: typeof fetch): Promise<{ pages: any[]; total: number; page: number; limit: number; total_pages: number }> {
  const url = new URL('/api/admin/pages', 'http://localhost:8080');
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const res = await authenticatedAdminFetch(url.pathname + url.search, {}, fetchFn);
  const json: ApiResponse<{ pages: any[]; total: number; page: number; limit: number; total_pages: number }> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 단일 페이지 조회
export async function getPage(id: string): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/pages/${id}`);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 페이지 생성
export async function createPage(data: any): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/pages', {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 페이지 수정
export async function updatePage(id: string, data: any): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/pages/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 페이지 상태 업데이트
export async function updatePageStatus(id: string, data: { status: string; is_published: boolean }): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/pages/${id}/status`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 페이지 삭제
export async function deletePage(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/pages/${id}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 알림 생성
export async function createNotification(data: {
  title: string;
  message: string;
  type: string;
  target: string;
}): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/notifications', {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 알림 발송
export async function sendNotification(id: string): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/notifications/${id}/send`, {
    method: 'POST'
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 캘린더 일정 목록 조회
export async function getCalendarEvents(): Promise<any[]> {
  const res = await authenticatedAdminFetch('/api/admin/calendar/events');
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 일정 추가
export async function createCalendarEvent(data: any): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/calendar/events', {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 일정 수정
export async function updateCalendarEvent(id: string, data: any): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/calendar/events/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 일정 삭제
export async function deleteCalendarEvent(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/calendar/events/${id}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// 게시글 생성
export async function createPost(data: {
  title: string;
  content: string;
  board_id: string;
  is_notice?: boolean;
  category_id?: string;
}, fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/posts', {
    method: 'POST',
    body: JSON.stringify(data)
  }, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 게시글 수정
export async function updatePost(id: string, data: {
  title?: string;
  content?: string;
  board_id?: string;
  is_notice?: boolean;
  category_id?: string;
  status?: string;
}, fetchFn?: typeof fetch): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/posts/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  }, fetchFn);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// adminApi 객체로 모든 함수들을 export
export const adminApi = {
  adminLogin,
  getAdminProfile,
  getAdminMe,
  getDashboardStats,
  getUsers,
  getUser,
  updateUser,
  getBoards,
  createBoard,
  updateBoard,
  deleteBoard,
  getBoard,
  getBoardCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  getPosts,
  getPost,
  togglePostVisibility,
  getComments,
  toggleCommentVisibility,
  deleteComment,
  updateUserStatus,
  updateUserRole,
  getSiteSettings,
  saveSiteSettings,
  getMenus,
  saveMenus,
  getPages,
  getPage,
  createPage,
  updatePage,
  updatePageStatus,
  deletePage,
  createNotification,
  sendNotification,
  getCalendarEvents,
  createCalendarEvent,
  updateCalendarEvent,
  deleteCalendarEvent,
  createPost,
  updatePost
}; 

// 파일 업로드 (사이트 파일)
export async function uploadSiteFile(file: File): Promise<any> {
  const formData = new FormData();
  formData.append('file', file);
  
  const res = await authenticatedAdminFetch('/api/upload/site', {
    method: 'POST',
    body: formData,
    headers: {} // FormData를 사용할 때는 Content-Type을 설정하지 않음
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 파일 업로드 (게시글 파일)
export async function uploadPostFile(file: File): Promise<any> {
  const formData = new FormData();
  formData.append('file', file);
  
  const res = await authenticatedAdminFetch('/api/upload/posts', {
    method: 'POST',
    body: formData,
    headers: {} // FormData를 사용할 때는 Content-Type을 설정하지 않음
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 파일 업로드 (프로필 파일)
export async function uploadProfileFile(file: File): Promise<any> {
  const formData = new FormData();
  formData.append('file', file);
  
  const res = await authenticatedAdminFetch('/api/upload/profiles', {
    method: 'POST',
    body: formData,
    headers: {} // FormData를 사용할 때는 Content-Type을 설정하지 않음
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
} 

// RBAC - 역할 목록 조회
export async function getRoles(): Promise<any[]> {
  const res = await authenticatedAdminFetch('/api/admin/roles');
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 역할 상세 조회
export async function getRole(id: string): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/roles/${id}`);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 역할 생성
export async function createRole(data: {
  name: string;
  description?: string;
  permissions: string[];
}): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/roles', {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 역할 수정
export async function updateRole(id: string, data: {
  name?: string;
  description?: string;
  is_active?: boolean;
  permissions?: string[];
}): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/roles/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 역할 삭제
export async function deleteRole(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/roles/${id}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// RBAC - 권한 목록 조회
export async function getPermissions(): Promise<any[]> {
  const res = await authenticatedAdminFetch('/api/admin/permissions');
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 권한 생성
export async function createPermission(data: {
  name: string;
  description?: string;
  resource: string;
  action: string;
}): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/permissions', {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 권한 수정
export async function updatePermission(id: string, data: {
  name?: string;
  description?: string;
  resource?: string;
  action?: string;
  is_active?: boolean;
}): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/permissions/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 권한 삭제
export async function deletePermission(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/permissions/${id}`, {
    method: 'DELETE'
  });
  const json: ApiResponse<null> = await res.json();
  if (!json.success) throw new Error(json.message);
}

// RBAC - 사용자 권한 조회
export async function getUserPermissions(userId: string): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/users/${userId}/permissions`);
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 사용자 역할 할당
export async function assignUserRoles(userId: string, roleIds: string[]): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/users/${userId}/roles`, {
    method: 'PUT',
    body: JSON.stringify({ user_id: userId, role_ids: roleIds })
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// RBAC - 권한 체크
export async function checkPermission(userId: string, resource: string, action: string): Promise<boolean> {
  const res = await authenticatedAdminFetch('/api/admin/check-permission', {
    method: 'POST',
    body: JSON.stringify({ user_id: userId, resource, action })
  });
  const json: ApiResponse<boolean> = await res.json();
  if (!json.success) throw new Error(json.message);
  return json.data || false;
} 