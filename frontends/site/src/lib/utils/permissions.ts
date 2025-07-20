import type { User, PostDetail, Board } from '$lib/types';

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
export function hasPermission(currentUser: User | null, permission: string): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 권한을 가짐
  if (currentUser.role === 'admin') return true;

  // 사용자의 권한 목록 확인
  return currentUser.permissions?.includes(permission) || false;
}

// 여러 권한 중 하나라도 있는지 확인
export function hasAnyPermission(currentUser: User | null, permissions: string[]): boolean {
  return permissions.some(permission => hasPermission(currentUser, permission));
}

// 모든 권한을 가지고 있는지 확인
export function hasAllPermissions(currentUser: User | null, permissions: string[]): boolean {
  return permissions.every(permission => hasPermission(currentUser, permission));
}

// 역할 확인
export function hasRole(currentUser: User | null, role: string): boolean {
  if (!currentUser) return false;
  return currentUser.role === role;
}

// 역할 기반 권한 확인
export function hasRolePermission(role: string, permission: string): boolean {
  const rolePermissions = ROLE_PERMISSIONS[role];
  return rolePermissions?.includes(permission) || false;
}

// 게시글 작성 권한 확인
export function canCreatePost(currentUser: User | null): boolean {
  return !!currentUser; // 로그인한 사용자는 글쓰기 가능
}

// 게시글 수정 권한 확인
export function canEditPost(post: PostDetail, currentUser: User | null): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 게시글 수정 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 게시글만 수정 가능
  const currentUserId = String(currentUser.id);
  const postUserId = String(post.user_id);
  
  console.log('권한 체크 상세:', {
    currentUserId,
    postUserId,
    isEqual: currentUserId === postUserId,
    currentUserRole: currentUser.role
  });
  
  return currentUserId === postUserId;
}

// 게시글 삭제 권한 확인
export function canDeletePost(post: PostDetail, currentUser: User | null): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 게시글 삭제 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 게시글만 삭제 가능
  return String(currentUser.id) === String(post.user_id);
}

// 댓글 작성 권한 확인
export function canCreateComment(currentUser: User | null): boolean {
  return hasPermission(currentUser, PERMISSIONS.COMMENT_CREATE);
}

// 댓글 수정 권한 확인
export function canEditComment(comment: any, currentUser: User | null): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 댓글 수정 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 댓글만 수정 가능
  return String(currentUser.id) === String(comment.user_id);
}

// 댓글 삭제 권한 확인
export function canDeleteComment(comment: any, currentUser: User | null): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 댓글 삭제 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 댓글만 삭제 가능
  return String(currentUser.id) === String(comment.user_id);
}

// 봉사 신청 권한 확인
export function canApplyVolunteer(currentUser: User | null): boolean {
  return hasPermission(currentUser, PERMISSIONS.VOLUNTEER_APPLY);
}

// 관리자 권한 확인
export function isAdmin(currentUser: User | null): boolean {
  return hasRole(currentUser, 'admin');
}

// 모더레이터 권한 확인
export function isModerator(currentUser: User | null): boolean {
  return hasRole(currentUser, 'moderator') || hasRole(currentUser, 'admin');
}

// 게시판 권한 체크 함수들
export function canListBoard(board: Board, currentUser: User | null): boolean {
  const permission = board.list_permission || 'guest';
  
  switch (permission) {
    case 'guest':
      return true; // 모든 사용자 접근 가능
    case 'member':
      return !!currentUser; // 로그인한 사용자만
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return true;
  }
}

export function canReadPost(board: Board, currentUser: User | null): boolean {
  const permission = board.read_permission || 'guest';
  
  switch (permission) {
    case 'guest':
      return true;
    case 'member':
      return !!currentUser;
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return true;
  }
}

export function canWritePost(board: Board, currentUser: User | null): boolean {
  const permission = board.write_permission || 'member';
  
  // 익명 작성 허용 체크
  if (board.allow_anonymous && permission === 'guest') {
    return true;
  }
  
  switch (permission) {
    case 'guest':
      return true;
    case 'member':
      return !!currentUser;
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return !!currentUser;
  }
}

