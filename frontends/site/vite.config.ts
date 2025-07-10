import tailwindcss from '@tailwindcss/vite';
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
	// 환경변수 로드
	const env = loadEnv(mode, process.cwd(), '');
	
	return {
		plugins: [tailwindcss(), sveltekit()],
		optimizeDeps: {
			exclude: ['svelte-fullcalendar']
		},
		resolve: {
			alias: {
				$lib: './src/lib'
			}
		},
		server: {
			proxy: {
				'/api': {
					target: 'http://localhost:8080',
					changeOrigin: true,
					secure: false
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
			'process.env.VITE_API_URL': JSON.stringify(env.VITE_API_URL),
			'process.env.VITE_GOOGLE_CLIENT_ID': JSON.stringify(env.VITE_GOOGLE_CLIENT_ID),
			'process.env.VITE_KAKAO_CLIENT_ID': JSON.stringify(env.VITE_KAKAO_CLIENT_ID)
		}
	};
});
