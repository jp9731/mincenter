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
  description: string;
  category: string;
  post_count: number;
  created_at: string;
  is_active: boolean;
  sort_order: number;
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