import type {
  AdminUser,
  DashboardStats,
  User,
  Post,
  Board,
  Comment,
  VolunteerActivity,
  Donation,
  Notification,
  SystemLog,
  PaginationParams,
  FilterParams,
  ApiResponse
} from '$lib/types/admin.js';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// 관리자 인증 토큰 가져오기
function getAdminAuthHeaders(): HeadersInit {
  const token = localStorage.getItem('admin_token');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
}

// 공통 API 요청 함수
async function apiRequest<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    headers: {
      'Content-Type': 'application/json',
      ...getAdminAuthHeaders(),
      ...options?.headers,
    },
    ...options,
  });

  if (!response.ok) {
    if (response.status === 401) {
      // 인증 실패 시 로그인 페이지로 리다이렉트
      window.location.href = '/login';
      throw new Error('인증이 필요합니다.');
    }
    throw new Error(`API Error: ${response.status}`);
  }

  const data: ApiResponse<T> = await response.json();
  if (!data.success) {
    throw new Error(data.message || 'API 요청에 실패했습니다.');
  }

  return data.data!;
}

// 관리자 로그인
export async function adminLogin(email: string, password: string): Promise<{ user: AdminUser; token: string }> {
  const response = await fetch(`${API_BASE}/api/admin/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password,
      service_type: 'admin'
    }),
  });

  if (!response.ok) {
    throw new Error('로그인에 실패했습니다.');
  }

  const data: ApiResponse<{ user: AdminUser; token: string }> = await response.json();
  if (!data.success) {
    throw new Error(data.message || '로그인에 실패했습니다.');
  }

  return data.data!;
}

// 대시보드 통계
export async function getDashboardStats(): Promise<DashboardStats> {
  return apiRequest<DashboardStats>('/api/admin/dashboard/stats');
}

// 사용자 관리
export async function getUsers(params?: PaginationParams & FilterParams): Promise<{ users: User[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/users`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ users: User[]; pagination: PaginationParams }>(endpoint);
}

export async function getUser(id: string): Promise<User> {
  return apiRequest<User>(`/api/admin/users/${id}`);
}

export async function updateUser(id: string, data: Partial<User>): Promise<User> {
  return apiRequest<User>(`/api/admin/users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
}

export async function deleteUser(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/users/${id}`, {
    method: 'DELETE'
  });
}

export async function suspendUser(id: string, reason: string): Promise<void> {
  return apiRequest<void>(`/api/admin/users/${id}/suspend`, {
    method: 'POST',
    body: JSON.stringify({ reason })
  });
}

export async function activateUser(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/users/${id}/activate`, {
    method: 'POST'
  });
}

// 게시글 관리
export async function getPosts(params?: PaginationParams & FilterParams): Promise<{ posts: Post[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/posts`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ posts: Post[]; pagination: PaginationParams }>(endpoint);
}

export async function getPost(id: string): Promise<Post> {
  return apiRequest<Post>(`/api/admin/posts/${id}`);
}

export async function updatePost(id: string, data: Partial<Post>): Promise<Post> {
  return apiRequest<Post>(`/api/admin/posts/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
}

export async function deletePost(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/posts/${id}`, {
    method: 'DELETE'
  });
}

export async function hidePost(id: string, reason: string): Promise<void> {
  return apiRequest<void>(`/api/admin/posts/${id}/hide`, {
    method: 'POST',
    body: JSON.stringify({ reason })
  });
}

// 게시판 관리
export async function getBoards(): Promise<Board[]> {
  return apiRequest<Board[]>('/api/admin/boards');
}

export async function createBoard(data: Partial<Board>): Promise<Board> {
  return apiRequest<Board>('/api/admin/boards', {
    method: 'POST',
    body: JSON.stringify(data)
  });
}

export async function updateBoard(id: string, data: Partial<Board>): Promise<Board> {
  return apiRequest<Board>(`/api/admin/boards/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
}

export async function deleteBoard(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/boards/${id}`, {
    method: 'DELETE'
  });
}

// 댓글 관리
export async function getComments(params?: PaginationParams & FilterParams): Promise<{ comments: Comment[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/comments`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ comments: Comment[]; pagination: PaginationParams }>(endpoint);
}

export async function deleteComment(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/comments/${id}`, {
    method: 'DELETE'
  });
}

export async function hideComment(id: string, reason: string): Promise<void> {
  return apiRequest<void>(`/api/admin/comments/${id}/hide`, {
    method: 'POST',
    body: JSON.stringify({ reason })
  });
}

// 봉사 활동 관리
export async function getVolunteerActivities(params?: PaginationParams & FilterParams): Promise<{ activities: VolunteerActivity[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/volunteer/activities`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ activities: VolunteerActivity[]; pagination: PaginationParams }>(endpoint);
}

export async function createVolunteerActivity(data: Partial<VolunteerActivity>): Promise<VolunteerActivity> {
  return apiRequest<VolunteerActivity>('/api/admin/volunteer/activities', {
    method: 'POST',
    body: JSON.stringify(data)
  });
}

export async function updateVolunteerActivity(id: string, data: Partial<VolunteerActivity>): Promise<VolunteerActivity> {
  return apiRequest<VolunteerActivity>(`/api/admin/volunteer/activities/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
}

export async function deleteVolunteerActivity(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/volunteer/activities/${id}`, {
    method: 'DELETE'
  });
}

// 후원 관리
export async function getDonations(params?: PaginationParams & FilterParams): Promise<{ donations: Donation[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/donations`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ donations: Donation[]; pagination: PaginationParams }>(endpoint);
}

export async function updateDonation(id: string, data: Partial<Donation>): Promise<Donation> {
  return apiRequest<Donation>(`/api/admin/donations/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data)
  });
}

// 알림 관리
export async function getNotifications(params?: PaginationParams): Promise<{ notifications: Notification[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/notifications`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ notifications: Notification[]; pagination: PaginationParams }>(endpoint);
}

export async function createNotification(data: Partial<Notification>): Promise<Notification> {
  return apiRequest<Notification>('/api/admin/notifications', {
    method: 'POST',
    body: JSON.stringify(data)
  });
}

export async function sendNotification(id: string): Promise<void> {
  return apiRequest<void>(`/api/admin/notifications/${id}/send`, {
    method: 'POST'
  });
}

// 시스템 로그
export async function getSystemLogs(params?: PaginationParams & FilterParams): Promise<{ logs: SystemLog[]; pagination: PaginationParams }> {
  const url = new URL(`${API_BASE}/api/admin/system/logs`, window.location.origin);
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.append(k, String(v));
    });
  }
  const endpoint = url.toString().replace(window.location.origin, '');
  return apiRequest<{ logs: SystemLog[]; pagination: PaginationParams }>(endpoint);
} 