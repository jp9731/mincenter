import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
	return {
		slug: params.slug,
		postId: params.post_id
	};
}; 