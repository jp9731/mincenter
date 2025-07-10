import tailwindcss from '@tailwindcss/vite';
import devtoolsJson from 'vite-plugin-devtools-json';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
	// 환경변수 로드
	const env = loadEnv(mode, process.cwd(), '');
	
	return {
		plugins: [tailwindcss(), sveltekit(), devtoolsJson()],
		server: {
			proxy: {
				'/api/admin': {
					target: 'http://localhost:18080',
					changeOrigin: true,
					secure: false,
					rewrite: (path) => path.replace(/^\/api\/admin/, '/api/admin')
				}
			}
		},
		build: {
			// 메모리 최적화 설정
			chunkSizeWarningLimit: 1000,
			rollupOptions: {
				output: {
					manualChunks: {
						vendor: ['svelte', '@sveltejs/kit'],
						ui: ['bits-ui']
					}
				}
			},
			// Tree shaking 최적화
			target: 'esnext',
			minify: 'terser',
			terserOptions: {
				compress: {
					drop_console: true,
					drop_debugger: true
				}
			}
		},
		// 환경변수 정의
		define: {
			'process.env.VITE_API_URL': JSON.stringify(env.VITE_API_URL)
		}
	};
});
