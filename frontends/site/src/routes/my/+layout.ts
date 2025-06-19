import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';
import { isAuthenticated } from '$lib/utils/auth';

export const load: LayoutLoad = async ({ url }) => {
  // 인증 확인
  if (!isAuthenticated()) {
    throw redirect(302, `/auth/login?returnUrl=${encodeURIComponent(url.pathname)}`);
  }

  return {
    // 마이페이지 관련 데이터 로드
    meta: {
      title: '마이페이지 - 민들레장애인자립생활센터',
      description: '내 정보와 활동을 관리하세요.',
      requiresAuth: true
    }
  };
}; 