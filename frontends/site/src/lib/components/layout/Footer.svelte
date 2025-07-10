<script lang="ts">
	import { onMount } from 'svelte';

	let currentYear = new Date().getFullYear();
	
	// Svelte 5 스타일 터치 및 모바일 감지
	let isTouching = $state(false);
	let innerWidth = $state(typeof window !== 'undefined' ? window.innerWidth : 1024);
	let isMobile = $derived(innerWidth < 768);
	
	// 터치 투명도 계산 (5% 최소 투명도)
	let touchOpacity = $derived(isTouching ? 0.05 : 1);

	// 맨위로 스크롤 함수
	function scrollToTop() {
		window.scrollTo({ top: 0, behavior: 'smooth' });
	}

	// 전화 걸기 함수
	function makeCall() {
		window.location.href = 'tel:032-542-9294';
	}
	
	// 터치 이벤트 핸들러
	function handleTouchStart() {
		isTouching = true;
	}
	
	function handleTouchEnd() {
		isTouching = false;
	}
	
	// 윈도우 크기 변경 핸들러
	function handleResize() {
		innerWidth = window.innerWidth;
	}
	
	onMount(() => {
		// 터치 이벤트 리스너 추가
		document.addEventListener('touchstart', handleTouchStart);
		document.addEventListener('touchend', handleTouchEnd);
		document.addEventListener('touchcancel', handleTouchEnd);
		
		// 윈도우 크기 변경 리스너
		window.addEventListener('resize', handleResize);
		
		return () => {
			document.removeEventListener('touchstart', handleTouchStart);
			document.removeEventListener('touchend', handleTouchEnd);
			document.removeEventListener('touchcancel', handleTouchEnd);
			window.removeEventListener('resize', handleResize);
		};
	});
</script>

<svelte:window bind:innerWidth={innerWidth} />

<footer class="mt-16 py-8 text-white" style="background-color: oklch(0.41 0.10 131);">
	<div class="max-w-7xl mx-auto px-4 flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
		<div class="flex flex-col md:flex-row md:items-center gap-6 md:gap-12 w-full">
			<!-- 로고 이미지 -->
			<div class="flex-shrink-0 mx-auto md:mx-0">
				<img src="/images/min_logo.png" alt="민들레장애인자립생활센터 로고" class="w-32 h-32 object-contain">
			</div>
			
			<!-- 기존 정보 -->
			<div class="min-w-[340px] md:min-w-[420px] flex-1">
				<h2 class="mb-2 text-lg font-bold">민들레장애인자립생활센터</h2>
				<ul class="space-y-1 text-base">
					<li><span class="font-semibold">대표</span>: 박길연</li>
					<li>
						<span class="font-semibold">주소</span>: 인천광역시 계양구 계산새로71 A동 201~202호
						<span class="text-sm text-gray-200">(계산동, 하이베라스)</span>
					</li>
					<li><span class="font-semibold">사업자등록번호</span>: 131-80-12554</li>
					<li>
						<span class="font-semibold">전화</span>: <a href="tel:032-542-9294" class="underline text-green-200 font-medium">032-542-9294</a>
					</li>
					<li>
						<span class="font-semibold">이메일</span>: <a href="mailto:mincenter08@daum.net" class="underline text-green-200 font-medium">mincenter08@daum.net</a>
					</li>
					<li><span class="font-semibold">전자팩스</span>: 032-232-0739</li>
				</ul>
			</div>
		</div>
		<div class="text-center md:text-right mt-6 md:mt-0 w-full">
			<p class="text-md">© 2025 민들레장애인자립생활센터. All rights reserved.</p>
		</div>
	</div>
</footer>

<!-- 플로팅 메뉴 -->
<div 
	class="fixed bottom-12 z-50 transition-all duration-1400"
	class:right-6={isMobile}
	class:right-12={!isMobile}
	style="opacity: {touchOpacity};"
>
	<ul class="flex flex-col space-y-3">
		<!-- 전화 버튼 -->
		<li class="flex justify-end">
			<button
				onclick={makeCall}
				class="fab-btn group ml-auto"
				aria-label="전화하기"
			>
				<svg class="fab-icon h-7 w-7 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
					<path
						d="M2 3a1 1 0 011-1h2.153a1 1 0 01.986.836l.74 4.435a1 1 0 01-.54 1.06l-1.548.773a11.037 11.037 0 006.105 6.105l.774-1.548a1 1 0 011.059-.54l4.435.74a1 1 0 01.836.986V17a1 1 0 01-1 1h-2C7.82 18 2 12.18 2 5V3z"
					/>
				</svg>
				<span class="fab-label">전화</span>
			</button>
		</li>

		<!-- 유튜브 버튼 -->
		<li class="flex justify-end">
			<a
				href="#"
				class="fab-btn group ml-auto"
				aria-label="유튜브"
			>
				<svg class="fab-icon h-7 w-7 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
					<path
						d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"
					/>
				</svg>
				<span class="fab-label">유튜브</span>
			</a>
		</li>

		<!-- 인스타그램 버튼 -->
		<li class="flex justify-end">
			<a
				href="https://www.instagram.com/mincenter08?igsh=bTZyM2Qxa2t4ajJv"
				target="_blank"
				rel="noopener noreferrer"
				class="fab-btn group ml-auto"
				aria-label="인스타그램"
			>
				<svg class="fab-icon h-7 w-7 flex-shrink-0" fill="currentColor" viewBox="0 0 24 24">
					<path
						d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"
					/>
				</svg>
				<span class="fab-label">인스타</span>
			</a>
		</li>

		<!-- 맨위로 버튼 -->
		<li class="flex justify-end">
			<button
				onclick={scrollToTop}
				class="flex h-14 w-14 items-center justify-center rounded-full bg-white p-4 text-gray-500 shadow-lg transition-all duration-200 hover:scale-110 hover:bg-gray-200 ml-auto"
				aria-label="맨위로"
			>
				<svg class="fab-icon h-7 w-7 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
					<path
						fill-rule="evenodd"
						d="M3.293 9.707a1 1 0 010-1.414l6-6a1 1 0 011.414 0l6 6a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L4.707 9.707a1 1 0 01-1.414 0z"
						clip-rule="evenodd"
					/>
				</svg>
			</button>
		</li>
	</ul>
</div>

<style>
.fab-btn {
	display: flex;
	align-items: center;
	width: 56px;
	height: 56px;
	background: oklch(0.65 0.18 132);
	border-radius: 9999px;
	box-shadow: 0 2px 8px rgba(0,0,0,0.15);
	color: white;
	cursor: pointer;
	transition: width 0.3s cubic-bezier(.4,0,.2,1), justify-content 0.3s;
	overflow: hidden;
	position: relative;
	justify-content: center;
}
.fab-btn:hover {
	width: 112px;
	justify-content: flex-start;
}
.fab-icon {
	transition: margin 0.3s;
	margin-left: 0;
	margin-right: 0;
	display: block;
	margin-left: auto;
	margin-right: auto;
}
.fab-btn:hover .fab-icon {
	margin-left: 16px;
	margin-right: 8px;
}
.fab-label {
	display: none;
	opacity: 0;
	transform: translateX(-10px);
	transition: opacity 0.2s, transform 0.2s;
	white-space: nowrap;
	font-size: 1rem;
	pointer-events: none;
}
.fab-btn:hover .fab-label {
	display: flex;
	opacity: 1;
	transform: translateX(0);
}
</style>
