import type { LayoutLoad } from './$types.js';
import { browser, dev } from '$app/environment';

export const load: LayoutLoad = async ({ url }: { url: URL }) => {
  // 브라우저 환경에서만 인증 확인
  if (browser) {
    const token = localStorage.getItem('admin_token');
    const isLoginPage = url.pathname === '/login';

    // dev && console.log('Layout Load Debug:', {
    //   pathname: url.pathname,
    //   isLoginPage,
    //   hasToken: !!token,
    //   token: token
    // });

    // 로그인 페이지이고 토큰이 있으면 대시보드로 리다이렉트
    if (isLoginPage && token) {
      console.log('Redirecting from login to dashboard');
      window.location.href = '/';
      return {};
    }

    // 로그인 페이지가 아니고 토큰이 없으면 로그인 페이지로 리다이렉트
    if (!isLoginPage && !token) {
      console.log('Redirecting to login page');
      window.location.href = '/login';
      return {};
    }

    console.log('No redirect needed');
  }

  return {};
}; 