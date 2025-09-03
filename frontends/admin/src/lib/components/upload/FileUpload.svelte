<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	// lucide-svelte 대신 기본 HTML 아이콘 사용
	const Upload = '📤';
	const X = '❌';
	const File = '📄';
	const ImageIcon = '🖼️';
	const FileText = '📝';
	const Music = '🎵';
	const Video = '🎬';
	const Archive = '📦';
	const Zap = '⚡';

	export let files: File[] = [];
	export let maxFiles = 5;
	export let maxFileSize = 20 * 1024 * 1024; // 20MB로 증가
	export let allowedTypes: string[] | null = null;
	export let onUpload: ((file: File) => Promise<string>) | null = null;
	export let onUploadComplete: ((event: CustomEvent) => void) | null = null;
	export let disabled = false;
	export let enableImageCompression = false; // 이미지 압축 일시 비활성화 (File 생성자 문제 해결 전까지)

	const dispatch = createEventDispatcher();

	let dragOver = false;
	let uploadProgress: Record<string, number> = {};
	let uploadedFiles: Record<string, string> = {};
	let compressionProgress: Record<string, number> = {};
	let compressedFiles: Record<string, CompressedImageInfo> = {};

	interface CompressedImageInfo {
		file: Blob;
		originalSize: number;
		compressedSize: number;
		compressionRatio: number;
		fileName: string;
	}

	// allowedTypes가 null이거나 undefined일 때 기본값 사용
	$: safeAllowedTypes = allowedTypes || ['*/*'];

	// 이미지 압축 옵션
	function getCompressionOptions(file: File) {
		const sizeMB = file.size / (1024 * 1024);

		if (sizeMB > 10) {
			return { maxWidth: 1200, maxHeight: 800, quality: 0.6, format: 'webp' };
		} else if (sizeMB > 5) {
			return { maxWidth: 1600, maxHeight: 1000, quality: 0.7, format: 'webp' };
		} else if (sizeMB > 2) {
			return { maxWidth: 1920, maxHeight: 1080, quality: 0.8, format: 'webp' };
		} else {
			return { maxWidth: 1920, maxHeight: 1080, quality: 0.9, format: 'webp' };
		}
	}

	// 이미지 압축 함수
	async function compressImage(file: File): Promise<CompressedImageInfo> {
		const options = getCompressionOptions(file);

		return new Promise((resolve, reject) => {
			const canvas = document.createElement('canvas');
			const ctx = canvas.getContext('2d');
			const img = new Image();

			img.onload = () => {
				const originalWidth = img.width;
				const originalHeight = img.height;

				// 비율을 유지하면서 크기 조정
				const ratio = Math.min(options.maxWidth / originalWidth, options.maxHeight / originalHeight);
				const width = originalWidth * ratio;
				const height = originalHeight * ratio;

				canvas.width = width;
				canvas.height = height;

				ctx?.drawImage(img, 0, 0, width, height);

				canvas.toBlob(
					(blob) => {
						if (!blob) {
							reject(new Error('이미지 압축에 실패했습니다.'));
							return;
						}

						const originalName = file.name;
						const nameWithoutExt = originalName.substring(0, originalName.lastIndexOf('.'));
						const newFileName = `${nameWithoutExt}_compressed.${options.format}`;

						// File 생성자 대신 안전한 방법으로 파일 객체 생성
						let compressedFile: File;
						
						// Blob을 사용하여 압축된 파일 객체 생성
						const compressedBlob = new Blob([blob], {
							type: `image/${options.format}`
						});
						
						// Blob을 그대로 사용 (File 객체 대신)
						compressedFile = compressedBlob as File;

						const originalSize = file.size;
						const compressedSize = compressedFile.size;
						const compressionRatio = ((originalSize - compressedSize) / originalSize) * 100;

						resolve({
							file: compressedBlob,
							originalSize,
							compressedSize,
							compressionRatio,
							fileName: newFileName
						});
					},
					`image/${options.format}`,
					options.quality
				);
			};

			img.onerror = () => {
				reject(new Error('이미지를 로드할 수 없습니다.'));
			};

			img.src = URL.createObjectURL(file);
		});
	}

	// 이미지 파일인지 확인
	function isImageFile(file: File): boolean {
		return file.type.startsWith('image/');
	}

	// 이미지 압축이 필요한지 확인
	function needsCompression(file: File, thresholdMB: number = 2): boolean {
		if (!isImageFile(file)) return false;
		return file.size > thresholdMB * 1024 * 1024;
	}

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
		// 파일 크기 검사 (압축 후 크기 고려)
		const effectiveSize = compressedFiles[file.name]?.compressedSize || file.size;
		if (effectiveSize > maxFileSize) {
			return `파일 크기가 너무 큽니다. (최대 ${formatFileSize(maxFileSize)})`;
		}

		// 파일 타입 검사
		if (safeAllowedTypes.length > 0 && !safeAllowedTypes.includes('*/*')) {
			const isValidType = safeAllowedTypes.some((type) => {
				if (type.endsWith('/*')) {
					return file.type.startsWith(type.replace('/*', ''));
				}
				return file.type === type;
			});
			if (!isValidType) {
				return `지원하지 않는 파일 형식입니다. (${safeAllowedTypes.join(', ')})`;
			}
		}

		// 파일 개수 검사
		if (files.length >= maxFiles) {
			return `최대 ${maxFiles}개까지 업로드 가능합니다.`;
		}

		return null;
	}

	// 파일 추가
	async function addFiles(newFiles: FileList | File[]) {
		const fileArray = Array.from(newFiles);

		for (const file of fileArray) {
			// 이미지 압축 처리
			if (enableImageCompression && isImageFile(file) && needsCompression(file)) {
				try {
					compressionProgress[file.name] = 0;
					compressionProgress = { ...compressionProgress };

					const compressedInfo = await compressImage(file);
					compressedFiles[file.name] = compressedInfo;
					compressionProgress[file.name] = 100;
					compressionProgress = { ...compressionProgress };

					console.log(`이미지 압축 완료: ${file.name} (${formatFileSize(compressedInfo.originalSize)} → ${formatFileSize(compressedInfo.compressedSize)}, ${compressedInfo.compressionRatio.toFixed(1)}% 압축)`);
				} catch (error) {
					console.error('이미지 압축 실패:', error);
					// 압축 실패 시 원본 파일 사용
				}
			}

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
		delete compressionProgress[file.name];
		delete compressedFiles[file.name];
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
		input.accept = safeAllowedTypes.join(',');
		input.onchange = (e) => {
			const files = (e.target as HTMLInputElement).files;
			if (files) {
				addFiles(files);
			}
		};
		input.click();
	}

	// 파일 업로드 (압축된 파일 우선 사용)
	async function uploadFile(file: File) {
		if (!onUpload) return;

		uploadProgress[file.name] = 0;
		uploadProgress = { ...uploadProgress };

		try {
					// 원본 파일 사용 (압축 기능 일시 비활성화)
		const fileToUpload = file;
			const url = await onUpload(fileToUpload);
			uploadedFiles[file.name] = url;
			uploadProgress[file.name] = 100;
			uploadProgress = { ...uploadProgress };
			dispatch('uploadComplete', { file: fileToUpload, url });
			
			// onUploadComplete 콜백 호출
			if (onUploadComplete) {
				onUploadComplete(new CustomEvent('uploadComplete', { detail: { file: fileToUpload, url } }));
			}
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

	// 압축 정보 표시
	function getCompressionInfo(file: File): string | null {
		const compressed = compressedFiles[file.name];
		if (!compressed) return null;
		
		return `${formatFileSize(compressed.originalSize)} → ${formatFileSize(compressed.compressedSize)} (${compressed.compressionRatio.toFixed(1)}% 압축)`;
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
		<div class="mx-auto mb-4 h-12 w-12 text-gray-400 text-4xl flex items-center justify-center">{Upload}</div>
		<div class="mb-2 text-lg font-medium text-gray-900">
			파일을 드래그하여 업로드하거나 클릭하여 선택하세요
		</div>
		<div class="text-sm text-gray-500">
			최대 {maxFiles}개 파일, 각 파일 최대 {formatFileSize(maxFileSize)}
		</div>
		{#if enableImageCompression}
			<div class="mt-1 text-sm text-green-600">
				✓ 이미지 자동 압축 활성화 (WebP 변환)
			</div>
		{/if}
		{#if safeAllowedTypes.length > 0 && !safeAllowedTypes.includes('*/*')}
			<div class="mt-1 text-sm text-gray-500">
				지원 형식: {safeAllowedTypes.join(', ')}
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
					<button 
						class="px-3 py-1 text-sm bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
						onclick={uploadAllFiles} 
						{disabled}
					>
						모두 업로드
					</button>
				{/if}
			</div>

			<div class="space-y-2">
				{#each files as file, index}
					<div class="flex items-center justify-between rounded-lg bg-gray-50 p-3">
						<div class="flex items-center space-x-3">
							<div class="h-8 w-8 text-gray-500 text-2xl flex items-center justify-center">{getFileIcon(file)}</div>
							<div class="min-w-0 flex-1">
								<p class="truncate text-sm font-medium text-gray-900">{file.name}</p>
								<p class="text-sm text-gray-500">
									{#if compressedFiles[file.name]}
										<span class="text-green-600">{getCompressionInfo(file)}</span>
									{:else}
										{formatFileSize(file.size)}
									{/if}
								</p>
								{#if compressionProgress[file.name] !== undefined && compressionProgress[file.name] < 100}
									<div class="mt-1 flex items-center space-x-2">
										<div class="h-3 w-3 text-blue-500 text-sm">{Zap}</div>
										<div class="h-2 flex-1 rounded-full bg-gray-200">
											<div
												class="h-2 rounded-full bg-blue-600 transition-all duration-300"
												style="width: {compressionProgress[file.name]}%"
											></div>
										</div>
										<span class="text-xs text-gray-500">압축 중...</span>
									</div>
								{/if}
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
								<span class="px-2 py-1 text-xs bg-green-100 text-green-800 rounded">업로드 완료</span>
							{:else if onUpload}
								<button
									class="px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
									onclick={() => uploadFile(file)}
									disabled={disabled || uploadProgress[file.name] !== undefined}
								>
									업로드
								</button>
							{/if}
							<button 
								class="px-2 py-1 text-sm text-gray-500 hover:text-gray-700 disabled:opacity-50 disabled:cursor-not-allowed"
								onclick={() => removeFile(index)} 
								{disabled}
							>
								<div class="h-4 w-4 text-sm">{X}</div>
							</button>
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
