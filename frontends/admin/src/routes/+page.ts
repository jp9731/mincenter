import type { PageLoad } from './$types.js';
import { getDashboardStats } from '$lib/api/admin';
import { redirect } from '@sveltejs/kit';

export const load: PageLoad = async ({ fetch }) => {
  try {
    const stats = await getDashboardStats(fetch);
    return { stats };
  } catch (error) {
    console.error('Failed to load dashboard stats:', error);
    
    // 인증 관련 오류인 경우 로그인 페이지로 리다이렉트
    if (error instanceof Error && (
      error.message.includes('Unauthorized') || 
      error.message.includes('No admin token') ||
      error.message.includes('Token refresh failed')
    )) {
      throw redirect(302, '/login');
    }
    
    return {
      stats: null,
      error: error instanceof Error ? error.message : '데이터를 불러오는데 실패했습니다.'
    };
  }
}; 