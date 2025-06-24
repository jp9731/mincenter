import type { PageLoad } from './$types.js';
import { getPages } from '$lib/api/admin';

export const load: PageLoad = async ({ fetch, url }) => {
  const searchParams = url.searchParams;
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '10');
  const search = searchParams.get('search') || '';
  const status = searchParams.get('status') || '';

  try {
    const response = await getPages({
      page,
      limit,
      search: search || undefined,
      status: status || undefined
    }, fetch);

    return {
      pages: response.pages,
      pagination: {
        page: response.page,
        limit: response.limit,
        total: response.total,
        totalPages: response.total_pages
      },
      filters: {
        search,
        status
      }
    };
  } catch (error) {
    console.error('Failed to load pages:', error);
    return {
      pages: [],
      pagination: {
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 0
      },
      filters: {
        search,
        status
      },
      error: error instanceof Error ? error.message : '페이지 목록을 불러오는데 실패했습니다.'
    };
  }
}; 