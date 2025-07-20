<script lang="ts">
	import type { Block } from '$lib/types/blocks';

	export let content: string;

	let blocks: Block[] = [];

	$: {
		// Parse content and extract blocks
		if (content) {
			console.log('BlockRenderer received content:', content);
			try {
				const parsed = JSON.parse(content);
				console.log('Parsed content:', parsed);
				
				// Check if it's already in the expected BlocksData format
				if (parsed.blocks && Array.isArray(parsed.blocks)) {
					blocks = parsed.blocks.sort((a: Block, b: Block) => a.order - b.order);
					console.log('Loaded blocks from .blocks property:', blocks);
				} 
				// Check if it's a direct array of blocks
				else if (Array.isArray(parsed)) {
					blocks = parsed.sort((a: Block, b: Block) => a.order - b.order);
					console.log('Loaded blocks from direct array:', blocks);
				}
				// Check if it's a single block
				else if (parsed.type && parsed.id) {
					blocks = [parsed];
					console.log('Loaded single block:', blocks);
				}
				else {
					console.warn('Unknown content format:', parsed);
					blocks = [];
				}
			} catch (e) {
				console.warn('Failed to parse content as JSON:', e, 'Content was:', content);
				blocks = [];
			}
		} else {
			blocks = [];
		}
	}

	function renderListItems(items: string[]): string {
		return items.map(item => `<li class="text-gray-700 leading-relaxed mb-1">${item}</li>`).join('');
	}

	function getResponsiveColumnClass(column: any): string {
		// Tailwind 클래스를 사용하여 반응형 그리드 컬럼 생성
		const desktop = `col-span-${column.width}`;
		const tablet = column.widthTablet ? `md:col-span-${column.widthTablet}` : `md:col-span-${column.width}`;
		const mobile = column.widthMobile ? `sm:col-span-${column.widthMobile}` : 'col-span-12';
		
		return `${mobile} ${tablet} ${desktop}`;
	}
</script>

