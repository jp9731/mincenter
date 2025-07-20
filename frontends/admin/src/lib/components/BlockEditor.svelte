<script lang="ts">
	import { onMount } from 'svelte';
	import { dndzone } from 'svelte-dnd-action';
	import { flipDurationMs } from '$lib/utils/constants';
	import { Button } from '$lib/components/ui/button';
	import { 
		Card, 
		CardContent
	} from '$lib/components/ui/card';
	import {
		DropdownMenu,
		DropdownMenuContent,
		DropdownMenuGroup,
		DropdownMenuItem,
		DropdownMenuTrigger
	} from '$lib/components/ui/dropdown-menu';
	import {
		Plus,
		Type,
		Heading1,
		Image,
		List,
		Quote,
		Code,
		Minus,
		FileText,
		GripVertical,
		Trash2,
		MapPin,
		Grid3X3,
		Newspaper,
		Sparkles
	} from 'lucide-svelte';
	import type { Block, BlockType, BlocksData } from '$lib/types/blocks';
	import type { BlockTemplate } from '$lib/data/templates';
	import BlockRenderer from './blocks/BlockRenderer.svelte';
	import TemplateSelector from './TemplateSelector.svelte';
	import { generateId } from '$lib/utils/helpers';

	interface Props {
		value?: string;
		placeholder?: string;
		onchange?: (value: string) => void;
	}

	let { value = '', placeholder = '블록을 추가하여 내용을 작성하세요', onchange }: Props = $props();

	let blocks = $state<Block[]>([]);
	let dragDisabled = $state(true);
	let isInitialized = $state(false);
	let lastValue = $state('');
	let showTemplateSelector = $state(false);
	let selectedBlockId = $state<string | null>(null);
	let selectedGridId = $state<string | null>(null);

	// Initialize blocks from value
	function initializeBlocks() {
		if (isInitialized) return;
		
		console.log('Admin BlockEditor initializing with value:', value);
		
		if (value && value.trim()) {
			try {
				const parsed: BlocksData = JSON.parse(value);
				console.log('Admin BlockEditor parsed:', parsed);
				if (parsed.blocks && Array.isArray(parsed.blocks)) {
					blocks = parsed.blocks;
					console.log('Admin BlockEditor loaded blocks:', blocks.length);
				}
			} catch (e) {
				console.warn('Admin BlockEditor failed to parse:', e);
				// If parsing fails, treat as plain text content
				blocks = [{
					id: generateId(),
					type: 'paragraph',
					content: value,
					order: 0
				}];
				console.log('Admin BlockEditor created fallback block');
			}
		} else {
			// Empty value - start with empty blocks
			blocks = [];
			console.log('Admin BlockEditor initialized with empty blocks');
		}
		isInitialized = true;
		lastValue = value || '';
	}

	// Update parent when blocks change
	function updateParent() {
		if (!isInitialized || !onchange) return;
		
		const blocksData: BlocksData = {
			blocks,
			version: '1.0'
		};
		const newValue = JSON.stringify(blocksData);
		
		// Prevent infinite loop by checking if the value actually changed
		if (newValue !== lastValue) {
			console.log('Admin BlockEditor updating value:', newValue);
			lastValue = newValue;
			onchange(newValue);
		}
	}

	// Effect to handle value changes from parent
	$effect(() => {
		if (value !== lastValue && !isInitialized) {
			initializeBlocks();
		}
	});

	// Effect to update parent when blocks change
	$effect(() => {
		if (isInitialized) {
			updateParent();
		}
	});

	onMount(() => {
		// Initialize on mount
		initializeBlocks();
	});

	function handleDndConsider(e: CustomEvent) {
		blocks = e.detail.items;
		dragDisabled = true;
	}

	function handleDndFinalize(e: CustomEvent) {
		blocks = e.detail.items;
		// Update order after reordering
		blocks.forEach((block, index) => {
			block.order = index;
		});
		dragDisabled = true;
	}

	function handleTemplateSelect(template: any) {
		// Convert template blocks to our format
		const newBlocks = template.blocks.map((block: any, index: number) => ({
			...block,
			id: generateId(),
			order: index
		}));
		
		// If a specific block is selected, insert after it
		if (selectedBlockId) {
			const selectedIndex = blocks.findIndex(block => block.id === selectedBlockId);
			if (selectedIndex !== -1) {
				// Update order for existing blocks after insertion point
				blocks.forEach((block, index) => {
					if (index > selectedIndex) {
						block.order = index + newBlocks.length;
					}
				});
				
				// Update order for new blocks
				newBlocks.forEach((block, index) => {
					block.order = selectedIndex + 1 + index;
				});
				
				blocks = [
					...blocks.slice(0, selectedIndex + 1),
					...newBlocks,
					...blocks.slice(selectedIndex + 1)
				];
			} else {
				// Fallback: append to end
				blocks = [...blocks, ...newBlocks];
			}
		} else {
			// No selection: append to end
			blocks = [...blocks, ...newBlocks];
		}
		
		// Reset selection
		selectedBlockId = null;
		selectedGridId = null;
		showTemplateSelector = false;
	}

	function addBlock(type: BlockType, afterIndex?: number) {
		const newBlock = createEmptyBlock(type);
		const insertIndex = afterIndex !== undefined ? afterIndex + 1 : blocks.length;
		
		// Update order for existing blocks
		blocks.forEach((block, index) => {
			if (index >= insertIndex) {
				block.order = index + 1;
			}
		});
		
		newBlock.order = insertIndex;
		blocks = [
			...blocks.slice(0, insertIndex),
			newBlock,
			...blocks.slice(insertIndex)
		];
	}

	function createEmptyBlock(type: BlockType): Block {
		const id = generateId();
		
		switch (type) {
			case 'paragraph':
				return { id, type: 'paragraph', content: '', order: 0 };
			case 'heading':
				return { id, type: 'heading', level: 2, content: '', order: 0 };
			case 'image':
				return { id, type: 'image', src: '', alt: '', order: 0 };
			case 'list':
				return { id, type: 'list', style: 'unordered', items: [''], order: 0 };
			case 'quote':
				return { id, type: 'quote', content: '', order: 0 };
			case 'code':
				return { id, type: 'code', content: '', order: 0 };
			case 'map':
				return { 
					id, 
					type: 'map', 
					address: '', 
					latitude: 37.5665, 
					longitude: 126.9780, 
					width: 400, 
					height: 300, 
					zoom: 3, 
					title: '지도',
					order: 0 
				};
			case 'grid':
				return {
					id,
					type: 'grid',
					columns: [
						{
							id: generateId(),
							width: 6,
							widthTablet: 6,
							widthMobile: 12,
							blocks: []
						},
						{
							id: generateId(),
							width: 6,
							widthTablet: 6,
							widthMobile: 12,
							blocks: []
						}
					],
					gap: 4,
					alignment: 'start',
					order: 0
				};
			case 'post-list':
				return {
					id,
					type: 'post-list',
					title: '최신 게시글',
					boardType: 'community',
					limit: 5,
					sortBy: 'recent',
					layout: 'list',
					showImage: true,
					showCategory: true,
					showExcerpt: true,
					showDate: true,
					truncateTitle: 50,
					carouselOptions: {
						itemsPerView: 3,
						autoPlay: false,
						autoPlayInterval: 5,
						showImageOnly: false,
						showDots: true,
						showArrows: true
					},
					order: 0
				};
			case 'divider':
				return { id, type: 'divider', order: 0 };
			case 'button':
				return { 
					id, 
					type: 'button', 
					text: '버튼 텍스트',
					link: { url: '#', target: '_self' },
					styles: {
						variant: 'primary',
						size: 'md',
						textAlign: 'center',
						width: 'auto'
					},
					order: 0 
				};
			case 'html':
				return { id, type: 'html', content: '', order: 0 };
			default:
				return { id, type: 'paragraph', content: '', order: 0 };
		}
	}

	function deleteBlock(blockId: string) {
		blocks = blocks.filter(block => block.id !== blockId);
		// Update order after deletion
		blocks.forEach((block, index) => {
			block.order = index;
		});
	}

	function updateBlock(blockId: string, updatedBlock: Partial<Block>) {
		blocks = blocks.map(block => 
			block.id === blockId 
				? { ...block, ...updatedBlock }
				: block
		);
	}

	function selectBlock(blockId: string) {
		selectedBlockId = blockId;
		selectedGridId = null;
	}

	function selectGrid(gridId: string) {
		selectedGridId = gridId;
		selectedBlockId = null;
	}

	function handleKeyDown(event: KeyboardEvent, blockIndex: number) {
		if (event.key === 'Enter' && !event.shiftKey) {
			event.preventDefault();
			addBlock('paragraph', blockIndex);
		}
	}

	const blockTypes = [
		{ type: 'paragraph', label: '문단', icon: Type },
		{ type: 'heading', label: '제목', icon: Heading1 },
		{ type: 'image', label: '이미지', icon: Image },
		{ type: 'list', label: '목록', icon: List },
		{ type: 'quote', label: '인용문', icon: Quote },
		{ type: 'code', label: '코드', icon: Code },
		{ type: 'button', label: '버튼', icon: Plus },
		{ type: 'map', label: '지도', icon: MapPin },
		{ type: 'grid', label: '그리드', icon: Grid3X3 },
		{ type: 'post-list', label: '포스트 목록', icon: Newspaper },
		{ type: 'divider', label: '구분선', icon: Minus },
		{ type: 'html', label: 'HTML', icon: FileText }
	] as const;
