import { writable, derived } from 'svelte/store';
import * as adminApi from '$lib/api/admin.js';
import type {
  AdminUser,
  DashboardStats,
  User,
  Post,
  Board,
  Comment,
  VolunteerActivity,
  Donation,
  Notification,
  SystemLog,
  PaginationParams,
  FilterParams
} from '$lib/types/admin.js';

// 관리자 인증 상태
export const adminUser = writable<AdminUser | null>(null);
export const isAuthenticated = derived(adminUser, ($adminUser) => !!$adminUser);

// 로딩 상태
export const isLoading = writable(false);
export const error = writable<string | null>(null);

// 대시보드 통계
export const dashboardStats = writable<DashboardStats | null>(null);

// 사용자 관리
export const users = writable<User[]>([]);
export const usersPagination = writable<PaginationParams>({
  page: 1,
  limit: 20,
  total: 0,
  total_pages: 0
});

// 게시글 관리
export const posts = writable<Post[]>([]);
export const postsPagination = writable<PaginationParams>({
  page: 1,
  limit: 20,
  total: 0,
  total_pages: 0
});

// 게시판 관리
export const boards = writable<Board[]>([]);

// 댓글 관리
export const comments = writable<Comment[]>([]);
export const commentsPagination = writable<PaginationParams>({
  page: 1,
  limit: 20,
  total: 0,
  total_pages: 0
});

// 봉사 활동 관리
export const volunteerActivities = writable<VolunteerActivity[]>([]);
export const volunteerPagination = writable<PaginationParams>({
  page: 1,
  limit: 20,
  total: 0,
  total_pages: 0
});

// 후원 관리
export const donations = writable<Donation[]>([]);
export const donationsPagination = writable<PaginationParams>({
  page: 1,
  limit: 20,
  total: 0,
  total_pages: 0
});

// 알림 관리
export const notifications = writable<Notification[]>([]);
export const notificationsPagination = writable<PaginationParams>({
  page: 1,
  limit: 20,
  total: 0,
  total_pages: 0
});

// 시스템 로그
export const systemLogs = writable<SystemLog[]>([]);
export const logsPagination = writable<PaginationParams>({
  page: 1,
  limit: 50,
  total: 0,
  total_pages: 0
});

// 대시보드 통계 로드
export async function loadDashboardStats() {
  isLoading.set(true);
  error.set(null);

  try {
    const stats = await adminApi.getDashboardStats();
    dashboardStats.set(stats);
  } catch (e: any) {
    error.set(e.message || '대시보드 통계를 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 사용자 목록 로드
export async function loadUsers(params?: PaginationParams & FilterParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getUsers(params);
    users.set(result.users);
    usersPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '사용자 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 목록 로드
export async function loadPosts(params?: PaginationParams & FilterParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getPosts(params);
    posts.set(result.posts);
    postsPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '게시글 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시판 목록 로드
export async function loadBoards() {
  isLoading.set(true);
  error.set(null);

  try {
    const boardsData = await adminApi.getBoards();
    boards.set(boardsData);
  } catch (e: any) {
    error.set(e.message || '게시판 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 댓글 목록 로드
export async function loadComments(params?: PaginationParams & FilterParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getComments(params);
    comments.set(result.comments);
    commentsPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '댓글 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 봉사 활동 목록 로드
export async function loadVolunteerActivities(params?: PaginationParams & FilterParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getVolunteerActivities(params);
    volunteerActivities.set(result.activities);
    volunteerPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '봉사 활동 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 후원 목록 로드
export async function loadDonations(params?: PaginationParams & FilterParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getDonations(params);
    donations.set(result.donations);
    donationsPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '후원 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 알림 목록 로드
export async function loadNotifications(params?: PaginationParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getNotifications(params);
    notifications.set(result.notifications);
    notificationsPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '알림 목록을 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 시스템 로그 로드
export async function loadSystemLogs(params?: PaginationParams & FilterParams) {
  isLoading.set(true);
  error.set(null);

  try {
    const result = await adminApi.getSystemLogs(params);
    systemLogs.set(result.logs);
    logsPagination.set(result.pagination);
  } catch (e: any) {
    error.set(e.message || '시스템 로그를 불러오는데 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 사용자 관리 액션
export async function updateUser(id: string, data: Partial<User>) {
  isLoading.set(true);
  error.set(null);

  try {
    const updatedUser = await adminApi.updateUser(id, data);
    users.update(userList =>
      userList.map(user => user.id === id ? updatedUser : user)
    );
  } catch (e: any) {
    error.set(e.message || '사용자 정보 수정에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

export async function suspendUser(id: string, reason: string) {
  isLoading.set(true);
  error.set(null);

  try {
    await adminApi.suspendUser(id, reason);
    users.update(userList =>
      userList.map(user =>
        user.id === id ? { ...user, status: 'suspended' as const } : user
      )
    );
  } catch (e: any) {
    error.set(e.message || '사용자 정지에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

export async function activateUser(id: string) {
  isLoading.set(true);
  error.set(null);

  try {
    await adminApi.activateUser(id);
    users.update(userList =>
      userList.map(user =>
        user.id === id ? { ...user, status: 'active' as const } : user
      )
    );
  } catch (e: any) {
    error.set(e.message || '사용자 활성화에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 게시글 관리 액션
export async function hidePost(id: string, reason: string) {
  isLoading.set(true);
  error.set(null);

  try {
    await adminApi.hidePost(id, reason);
    posts.update(postList =>
      postList.map(post =>
        post.id === id ? { ...post, status: 'hidden' as const } : post
      )
    );
  } catch (e: any) {
    error.set(e.message || '게시글 숨김에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
}

// 댓글 관리 액션
export async function hideComment(id: string, reason: string) {
  isLoading.set(true);
  error.set(null);

  try {
    await adminApi.hideComment(id, reason);
    comments.update(commentList =>
      commentList.map(comment =>
        comment.id === id ? { ...comment, status: 'hidden' as const } : comment
      )
    );
  } catch (e: any) {
    error.set(e.message || '댓글 숨김에 실패했습니다.');
  } finally {
    isLoading.set(false);
  }
} 