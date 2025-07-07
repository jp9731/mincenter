/**
 * YouTube 링크를 임베드 영상으로 변환하는 함수
 * @param content - 변환할 HTML 내용
 * @returns 변환된 HTML 내용
 */
export function processYouTubeLinks(content: string): string {
	if (!content) return '';
	
	let processedContent = content;
	
	// 1단계: <a> 태그로 감싸진 YouTube 링크 처리
	processedContent = processedContent.replace(
		/<a[^>]*href="([^"]*youtube\.com[^"]*)"[^>]*>([^<]*)<\/a>/gi,
		(match, href, text) => {
			const videoId = extractYouTubeVideoId(href);
			if (videoId) {
				return `<div class="youtube-embed-container my-4">
					<iframe 
						width="100%" 
						height="315" 
						src="${createYouTubeEmbedUrl(videoId)}" 
						title="YouTube video player" 
						frameborder="0" 
						allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
						allowfullscreen
						class="youtube-iframe"
					></iframe>
				</div>`;
			}
			// YouTube 링크가 아니면 원본 유지
			return match;
		}
	);
	
	// 2단계: 일반 텍스트로 된 YouTube 링크 처리
	// YouTube 링크 패턴들
	const youtubePatterns = [
		/https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)(?:\?[^\s<>]*)?/g,
		/https?:\/\/(?:www\.)?youtu\.be\/([a-zA-Z0-9_-]+)(?:\?[^\s<>]*)?/g,
		/https?:\/\/(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)(?:\?[^\s<>]*)?/g
	];
	
	youtubePatterns.forEach(pattern => {
		processedContent = processedContent.replace(pattern, (match, videoId) => {
			// 이미 iframe으로 변환된 경우 스킵
			if (match.includes('youtube-embed-container')) {
				return match;
			}
			return `<div class="youtube-embed-container my-4">
				<iframe 
					width="100%" 
					height="315" 
					src="${createYouTubeEmbedUrl(videoId)}" 
					title="YouTube video player" 
					frameborder="0" 
					allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
					allowfullscreen
					class="youtube-iframe"
				></iframe>
			</div>`;
		});
	});
	
	return processedContent.trim();
}

/**
 * YouTube 비디오 ID를 추출하는 함수
 * @param url - YouTube URL
 * @returns 비디오 ID 또는 null
 */
export function extractYouTubeVideoId(url: string): string | null {
	// URL에서 쿼리 파라미터 제거
	const cleanUrl = url.split('?')[0];
	
	const patterns = [
		/https?:\/\/(?:www\.)?youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)/,
		/https?:\/\/(?:www\.)?youtu\.be\/([a-zA-Z0-9_-]+)/,
		/https?:\/\/(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)/
	];
	
	for (const pattern of patterns) {
		const match = url.match(pattern);
		if (match) {
			return match[1];
		}
	}
	
	return null;
}

/**
 * YouTube 임베드 URL을 생성하는 함수
 * @param videoId - YouTube 비디오 ID
 * @returns 임베드 URL
 */
export function createYouTubeEmbedUrl(videoId: string): string {
	return `https://www.youtube.com/embed/${videoId}`;
} 