<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Switch } from '$lib/components/ui/switch';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import {
		Dialog,
		DialogContent,
		DialogHeader,
		DialogTitle,
		DialogTrigger
	} from '$lib/components/ui/dialog';
	import {
		Save,
		Eye,
		Globe,
		Settings,
		ArrowLeft,
		ExternalLink,
		Calendar,
		User,
		Monitor,
		Tablet,
		Smartphone,
		X
	} from 'lucide-svelte';
	import { getPage, updatePage } from '$lib/api/admin';
	import { goto } from '$app/navigation';
	import BlockEditor from '$lib/components/BlockEditor.svelte';
	import TemplateSelector from '$lib/components/TemplateSelector.svelte';
	import type { BlocksData } from '$lib/types/blocks';
	import type { PageTemplate } from '$lib/types/templates';

	type ViewportMode = 'desktop' | 'tablet' | 'mobile';

	let loading = true;
	let saving = false;
	let previewModalOpen = false;
	let viewportMode: ViewportMode = 'desktop';
	let pageData: any = null;

	// 페이지 데이터 초기화
	let formData = {
		title: '',
		slug: '',
		content: '',
		excerpt: '',
		meta_title: '',
		meta_description: '',
		status: 'draft',
		is_published: false,
		sort_order: 0
	};

	onMount(async () => {
		const pageId = $page.params.id;
		await loadPage(pageId);
	});

	async function loadPage(pageId: string) {
		try {
			pageData = await getPage(pageId);
			formData = {
				title: pageData.title || '',
				slug: pageData.slug || '',
				content: pageData.content || '',
				excerpt: pageData.excerpt || '',
				meta_title: pageData.meta_title || '',
				meta_description: pageData.meta_description || '',
				status: pageData.status || 'draft',
				is_published: pageData.is_published || false,
				sort_order: pageData.sort_order || 0
			};
			
			// 블록 에디터에 기존 내용 전달을 위한 지연 처리
			await new Promise(resolve => setTimeout(resolve, 100));
		} catch (error) {
			console.error('페이지 로드 실패:', error);
			alert('페이지를 불러오는데 실패했습니다.');
			goto('/pages');
		} finally {
			loading = false;
		}
	}

	async function handleSave(isPublished = false) {
		if (!formData.title.trim()) {
			alert('제목을 입력해주세요.');
			return;
		}

		if (!formData.slug.trim()) {
			alert('슬러그를 입력해주세요.');
			return;
		}

		// Check if content is valid (either plain text or valid blocks)
		const hasContent = formData.content.trim() && (
			// Check for plain text
			formData.content.trim().length > 0 ||
			// Check for block content
			(() => {
				try {
					const blocksData: BlocksData = JSON.parse(formData.content);
					return blocksData.blocks && blocksData.blocks.length > 0;
				} catch {
					return formData.content.trim().length > 0;
				}
			})()
		);

		if (!hasContent) {
			alert('내용을 입력해주세요.');
			return;
		}

		saving = true;
		try {
			const data = {
				...formData,
				is_published: isPublished,
				status: isPublished ? 'published' : formData.status
			};

			await updatePage(pageData.id, data);
			alert(isPublished ? '페이지가 발행되었습니다.' : '페이지가 저장되었습니다.');
			goto('/pages');
		} catch (error) {
			console.error('페이지 저장 실패:', error);
			alert('페이지 저장에 실패했습니다.');
		} finally {
			saving = false;
		}
	}

	function handlePreview() {
		previewModalOpen = true;
	}

	function getViewportClass(mode: ViewportMode): string {
		switch (mode) {
			case 'desktop':
				return 'w-full';
			case 'tablet':
				return 'max-w-3xl mx-auto';
			case 'mobile':
				return 'max-w-sm mx-auto';
			default:
				return 'w-full';
		}
	}

	function getViewportWidth(mode: ViewportMode): string {
		switch (mode) {
			case 'desktop':
				return '100%';
			case 'tablet':
				return '768px';
			case 'mobile':
				return '375px';
			default:
				return '100%';
		}
	}

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleDateString('ko-KR', {
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit'
		});
	}

	function renderBlocksPreview(content: string): string {
		if (!content) return '';
		
		try {
			const blocksData: BlocksData = JSON.parse(content);
			if (!blocksData.blocks) return content; // Fallback to raw content if not blocks format
			
			return blocksData.blocks.map(block => {
				switch (block.type) {
					case 'paragraph':
						return `<p>${block.content}</p>`;
					case 'heading':
						return `<h${block.level}>${block.content}</h${block.level}>`;
					case 'image':
						return `<img src="${block.src}" alt="${block.alt}" ${block.caption ? `title="${block.caption}"` : ''} />`;
					case 'list':
						const tag = block.style === 'ordered' ? 'ol' : 'ul';
						const items = block.items.map(item => `<li>${item}</li>`).join('');
						return `<${tag}>${items}</${tag}>`;
					case 'quote':
						return `<blockquote>${block.content}${block.author ? `<cite>— ${block.author}</cite>` : ''}</blockquote>`;
					case 'code':
						return `<pre><code${block.language ? ` class="language-${block.language}"` : ''}>${block.content}</code></pre>`;
					case 'map':
						return `<div class="bg-gray-100 p-4 rounded-lg text-center">
							<div class="text-gray-600 mb-2">📍 카카오 지도</div>
							${block.title ? `<div class="font-medium">${block.title}</div>` : ''}
							${block.address ? `<div class="text-sm text-gray-500">${block.address}</div>` : ''}
							<div class="text-xs text-gray-400 mt-1">${block.width || 400}px × ${block.height || 300}px</div>
						</div>`;
					case 'grid':
						const gridColumns = block.columns.map(col => {
							const columnBlocks = col.blocks.map(columnBlock => {
								// 재귀적으로 컬럼 내 블록들 렌더링
								switch (columnBlock.type) {
									case 'paragraph':
										return `<p>${columnBlock.content}</p>`;
									case 'heading':
										return `<h${columnBlock.level}>${columnBlock.content}</h${columnBlock.level}>`;
									case 'image':
										return `<img src="${columnBlock.src}" alt="${columnBlock.alt}" style="max-width: 100%;" />`;
									default:
										return `<div class="text-gray-500">[${columnBlock.type} 블록]</div>`;
								}
							}).join('');
							return `<div class="border border-gray-200 p-2 rounded">${columnBlocks || '<div class="text-gray-400 text-sm">빈 컬럼</div>'}</div>`;
						}).join('');
						return `<div class="bg-gray-50 p-3 rounded-lg">
							<div class="text-sm text-gray-600 mb-2">📊 그리드 레이아웃 (${block.columns.length}컬럼)</div>
							<div class="grid gap-2" style="grid-template-columns: ${block.columns.map(col => `${col.width}fr`).join(' ')}">${gridColumns}</div>
						</div>`;
					case 'post-list':
						return `<div class="bg-blue-50 p-4 rounded-lg border border-blue-200">
							<div class="text-blue-800 font-medium mb-2">📄 ${block.title || '포스트 목록'}</div>
							<div class="text-sm text-blue-600 space-y-1">
								<div>게시판: ${block.boardType || 'community'}</div>
								${block.category ? `<div>카테고리: ${block.category}</div>` : ''}
								<div>정렬: ${block.sortBy === 'recent' ? '최신순' : block.sortBy === 'popular' ? '인기순' : '좋아요순'} • ${block.limit}개</div>
								<div>레이아웃: ${block.layout === 'list' ? '목록형' : block.layout === 'card' ? '카드형' : '심플형'}</div>
							</div>
						</div>`;
					case 'divider':
						return '<hr />';
					case 'html':
						return block.content;
					default:
						return '';
				}
			}).join('');
		} catch (e) {
			// If parsing fails, return as is (backward compatibility)
			return content;
		}
	}

	function handleTemplateSelect(template: PageTemplate) {
		if (template.blocks.length === 0) {
			// 빈 페이지 템플릿
			formData.content = '';
		} else {
			// 템플릿 블록을 JSON으로 변환
			const blocksData: BlocksData = {
				blocks: template.blocks,
				version: '1.0'
			};
			formData.content = JSON.stringify(blocksData);
		}
		
		// 제목이 비어있으면 템플릿 이름으로 설정
		if (!formData.title.trim()) {
			formData.title = template.name;
		}
	}
