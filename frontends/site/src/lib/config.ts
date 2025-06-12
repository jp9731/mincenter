// API 설정
export const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

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