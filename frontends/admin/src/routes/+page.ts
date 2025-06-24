import type { PageLoad } from './$types.js';
import { getDashboardStats } from '$lib/api/admin';

export const load: PageLoad = async ({ fetch }) => {
  try {
    const stats = await getDashboardStats(fetch);
    return { stats };
  } catch (error) {
    console.error('Failed to load dashboard stats:', error);
    return {
      stats: null,
      error: error instanceof Error ? error.message : '데이터를 불러오는데 실패했습니다.'
    };
  }
}; 