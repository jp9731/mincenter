import { redirect } from '@sveltejs/kit';
import type { LayoutLoad } from './$types';
import { isAuthenticated } from '$lib/utils/auth';

export const load: LayoutLoad = async ({ url }) => {
  // 인증 확인
  if (!isAuthenticated()) {
    throw redirect(302, `/auth/login?returnUrl=${encodeURIComponent(url.pathname)}`);
  }

  return {
    meta: {
      title: '게시글 작성 - 민들레장애인자립생활센터',
      description: '새로운 게시글을 작성하세요.',
      requiresAuth: true
    }
  };
}; 