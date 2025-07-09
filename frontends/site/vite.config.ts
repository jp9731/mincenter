import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
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
			'/api/site': {
				target: 'http://localhost:18080',
				changeOrigin: true,
				secure: false,
				rewrite: (path) => path.replace(/^\/api\/site/, '/api/site')
			},
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
	}
});
