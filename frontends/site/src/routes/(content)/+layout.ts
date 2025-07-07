import type { LayoutLoad } from './$types';

export const load: LayoutLoad = async ({ url }) => {
  console.log('📁 (content) layout load 실행됨');
  console.log('🔗 URL:', url.pathname);
  
  return {
    url: url.pathname
  };
}; 