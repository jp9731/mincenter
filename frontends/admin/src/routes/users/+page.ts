import type { PageLoad } from './$types.js';
import { getUsers } from '$lib/api/admin';

export const load: PageLoad = async ({ fetch, url }) => {
  const searchParams = url.searchParams;
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');
  const search = searchParams.get('search') || '';
  const status = searchParams.get('status') || '';
  const role = searchParams.get('role') || '';

  try {
    const response = await getUsers({
      page,
      limit,
      search: search || undefined,
      status: status || undefined,
      role: role || undefined
    }, fetch);

    return {
      users: response.users,
      pagination: response.pagination,
      filters: {
        search,
        status,
        role
      }
    };
  } catch (error) {
    console.error('Failed to load users:', error);
    return {
      users: [],
      pagination: {
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0
      },
      filters: {
        search,
        status,
        role
      },
      error: error instanceof Error ? error.message : '사용자 목록을 불러오는데 실패했습니다.'
    };
  }
}; 