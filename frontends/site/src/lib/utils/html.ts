/**
 * HTML 유틸리티 함수들
 */

/**
 * HTML 엔티티를 일반 텍스트로 변환
 * @param html HTML 문자열
 * @returns 변환된 텍스트
 */
export function decodeHtmlEntities(html: string): string {
	return html
		.replace(/&nbsp;/g, ' ')  // non-breaking space를 일반 공백으로
		.replace(/&amp;/g, '&')   // ampersand
		.replace(/&lt;/g, '<')    // less than
		.replace(/&gt;/g, '>')    // greater than
		.replace(/&quot;/g, '"')  // quote
		.replace(/&#39;/g, "'")   // apostrophe
		.replace(/&apos;/g, "'"); // apostrophe (alternative)
}

/**
 * HTML 태그를 제거하고 텍스트만 추출
 * @param html HTML 문자열
 * @returns HTML 태그가 제거된 텍스트
 */
export function stripHtml(html: string | null | undefined): string {
	if (!html) return '';
	return decodeHtmlEntities(html)
		.replace(/<[^>]*>/g, '')  // HTML 태그 제거
		.replace(/\s+/g, ' ')     // 연속된 공백을 하나로
		.trim();
}

/**
 * HTML 내용을 안전하게 렌더링하기 위해 엔티티를 정리
 * @param html HTML 문자열
 * @returns 정리된 HTML 문자열
 */
export function cleanHtmlContent(html: string): string {
	return decodeHtmlEntities(html);
}
