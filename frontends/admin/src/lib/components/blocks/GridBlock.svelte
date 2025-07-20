<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card';
	import {
		DropdownMenu,
		DropdownMenuContent,
		DropdownMenuGroup,
		DropdownMenuItem,
		DropdownMenuTrigger
	} from '$lib/components/ui/dropdown-menu';
	import { 
		Plus, 
		Trash2, 
		Grid3X3, 
		Settings,
		LayoutGrid,
		Columns2,
		Columns3,
		Columns4,
		Type,
		Heading1,
		Image,
		List,
		Quote,
		Code,
		MapPin,
		FileText,
		Minus,
		Sparkles
	} from 'lucide-svelte';
	import type { GridBlock, GridColumn, Block } from '$lib/types/blocks';
	import { generateId } from '$lib/utils/helpers';
	import BlockRenderer from './BlockRenderer.svelte';

	interface Props {
		block: GridBlock;
		isSelected?: boolean;
		onupdate?: (data: Partial<GridBlock>) => void;
		ondelete?: () => void;
		onselect?: () => void;
		onTemplateSelect?: (template: any, columnId?: string) => void;
	}

	let { block, isSelected = false, onupdate, ondelete, onselect, onTemplateSelect }: Props = $props();

	let showSettings = $state(false);

	// 사전 정의된 그리드 레이아웃 템플릿
	const gridTemplates = [
		{ name: '2컬럼 (6:6)', columns: [6, 6], icon: Columns2 },
		{ name: '3컬럼 (4:4:4)', columns: [4, 4, 4], icon: Columns3 },
		{ name: '4컬럼 (3:3:3:3)', columns: [3, 3, 3, 3], icon: Columns4 },
		{ name: '사이드바 (8:4)', columns: [8, 4], icon: LayoutGrid },
		{ name: '사이드바 (4:8)', columns: [4, 8], icon: LayoutGrid },
		{ name: '3컬럼 (3:6:3)', columns: [3, 6, 3], icon: Columns3 }
	];

	// 컬럼 내 추가 가능한 블록 타입들
	const columnBlockTypes = [
		{ type: 'paragraph', label: '문단', icon: Type },
		{ type: 'heading', label: '제목', icon: Heading1 },
		{ type: 'image', label: '이미지', icon: Image },
		{ type: 'list', label: '목록', icon: List },
		{ type: 'quote', label: '인용문', icon: Quote },
		{ type: 'code', label: '코드', icon: Code },
		{ type: 'map', label: '지도', icon: MapPin },
		{ type: 'divider', label: '구분선', icon: Minus },
		{ type: 'html', label: 'HTML', icon: FileText }
	] as const;

	function createGridFromTemplate(columnWidths: number[]) {
		const newColumns: GridColumn[] = columnWidths.map((width, index) => ({
			id: generateId(),
			width,
			widthTablet: width > 6 ? 12 : width * 2, // 큰 컬럼은 태블릿에서 전체, 작은 컬럼은 2배
			widthMobile: 12, // 모바일에서는 모두 전체 너비
			blocks: []
		}));

		onupdate?.({
			columns: newColumns
		});
	}

	function addColumn() {
		const currentTotalWidth = block.columns.reduce((sum, col) => sum + col.width, 0);
		const remainingWidth = 12 - currentTotalWidth;
		
		if (remainingWidth <= 0) {
			alert('더 이상 컬럼을 추가할 수 없습니다. (최대 12칸)');
			return;
		}

		const newColumn: GridColumn = {
			id: generateId(),
			width: Math.min(remainingWidth, 4), // 기본 4칸, 남은 공간이 적으면 그만큼
			widthTablet: Math.min(remainingWidth, 6),
			widthMobile: 12,
			blocks: []
		};

		onupdate?.({
			columns: [...block.columns, newColumn]
		});
	}

	function removeColumn(columnId: string) {
		const updatedColumns = block.columns.filter(col => col.id !== columnId);
		onupdate?.({
			columns: updatedColumns
		});
	}

	function updateColumnWidth(columnId: string, newWidth: number) {
		const updatedColumns = block.columns.map(col => 
			col.id === columnId ? { ...col, width: newWidth } : col
		);
		
		// 전체 너비가 12를 넘지 않도록 검증
		const totalWidth = updatedColumns.reduce((sum, col) => sum + col.width, 0);
		if (totalWidth > 12) {
			alert('전체 컬럼 너비가 12를 넘을 수 없습니다.');
			return;
		}

		onupdate?.({
			columns: updatedColumns
		});
	}

	function updateColumnTabletWidth(columnId: string, newWidth: number) {
		const updatedColumns = block.columns.map(col => 
			col.id === columnId ? { ...col, widthTablet: newWidth } : col
		);

		onupdate?.({
			columns: updatedColumns
		});
	}

	function updateColumnMobileWidth(columnId: string, newWidth: number) {
		const updatedColumns = block.columns.map(col => 
			col.id === columnId ? { ...col, widthMobile: newWidth } : col
		);

		onupdate?.({
			columns: updatedColumns
		});
	}

	function updateGap(newGap: number) {
		onupdate?.({ gap: newGap });
	}

	function updateAlignment(newAlignment: 'start' | 'center' | 'end' | 'stretch') {
		onupdate?.({ alignment: newAlignment });
	}

	function addBlockToColumn(columnId: string, blockType: string) {
		const newBlock = createEmptyBlock(blockType);
		const updatedColumns = block.columns.map(col => {
			if (col.id === columnId) {
				return {
					...col,
					blocks: [...col.blocks, newBlock]
				};
			}
			return col;
		});

		onupdate?.({
			columns: updatedColumns
		});
	}

	function handleTemplateSelect(template: any, columnId: string) {
		// Convert template blocks to our format
		const newBlocks = template.blocks.map((block: any, index: number) => ({
			...block,
			id: generateId(),
			order: index
		}));
		
		const updatedColumns = block.columns.map(col => {
			if (col.id === columnId) {
				return {
					...col,
					blocks: [...col.blocks, ...newBlocks]
				};
			}
			return col;
		});

		onupdate?.({
			columns: updatedColumns
		});
	}

	function updateBlockInColumn(columnId: string, blockId: string, blockData: Partial<Block>) {
		const updatedColumns = block.columns.map(col => {
			if (col.id === columnId) {
				return {
					...col,
					blocks: col.blocks.map(block => 
						block.id === blockId ? { ...block, ...blockData } : block
					)
				};
			}
			return col;
		});

		onupdate?.({
			columns: updatedColumns
		});
	}

	function deleteBlockFromColumn(columnId: string, blockId: string) {
		const updatedColumns = block.columns.map(col => {
			if (col.id === columnId) {
				return {
					...col,
					blocks: col.blocks.filter(block => block.id !== blockId)
				};
			}
			return col;
		});

		onupdate?.({
			columns: updatedColumns
		});
	}

	function createEmptyBlock(type: string): Block {
		const id = generateId();
		const order = 0;
		
		switch (type) {
			case 'paragraph':
				return { id, type: 'paragraph', content: '', order };
			case 'heading':
				return { id, type: 'heading', level: 2, content: '', order };
			case 'image':
				return { id, type: 'image', src: '', alt: '', order };
			default:
				return { id, type: 'paragraph', content: '', order };
		}
	}

	function getTotalWidth(): number {
		return block.columns.reduce((sum, col) => sum + col.width, 0);
	}
