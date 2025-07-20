<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Switch } from '$lib/components/ui/switch';
	import { Trash2, Settings, FileText, Clock, Heart, TrendingUp } from 'lucide-svelte';
	import type { PostListBlock } from '$lib/types/blocks';

	interface Props {
		block: PostListBlock;
		onupdate?: (data: Partial<PostListBlock>) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, ondelete }: Props = $props();

	let showSettings = $state(false);

	function updateBlock(updates: Partial<PostListBlock>) {
		onupdate?.(updates);
	}

	function handleDelete() {
		ondelete?.();
	}

	const sortOptions = [
		{ value: 'recent', label: '최신순', icon: Clock },
		{ value: 'popular', label: '조회수순', icon: TrendingUp },
		{ value: 'likes', label: '좋아요순', icon: Heart }
	];

	const layoutOptions = [
		{ value: 'list', label: '목록형' },
		{ value: 'card', label: '카드형' },
		{ value: 'minimal', label: '심플형' },
		{ value: 'carousel', label: '캐러셀' }
	];

	const boardTypeOptions = [
		{ value: 'community', label: '커뮤니티' },
		{ value: 'news', label: '뉴스' },
		{ value: 'notice', label: '공지사항' },
		{ value: 'event', label: '이벤트' }
	];
</script>

