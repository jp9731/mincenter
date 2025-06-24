import { browser } from '$app/environment';
import { goto } from '$app/navigation';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// JWT 토큰 관리
export const ADMIN_JWT_TOKEN_KEY = 'admin_token';
export const ADMIN_REFRESH_TOKEN_KEY = 'admin_refresh_token';

// 토큰 저장
export function setAdminToken(token: string, refreshToken?: string) {
  if (browser) {
    localStorage.setItem(ADMIN_JWT_TOKEN_KEY, token);
    if (refreshToken) {
      localStorage.setItem(ADMIN_REFRESH_TOKEN_KEY, refreshToken);
    }
  }
}

// 토큰 가져오기
export function getAdminToken(): string | null {
  if (browser) {
    return localStorage.getItem(ADMIN_JWT_TOKEN_KEY);
  }
  return null;
}

// 리프레시 토큰 가져오기
export function getAdminRefreshToken(): string | null {
  if (browser) {
    return localStorage.getItem(ADMIN_REFRESH_TOKEN_KEY);
  }
  return null;
}

// 토큰 삭제
export function removeAdminTokens() {
  if (browser) {
    localStorage.removeItem(ADMIN_JWT_TOKEN_KEY);
    localStorage.removeItem(ADMIN_REFRESH_TOKEN_KEY);
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
    console.error('Token decode error:', error);
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

// 관리자 인증된 API 요청 헤더 생성
export function getAdminAuthHeaders(): Record<string, string> {
  const token = getAdminToken();
  return {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` })
  };
}

// 관리자 인증 상태 확인
export function isAdminAuthenticated(): boolean {
  const token = getAdminToken();
  if (!token) return false;
  return !isTokenExpired(token);
}

// 관리자 로그인 리다이렉트
export function redirectToAdminLogin(returnUrl?: string) {
  const url = returnUrl ? `/login?returnUrl=${encodeURIComponent(returnUrl)}` : '/login';
  goto(url);
}

// 관리자 권한 확인
export function hasAdminPermission(requiredPermissions: string[], userPermissions: string[]): boolean {
  if (!userPermissions || userPermissions.length === 0) return false;
  return requiredPermissions.some(permission => userPermissions.includes(permission));
}

// 관리자 토큰 갱신
export async function refreshAdminToken(): Promise<boolean> {
  const refreshToken = getAdminRefreshToken();
  if (!refreshToken) return false;

  try {
    const response = await fetch(`${API_URL}/api/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        refresh_token: refreshToken,
        service_type: 'admin'
      })
    });

    if (response.ok) {
      const apiResponse = await response.json();
      if (apiResponse.success) {
        const data = apiResponse.data;
        setAdminToken(data.access_token, data.refresh_token);
        return true;
      }
    }
  } catch (error) {
    console.error('Admin token refresh failed:', error);
  }

  // 리프레시 실패시 로그아웃
  removeAdminTokens();
  return false;
} 