// 관리자 사용자 타입
export interface AdminUser {
  id: string;
  username: string;
  email: string;
  role: 'super_admin' | 'admin' | 'moderator';
  name: string;
  avatar?: string;
  created_at: string;
  last_login?: string;
  is_active: boolean;
  permissions: string[];
}

// 대시보드 통계 타입
export interface DashboardStats {
  total_users: number;
  total_posts: number;
  total_comments: number;
  total_boards: number;
  active_volunteers: number;
  total_donations: number;
  monthly_visitors: number;
  monthly_posts: number;
}

// 사용자 관리 타입
export interface User {
  id: string;
  username: string;
  email: string;
  name: string;
  role: 'user' | 'admin' | 'moderator';
  status: 'active' | 'suspended' | 'pending';
  created_at: string;
  last_login?: string;
  post_count: number;
  comment_count: number;
  point_balance: number;
}

// 게시글 관리 타입
export interface Post {
  id: string;
  title: string;
  content: string;
  board_id: string;
  board_name: string;
  user_id: string;
  user_name: string;
  created_at: string;
  updated_at?: string;
  views: number;
  likes: number;
  comment_count: number;
  is_notice: boolean;
  status: 'published' | 'draft' | 'hidden';
}

// 게시판 관리 타입
export interface Board {
  id: string;
  name: string;
  slug: string;
  description?: string;
  category?: string;
  display_order: number;
  is_public: boolean;
  allow_anonymous: boolean;
  allow_file_upload: boolean;
  max_files: number;
  max_file_size: number;
  allowed_file_types?: string[];
  allow_rich_text: boolean;
  require_category: boolean;
  allow_comments: boolean;
  allow_likes: boolean;
  write_permission: string;
  list_permission: string;
  read_permission: string;
  reply_permission: string;
  comment_permission: string;
  download_permission: string;
  hide_list: boolean;
  editor_type: string;
  allow_search: boolean;
  allow_recommend: boolean;
  allow_disrecommend: boolean;
  show_author_name: boolean;
  show_ip: boolean;
  edit_comment_limit: number;
  delete_comment_limit: number;
  use_sns: boolean;
  use_captcha: boolean;
  title_length: number;
  posts_per_page: number;
  read_point: number;
  write_point: number;
  comment_point: number;
  download_point: number;
  allowed_iframe_domains?: string[];
  created_at: string;
  updated_at: string;
}

// 카테고리 타입
export interface Category {
  id: string;
  board_id: string;
  name: string;
  description?: string;
  display_order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

// 댓글 관리 타입
export interface Comment {
  id: string;
  content: string;
  post_id: string;
  post_title: string;
  user_id: string;
  user_name: string;
  created_at: string;
  updated_at?: string;
  likes: number;
  status: 'published' | 'hidden';
}

// 페이지 관리 타입
export interface Page {
  id: string;
  slug: string;
  title: string;
  content: string;
  excerpt?: string;
  meta_title?: string;
  meta_description?: string;
  status: 'draft' | 'published' | 'archived';
  is_published: boolean;
  published_at?: string;
  created_by: string;
  created_by_name?: string;
  updated_by?: string;
  updated_by_name?: string;
  created_at: string;
  updated_at: string;
  view_count: number;
  sort_order: number;
}

// 페이지 생성 요청 타입
export interface CreatePageRequest {
  slug: string;
  title: string;
  content: string;
  excerpt?: string;
  meta_title?: string;
  meta_description?: string;
  status: 'draft' | 'published' | 'archived';
  is_published: boolean;
  sort_order?: number;
}

// 페이지 수정 요청 타입
export interface UpdatePageRequest {
  slug?: string;
  title?: string;
  content?: string;
  excerpt?: string;
  meta_title?: string;
  meta_description?: string;
  status?: 'draft' | 'published' | 'archived';
  is_published?: boolean;
  sort_order?: number;
}

// 페이지 상태 업데이트 타입
export interface PageStatusUpdate {
  status: 'draft' | 'published' | 'archived';
  is_published: boolean;
}

// 페이지 목록 응답 타입
export interface PageListResponse {
  pages: Page[];
  total: number;
  page: number;
  limit: number;
  total_pages: number;
}

// 봉사 활동 타입
export interface VolunteerActivity {
  id: string;
  title: string;
  description: string;
  date: string;
  location: string;
  volunteer_count: number;
  max_volunteers: number;
  status: 'upcoming' | 'ongoing' | 'completed' | 'cancelled';
  created_at: string;
}

// 후원 관리 타입
export interface Donation {
  id: string;
  donor_name: string;
  donor_email: string;
  amount: number;
  payment_method: string;
  status: 'pending' | 'completed' | 'failed' | 'refunded';
  created_at: string;
  receipt_sent: boolean;
}

// 알림 타입
export interface Notification {
  id: string;
  title: string;
  message: string;
  type: 'info' | 'success' | 'warning' | 'error';
  target_users: 'all' | 'admins' | 'specific';
  target_user_ids?: string[];
  created_at: string;
  sent_at?: string;
  read_count: number;
}

// 시스템 로그 타입
export interface SystemLog {
  id: string;
  level: 'info' | 'warning' | 'error' | 'critical';
  message: string;
  user_id?: string;
  user_name?: string;
  ip_address?: string;
  user_agent?: string;
  created_at: string;
}

// API 응답 타입
export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
}

// 페이지네이션 타입
export interface PaginationParams {
  page: number;
  limit: number;
  total?: number;
  total_pages?: number;
}

// 필터 타입
export interface FilterParams {
  search?: string;
  status?: string;
  role?: string;
  date_from?: string;
  date_to?: string;
  sort_by?: string;
  sort_order?: 'asc' | 'desc';
} 