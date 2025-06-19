import type { LayoutLoad } from './$types';
import { initializeAuth } from '$lib/stores/auth';

export const load: LayoutLoad = async ({ url }) => {
  // 인증 상태 초기화
  await initializeAuth();

  return {
    meta: {
      title: '민들레장애인자립생활센터',
      description: '장애인의 자립생활을 지원하는 봉사단체입니다.',
      keywords: '장애인, 자립생활, 봉사, 지원',
      ogImage: '/images/og-image.jpg'
    }
  };
};