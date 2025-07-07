import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
  console.log('📋 [slug] +page.ts 실행됨 - 게시판 목록 페이지');
  console.log('📝 전체 params:', params);
  console.log('🔗 slug:', params.slug);
  console.log('📄 post_id (있다면):', (params as any).post_id);
  
  return { slug: params.slug };
}; 