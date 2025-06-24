import type { ApiResponse } from '../types/community.js';

export interface MenuTree {
  id: string;
  name: string;
  description?: string;
  menu_type: 'page' | 'board' | 'url';
  target_id?: string;
  url?: string;
  display_order: number;
  is_active: boolean;
  children: MenuTree[];
}

export interface SiteMenuResponse {
  menus: MenuTree[];
  cached_at: string;
}

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export async function getSiteMenus(): Promise<ApiResponse<SiteMenuResponse>> {
  const response = await fetch(`${API_BASE}/api/site/menus`);

  if (!response.ok) {
    throw new Error('Failed to fetch site menus');
  }

  return response.json();
} 