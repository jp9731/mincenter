import type { PageLoad } from './$types.js';

export const load: PageLoad = async ({ params }) => {
  return { slug: params.slug };
}; 