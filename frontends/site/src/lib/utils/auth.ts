import { browser } from '$app/environment';
import { goto } from '$app/navigation';

const API_URL = import.meta.env.VITE_API_URL || '';

// JWT 토큰 관리
export const JWT_TOKEN_KEY = 'auth_token';
export const REFRESH_TOKEN_KEY = 'refresh_token';

// 토큰 저장
export function setToken(token: string, refreshToken?: string) {
  if (browser) {
    localStorage.setItem(JWT_TOKEN_KEY, token);
    if (refreshToken) {
      localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
    }
  }
}

// 토큰 가져오기
export function getToken(): string | null {
  if (browser) {
    return localStorage.getItem(JWT_TOKEN_KEY);
  }
  return null;
}

// 리프레시 토큰 가져오기
export function getRefreshToken(): string | null {
  if (browser) {
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  }
  return null;
}

// 토큰 삭제
export function removeTokens() {
  if (browser) {
    localStorage.removeItem(JWT_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
  }
}

// JWT 디코딩 (클라이언트 사이드)
export function decodeToken(token: string) {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (error) {
    return null;
  }
}

// 토큰 만료 확인
export function isTokenExpired(token: string): boolean {
  const decoded = decodeToken(token);
  if (!decoded || !decoded.exp) return true;

  const currentTime = Math.floor(Date.now() / 1000);
  return decoded.exp < currentTime;
}

// 인증된 API 요청 헤더 생성
export function getAuthHeaders(): Record<string, string> {
  const token = getToken();
  return {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` })
  };
}

// 인증 상태 확인
export function isAuthenticated(): boolean {
  const token = getToken();
  if (!token) return false;
  return !isTokenExpired(token);
}

// 로그인 리다이렉트
export function redirectToLogin(returnUrl?: string) {
  const url = returnUrl ? `/auth/login?returnUrl=${encodeURIComponent(returnUrl)}` : '/auth/login';
  goto(url);
}

// 권한 확인
export function hasPermission(requiredPermissions: string[], userPermissions: string[]): boolean {
  if (!userPermissions || userPermissions.length === 0) return false;
  return requiredPermissions.some(permission => userPermissions.includes(permission));
}

// 토큰 갱신
export async function refreshAuthToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) return false;

  try {
    const response = await fetch(`${API_URL}/api/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        refresh_token: refreshToken,
        service_type: 'site'
      })
    });

    if (response.ok) {
      const apiResponse = await response.json();
      if (apiResponse.success) {
        const data = apiResponse.data;
        setToken(data.access_token, data.refresh_token);
        return true;
      }
    }
  } catch (error) {
    // 토큰 갱신 실패
  }

  // 리프레시 실패시 로그아웃
  removeTokens();
  return false;
} 