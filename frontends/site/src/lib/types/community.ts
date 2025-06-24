export interface Board {
  id: string;
  slug: string;
  name: string;
  description?: string;
  category?: string;
  display_order?: number;
  is_public?: boolean;
  allow_anonymous?: boolean;
  // 파일 업로드 설정
  allow_file_upload?: boolean;
  max_files?: number;
  max_file_size?: number;
  allowed_file_types?: string[];
  // 리치 텍스트 에디터 설정
  allow_rich_text?: boolean;
  // 기타 설정
  require_category?: boolean;
  allow_comments?: boolean;
  allow_likes?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface Category {
  id: string;
  board_id: string;
  name: string;
  description?: string;
  display_order?: number;
  is_active?: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface Post {
  id: string;
  board_id: string;
  category_id?: string;
  user_id: string;
  title: string;
  content: string;
  views?: number;
  likes?: number;
  comments?: number;
  is_notice?: boolean;
  status?: string;
  created_at?: string;
  updated_at?: string;
}

export interface PostDetail extends Post {
  user_name: string;
  board_name: string;
  board_slug: string;
  category_name?: string;
  comment_count?: number;
  user_id: string;
  board_id: string;
  category_id?: string;
  created_at: string;
  updated_at: string;
}

export interface Comment {
  id: string;
  post_id: string;
  user_id: string;
  parent_id?: string;
  content: string;
  likes?: number;
  status?: string;
  created_at?: string;
  updated_at?: string;
}

export interface CommentDetail extends Comment {
  user_name: string;
  user_id: string;
  created_at: string;
  updated_at: string;
}

export interface BoardStats {
  board_id: string;
  board_name: string;
  post_count?: number;
  comment_count?: number;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  pagination?: any;
}

export interface Category {
  id: string;
  name: string;
  description?: string;
  postCount: number;
}

export interface Tag {
  id: string;
  name: string;
  postCount: number;
}

export type PostSortOption = 'latest' | 'popular' | 'comments';
export interface PostFilter {
  search: string;
  board_id?: string;
  category_id?: string;
  tags: string[];
  sort: 'latest' | 'popular' | 'comments';
  page: number;
  limit: number;
}

export interface PostsResponse {
  posts: Post[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}