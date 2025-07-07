import type { ApiResponse } from '../types/community.js';

export interface MenuTree {
  id: string;
  name: string;
  description?: string;
  menu_type: 'page' | 'board' | 'url';
  target_id?: string;
  slug?: string;
  url?: string;
  display_order: number;
  is_active: boolean;
  children: MenuTree[];
}

export interface SiteMenuResponse {
  menus: MenuTree[];
  cached_at: string;
}

// 기본 메뉴 데이터 (API 실패 시 폴백용)
export const DEFAULT_MENUS: MenuTree[] = [
  {
    id: '1',
    name: '민들레는요',
    url: '/about',
    menu_type: 'page',
    display_order: 1,
    is_active: true,
    children: []
  },
  {
    id: '2',
    name: '사업소개',
    url: '/services',
    menu_type: 'page',
    display_order: 2,
    is_active: true,
    children: []
  },
  {
    id: '3',
    name: '정보마당',
    url: '/community',
    menu_type: 'board',
    display_order: 3,
    is_active: true,
    children: []
  },
  {
    id: '4',
    name: '일정',
    url: '/calendar',
    menu_type: 'page',
    display_order: 4,
    is_active: true,
    children: []
  },
  {
    id: '5',
    name: '후원하기',
    url: '/donation',
    menu_type: 'page',
    display_order: 5,
    is_active: true,
    children: []
  }
];

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export async function getSiteMenus(): Promise<ApiResponse<SiteMenuResponse>> {
  try {
    const response = await fetch(`${API_BASE}/api/site/menus`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('API 응답 오류:', {
        status: response.status,
        statusText: response.statusText,
        url: response.url,
        error: errorText
      });
      
      throw new Error(`Failed to fetch site menus: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    
    // 응답 구조 검증
    if (!data.success || !data.data || !Array.isArray(data.data.menus)) {
      console.error('API 응답 구조 오류:', data);
      throw new Error('Invalid API response structure');
    }

    return data;
  } catch (error) {
    console.error('메뉴 API 호출 실패:', error);
    
    // 네트워크 오류나 API 서버 문제인 경우 폴백 데이터 반환
    if (error instanceof TypeError && error.message.includes('fetch')) {
      console.warn('네트워크 오류로 인해 기본 메뉴를 사용합니다.');
      return {
        success: true,
        data: {
          menus: DEFAULT_MENUS,
          cached_at: new Date().toISOString()
        },
        message: '기본 메뉴 데이터 (API 서버 연결 실패)'
      };
    }
    
    throw error;
  }
}

export interface Page {
  id: string;
  slug: string;
  title: string;
  content: string;
  excerpt?: string;
  meta_title?: string;
  meta_description?: string;
  status: string;
  is_published: boolean;
  published_at?: string;
  created_by?: string;
  created_at: string;
  updated_at: string;
  updated_by?: string;
  view_count: number;
  sort_order: number;
}

export async function getPageBySlug(slug: string): Promise<ApiResponse<Page>> {
  const response = await fetch(`${API_BASE}/api/pages/${slug}`);

  if (!response.ok) {
    throw new Error('Failed to fetch page');
  }

  return response.json();
} 