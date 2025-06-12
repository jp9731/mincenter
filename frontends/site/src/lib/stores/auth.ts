import { writable } from 'svelte/store';
import type { User } from '$lib/types';

export const user = writable<User | null>(null);
export const isAuthenticated = writable(false);
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// 로그인 상태 초기화
export async function initializeAuth() {
  try {
    const response = await fetch('/api/auth/me');
    if (response.ok) {
      const userData = await response.json();
      user.set(userData);
      isAuthenticated.set(true);
    }
  } catch (e) {
    console.error('Failed to initialize auth:', e);
  }
}

// 로그인
export async function login(email: string, password: string) {
  isLoading.set(true);
  error.set(null);

  try {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.message || '로그인에 실패했습니다.');
    }

    const userData = await response.json();
    user.set(userData);
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
    await fetch('/api/auth/logout', { method: 'POST' });
    user.set(null);
    isAuthenticated.set(false);
  } catch (e) {
    console.error('Logout failed:', e);
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
    const response = await fetch('/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(userData)
    });

    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.message || '회원가입에 실패했습니다.');
    }

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
    const response = await fetch('/api/auth/forgot-password', {
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