export function canReplyPost(board: Board, currentUser: User | null): boolean {
  const permission = board.reply_permission || 'member';
  
  switch (permission) {
    case 'guest':
      return true;
    case 'member':
      return !!currentUser;
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return !!currentUser;
  }
}

export function canCreateCommentInBoard(board: Board, currentUser: User | null): boolean {
  const permission = board.comment_permission || 'member';
  
  // 댓글 허용 체크
  if (!board.allow_comments) {
    return false;
  }
  
  switch (permission) {
    case 'guest':
      return true;
    case 'member':
      return !!currentUser;
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return !!currentUser;
  }
}

// 답글 생성 권한 확인 (게시판 기반)
export function canCreateReplyInBoard(board: Board, currentUser: User | null): boolean {
  // 답글 생성 권한은 reply_permission을 사용
  const permission = board.reply_permission || 'member';
  

  
  switch (permission) {
    case 'guest':
      return true;
    case 'member':
      return !!currentUser;
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return !!currentUser;
  }
}

export function canDownloadFile(board: Board, currentUser: User | null): boolean {
  const permission = board.download_permission || 'member';
  
  switch (permission) {
    case 'guest':
      return true;
    case 'member':
      return !!currentUser;
    case 'admin':
      return currentUser?.role === 'admin' || currentUser?.role === 'Admin';
    default:
      return !!currentUser;
  }
}

// 게시글 수정/삭제 제한 체크
export function canEditPostWithLimit(post: PostDetail, board: Board, currentUser: User | null): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 게시글 수정 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 게시글만 수정 가능
  if (String(currentUser.id) !== String(post.user_id)) return false;

  // 댓글 수 제한 체크
  const commentCount = post.comment_count || 0;
  if (board.edit_comment_limit && board.edit_comment_limit > 0 && commentCount >= board.edit_comment_limit) {
    return false;
  }

  return true;
}

export function canDeletePostWithLimit(post: PostDetail, board: Board, currentUser: User | null): boolean {
  if (!currentUser) return false;

  // 관리자는 모든 게시글 삭제 가능
  if (currentUser.role === 'admin') return true;

  // 작성자는 자신의 게시글만 삭제 가능
  if (currentUser.id !== post.user_id) return false;

  // 댓글 수 제한 체크
  const commentCount = post.comment_count || 0;
  if (board.delete_comment_limit && board.delete_comment_limit > 0 && commentCount >= board.delete_comment_limit) {
    return false;
  }

  return true;
}

// 표시 설정 체크
export function shouldShowAuthorName(board: Board): boolean {
  return board.show_author_name !== false; // 기본값 true
}

export function shouldShowIp(board: Board): boolean {
  return board.show_ip === true; // 기본값 false
}

export function shouldShowRecommend(board: Board): boolean {
  return board.allow_recommend !== false; // 기본값 true
}

export function shouldShowDisrecommend(board: Board): boolean {
  return board.allow_disrecommend === true; // 기본값 false
}

export function shouldShowSearch(board: Board): boolean {
  return board.allow_search !== false; // 기본값 true
}

// 파일 업로드 체크
export function canUploadFile(board: Board): boolean {
  return board.allow_file_upload !== false; // 기본값 true
}

// 리치 텍스트 에디터 체크
export function canUseRichText(board: Board): boolean {
  return board.allow_rich_text !== false; // 기본값 true
}

// 카테고리 필수 체크
export function isCategoryRequired(board: Board): boolean {
  return board.require_category === true; // 기본값 false
}

// 포인트 차감 체크
export function getReadPoint(board: Board): number {
  return board.read_point || 0;
}

export function getWritePoint(board: Board): number {
  return board.write_point || 0;
}

export function getCommentPoint(board: Board): number {
  return board.comment_point || 0;
}

export function getDownloadPoint(board: Board): number {
  return board.download_point || 0;
} 