</script>

<div class="border border-gray-200 rounded-lg p-4 bg-gray-50">
	<div class="flex items-center justify-between mb-4">
		<div class="flex items-center gap-2">
			<Grid3X3 class="h-5 w-5 text-gray-600" />
			<span class="font-medium text-gray-700">그리드 레이아웃</span>
			<span class="text-sm text-gray-500">
				({block.columns.length}컬럼, {getTotalWidth()}/12)
			</span>
		</div>
		<div class="flex gap-2">
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
				onclick={ondelete}
			>
				<Trash2 class="h-4 w-4" />
			</Button>
		</div>
	</div>

	{#if showSettings}
		<div class="mb-4 p-4 bg-white rounded-lg border">
			<h4 class="font-medium mb-3">그리드 설정</h4>
			
			<!-- 템플릿 선택 -->
			<div class="mb-4">
				<label class="block text-sm font-medium text-gray-700 mb-2">템플릿 선택</label>
				<div class="grid grid-cols-2 gap-2">
					{#each gridTemplates as template}
						<Button
							variant="outline"
							size="sm"
							onclick={() => createGridFromTemplate(template.columns)}
							class="flex items-center gap-2 justify-start"
						>
							<svelte:component this={template.icon} class="h-4 w-4" />
							{template.name}
						</Button>
					{/each}
				</div>
			</div>

			<!-- 간격 설정 -->
			<div class="mb-4">
				<label class="block text-sm font-medium text-gray-700 mb-2">컬럼 간격</label>
				<Select type="single" value={block.gap?.toString() || '4'} onValueChange={(value) => updateGap(parseInt(value))}>
					<SelectTrigger>
						{block.gap === 0 ? '없음' : block.gap === 1 ? '1' : block.gap === 2 ? '2' : block.gap === 6 ? '6' : block.gap === 8 ? '8' : '4 (기본)'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="0">없음</SelectItem>
						<SelectItem value="1">1</SelectItem>
						<SelectItem value="2">2</SelectItem>
						<SelectItem value="4">4 (기본)</SelectItem>
						<SelectItem value="6">6</SelectItem>
						<SelectItem value="8">8</SelectItem>
					</SelectContent>
				</Select>
			</div>

			<!-- 정렬 설정 -->
			<div class="mb-4">
				<label class="block text-sm font-medium text-gray-700 mb-2">세로 정렬</label>
				<Select type="single" value={block.alignment || 'start'} onValueChange={(value) => updateAlignment(value as 'start' | 'center' | 'end' | 'stretch')}>
					<SelectTrigger>
						{block.alignment === 'center' ? '중앙' : block.alignment === 'end' ? '하단' : block.alignment === 'stretch' ? '늘이기' : '상단'}
					</SelectTrigger>
					<SelectContent>
						<SelectItem value="start">상단</SelectItem>
						<SelectItem value="center">중앙</SelectItem>
						<SelectItem value="end">하단</SelectItem>
						<SelectItem value="stretch">늘이기</SelectItem>
					</SelectContent>
				</Select>
			</div>
		</div>
	{/if}

	<!-- 그리드 컬럼들 -->
	<div 
		class="grid gap-{block.gap || 4} items-{block.alignment || 'start'}"
		style="grid-template-columns: {block.columns.map(col => `${col.width}fr`).join(' ')}"
	>
		{#each block.columns as column, columnIndex}
			<div class="border border-gray-300 rounded-lg p-3 bg-white min-h-[100px]">
				<div class="flex items-center justify-between mb-3">
					<span class="text-sm font-medium text-gray-600">
						컬럼 {columnIndex + 1}
					</span>
					{#if block.columns.length > 1}
						<Button
							variant="outline"
							size="sm"
							onclick={() => removeColumn(column.id)}
						>
							<Trash2 class="h-3 w-3" />
						</Button>
					{/if}
				</div>

				<!-- 반응형 설정 -->
				<div class="mb-3 space-y-2">
					<div class="grid grid-cols-3 gap-2 text-xs">
						<div>
							<label class="block text-gray-500 mb-1">데스크톱</label>
							<Input
								type="number"
								min="1"
								max="12"
								value={column.width}
								onchange={(e) => updateColumnWidth(column.id, parseInt((e.target as HTMLInputElement).value))}
								class="w-full h-7 text-xs"
								placeholder="12"
							/>
						</div>
						<div>
							<label class="block text-gray-500 mb-1">태블릿</label>
							<Input
								type="number"
								min="1"
								max="12"
								value={column.widthTablet || column.width}
								onchange={(e) => updateColumnTabletWidth(column.id, parseInt((e.target as HTMLInputElement).value))}
								class="w-full h-7 text-xs"
								placeholder={column.width.toString()}
							/>
						</div>
						<div>
							<label class="block text-gray-500 mb-1">모바일</label>
							<Input
								type="number"
								min="1"
								max="12"
								value={column.widthMobile || 12}
								onchange={(e) => updateColumnMobileWidth(column.id, parseInt((e.target as HTMLInputElement).value))}
								class="w-full h-7 text-xs"
								placeholder="12"
							/>
						</div>
					</div>
				</div>

				<!-- 컬럼 내 블록들 -->
				<div class="space-y-3">
					{#each column.blocks as columnBlock}
						<div class="border border-gray-200 rounded p-2">
							<BlockRenderer
								block={columnBlock}
								onupdate={(data) => updateBlockInColumn(column.id, columnBlock.id, data)}
								ondelete={() => deleteBlockFromColumn(column.id, columnBlock.id)}
							/>
						</div>
					{/each}

					<!-- 블록 추가 버튼 -->
					<div class="flex gap-1">
						<DropdownMenu>
							<DropdownMenuTrigger>
								<Button variant="outline" size="sm" class="flex-1 text-xs">
									<Plus class="mr-1 h-3 w-3" />
									블록 추가
								</Button>
							</DropdownMenuTrigger>
							<DropdownMenuContent align="center">
								<DropdownMenuGroup>
									{#each columnBlockTypes as blockType}
										<DropdownMenuItem
											onclick={() => addBlockToColumn(column.id, blockType.type)}
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
							variant="outline" 
							size="sm" 
							class="text-xs"
							onclick={() => onTemplateSelect?.(null, column.id)}
						>
							<Sparkles class="h-3 w-3" />
						</Button>
					</div>
				</div>
			</div>
		{/each}
	</div>

	<!-- 컬럼 추가 버튼 -->
	{#if getTotalWidth() < 12}
		<div class="mt-4 text-center">
			<Button
				variant="outline"
				onclick={addColumn}
				class="flex items-center gap-2"
			>
				<Plus class="h-4 w-4" />
				컬럼 추가 (남은 공간: {12 - getTotalWidth()})
			</Button>
		</div>
	{/if}
</div>