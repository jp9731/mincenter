import type { LayoutLoad } from './$types';
import { browser } from '$app/environment';
import { getToken, isTokenExpired } from '$lib/utils/auth';

const API_URL = import.meta.env.VITE_API_URL || '';

export const load: LayoutLoad = async ({ fetch, url }) => {
  // 브라우저에서만 인증 상태 확인
  if (browser) {
    const token = getToken();
    
    if (token && !isTokenExpired(token)) {
      try {
        // SvelteKit의 fetch 사용
        const response = await fetch(`${API_URL}/api/auth/me`, {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          }
        });

        if (response.ok) {
          const apiResponse = await response.json();
          if (apiResponse.success) {
            return {
              user: apiResponse.data,
              isAuthenticated: true,
              meta: {
                title: '민들레장애인자립생활센터',
                description: '장애인의 자립생활을 지원하는 봉사단체입니다.',
                keywords: '장애인, 자립생활, 봉사, 지원',
                ogImage: '/images/og-image.jpg'
              }
            };
          }
        }
      } catch (error) {
        console.error('인증 상태 확인 실패:', error);
      }
    }
  }

  return {
    user: null,
    isAuthenticated: false,
    meta: {
      title: '민들레장애인자립생활센터',
      description: '장애인의 자립생활을 지원하는 봉사단체입니다.',
      keywords: '장애인, 자립생활, 봉사, 지원',
      ogImage: '/images/og-image.jpg'
    }
  };
};