// 사용자 타입
export interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  permissions?: string[];
  created_at: string;
  updated_at: string;
}

// 사용자 역할
export enum UserRole {
  ADMIN = 'admin',
  MODERATOR = 'moderator',
  USER = 'user',
  GUEST = 'guest'
}

// 사용자 프로필
export interface UserProfile {
  avatar?: string;
  phone?: string;
  address?: string;
  bio?: string;
  birthDate?: string;
  gender?: 'male' | 'female' | 'other';
}

// 인증 응답 (Rust API 형식)
export interface AuthResponse {
  user: User;
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

// 리프레시 응답 (Rust API 형식)
export interface RefreshResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

// 로그인 요청
export interface LoginRequest {
  email: string;
  password: string;
}

// 회원가입 요청
export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
}

// 리프레시 요청
export interface RefreshRequest {
  refresh_token: string;
}

// JWT 페이로드
export interface JWTPayload {
  sub: string; // 사용자 ID
  iat: number; // 발급 시간
  exp: number; // 만료 시간
}

// API 응답 기본 타입
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: {
    message: string;
  };
  pagination?: any;
}

// 페이지네이션 타입
export interface PaginationParams {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
} 