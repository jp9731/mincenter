import type { LayoutLoad } from './$types.js';
import { browser } from '$app/environment';
import { redirect } from '@sveltejs/kit';
import { get } from 'svelte/store';
import { initializeAdminAuth, isAdminAuthenticated } from '$lib/stores/admin';

export const load: LayoutLoad = async ({ url, fetch }) => {
  // 브라우저 환경에서만 인증 확인
  if (browser) {
    const isLoginPage = url.pathname === '/login';

    // 관리자 인증 상태 초기화
    await initializeAdminAuth(fetch);

    // 로그인 페이지이고 인증되어 있으면 대시보드로 리다이렉트
    if (isLoginPage && get(isAdminAuthenticated)) {
      throw redirect(302, '/');
    }

    // 로그인 페이지가 아니고 인증되어 있지 않으면 로그인 페이지로 리다이렉트
    if (!isLoginPage && !get(isAdminAuthenticated)) {
      throw redirect(302, '/login');
    }
  }

  return {};
}; 