<div class="border border-gray-200 rounded-lg p-4 bg-gray-50">
	<!-- 헤더 -->
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-2">
			<FileText class="h-5 w-5 text-blue-500" />
			<span class="font-medium text-gray-700">포스트 목록</span>
			{#if block.title}
				<span class="text-sm text-gray-500">- {block.title}</span>
			{/if}
		</div>
		<div class="flex gap-1">
			<Button
				variant="outline"
				size="sm"
				onclick={() => showSettings = !showSettings}
			>
				<Settings class="h-4 w-4" />
			</Button>
			<Button
				variant="outline"
				size="sm"
				onclick={handleDelete}
				class="text-red-500 hover:text-red-700"
			>
				<Trash2 class="h-4 w-4" />
			</Button>
		</div>
	</div>

	<!-- 미리보기 -->
	<div class="mb-4 p-3 bg-white rounded border">
		<div class="text-sm text-gray-600 mb-2">
			📋 {block.boardType ? boardTypeOptions.find(opt => opt.value === block.boardType)?.label : '전체'} 
			{block.category ? `• ${block.category}` : ''} 
			• {block.limit}개 • {sortOptions.find(opt => opt.value === block.sortBy)?.label}
			{#if block.layout === 'carousel'}
				• 🎠 캐러셀 ({block.carouselOptions?.itemsPerView || 3}개씩)
			{/if}
		</div>
		
		{#if block.layout === 'carousel'}
			<!-- Carousel 미리보기 -->
			<div class="relative bg-gray-50 rounded p-2">
				<div class="flex gap-2 overflow-hidden">
					{#each Array(Math.min(block.carouselOptions?.itemsPerView || 3, 3)) as _, index}
						<div class="flex-shrink-0 bg-white rounded border p-2" style="width: {100 / (block.carouselOptions?.itemsPerView || 3)}%">
							{#if block.carouselOptions?.showImageOnly}
								<div class="w-full h-20 bg-gray-200 rounded"></div>
							{:else}
								{#if block.showImage}
									<div class="w-full h-12 bg-gray-200 rounded mb-2"></div>
								{/if}
								<h5 class="text-xs font-medium truncate">제목 {index + 1}</h5>
								{#if block.showExcerpt && !block.carouselOptions?.showImageOnly}
									<p class="text-xs text-gray-600 truncate">요약...</p>
								{/if}
							{/if}
						</div>
					{/each}
				</div>
				{#if block.carouselOptions?.showArrows !== false}
					<div class="absolute inset-y-0 left-0 flex items-center">
						<div class="w-4 h-4 bg-gray-400 rounded-full text-xs flex items-center justify-center text-white">‹</div>
					</div>
					<div class="absolute inset-y-0 right-0 flex items-center">
						<div class="w-4 h-4 bg-gray-400 rounded-full text-xs flex items-center justify-center text-white">›</div>
					</div>
				{/if}
				{#if block.carouselOptions?.showDots !== false}
					<div class="flex justify-center mt-2 gap-1">
						{#each Array(3) as _, index}
							<div class="w-1.5 h-1.5 bg-gray-400 rounded-full"></div>
						{/each}
					</div>
				{/if}
			</div>
		{:else}
			<!-- 일반 레이아웃 미리보기 -->
			<div class="space-y-2">
				{#each Array(Math.min(block.limit, 3)) as _, index}
					<div class="flex items-center gap-3 p-2 bg-gray-50 rounded">
						{#if block.showImage}
							<div class="w-12 h-12 bg-gray-200 rounded flex-shrink-0"></div>
						{/if}
						<div class="flex-1 min-w-0">
							<div class="flex items-center gap-2 mb-1">
								{#if block.showCategory}
									<span class="text-xs bg-blue-100 text-blue-600 px-2 py-1 rounded">카테고리</span>
								{/if}
								{#if block.showDate}
									<span class="text-xs text-gray-500">2024.01.{15 + index}</span>
								{/if}
							</div>
							<h4 class="text-sm font-medium text-gray-900 truncate">
								예시 게시글 제목 {index + 1}
							</h4>
							{#if block.showExcerpt}
								<p class="text-xs text-gray-600 truncate">게시글의 요약 내용이 여기에 표시됩니다...</p>
							{/if}
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>

	{#if showSettings}
		<!-- 설정 패널 -->
		<div class="space-y-4 p-4 bg-white rounded-lg border">
			<h4 class="font-medium mb-3">포스트 목록 설정</h4>
			
			<!-- 기본 설정 -->
			<div class="grid grid-cols-2 gap-4">
				<div>
					<Label for="title">섹션 제목</Label>
					<Input
						id="title"
						value={block.title || ''}
						onchange={(e) => updateBlock({ title: (e.target as HTMLInputElement).value })}
						placeholder="최신 소식"
					/>
				</div>
				<div>
					<Label for="category">카테고리 필터</Label>
					<Input
						id="category"
						value={block.category || ''}
						onchange={(e) => updateBlock({ category: (e.target as HTMLInputElement).value })}
						placeholder="전체 (비어두면 전체)"
					/>
				</div>
			</div>

			<div class="grid grid-cols-3 gap-4">
				<div>
					<Label for="boardType">게시판 타입</Label>
					<Select type="single" value={block.boardType || 'community'} onValueChange={(value) => updateBlock({ boardType: value as any })}>
						<SelectTrigger>
							{boardTypeOptions.find(opt => opt.value === (block.boardType || 'community'))?.label || '타입 선택'}
						</SelectTrigger>
						<SelectContent>
							{#each boardTypeOptions as option}
								<SelectItem value={option.value}>{option.label}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>
				<div>
					<Label for="sortBy">정렬 순서</Label>
					<Select type="single" value={block.sortBy} onValueChange={(value) => updateBlock({ sortBy: value as any })}>
						<SelectTrigger>
							{sortOptions.find(opt => opt.value === block.sortBy)?.label || '정렬 선택'}
						</SelectTrigger>
						<SelectContent>
							{#each sortOptions as option}
								<SelectItem value={option.value}>{option.label}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>
				<div>
					<Label for="layout">레이아웃</Label>
					<Select type="single" value={block.layout} onValueChange={(value) => updateBlock({ layout: value as any })}>
						<SelectTrigger>
							{layoutOptions.find(opt => opt.value === block.layout)?.label || '레이아웃 선택'}
						</SelectTrigger>
						<SelectContent>
							{#each layoutOptions as option}
								<SelectItem value={option.value}>{option.label}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>
			</div>

			<div class="grid grid-cols-2 gap-4">
				<div>
					<Label for="limit">표시 개수</Label>
					<Input
						id="limit"
						type="number"
						min="1"
						max="20"
						value={block.limit}
						onchange={(e) => updateBlock({ limit: parseInt((e.target as HTMLInputElement).value) })}
					/>
				</div>
				<div>
					<Label for="truncate">제목 글자 수 제한</Label>
					<Input
						id="truncate"
						type="number"
						min="10"
						max="100"
						value={block.truncateTitle || 50}
						onchange={(e) => updateBlock({ truncateTitle: parseInt((e.target as HTMLInputElement).value) })}
						placeholder="50"
					/>
				</div>
			</div>

			<!-- 표시 옵션 -->
			<div class="space-y-3">
				<h5 class="font-medium text-sm">표시 옵션</h5>
				<div class="grid grid-cols-2 gap-4">
					<div class="flex items-center justify-between">
						<Label for="showImage">이미지 표시</Label>
						<Switch
							id="showImage"
							checked={block.showImage}
							onCheckedChange={(checked) => updateBlock({ showImage: checked })}
						/>
					</div>
					<div class="flex items-center justify-between">
						<Label for="showCategory">카테고리 표시</Label>
						<Switch
							id="showCategory"
							checked={block.showCategory}
							onCheckedChange={(checked) => updateBlock({ showCategory: checked })}
						/>
					</div>
					<div class="flex items-center justify-between">
						<Label for="showExcerpt">요약글 표시</Label>
						<Switch
							id="showExcerpt"
							checked={block.showExcerpt}
							onCheckedChange={(checked) => updateBlock({ showExcerpt: checked })}
						/>
					</div>
					<div class="flex items-center justify-between">
						<Label for="showDate">날짜 표시</Label>
						<Switch
							id="showDate"
							checked={block.showDate}
							onCheckedChange={(checked) => updateBlock({ showDate: checked })}
						/>
					</div>
				</div>
			</div>

			<!-- Carousel 전용 설정 -->
			{#if block.layout === 'carousel'}
				<div class="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-200">
					<h5 class="font-medium text-sm mb-3 text-blue-800">캐러셀 설정</h5>
					
					<div class="grid grid-cols-2 gap-4 mb-4">
						<div>
							<Label for="itemsPerView">한번에 보일 개수</Label>
							<Input
								id="itemsPerView"
								type="number"
								min="1"
								max="5"
								value={block.carouselOptions?.itemsPerView || 3}
								onchange={(e) => updateBlock({ 
									carouselOptions: { 
										...(block.carouselOptions || {}), 
										itemsPerView: parseInt((e.target as HTMLInputElement).value) 
									} 
								})}
							/>
						</div>
						<div>
							<Label for="autoPlayInterval">자동 전환 간격 (초)</Label>
							<Input
								id="autoPlayInterval"
								type="number"
								min="2"
								max="10"
								value={block.carouselOptions?.autoPlayInterval || 5}
								onchange={(e) => updateBlock({ 
									carouselOptions: { 
										...(block.carouselOptions || {}), 
										autoPlayInterval: parseInt((e.target as HTMLInputElement).value) 
									} 
								})}
							/>
						</div>
					</div>

					<div class="grid grid-cols-2 gap-4">
						<div class="flex items-center justify-between">
							<Label for="autoPlay">자동 전환</Label>
							<Switch
								id="autoPlay"
								checked={block.carouselOptions?.autoPlay || false}
								onCheckedChange={(checked) => updateBlock({ 
									carouselOptions: { 
										...(block.carouselOptions || {}), 
										autoPlay: checked 
									} 
								})}
							/>
						</div>
						<div class="flex items-center justify-between">
							<Label for="showImageOnly">이미지만 표시</Label>
							<Switch
								id="showImageOnly"
								checked={block.carouselOptions?.showImageOnly || false}
								onCheckedChange={(checked) => updateBlock({ 
									carouselOptions: { 
										...(block.carouselOptions || {}), 
										showImageOnly: checked 
									} 
								})}
							/>
						</div>
						<div class="flex items-center justify-between">
							<Label for="showDots">도트 인디케이터</Label>
							<Switch
								id="showDots"
								checked={block.carouselOptions?.showDots !== false}
								onCheckedChange={(checked) => updateBlock({ 
									carouselOptions: { 
										...(block.carouselOptions || {}), 
										showDots: checked 
									} 
								})}
							/>
						</div>
						<div class="flex items-center justify-between">
							<Label for="showArrows">화살표 버튼</Label>
							<Switch
								id="showArrows"
								checked={block.carouselOptions?.showArrows !== false}
								onCheckedChange={(checked) => updateBlock({ 
									carouselOptions: { 
										...(block.carouselOptions || {}), 
										showArrows: checked 
									} 
								})}
							/>
						</div>
					</div>
				</div>
			{/if}
		</div>
	{/if}
</div>