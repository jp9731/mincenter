import type {
  AdminUser,
  ApiResponse
} from '$lib/types/admin';
import { authenticatedAdminFetch } from '$lib/stores/admin';

// 관리자 로그인
export async function adminLogin(email: string, password: string): Promise<{
  access_token: string;
  refresh_token: string;
  user: AdminUser;
}> {
  const res = await fetch(`http://localhost:8080/api/admin/login`, {
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
  const json: ApiResponse<any[]> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 게시판 생성
export async function createBoard(data: any): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/boards', {
    method: 'POST',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 게시판 수정
export async function updateBoard(id: string, data: any): Promise<any> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
  const json: ApiResponse<any> = await res.json();
  if (!json.success || !json.data) throw new Error(json.message);
  return json.data;
}

// 게시판 삭제
export async function deleteBoard(id: string): Promise<void> {
  const res = await authenticatedAdminFetch(`/api/admin/boards/${id}`, {
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
  const json: ApiResponse<{ posts: any[]; pagination: any }> = await res.json();
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

// 사이트 설정 가져오기
export async function getSiteSettings(): Promise<any> {
  const res = await authenticatedAdminFetch('/api/admin/site/settings');
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