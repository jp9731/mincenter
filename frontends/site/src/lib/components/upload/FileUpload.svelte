<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Upload,
		X,
		File,
		Image as ImageIcon,
		FileText,
		Music,
		Video,
		Archive
	} from 'lucide-svelte';

	export let files: File[] = [];
	export let maxFiles = 5;
	export let maxFileSize = 10 * 1024 * 1024; // 10MB
	export let allowedTypes: string[] = ['*/*'];
	export let onUpload: ((file: File) => Promise<string>) | null = null;
	export let disabled = false;

	const dispatch = createEventDispatcher();

	let dragOver = false;
	let uploadProgress: Record<string, number> = {};
	let uploadedFiles: Record<string, string> = {};

	// 파일 타입별 아이콘
	function getFileIcon(file: File) {
		if (file.type.startsWith('image/')) return ImageIcon;
		if (file.type.startsWith('video/')) return Video;
		if (file.type.startsWith('audio/')) return Music;
		if (file.type.includes('pdf') || file.type.includes('text/')) return FileText;
		if (file.type.includes('zip') || file.type.includes('rar')) return Archive;
		return File;
	}

	// 파일 크기 포맷팅
	function formatFileSize(bytes: number): string {
		if (bytes === 0) return '0 Bytes';
		const k = 1024;
		const sizes = ['Bytes', 'KB', 'MB', 'GB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
	}

	// 파일 유효성 검사
	function validateFile(file: File): string | null {
		// 파일 크기 검사
		if (file.size > maxFileSize) {
			return `파일 크기가 너무 큽니다. (최대 ${formatFileSize(maxFileSize)})`;
		}

		// 파일 타입 검사
		if (allowedTypes.length > 0 && !allowedTypes.includes('*/*')) {
			const isValidType = allowedTypes.some((type) => {
				if (type.endsWith('/*')) {
					return file.type.startsWith(type.replace('/*', ''));
				}
				return file.type === type;
			});
			if (!isValidType) {
				return `지원하지 않는 파일 형식입니다. (${allowedTypes.join(', ')})`;
			}
		}

		// 파일 개수 검사
		if (files.length >= maxFiles) {
			return `최대 ${maxFiles}개까지 업로드 가능합니다.`;
		}

		return null;
	}

	// 파일 추가
	function addFiles(newFiles: FileList | File[]) {
		const fileArray = Array.from(newFiles);

		for (const file of fileArray) {
			const error = validateFile(file);
			if (error) {
				alert(error);
				continue;
			}

			if (!files.find((f) => f.name === file.name && f.size === file.size)) {
				files = [...files, file];
				dispatch('filesChange', { files });
			}
		}
	}

	// 파일 제거
	function removeFile(index: number) {
		const file = files[index];
		files = files.filter((_, i) => i !== index);
		delete uploadProgress[file.name];
		delete uploadedFiles[file.name];
		dispatch('filesChange', { files });
	}

	// 드래그 앤 드롭 핸들러
	function handleDragOver(e: DragEvent) {
		e.preventDefault();
		dragOver = true;
	}

	function handleDragLeave(e: DragEvent) {
		e.preventDefault();
		dragOver = false;
	}

	function handleDrop(e: DragEvent) {
		e.preventDefault();
		dragOver = false;

		if (disabled) return;

		const droppedFiles = e.dataTransfer?.files;
		if (droppedFiles) {
			addFiles(droppedFiles);
		}
	}

	// 파일 선택
	function handleFileSelect() {
		if (disabled) return;

		const input = document.createElement('input');
		input.type = 'file';
		input.multiple = true;
		input.accept = allowedTypes.join(',');
		input.onchange = (e) => {
			const files = (e.target as HTMLInputElement).files;
			if (files) {
				addFiles(files);
			}
		};
		input.click();
	}

	// 파일 업로드
	async function uploadFile(file: File) {
		if (!onUpload) return;

		uploadProgress[file.name] = 0;
		uploadProgress = { ...uploadProgress };

		try {
			const url = await onUpload(file);
			uploadedFiles[file.name] = url;
			uploadProgress[file.name] = 100;
			uploadProgress = { ...uploadProgress };
			dispatch('uploadComplete', { file, url });
		} catch (error) {
			console.error('파일 업로드 실패:', error);
			delete uploadProgress[file.name];
			uploadProgress = { ...uploadProgress };
			alert(`${file.name} 업로드에 실패했습니다.`);
		}
	}

	// 모든 파일 업로드
	async function uploadAllFiles() {
		if (!onUpload) return;

		for (const file of files) {
			if (!uploadedFiles[file.name]) {
				await uploadFile(file);
			}
		}
	}

	// 파일 미리보기 URL 생성
	function getFilePreview(file: File): string | null {
		if (file.type.startsWith('image/')) {
			return URL.createObjectURL(file);
		}
		return null;
	}
</script>

<div class="space-y-4">
	<!-- 드래그 앤 드롭 영역 -->
	<div
		class="rounded-lg border-2 border-dashed p-8 text-center transition-colors {dragOver
			? 'border-blue-500 bg-blue-50'
			: 'border-gray-300 hover:border-gray-400'} {disabled
			? 'cursor-not-allowed opacity-50'
			: 'cursor-pointer'}"
		ondragover={handleDragOver}
		ondragleave={handleDragLeave}
		ondrop={handleDrop}
		onclick={handleFileSelect}
	>
		<Upload class="mx-auto mb-4 h-12 w-12 text-gray-400" />
		<div class="mb-2 text-lg font-medium text-gray-900">
			파일을 드래그하여 업로드하거나 클릭하여 선택하세요
		</div>
		<div class="text-sm text-gray-500">
			최대 {maxFiles}개 파일, 각 파일 최대 {formatFileSize(maxFileSize)}
		</div>
		{#if allowedTypes.length > 0 && !allowedTypes.includes('*/*')}
			<div class="mt-1 text-sm text-gray-500">
				지원 형식: {allowedTypes.join(', ')}
			</div>
		{/if}
	</div>

	<!-- 파일 목록 -->
	{#if files.length > 0}
		<div class="space-y-2">
			<div class="flex items-center justify-between">
				<h3 class="text-sm font-medium text-gray-900">
					선택된 파일 ({files.length}/{maxFiles})
				</h3>
				{#if onUpload}
					<Button size="sm" onclick={uploadAllFiles} {disabled}>모두 업로드</Button>
				{/if}
			</div>

			<div class="space-y-2">
				{#each files as file, index}
					<div class="flex items-center justify-between rounded-lg bg-gray-50 p-3">
						<div class="flex items-center space-x-3">
							<svelte:component this={getFileIcon(file)} class="h-8 w-8 text-gray-500" />
							<div class="min-w-0 flex-1">
								<p class="truncate text-sm font-medium text-gray-900">{file.name}</p>
								<p class="text-sm text-gray-500">{formatFileSize(file.size)}</p>
								{#if uploadProgress[file.name] !== undefined}
									<div class="mt-1 h-2 w-full rounded-full bg-gray-200">
										<div
											class="h-2 rounded-full bg-blue-600 transition-all duration-300"
											style="width: {uploadProgress[file.name]}%"
										></div>
									</div>
								{/if}
							</div>
						</div>

						<div class="flex items-center space-x-2">
							{#if uploadedFiles[file.name]}
								<Badge variant="default">업로드 완료</Badge>
							{:else if onUpload}
								<Button
									size="sm"
									variant="outline"
									onclick={() => uploadFile(file)}
									disabled={disabled || uploadProgress[file.name] !== undefined}
								>
									업로드
								</Button>
							{/if}
							<Button size="sm" variant="ghost" onclick={() => removeFile(index)} {disabled}>
								<X class="h-4 w-4" />
							</Button>
						</div>
					</div>

					<!-- 이미지 미리보기 -->
					{#if file.type.startsWith('image/')}
						<div class="ml-11">
							<img
								src={getFilePreview(file)}
								alt={file.name}
								class="max-h-32 max-w-xs rounded border object-cover"
							/>
						</div>
					{/if}
				{/each}
			</div>
		</div>
	{/if}
</div>