</script>

<div class="space-y-4">
	<!-- Empty state -->
	{#if blocks.length === 0}
		<Card class="border-dashed">
			<CardContent class="flex flex-col items-center justify-center py-12">
				<div class="text-center">
					<Type class="mx-auto h-12 w-12 text-gray-400" />
					<h3 class="mt-4 text-lg font-medium text-gray-900">
						아직 블록이 없습니다
					</h3>
					<p class="mt-2 text-sm text-gray-500">
						{placeholder}
					</p>
					<div class="mt-6">
						<DropdownMenu>
							<DropdownMenuTrigger>
								<Button size="lg">
									<Plus class="mr-2 h-4 w-4" />
									첫 번째 블록 추가
								</Button>
							</DropdownMenuTrigger>
							<DropdownMenuContent align="center">
								<DropdownMenuGroup>
									{#each blockTypes as blockType}
										<DropdownMenuItem
											onclick={() => addBlock(blockType.type)}
										>
											{@const IconComponent = blockType.icon}
										<IconComponent class="mr-2 h-4 w-4" />
											{blockType.label}
										</DropdownMenuItem>
									{/each}
								</DropdownMenuGroup>
							</DropdownMenuContent>
						</DropdownMenu>
					</div>
				</div>
			</CardContent>
		</Card>
	{:else}
		<!-- Blocks list with drag and drop -->
		<div
			use:dndzone={{
				items: blocks,
				flipDurationMs,
				dragDisabled,
				dropTargetStyle: {}
			}}
			onconsider={handleDndConsider}
			onfinalize={handleDndFinalize}
			class="space-y-4"
		>
			{#each blocks as block, index (block.id)}
				<div class="group relative">
					<!-- Drag handle -->
					<div class="absolute -left-8 top-4 opacity-0 group-hover:opacity-100 transition-opacity">
						<Button
							variant="ghost"
							size="sm"
							class="h-6 w-6 p-0 cursor-grab active:cursor-grabbing"
							onmousedown={() => dragDisabled = false}
							ontouchstart={() => dragDisabled = false}
						>
							<GripVertical class="h-4 w-4" />
						</Button>
					</div>

					<!-- Block content -->
					<Card class="relative">
						<CardContent class="p-4">
							<BlockRenderer
								{block}
								isSelected={selectedBlockId === block.id}
								onupdate={(data) => updateBlock(block.id, data)}
								onkeydown={(event) => handleKeyDown(event, index)}
								ondelete={() => deleteBlock(block.id)}
								onselect={() => selectBlock(block.id)}
								onTemplateSelect={handleTemplateSelect}
							/>
						</CardContent>

						<!-- Block controls -->
						<div class="absolute -bottom-2 left-1/2 transform -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity">
							<div class="flex items-center gap-1 bg-white border rounded-md shadow-sm px-2 py-1">
								<DropdownMenu>
									<DropdownMenuTrigger>
										<Button variant="ghost" size="sm" class="h-6 w-6 p-0">
											<Plus class="h-3 w-3" />
										</Button>
									</DropdownMenuTrigger>
									<DropdownMenuContent align="center">
										<DropdownMenuGroup>
											{#each blockTypes as blockType}
												<DropdownMenuItem
													onclick={() => addBlock(blockType.type, index)}
												>
													{@const IconComponent = blockType.icon}
										<IconComponent class="mr-2 h-4 w-4" />
													{blockType.label}
												</DropdownMenuItem>
											{/each}
										</DropdownMenuGroup>
									</DropdownMenuContent>
								</DropdownMenu>

								<Button
									variant="ghost"
									size="sm"
									class="h-6 w-6 p-0 text-red-500 hover:text-red-700"
									onclick={() => deleteBlock(block.id)}
								>
									<Trash2 class="h-3 w-3" />
								</Button>
							</div>
						</div>
					</Card>
				</div>
			{/each}
		</div>

		<!-- Add block button at the end -->
		<div class="flex justify-center gap-2">
			<Button 
				variant="outline" 
				onclick={() => showTemplateSelector = true}
			>
				<Sparkles class="mr-2 h-4 w-4" />
				템플릿 사용
			</Button>
			<DropdownMenu>
				<DropdownMenuTrigger>
					<Button variant="outline">
						<Plus class="mr-2 h-4 w-4" />
						블록 추가
					</Button>
				</DropdownMenuTrigger>
				<DropdownMenuContent align="center">
					<DropdownMenuGroup>
						{#each blockTypes as blockType}
							<DropdownMenuItem
								onclick={() => addBlock(blockType.type)}
							>
								{@const IconComponent = blockType.icon}
								<IconComponent class="mr-2 h-4 w-4" />
								{blockType.label}
							</DropdownMenuItem>
						{/each}
					</DropdownMenuGroup>
				</DropdownMenuContent>
			</DropdownMenu>
		</div>
	{/if}

	<!-- Template Selector Modal -->
	{#if showTemplateSelector}
		<div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
			<div class="bg-white rounded-lg shadow-xl max-w-4xl w-full mx-4 max-h-[80vh] overflow-y-auto">
				<div class="sticky top-0 bg-white border-b p-4 flex items-center justify-between">
					<div>
						<h3 class="text-lg font-semibold">템플릿 선택</h3>
						<p class="text-sm text-gray-600">미리 구성된 템플릿을 선택하여 빠르게 페이지를 만들어보세요</p>
					</div>
					<Button 
						variant="outline" 
						onclick={() => showTemplateSelector = false}
					>
						닫기
					</Button>
				</div>
				
				<div class="p-4">
					<TemplateSelector onTemplateSelect={handleTemplateSelect} />
				</div>
			</div>
		</div>
	{/if}
</div>