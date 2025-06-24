import { writable, get } from 'svelte/store';
import { browser } from '$app/environment';
import { goto } from '$app/navigation';
import type { AdminUser } from '$lib/types/admin';
import {
  setAdminToken,
  getAdminToken,
  getAdminRefreshToken,
  removeAdminTokens,
  isTokenExpired,
  decodeToken,
  getAdminAuthHeaders,
  refreshAdminToken
} from '$lib/utils/auth';
import { getUsers, getPosts, togglePostVisibility, updateUserStatus } from '$lib/api/admin';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export const adminUser = writable<AdminUser | null>(null);
export const isAdminAuthenticated = writable(false);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// 데이터 스토어
export const users = writable<any[]>([]);
export const usersPagination = writable({
  page: 1,
  limit: 20,
  total: 0,
  totalPages: 0
});

export const posts = writable<any[]>([]);
export const postsPagination = writable({
  page: 1,
  limit: 20,
  total: 0,
  totalPages: 0
});

// 관리자 로그인 상태 초기화
export async function initializeAdminAuth(fetchFn?: typeof fetch) {
  if (!browser) return;

  try {
    const token = getAdminToken();
    if (!token) {
      isAdminAuthenticated.set(false);
      adminUser.set(null);
      return;
    }

    if (isTokenExpired(token)) {
      // 토큰이 만료되었으면 리프레시 시도
      const refreshed = await refreshAdminToken();
      if (!refreshed) {
        isAdminAuthenticated.set(false);
        adminUser.set(null);
        return;
      }
    }

    // 서버에서 관리자 정보 가져오기
    await fetchAdminProfile(fetchFn);
  } catch (e) {
    console.error('Failed to initialize admin auth:', e);
    isAdminAuthenticated.set(false);
    adminUser.set(null);
  }
}

// 관리자 프로필 가져오기
async function fetchAdminProfile(fetchFn?: typeof fetch) {
  try {
    const fetcher = fetchFn || fetch;
    const response = await fetcher(`${API_URL}/api/admin/me`, {
      headers: getAdminAuthHeaders()
    });

    if (response.ok) {
      const userData = await response.json();
      adminUser.set(userData);
      isAdminAuthenticated.set(true);
    } else {
      throw new Error('Failed to fetch admin profile');
    }
  } catch (e) {
    console.error('Failed to fetch admin profile:', e);
    await adminLogout();
  }
}

// 관리자 로그인
export async function adminLogin(email: string, password: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        password,
        service_type: 'admin'
      })
    });

    const apiResponse = await response.json();

    if (!response.ok || !apiResponse.success) {
      throw new Error(apiResponse.message || '관리자 로그인에 실패했습니다.');
    }

    const authData = apiResponse.data;

    // JWT 토큰 저장
    setAdminToken(authData.access_token, authData.refresh_token);

    // 관리자 정보 설정
    adminUser.set(authData.user);
    isAdminAuthenticated.set(true);

    return true;
  } catch (e) {
    error.set(e instanceof Error ? e.message : '관리자 로그인에 실패했습니다.');
    return false;
  } finally {
    isLoading.set(false);
  }
}

// 관리자 로그아웃
export async function adminLogout() {
  try {
    // 서버에 관리자 로그아웃 요청
    await fetch(`${API_URL}/api/admin/logout`, {
      method: 'POST',
      headers: getAdminAuthHeaders()
    });
  } catch (e) {
    console.error('Admin logout request failed:', e);
  } finally {
    // 클라이언트 상태 정리
    removeAdminTokens();
    adminUser.set(null);
    isAdminAuthenticated.set(false);

    // 로그인 페이지로 리다이렉트
    if (browser) {
      goto('/login');
    }
  }
}

// 관리자 인증된 API 요청
export async function authenticatedAdminFetch(url: string, options: RequestInit = {}, fetchFn?: typeof fetch) {
  const token = getAdminToken();

  if (!token) {
    throw new Error('No admin token available');
  }

  if (isTokenExpired(token)) {
    const refreshed = await refreshAdminToken();
    if (!refreshed) {
      await adminLogout();
      throw new Error('Token refresh failed');
    }
  }

  // URL이 상대 경로인 경우 API_URL과 결합
  const fullUrl = url.startsWith('http') ? url : `${API_URL}${url}`;

  const fetcher = fetchFn || fetch;
  const response = await fetcher(fullUrl, {
    ...options,
    headers: {
      ...getAdminAuthHeaders(),
      ...options.headers
    }
  });

  if (response.status === 401) {
    await adminLogout();
    throw new Error('Unauthorized');
  }

  return response;
}

// 사용자 관리 함수들
export async function loadUsers(params: {
  page?: number;
  limit?: number;
  search?: string;
  status?: string;
  role?: string;
}) {
  try {
    const data = await getUsers(params);
    users.set(data.users);
    usersPagination.set(data.pagination);
  } catch (error) {
    console.error('Failed to load users:', error);
    throw error;
  }
}

export async function suspendUser(userId: string, reason: string) {
  try {
    await updateUserStatus(userId, 'suspended');
    // 사용자 목록 새로고침
    const currentPagination = get(usersPagination);
    await loadUsers({
      page: currentPagination.page,
      limit: currentPagination.limit
    });
  } catch (error) {
    console.error('Failed to suspend user:', error);
    throw error;
  }
}

export async function activateUser(userId: string) {
  try {
    await updateUserStatus(userId, 'active');
    // 사용자 목록 새로고침
    const currentPagination = get(usersPagination);
    await loadUsers({
      page: currentPagination.page,
      limit: currentPagination.limit
    });
  } catch (error) {
    console.error('Failed to activate user:', error);
    throw error;
  }
}

// 게시글 관리 함수들
export async function loadPosts(params: {
  page?: number;
  limit?: number;
  search?: string;
  board_id?: string;
  status?: string;
}) {
  try {
    const data = await getPosts(params);
    posts.set(data.posts);
    postsPagination.set(data.pagination);
  } catch (error) {
    console.error('Failed to load posts:', error);
    throw error;
  }
}

export async function hidePost(postId: string, reason: string) {
  try {
    await togglePostVisibility(postId, true);
    // 게시글 목록 새로고침
    const currentPagination = get(postsPagination);
    await loadPosts({
      page: currentPagination.page,
      limit: currentPagination.limit
    });
  } catch (error) {
    console.error('Failed to hide post:', error);
    throw error;
  }
}

export async function showPost(postId: string) {
  try {
    await togglePostVisibility(postId, false);
    // 게시글 목록 새로고침
    const currentPagination = get(postsPagination);
    await loadPosts({
      page: currentPagination.page,
      limit: currentPagination.limit
    });
  } catch (error) {
    console.error('Failed to show post:', error);
    throw error;
  }
} 