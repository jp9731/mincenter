import adapter from '@sveltejs/adapter-cloudflare';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

const config = {
	preprocess: vitePreprocess(),
	kit: {
		alias: {
			"@/*": "./path/to/lib/*",
		},
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
