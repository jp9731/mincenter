import type { PageLoad } from './$types';

const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export const load: PageLoad = async ({ params, fetch }) => {
  try {
    const apiUrl = `${API_BASE}/api/community/posts/${params.post_id}`;
    const res = await fetch(apiUrl);
    if (!res.ok) {
      const errorText = await res.text();
      throw new Error(`게시글을 불러올 수 없습니다. (${res.status})\n${errorText}`);
    }
    const post = await res.json();

    const boardApiUrl = `${API_BASE}/api/community/boards/${params.slug}`;
    const boardRes = await fetch(boardApiUrl);
    if (boardRes.ok) {
      const board = await boardRes.json();
      return {
        slug: params.slug,
        postId: params.post_id,
        post: post.data,
        board: board.data,
      };
    }
    return {
      slug: params.slug,
      postId: params.post_id,
      post: post.data,
    };
  } catch (error) {
    throw error;
  }
}; 