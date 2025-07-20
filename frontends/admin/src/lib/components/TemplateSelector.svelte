<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { 
		Card, 
		CardContent, 
		CardDescription, 
		CardHeader, 
		CardTitle 
	} from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';
	import { 
		Tabs, 
		TabsContent, 
		TabsList, 
		TabsTrigger 
	} from '$lib/components/ui/tabs';
	import { 
		FileText, 
		Eye, 
		Sparkles 
	} from 'lucide-svelte';
	import { defaultTemplates, templateCategories, type BlockTemplate } from '$lib/data/templates';
	import type { BlocksData } from '$lib/types/blocks';

	interface Props {
		onTemplateSelect: (template: BlockTemplate) => void;
	}

	let { onTemplateSelect }: Props = $props();

	let selectedCategory = $state('layout');
	let previewTemplate = $state<BlockTemplate | null>(null);
	let showPreview = $state(false);

	const filteredTemplates = $derived(defaultTemplates.filter(
		template => template.category === selectedCategory
	));

	function handleTemplateSelect(template: BlockTemplate) {
		onTemplateSelect(template);
	}

	function handlePreview(template: BlockTemplate) {
		previewTemplate = template;
		showPreview = true;
	}

	function closePreview() {
		showPreview = false;
		previewTemplate = null;
	}

	function generatePreviewHtml(template: BlockTemplate): string {
		return template.blocks.map((block: any) => {
			switch (block.type) {
				case 'paragraph':
					return `<p class="mb-2 text-sm">${block.content.substring(0, 50)}...</p>`;
				case 'heading':
					return `<h${block.level} class="font-bold mb-2 text-sm">H${block.level}. ${block.content.substring(0, 30)}...</h${block.level}>`;
				case 'image':
					return `<div class="bg-gray-200 h-16 mb-2 rounded flex items-center justify-center text-xs text-gray-500">이미지</div>`;
				case 'list':
					return `<ul class="text-xs mb-2"><li>• 목록 항목 ${block.items.length}개</li></ul>`;
				case 'quote':
					return `<blockquote class="border-l-2 border-blue-300 pl-2 text-xs italic mb-2">"${block.content.substring(0, 30)}..."</blockquote>`;
				case 'code':
					return `<div class="bg-gray-800 text-white p-2 rounded text-xs mb-2">코드 블록</div>`;
				case 'divider':
					return `<hr class="my-2" />`;
				case 'html':
					return `<div class="bg-yellow-100 p-1 text-xs mb-2">HTML 블록</div>`;
				case 'button':
					return `<div class="bg-blue-600 text-white px-3 py-1 rounded text-xs mb-2">${block.text}</div>`;
				case 'grid':
					return `<div class="bg-gray-100 p-2 rounded text-xs mb-2">그리드 (${block.columns.length}컬럼)</div>`;
				case 'map':
					return `<div class="bg-green-100 p-2 rounded text-xs mb-2">지도</div>`;
				case 'post-list':
					return `<div class="bg-purple-100 p-2 rounded text-xs mb-2">포스트 목록</div>`;
				default:
					return '';
			}
		}).join('');
	}
</script>

<Card>
	<CardHeader>
		<CardTitle class="flex items-center gap-2">
			<Sparkles class="h-5 w-5" />
			페이지 템플릿
		</CardTitle>
		<CardDescription>
			미리 구성된 템플릿을 선택하여 빠르게 페이지를 만들어보세요
		</CardDescription>
	</CardHeader>
	<CardContent>
		<Tabs bind:value={selectedCategory}>
			<div class="border-b border-gray-200 mb-4">
				<TabsList class="flex w-full overflow-x-auto scrollbar-hide gap-1 p-1 bg-transparent border-0">
					{#each templateCategories as category}
						<TabsTrigger 
							value={category.id} 
							class="text-xs whitespace-nowrap flex-shrink-0 px-3 py-1.5 min-w-fit data-[state=active]:bg-blue-50 data-[state=active]:text-blue-700 data-[state=active]:border-blue-200"
						>
							{category.name}
						</TabsTrigger>
					{/each}
				</TabsList>
			</div>

			{#each templateCategories as category}
				<TabsContent value={category.id} class="space-y-3 mt-4">
					{#each filteredTemplates as template}
						<div class="border rounded-lg p-3 hover:border-blue-300 transition-colors">
							<!-- 템플릿 미리보기 -->
							<div class="bg-white border rounded mb-3 h-24 overflow-hidden">
								<div class="p-2 scale-75 origin-top-left transform">
									{@html generatePreviewHtml(template)}
								</div>
							</div>

							<!-- 템플릿 정보 -->
							<div class="space-y-2">
								<div class="flex items-center justify-between">
									<h4 class="font-medium text-sm">{template.name}</h4>
									<Badge variant="secondary" class="text-xs">
										{templateCategories.find((cat: any) => cat.id === template.category)?.name}
									</Badge>
								</div>
								<p class="text-xs text-gray-600">{template.description}</p>
								
								<!-- 액션 버튼 -->
								<div class="flex gap-2">
									<Button 
										size="sm" 
										variant="outline" 
										class="flex-1 text-xs"
										onclick={() => handlePreview(template)}
									>
										<Eye class="mr-1 h-3 w-3" />
										미리보기
									</Button>
									<Button 
										size="sm" 
										class="flex-1 text-xs"
										onclick={() => handleTemplateSelect(template)}
									>
										<FileText class="mr-1 h-3 w-3" />
										사용하기
									</Button>
								</div>
							</div>
						</div>
					{/each}
				</TabsContent>
			{/each}
		</Tabs>
	</CardContent>
</Card>

<!-- 미리보기 모달 -->
{#if showPreview && previewTemplate}
	<div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
		<div class="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-y-auto">
			<div class="sticky top-0 bg-white border-b p-4 flex items-center justify-between">
				<div>
					<h3 class="text-lg font-semibold">{previewTemplate.name}</h3>
					<p class="text-sm text-gray-600">{previewTemplate.description}</p>
				</div>
				<div class="flex gap-2">
					<Button 
						variant="outline" 
						onclick={closePreview}
					>
						닫기
					</Button>
					<Button 
						onclick={() => {
							handleTemplateSelect(previewTemplate);
							closePreview();
						}}
					>
						사용하기
					</Button>
				</div>
			</div>
			
			<div class="p-6">
				<div class="prose max-w-none">
					{@html generatePreviewHtml(previewTemplate)}
				</div>
				
				<div class="mt-6 p-4 bg-gray-50 rounded-lg">
					<h4 class="font-medium mb-2">포함된 블록:</h4>
					<div class="flex flex-wrap gap-1">
						{#each Array.from(new Set(previewTemplate.blocks.map((b: any) => b.type))) as blockType}
							<Badge variant="secondary" class="text-xs">
								{blockType === 'paragraph' ? '문단' :
								 blockType === 'heading' ? '제목' :
								 blockType === 'image' ? '이미지' :
								 blockType === 'list' ? '목록' :
								 blockType === 'quote' ? '인용문' :
								 blockType === 'code' ? '코드' :
								 blockType === 'divider' ? '구분선' :
								 blockType === 'html' ? 'HTML' :
								 blockType === 'button' ? '버튼' :
								 blockType === 'grid' ? '그리드' :
								 blockType === 'map' ? '지도' :
								 blockType === 'post-list' ? '포스트 목록' : blockType}
							</Badge>
						{/each}
					</div>
				</div>
			</div>
		</div>
	</div>
{/if}