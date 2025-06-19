import { get } from 'svelte/store';
import { user } from '$lib/stores/auth';
import type { UserRole, PostDetail } from '$lib/types';

// 권한 상수
export const PERMISSIONS = {
  // 게시판 관련
  POST_CREATE: 'post:create',
  POST_READ: 'post:read',
  POST_UPDATE: 'post:update',
  POST_DELETE: 'post:delete',

  // 댓글 관련
  COMMENT_CREATE: 'comment:create',
  COMMENT_READ: 'comment:read',
  COMMENT_UPDATE: 'comment:update',
  COMMENT_DELETE: 'comment:delete',

  // 관리자 권한
  ADMIN_ACCESS: 'admin:access',
  USER_MANAGE: 'user:manage',
  CONTENT_MODERATE: 'content:moderate',

  // 봉사 관련
  VOLUNTEER_APPLY: 'volunteer:apply',
  VOLUNTEER_MANAGE: 'volunteer:manage',

  // 후원 관련
  DONATION_VIEW: 'donation:view',
  DONATION_MANAGE: 'donation:manage'
} as const;

// 역할별 기본 권한
export const ROLE_PERMISSIONS: Record<string, string[]> = {
  'admin': [
    PERMISSIONS.POST_CREATE,
    PERMISSIONS.POST_READ,
    PERMISSIONS.POST_UPDATE,
    PERMISSIONS.POST_DELETE,
    PERMISSIONS.COMMENT_CREATE,
    PERMISSIONS.COMMENT_READ,
    PERMISSIONS.COMMENT_UPDATE,
    PERMISSIONS.COMMENT_DELETE,
    PERMISSIONS.ADMIN_ACCESS,
    PERMISSIONS.USER_MANAGE,
    PERMISSIONS.CONTENT_MODERATE,
    PERMISSIONS.VOLUNTEER_APPLY,
    PERMISSIONS.VOLUNTEER_MANAGE,
    PERMISSIONS.DONATION_VIEW,
    PERMISSIONS.DONATION_MANAGE
  ],
  'moderator': [
    PERMISSIONS.POST_CREATE,
    PERMISSIONS.POST_READ,
    PERMISSIONS.POST_UPDATE,
    PERMISSIONS.POST_DELETE,
    PERMISSIONS.COMMENT_CREATE,
    PERMISSIONS.COMMENT_READ,
    PERMISSIONS.COMMENT_UPDATE,
    PERMISSIONS.COMMENT_DELETE,
    PERMISSIONS.CONTENT_MODERATE,
    PERMISSIONS.VOLUNTEER_APPLY,
    PERMISSIONS.VOLUNTEER_MANAGE,
    PERMISSIONS.DONATION_VIEW
  ],
  'user': [
    PERMISSIONS.POST_CREATE,
    PERMISSIONS.POST_READ,
    PERMISSIONS.POST_UPDATE,
    PERMISSIONS.COMMENT_CREATE,
    PERMISSIONS.COMMENT_READ,
    PERMISSIONS.COMMENT_UPDATE,
    PERMISSIONS.VOLUNTEER_APPLY,
    PERMISSIONS.DONATION_VIEW
  ],
  'guest': [
    PERMISSIONS.POST_READ,
    PERMISSIONS.COMMENT_READ
  ]
};

// 현재 사용자의 권한 확인
export function hasPermission(permission: string): boolean {
  const currentUser = get(user);
  if (!currentUser) return false;

  // 관리자는 모든 권한을 가짐
  if (currentUser.role === 'admin') return true;

  // 사용자의 권한 목록 확인
  return currentUser.permissions?.includes(permission) || false;
}

// 여러 권한 중 하나라도 있는지 확인
export function hasAnyPermission(permissions: string[]): boolean {
  return permissions.some(permission => hasPermission(permission));
}

// 모든 권한을 가지고 있는지 확인
export function hasAllPermissions(permissions: string[]): boolean {
  return permissions.every(permission => hasPermission(permission));
}

// 역할 확인
export function hasRole(role: string): boolean {
  const currentUser = get(user);
  if (!currentUser) return false;

  return currentUser.role === role;
}

// 역할 기반 권한 확인
export function hasRolePermission(role: string, permission: string): boolean {
  const rolePermissions = ROLE_PERMISSIONS[role];
  return rolePermissions?.includes(permission) || false;
}

// 게시글 작성 권한 확인
export function canCreatePost(): boolean {
  const currentUser = get(user);
  return !!currentUser; // 로그인한 사용자는 글쓰기 가능
}

// 게시글 수정 권한 확인
export function canEditPost(post: PostDetail): boolean {
  const currentUser = get(user);
  if (!currentUser) return false;

  // 관리자는 모든 게시글 수정 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 게시글만 수정 가능
  return currentUser.id === post.user_id;
}

// 게시글 삭제 권한 확인
export function canDeletePost(post: PostDetail): boolean {
  const currentUser = get(user);
  if (!currentUser) return false;

  // 관리자는 모든 게시글 삭제 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 게시글만 삭제 가능
  return currentUser.id === post.user_id;
}

// 댓글 작성 권한 확인
export function canCreateComment(): boolean {
  return hasPermission(PERMISSIONS.COMMENT_CREATE);
}

// 댓글 수정 권한 확인
export function canEditComment(comment: any): boolean {
  const currentUser = get(user);
  if (!currentUser) return false;

  // 관리자는 모든 댓글 수정 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 댓글만 수정 가능
  return currentUser.id === comment.user_id;
}

// 댓글 삭제 권한 확인
export function canDeleteComment(comment: any): boolean {
  const currentUser = get(user);
  if (!currentUser) return false;

  // 관리자는 모든 댓글 삭제 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 댓글만 삭제 가능
  return currentUser.id === comment.user_id;
}

// 봉사 신청 권한 확인
export function canApplyVolunteer(): boolean {
  return hasPermission(PERMISSIONS.VOLUNTEER_APPLY);
}

// 관리자 권한 확인
export function isAdmin(): boolean {
  return hasRole('admin');
}

// 모더레이터 권한 확인
export function isModerator(): boolean {
  return hasRole('moderator') || hasRole('admin');
} 