// 환경 설정
export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// 앱 설정
export const APP_CONFIG = {
  name: '민중의집',
  description: '장애인 자립생활 지원 센터',
  version: '1.0.0'
};

// API 엔드포인트
export const API_ENDPOINTS = {
  auth: {
    register: '/api/auth/register',
    login: '/api/auth/login',
    refresh: '/api/auth/refresh',
    logout: '/api/auth/logout',
    me: '/api/auth/me'
  },
  community: {
    posts: '/api/posts',
    categories: '/api/categories',
    tags: '/api/tags'
  }
};

// 인증 설정
export const AUTH_TOKEN_KEY = 'auth_token';
export const AUTH_REFRESH_TOKEN_KEY = 'auth_refresh_token';

// 페이지네이션 설정
export const DEFAULT_PAGE_SIZE = 10;

// 파일 업로드 설정
export const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
export const ALLOWED_FILE_TYPES = ['image/jpeg', 'image/png', 'image/gif'];

// 소셜 로그인 설정
export const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID;
export const KAKAO_CLIENT_ID = import.meta.env.VITE_KAKAO_CLIENT_ID;

// 기타 설정
export const SITE_NAME = '민술';
export const SITE_DESCRIPTION = '민술 커뮤니티';