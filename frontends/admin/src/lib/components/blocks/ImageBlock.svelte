<script lang="ts">
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Button } from '$lib/components/ui/button';
	import { Upload, Image as ImageIcon, Loader2 } from 'lucide-svelte';
	import type { ImageBlock } from '$lib/types/blocks';
	import { uploadImage } from '$lib/api/admin';

	interface Props {
		block: ImageBlock;
		onupdate?: (data: Partial<ImageBlock>) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, ondelete }: Props = $props();

	let isUploading = $state(false);

	function handleSrcChange(event: Event) {
		const target = event.target as HTMLInputElement;
		onupdate?.({ src: target.value });
	}

	function handleAltChange(event: Event) {
		const target = event.target as HTMLInputElement;
		onupdate?.({ alt: target.value });
	}

	function handleCaptionChange(event: Event) {
		const target = event.target as HTMLTextAreaElement;
		onupdate?.({ caption: target.value });
	}

	async function handleFileUpload(event: Event) {
		const target = event.target as HTMLInputElement;
		const file = target.files?.[0];
		
		if (!file) return;

		// 파일 타입 검증
		if (!file.type.startsWith('image/')) {
			alert('이미지 파일만 업로드할 수 있습니다.');
			return;
		}

		// 파일 크기 검증 (10MB)
		const maxSize = 10 * 1024 * 1024;
		if (file.size > maxSize) {
			alert('파일 크기가 너무 큽니다. 10MB 이하의 파일을 선택해주세요.');
			return;
		}

		isUploading = true;
		
		try {
			const response = await uploadImage(file);
			
			// API 서버 URL 기반으로 완전한 URL 생성
			const API_BASE = (typeof window !== 'undefined' && (window as any).ENV?.API_URL) || 
			                 import.meta.env.VITE_API_URL || 
			                 'https://api.mincenter.kr';
			
			const fullImageUrl = `${API_BASE}${response.url}`;
			const thumbnailUrl = response.thumbnail_url ? `${API_BASE}${response.thumbnail_url}` : undefined;
			
			onupdate?.({ 
				src: fullImageUrl,
				alt: file.name.split('.')[0],
				caption: response.file_info.original_name
			});

			// 파일 입력 초기화
			target.value = '';
		} catch (error) {
			console.error('Upload failed:', error);
			alert('파일 업로드에 실패했습니다. 다시 시도해주세요.');
		} finally {
			isUploading = false;
		}
	}
</script>

<div class="space-y-4">
	{#if block.src}
		<div class="relative">
			<img 
				src={block.src} 
				alt={block.alt} 
				class="max-w-full h-auto rounded-md border"
				style={block.width ? `max-width: ${block.width}px` : ''}
			/>
			{#if block.caption}
				<p class="mt-2 text-sm text-gray-600 text-center italic">
					{block.caption}
				</p>
			{/if}
		</div>
	{:else}
		<div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
			<ImageIcon class="mx-auto h-12 w-12 text-gray-400" />
			<p class="mt-2 text-sm text-gray-500">이미지를 추가하세요</p>
		</div>
	{/if}

	<div class="space-y-3">
		<div class="flex gap-2">
			<Input
				value={block.src}
				placeholder="이미지 URL 또는 경로"
				oninput={handleSrcChange}
				class="flex-1"
			/>
			<input
				type="file"
				accept="image/*"
				onchange={handleFileUpload}
				class="hidden"
				id="image-upload-{block.id}"
			/>
			<Button
				variant="outline"
				onclick={() => document.getElementById(`image-upload-${block.id}`)?.click()}
				disabled={isUploading}
			>
				{#if isUploading}
					<Loader2 class="h-4 w-4 animate-spin" />
				{:else}
					<Upload class="h-4 w-4" />
				{/if}
			</Button>
		</div>

		<Input
			value={block.alt}
			placeholder="대체 텍스트 (alt)"
			oninput={handleAltChange}
		/>

		<Textarea
			value={block.caption || ''}
			placeholder="이미지 설명 (선택사항)"
			rows={2}
			oninput={handleCaptionChange}
		/>
	</div>
</div>