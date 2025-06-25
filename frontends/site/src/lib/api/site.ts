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

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export async function getSiteMenus(): Promise<ApiResponse<SiteMenuResponse>> {
  const response = await fetch(`${API_BASE}/api/site/menus`);

  if (!response.ok) {
    throw new Error('Failed to fetch site menus');
  }

  return response.json();
}

export async function getPageBySlug(slug: string): Promise<ApiResponse<Page>> {
  const response = await fetch(`${API_BASE}/api/pages/${slug}`);

  if (!response.ok) {
    throw new Error('Failed to fetch page');
  }

  return response.json();
} 