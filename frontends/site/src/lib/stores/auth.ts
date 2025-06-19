import { writable } from 'svelte/store';
import { browser } from '$app/environment';
import { goto } from '$app/navigation';
import type { User } from '$lib/types';
import {
  setToken,
  getToken,
  getRefreshToken,
  removeTokens,
  isTokenExpired,
  decodeToken,
  getAuthHeaders,
  refreshAuthToken
} from '$lib/utils/auth';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export const user = writable<User | null>(null);
export const isAuthenticated = writable(false);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// 로그인 상태 초기화
export async function initializeAuth() {
  if (!browser) return;

  try {
    const token = getToken();
    if (!token) {
      isAuthenticated.set(false);
      user.set(null);
      return;
    }

    if (isTokenExpired(token)) {
      // 토큰이 만료되었으면 리프레시 시도
      const refreshed = await refreshAuthToken();
      if (!refreshed) {
        isAuthenticated.set(false);
        user.set(null);
        return;
      }
    }

    // 서버에서 사용자 정보 가져오기
    await fetchUserProfile();
  } catch (e) {
    console.error('Failed to initialize auth:', e);
    isAuthenticated.set(false);
    user.set(null);
  }
}

// 사용자 프로필 가져오기
async function fetchUserProfile() {
  try {
    const response = await fetch(`${API_URL}/api/auth/me`, {
      headers: getAuthHeaders()
    });

    if (response.ok) {
      const userData = await response.json();
      user.set(userData);
      isAuthenticated.set(true);
    } else {
      throw new Error('Failed to fetch user profile');
    }
  } catch (e) {
    console.error('Failed to fetch user profile:', e);
    await logout();
  }
}

// 로그인
export async function login(email: string, password: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    const apiResponse = await response.json();

    if (!response.ok || !apiResponse.success) {
      throw new Error(apiResponse.message || '로그인에 실패했습니다.');
    }

    const authData = apiResponse.data;

    // JWT 토큰 저장
    setToken(authData.access_token, authData.refresh_token);

    // 사용자 정보 설정
    user.set(authData.user);
    isAuthenticated.set(true);

    return true;
  } catch (e) {
    error.set(e instanceof Error ? e.message : '로그인에 실패했습니다.');
    return false;
  } finally {
    isLoading.set(false);
  }
}

// 로그아웃
export async function logout() {
  try {
    const refreshToken = getRefreshToken();
    if (refreshToken) {
      // 서버에 로그아웃 요청
      await fetch(`${API_URL}/api/auth/logout`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refresh_token: refreshToken })
      });
    }
  } catch (e) {
    console.error('Logout request failed:', e);
  } finally {
    // 클라이언트 상태 정리
    removeTokens();
    user.set(null);
    isAuthenticated.set(false);

    // 홈페이지로 리다이렉트
    if (browser) {
      goto('/');
    }
  }
}

// 회원가입
export async function register(userData: {
  email: string;
  password: string;
  name: string;
}) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(userData)
    });

    const apiResponse = await response.json();

    if (!response.ok || !apiResponse.success) {
      throw new Error(apiResponse.message || '회원가입에 실패했습니다.');
    }

    // 회원가입 성공 시 자동 로그인
    const authData = apiResponse.data;
    setToken(authData.access_token, authData.refresh_token);
    user.set(authData.user);
    isAuthenticated.set(true);

    return true;
  } catch (e) {
    error.set(e instanceof Error ? e.message : '회원가입에 실패했습니다.');
    return false;
  } finally {
    isLoading.set(false);
  }
}

// 비밀번호 재설정 요청
export async function requestPasswordReset(email: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch(`${API_URL}/api/auth/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email })
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.message || '비밀번호 재설정 요청에 실패했습니다.');
    }

    return true;
  } catch (e) {
    error.set(e instanceof Error ? e.message : '비밀번호 재설정 요청에 실패했습니다.');
    return false;
  } finally {
    isLoading.set(false);
  }
}

// 인증된 API 요청 래퍼
export async function authenticatedFetch(url: string, options: RequestInit = {}) {
  const token = getToken();

  if (!token) {
    throw new Error('No authentication token');
  }

  if (isTokenExpired(token)) {
    const refreshed = await refreshAuthToken();
    if (!refreshed) {
      throw new Error('Token refresh failed');
    }
  }

  const headers = {
    ...getAuthHeaders(),
    ...options.headers
  };

  const response = await fetch(url, {
    ...options,
    headers
  });

  if (response.status === 401) {
    // 인증 실패시 로그아웃
    await logout();
    throw new Error('Authentication failed');
  }

  return response;
}