{#if blocks.length > 0}
	<!-- Render blocks -->
	{#each blocks as block}
		{#if block.type === 'paragraph'}
			<p class="mb-6 leading-relaxed text-gray-700 text-lg">{block.content}</p>
		{:else if block.type === 'heading'}
			{#if block.level === 1}
				<h1 class="text-4xl font-bold mb-8 mt-12 text-gray-900 border-b-2 border-blue-200 pb-4">{block.content}</h1>
			{:else if block.level === 2}
				<h2 class="text-3xl font-bold mb-6 mt-10 text-gray-900">{block.content}</h2>
			{:else if block.level === 3}
				<h3 class="text-2xl font-bold mb-5 mt-8 text-gray-800">{block.content}</h3>
			{:else if block.level === 4}
				<h4 class="text-xl font-semibold mb-4 mt-6 text-gray-800">{block.content}</h4>
			{:else if block.level === 5}
				<h5 class="text-lg font-semibold mb-3 mt-5 text-gray-700">{block.content}</h5>
			{:else if block.level === 6}
				<h6 class="text-base font-semibold mb-3 mt-4 text-gray-700 uppercase tracking-wide">{block.content}</h6>
			{/if}
		{:else if block.type === 'image'}
			<figure class="my-8">
				<div class="bg-gray-50 rounded-xl p-2 shadow-sm">
					<img
						src={block.src}
						alt={block.alt}
						class="max-w-full h-auto rounded-lg shadow-md transition-transform hover:scale-[1.02]"
						style={block.width ? `max-width: ${block.width}px` : ''}
					/>
				</div>
				{#if block.caption}
					<figcaption class="mt-3 text-sm text-gray-600 text-center italic font-medium">
						{block.caption}
					</figcaption>
				{/if}
			</figure>
		{:else if block.type === 'list'}
			{#if block.style === 'ordered'}
				<ol class="list-decimal list-inside mb-6 space-y-2 pl-2">
					{@html renderListItems(block.items)}
				</ol>
			{:else}
				<ul class="list-disc list-inside mb-6 space-y-2 pl-2">
					{@html renderListItems(block.items)}
				</ul>
			{/if}
		{:else if block.type === 'quote'}
			<blockquote class="border-l-4 border-blue-500 pl-8 py-6 my-8 italic text-xl bg-gradient-to-r from-blue-50 to-transparent rounded-r-lg">
				<p class="mb-3 text-gray-700 leading-relaxed">{block.content}</p>
				{#if block.author}
					<cite class="text-base text-gray-600 not-italic font-medium">— {block.author}</cite>
				{/if}
			</blockquote>
		{:else if block.type === 'code'}
			<div class="my-8">
				{#if block.language}
					<div class="text-xs text-gray-500 px-4 py-2 bg-gray-800 text-gray-300 rounded-t-lg border-b border-gray-700 font-mono">
						{block.language}
					</div>
				{/if}
				<pre class="bg-gray-900 text-gray-100 p-6 {block.language ? 'rounded-t-none' : 'rounded-lg'} rounded-b-lg overflow-x-auto shadow-lg"><code class={block.language ? `language-${block.language}` : ''} style="font-family: 'JetBrains Mono', 'Fira Code', Consolas, monospace;">{block.content}</code></pre>
			</div>
		{:else if block.type === 'map'}
			<div class="my-8">
				{#if block.title}
					<h3 class="text-lg font-semibold mb-4 text-gray-800">{block.title}</h3>
				{/if}
				<div class="bg-gray-100 rounded-lg p-4 shadow-sm">
					<div 
						id="kakao-map-{block.id}"
						class="w-full rounded-lg overflow-hidden shadow-md"
						style="width: {block.width || 400}px; height: {block.height || 300}px; max-width: 100%;"
					></div>
					{#if block.address}
						<p class="mt-3 text-sm text-gray-600 text-center">
							📍 {block.address}
						</p>
					{/if}
				</div>
				<!-- 카카오 맵 스크립트 -->
				{#if block.apiKey && block.latitude && block.longitude}
					<script>
						if (typeof window !== 'undefined' && !window.kakao) {
							const script = document.createElement('script');
							script.async = true;
							script.src = `//dapi.kakao.com/v2/maps/sdk.js?appkey=${block.apiKey}&autoload=false`;
							script.onload = () => {
								window.kakao.maps.load(() => {
									const container = document.getElementById('kakao-map-${block.id}');
									if (container) {
										const options = {
											center: new window.kakao.maps.LatLng(${block.latitude}, ${block.longitude}),
											level: ${block.zoom || 3}
										};
										const map = new window.kakao.maps.Map(container, options);
										
										// 마커 추가
										const markerPosition = new window.kakao.maps.LatLng(${block.latitude}, ${block.longitude});
										const marker = new window.kakao.maps.Marker({
											position: markerPosition
										});
										marker.setMap(map);
									}
								});
							};
							document.head.appendChild(script);
						} else if (window.kakao && window.kakao.maps) {
							// 이미 로드된 경우
							const container = document.getElementById('kakao-map-${block.id}');
							if (container) {
								const options = {
									center: new window.kakao.maps.LatLng(${block.latitude}, ${block.longitude}),
									level: ${block.zoom || 3}
								};
								const map = new window.kakao.maps.Map(container, options);
								
								const markerPosition = new window.kakao.maps.LatLng(${block.latitude}, ${block.longitude});
								const marker = new window.kakao.maps.Marker({
									position: markerPosition
								});
								marker.setMap(map);
							}
						}
					</script>
				{/if}
			</div>
		{:else if block.type === 'grid'}
			<div class="my-8">
				<div class="grid grid-cols-12 gap-{block.gap || 4} items-{block.alignment || 'start'}">
					{#each block.columns as column}
						<div class="space-y-4 {getResponsiveColumnClass(column)}">
							{#each column.blocks as columnBlock}
								<svelte:self content={JSON.stringify({ blocks: [columnBlock], version: '1.0' })} />
							{/each}
						</div>
					{/each}
				</div>
			</div>
		{:else if block.type === 'post-list'}
			<div class="my-8">
				{#if block.title}
					<h3 class="text-2xl font-bold mb-6 text-gray-900">{block.title}</h3>
				{/if}
				<div class="bg-gray-50 p-6 rounded-lg">
					<div class="text-center text-gray-600">
						<div class="text-lg font-medium mb-2">
							{#if block.layout === 'carousel'}
								🎠 포스트 캐러셀
							{:else}
								📄 포스트 목록
							{/if}
						</div>
						<div class="text-sm space-y-1">
							<div>게시판: {block.boardType || 'community'}</div>
							{#if block.category}
								<div>카테고리: {block.category}</div>
							{/if}
							<div>정렬: {block.sortBy === 'recent' ? '최신순' : block.sortBy === 'popular' ? '인기순' : '좋아요순'}</div>
							<div>표시 개수: {block.limit}개</div>
							{#if block.layout === 'carousel'}
								<div>레이아웃: 캐러셀 ({block.carouselOptions?.itemsPerView || 3}개씩 표시)</div>
								{#if block.carouselOptions?.autoPlay}
									<div>자동 전환: {block.carouselOptions.autoPlayInterval}초 간격</div>
								{/if}
							{:else}
								<div>레이아웃: {block.layout === 'list' ? '목록형' : block.layout === 'card' ? '카드형' : '심플형'}</div>
							{/if}
							<div class="text-xs text-gray-500 mt-3">
								※ 실제 사이트에서는 여기에 실제 게시글 목록이 표시됩니다
							</div>
						</div>
					</div>
				</div>
			</div>
		{:else if block.type === 'divider'}
			<div class="my-12 flex items-center justify-center">
				<div class="w-full max-w-xs">
					<hr class="border-gray-300 border-t-2" />
				</div>
			</div>
		{:else if block.type === 'html'}
			<div class="my-6 p-4 border border-gray-200 rounded-lg bg-gray-50">
				{@html block.content}
			</div>
		{/if}
	{/each}
{:else}
	<!-- Fallback: show message if no blocks or invalid content -->
	{#if content}
		{#if content.trim().startsWith('{') && content.trim().endsWith('}')}
			<!-- Looks like JSON but failed to parse properly -->
			<div class="p-6 bg-gray-50 rounded-lg border border-gray-200">
				<div class="text-center text-gray-600">
					<p class="text-lg font-medium mb-2">컨텐츠 로딩 중...</p>
					<p class="text-sm">페이지 내용을 불러오고 있습니다.</p>
				</div>
			</div>
		{:else}
			<!-- Plain text content -->
			<div class="prose max-w-none">
				{@html content}
			</div>
		{/if}
	{:else}
		<!-- No content at all -->
		<div class="p-6 bg-gray-50 rounded-lg border border-gray-200">
			<div class="text-center text-gray-600">
				<p class="text-lg font-medium mb-2">내용이 없습니다</p>
				<p class="text-sm">이 페이지에는 아직 내용이 없습니다.</p>
			</div>
		</div>
	{/if}
{/if}