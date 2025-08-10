import adapter from '@sveltejs/adapter-cloudflare';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://kit.svelte.dev/docs/integrations#preprocessors
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		// Cloudflare Pages 전용 어댑터 사용
		adapter: adapter({
			// Cloudflare Pages 설정
			platformProxy: {
				persist: true
			}
		}),
		paths: {
			base: process.env.NODE_ENV === 'production' ? '' : ''
		}
	}
};

export default config;