</script>

{#if loading}
	<div class="flex items-center justify-center py-12">
		<div class="border-primary h-8 w-8 animate-spin rounded-full border-b-2"></div>
	</div>
{:else}
	<div class="space-y-6">
		<!-- 페이지 헤더 -->
		<div class="flex items-center justify-between">
			<div class="flex items-center gap-4">
				<Button variant="outline" onclick={() => goto('/pages')}>
					<ArrowLeft class="mr-2 h-4 w-4" />
					목록으로
				</Button>
				<div>
					<h1 class="text-3xl font-bold text-gray-900">페이지 편집</h1>
					<p class="mt-2 text-gray-600">{pageData.title} 페이지를 편집합니다.</p>
				</div>
			</div>
			<div class="flex gap-2">
				<Dialog bind:open={previewModalOpen}>
					<DialogTrigger>
						<Button variant="outline" onclick={handlePreview}>
							<Eye class="mr-2 h-4 w-4" />
							미리보기
						</Button>
					</DialogTrigger>
					<DialogContent class="sm:max-w-[95vw] sm:w-[95vw] sm:max-h-[90vh]  overflow-hidden">
						<DialogHeader class="flex flex-row items-center justify-between">
							<DialogTitle class="flex items-center gap-2">
								<Eye class="h-5 w-5" />
								미리보기
							</DialogTitle>
							<div class="flex gap-1 rounded-lg border p-1">
								<Button
									variant={viewportMode === 'desktop' ? 'default' : 'ghost'}
									size="sm"
									onclick={() => viewportMode = 'desktop'}
								>
									<Monitor class="h-4 w-4" />
								</Button>
								<Button
									variant={viewportMode === 'tablet' ? 'default' : 'ghost'}
									size="sm"
									onclick={() => viewportMode = 'tablet'}
								>
									<Tablet class="h-4 w-4" />
								</Button>
								<Button
									variant={viewportMode === 'mobile' ? 'default' : 'ghost'}
									size="sm"
									onclick={() => viewportMode = 'mobile'}
								>
									<Smartphone class="h-4 w-4" />
								</Button>
							</div>
						</DialogHeader>
						
						<div class="flex items-center justify-center gap-2 text-sm text-gray-600 border-b pb-3">
							<span>현재 뷰포트:</span>
							<Badge variant="outline">
								{viewportMode === 'desktop' ? '데스크톱' : viewportMode === 'tablet' ? '태블릿' : '모바일'}
								({getViewportWidth(viewportMode)})
							</Badge>
						</div>

						<div class="bg-gray-100 p-4 rounded-lg overflow-auto flex-1">
							<div 
								class={getViewportClass(viewportMode)}
								style="max-width: {getViewportWidth(viewportMode)}; transition: all 0.3s ease; margin: 0 auto;"
							>
								<Card class="bg-white shadow-lg">
									<CardContent class="p-6">
										<div class="prose max-w-none">
											<h1>{formData.title || '제목을 입력하세요'}</h1>
											{#if formData.excerpt}
												<p class="text-lg text-gray-600">{formData.excerpt}</p>
											{/if}
											<div class="mt-6">
												{#if formData.content}
													{@html renderBlocksPreview(formData.content)}
												{:else}
													내용을 입력하세요
												{/if}
											</div>
										</div>
									</CardContent>
								</Card>
							</div>
						</div>
					</DialogContent>
				</Dialog>
				
				<Button variant="outline" onclick={() => handleSave(false)} disabled={saving}>
					<Save class="mr-2 h-4 w-4" />
					임시저장
				</Button>
				<Button onclick={() => handleSave(true)} disabled={saving}>
					<Globe class="mr-2 h-4 w-4" />
					{saving ? '저장 중...' : '발행'}
				</Button>
			</div>
		</div>

		<!-- 편집 모드 -->
		<div class="grid grid-cols-1 gap-6 xl:grid-cols-4">
			<!-- 메인 편집 영역 -->
			<div class="space-y-6 xl:col-span-3">
					<!-- 블록 에디터 -->
				<Card>
					<CardHeader>
						<CardTitle>페이지 내용</CardTitle>
						<CardDescription>블록을 추가하여 페이지 내용을 작성하세요</CardDescription>
					</CardHeader>
					<CardContent>
						{#if !loading}
							<BlockEditor
								value={formData.content}
								placeholder="블록을 추가하여 페이지 내용을 작성하세요"
								onchange={(newValue) => formData.content = newValue}
							/>
						{/if}
					</CardContent>
				</Card>
			</div>

			<!-- 사이드바 -->
			<div class="space-y-6">
				<!-- 템플릿 선택기 -->
				<TemplateSelector onTemplateSelect={handleTemplateSelect} />

				<!-- 기본 정보 -->
				<Card>
						<CardHeader>
							<CardTitle>기본 정보</CardTitle>
							<CardDescription>페이지의 기본적인 정보를 수정하세요</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div>
								<label for="title" class="mb-1 block text-sm font-medium text-gray-700">
									제목 <span class="text-red-500">*</span>
								</label>
								<Input
									id="title"
									bind:value={formData.title}
									placeholder="페이지 제목을 입력하세요"
									required
								/>
							</div>

							<div>
								<label for="slug" class="mb-1 block text-sm font-medium text-gray-700">
									슬러그 <span class="text-red-500">*</span>
								</label>
								<Input
									id="slug"
									bind:value={formData.slug}
									placeholder="URL 슬러그를 입력하세요"
									required
								/>
								<p class="mt-1 text-sm text-gray-500">
									예: /pages/{formData.slug || 'your-slug'}
								</p>
							</div>

							<div>
								<label for="excerpt" class="mb-1 block text-sm font-medium text-gray-700">
									요약
								</label>
								<Textarea
									id="excerpt"
									bind:value={formData.excerpt}
									placeholder="페이지 요약을 입력하세요"
									rows={3}
								/>
							</div>
						</CardContent>
					</Card>
					<!-- 발행 설정 -->
					<Card>
						<CardHeader>
							<CardTitle class="flex items-center gap-2">
								<Settings class="h-5 w-5" />
								발행 설정
							</CardTitle>
						</CardHeader>
						<CardContent class="space-y-4">
							<div class="flex items-center justify-between">
								<label class="text-sm font-medium text-gray-700">발행 상태</label>
								<Switch bind:checked={formData.is_published} />
							</div>

							<div>
								<label for="status" class="mb-1 block text-sm font-medium text-gray-700">
									상태
								</label>
								<Select bind:value={formData.status}>
									<SelectTrigger>
										{formData.status === 'draft'
											? '임시저장'
											: formData.status === 'published'
												? '발행됨'
												: '보관됨'}
									</SelectTrigger>
									<SelectContent>
										<SelectItem value="draft">임시저장</SelectItem>
										<SelectItem value="published">발행됨</SelectItem>
										<SelectItem value="archived">보관됨</SelectItem>
									</SelectContent>
								</Select>
							</div>

							<div>
								<label for="sort_order" class="mb-1 block text-sm font-medium text-gray-700">
									정렬 순서
								</label>
								<Input id="sort_order" type="number" bind:value={formData.sort_order} min="0" />
							</div>
						</CardContent>
					</Card>

					<!-- SEO 설정 -->
					<Card>
						<CardHeader>
							<CardTitle class="flex items-center gap-2">
								<Globe class="h-5 w-5" />
								SEO 설정
							</CardTitle>
						</CardHeader>
						<CardContent class="space-y-4">
							<div>
								<label for="meta_title" class="mb-1 block text-sm font-medium text-gray-700">
									메타 제목
								</label>
								<Input
									id="meta_title"
									bind:value={formData.meta_title}
									placeholder="SEO용 제목을 입력하세요"
								/>
							</div>

							<div>
								<label for="meta_description" class="mb-1 block text-sm font-medium text-gray-700">
									메타 설명
								</label>
								<Textarea
									id="meta_description"
									bind:value={formData.meta_description}
									placeholder="SEO용 설명을 입력하세요"
									rows="3"
								/>
							</div>
						</CardContent>
					</Card>

					<!-- 페이지 정보 -->
					<Card>
						<CardHeader>
							<CardTitle class="flex items-center gap-2">
								<Calendar class="h-5 w-5" />
								페이지 정보
							</CardTitle>
						</CardHeader>
						<CardContent class="space-y-3">
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">생성일</span>
								<span class="text-sm font-medium">{formatDate(pageData.created_at)}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">수정일</span>
								<span class="text-sm font-medium">{formatDate(pageData.updated_at)}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">조회수</span>
								<span class="text-sm font-medium">{pageData.view_count}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">상태</span>
								<Badge variant={formData.is_published ? 'default' : 'secondary'}>
									{formData.is_published ? '발행됨' : '임시저장'}
								</Badge>
							</div>
							{#if pageData.created_by_name}
								<div class="flex items-center justify-between">
									<span class="text-sm text-gray-600">작성자</span>
									<span class="text-sm font-medium">{pageData.created_by_name}</span>
								</div>
							{/if}
						</CardContent>
					</Card>
			</div>
		</div>
	</div>
{/if}
