<script lang="ts">
	import type { Block, BlocksData } from '$lib/types/blocks';

	interface Props {
		content: string;
	}

	let { content }: Props = $props();

	let blocks: Block[] = $state([]);

	$effect(() => {
		if (content && content.trim()) {
			try {
				const parsed: BlocksData = JSON.parse(content);
				if (parsed.blocks && Array.isArray(parsed.blocks)) {
					blocks = parsed.blocks;
				}
			} catch (e) {
				console.warn('Failed to parse blocks data:', e);
				// If parsing fails, treat as plain text
				blocks = [];
			}
		} else {
			blocks = [];
		}
	});

	function getTextStyles(styles?: any): string {
		if (!styles) return '';
		
		const classes = [];
		
		// 폰트 패밀리
		if (styles.fontFamily) {
			const fontMap = {
				'sans': 'font-sans',
				'serif': 'font-serif', 
				'mono': 'font-mono',
				'cursive': 'font-cursive'
			};
			classes.push(fontMap[styles.fontFamily] || 'font-sans');
		}
		
		// 폰트 크기
		if (styles.fontSize) {
			const sizeMap = {
				'xs': 'text-xs', 'sm': 'text-sm', 'base': 'text-base', 'lg': 'text-lg',
				'xl': 'text-xl', '2xl': 'text-2xl', '3xl': 'text-3xl', '4xl': 'text-4xl', '5xl': 'text-5xl'
			};
			classes.push(sizeMap[styles.fontSize] || 'text-base');
		}
		
		// 폰트 굵기
		if (styles.fontWeight) {
			const weightMap = {
				'light': 'font-light', 'normal': 'font-normal', 'medium': 'font-medium',
				'semibold': 'font-semibold', 'bold': 'font-bold', 'extrabold': 'font-extrabold'
			};
			classes.push(weightMap[styles.fontWeight] || 'font-normal');
		}
		
		// 폰트 스타일
		if (styles.fontStyle === 'italic') {
			classes.push('italic');
		}
		
		// 텍스트 색상
		if (styles.textColor) {
			classes.push(styles.textColor);
		}
		
		// 배경 색상
		if (styles.backgroundColor) {
			classes.push(styles.backgroundColor);
		}
		
		// 텍스트 장식
		if (styles.textDecoration) {
			const decorationMap = {
				'underline': 'underline',
				'line-through': 'line-through'
			};
			classes.push(decorationMap[styles.textDecoration] || '');
		}
		
		// 텍스트 정렬
		if (styles.textAlign) {
			const alignMap = {
				'left': 'text-left', 'center': 'text-center', 'right': 'text-right', 'justify': 'text-justify'
			};
			classes.push(alignMap[styles.textAlign] || 'text-left');
		}
		
		// 자간
		if (styles.letterSpacing) {
			const spacingMap = {
				'tighter': 'tracking-tighter', 'tight': 'tracking-tight', 'normal': 'tracking-normal',
				'wide': 'tracking-wide', 'wider': 'tracking-wider', 'widest': 'tracking-widest'
			};
			classes.push(spacingMap[styles.letterSpacing] || 'tracking-normal');
		}
		
		// 행간
		if (styles.lineHeight) {
			const heightMap = {
				'none': 'leading-none', 'tight': 'leading-tight', 'snug': 'leading-snug',
				'normal': 'leading-normal', 'relaxed': 'leading-relaxed', 'loose': 'leading-loose'
			};
			classes.push(heightMap[styles.lineHeight] || 'leading-normal');
		}
		
		// 커스텀 스타일
		if (styles.customStyles) {
			classes.push(styles.customStyles);
		}
		
		return classes.filter(Boolean).join(' ');
	}

	function renderBlock(block: Block): string {
		switch (block.type) {
			case 'paragraph':
				const pStyles = getTextStyles(block.styles);
				const pContent = block.link ? `<a href="${block.link.url}" target="${block.link.target || '_self'}" ${block.link.rel ? `rel="${block.link.rel}"` : ''}>${block.content}</a>` : block.content;
				return `<p class="mb-4 ${pStyles || 'text-gray-700 leading-relaxed'}">${pContent}</p>`;
			case 'heading':
				const hStyles = getTextStyles(block.styles);
				const headingClass = block.level === 1 ? 'text-3xl font-bold mb-6' :
					block.level === 2 ? 'text-2xl font-semibold mb-4' :
					block.level === 3 ? 'text-xl font-medium mb-3' :
					'text-lg font-medium mb-2';
				const hContent = block.link ? `<a href="${block.link.url}" target="${block.link.target || '_self'}" ${block.link.rel ? `rel="${block.link.rel}"` : ''}>${block.content}</a>` : block.content;
				return `<h${block.level} class="${headingClass} ${hStyles || 'text-gray-900'}">${hContent}</h${block.level}>`;
			case 'image':
				const caption = block.caption ? `<figcaption class="text-sm text-gray-500 text-center mt-2">${block.caption}</figcaption>` : '';
				return `
					<figure class="my-6">
						<img src="${block.src}" alt="${block.alt}" class="w-full h-auto rounded-lg shadow-md" ${block.width ? `width="${block.width}"` : ''} ${block.height ? `height="${block.height}"` : ''} />
						${caption}
					</figure>
				`;
			case 'list':
				const tag = block.style === 'ordered' ? 'ol' : 'ul';
				const listClass = block.style === 'ordered' ? 'list-decimal' : 'list-disc';
				const listStyles = getTextStyles(block.styles);
				const items = block.items.map((item: string) => `<li class="mb-1">${item}</li>`).join('');
				return `<${tag} class="${listClass} ml-6 mb-4 ${listStyles || 'text-gray-700'}">${items}</${tag}>`;
			case 'quote':
				const quoteStyles = getTextStyles(block.styles);
				const author = block.author ? `<cite class="block text-sm text-gray-500 mt-2">— ${block.author}</cite>` : '';
				return `
					<blockquote class="border-l-4 border-blue-500 pl-4 py-2 my-6 bg-blue-50 rounded-r-lg">
						<p class="${quoteStyles || 'text-gray-700 italic'}">${block.content}</p>
						${author}
					</blockquote>
				`;
			case 'code':
				const codeStyles = getTextStyles(block.styles);
				const languageClass = block.language ? `language-${block.language}` : '';
				return `
					<pre class="bg-gray-900 text-gray-100 p-4 rounded-lg overflow-x-auto my-6">
						<code class="${languageClass} ${codeStyles}">${block.content}</code>
					</pre>
				`;
			case 'map':
				return `
					<div class="bg-gray-100 p-4 rounded-lg my-6 text-center">
						<div class="text-gray-600 mb-2">📍 카카오 지도</div>
						${block.title ? `<div class="font-medium text-gray-900">${block.title}</div>` : ''}
						${block.address ? `<div class="text-sm text-gray-500">${block.address}</div>` : ''}
						<div class="text-xs text-gray-400 mt-1">${block.width || 400}px × ${block.height || 300}px</div>
					</div>
				`;
			case 'grid':
				const gridColumns = block.columns.map(col => {
					const columnBlocks = col.blocks.map(columnBlock => renderBlock(columnBlock)).join('');
					return `<div class="border border-gray-200 p-4 rounded bg-white">${columnBlocks || '<div class="text-gray-400 text-sm">빈 컬럼</div>'}</div>`;
				}).join('');
				return `
					<div class="bg-gray-50 p-4 rounded-lg my-6">
						<div class="text-sm text-gray-600 mb-3">📊 그리드 레이아웃 (${block.columns.length}컬럼)</div>
						<div class="grid gap-4" style="grid-template-columns: ${block.columns.map(col => `${col.width}fr`).join(' ')}">${gridColumns}</div>
					</div>
				`;
			case 'post-list':
				return `
					<div class="bg-blue-50 p-4 rounded-lg border border-blue-200 my-6">
						<div class="text-blue-800 font-medium mb-2">📄 ${block.title || '포스트 목록'}</div>
						<div class="text-sm text-blue-600 space-y-1">
							<div>게시판: ${block.boardType || 'community'}</div>
							${block.category ? `<div>카테고리: ${block.category}</div>` : ''}
							<div>정렬: ${block.sortBy === 'recent' ? '최신순' : block.sortBy === 'popular' ? '인기순' : '좋아요순'} • ${block.limit}개</div>
							<div>레이아웃: ${block.layout === 'list' ? '목록형' : block.layout === 'card' ? '카드형' : '심플형'}</div>
						</div>
					</div>
				`;
			case 'divider':
				return '<hr class="my-6 border-gray-300" />';
			case 'html':
				return `<div class="my-4">${block.content}</div>`;
			case 'button':
				const buttonStyles = block.styles;
				const variantClasses = {
					'primary': 'bg-blue-600 hover:bg-blue-700 text-white',
					'secondary': 'bg-gray-600 hover:bg-gray-700 text-white',
					'outline': 'border border-gray-300 hover:bg-gray-50 text-gray-700',
					'ghost': 'hover:bg-gray-100 text-gray-700',
					'destructive': 'bg-red-600 hover:bg-red-700 text-white',
					'link': 'text-blue-600 hover:text-blue-800 underline'
				};
				const sizeClasses = {
					'sm': 'px-3 py-1.5 text-sm',
					'md': 'px-4 py-2 text-sm',
					'lg': 'px-6 py-3 text-base',
					'xl': 'px-8 py-4 text-lg'
				};
				const widthClasses = {
					'auto': 'w-auto',
					'full': 'w-full',
					'fit': 'w-fit'
				};
				const alignClasses = {
					'left': 'text-left',
					'center': 'text-center',
					'right': 'text-right'
				};
				
				const classes = [
					'inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 disabled:pointer-events-none',
					variantClasses[buttonStyles.variant] || variantClasses.primary,
					sizeClasses[buttonStyles.size] || sizeClasses.md,
					widthClasses[buttonStyles.width] || widthClasses.auto,
					alignClasses[buttonStyles.textAlign] || alignClasses.center,
					buttonStyles.customStyles || ''
				].filter(Boolean).join(' ');
				
				const target = block.link.target || '_self';
				const rel = target === '_blank' ? 'rel="noopener noreferrer"' : '';
				
				return `<a href="${block.link.url}" target="${target}" ${rel} class="${classes}">${block.text}</a>`;
			default:
				return '';
		}
	}
</script>

<div class="prose max-w-none">
	{#if blocks.length > 0}
		{#each blocks as block (block.id)}
			{@html renderBlock(block)}
		{/each}
	{:else if content && content.trim()}
		<!-- Fallback to plain text if no valid blocks -->
		<div class="text-gray-700 leading-relaxed">
			{content}
		</div>
	{:else}
		<div class="text-gray-500 text-center py-8">
			내용이 없습니다.
		</div>
	{/if}
</div> 