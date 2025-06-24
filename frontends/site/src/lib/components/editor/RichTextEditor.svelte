<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { createEventDispatcher } from 'svelte';
	import { Editor } from '@tiptap/core';
	import StarterKit from '@tiptap/starter-kit';
	import Image from '@tiptap/extension-image';
	import Link from '@tiptap/extension-link';
	import Placeholder from '@tiptap/extension-placeholder';
	import TextAlign from '@tiptap/extension-text-align';
	import Underline from '@tiptap/extension-underline';
	import Color from '@tiptap/extension-color';
	import Highlight from '@tiptap/extension-highlight';

	export let value = '';
	export let placeholder = '내용을 입력하세요...';
	export let readonly = false;
	export let onImageUpload: ((file: File) => Promise<string>) | null = null;

	const dispatch = createEventDispatcher();

	let element: HTMLElement;
	let editor: Editor;
	let isEditorReady = false;

	onMount(() => {
		// DOM이 완전히 렌더링된 후 에디터 초기화
		setTimeout(() => {
			if (element) {
				editor = new Editor({
					element,
					extensions: [
						StarterKit,
						Image.configure({
							HTMLAttributes: {
								class: 'max-w-full h-auto rounded-lg'
							}
						}),
						Link.configure({
							openOnClick: false,
							HTMLAttributes: {
								class: 'text-blue-600 underline'
							}
						}),
						Placeholder.configure({
							placeholder
						}),
						TextAlign.configure({
							types: ['heading', 'paragraph']
						}),
						Underline,
						Color,
						Highlight
					],
					content: value,
					editable: !readonly,
					onUpdate: ({ editor }) => {
						const html = editor.getHTML();
						value = html;
						dispatch('update', { value: html });
					},
					onFocus: () => {
						// 포커스 시 커서가 보이도록 처리
						if (editor.isEmpty) {
							editor.commands.focus('end');
						}
					},
					onBlur: () => {
						// 블러 시에도 포커스 상태 유지
					}
				});

				isEditorReady = true;

				// 클릭 시 포커스 처리
				element.addEventListener('click', (e) => {
					if (editor && !readonly) {
						e.preventDefault();
						e.stopPropagation();
						editor.commands.focus();
					}
				});

				// 마우스 다운 시에도 포커스 처리
				element.addEventListener('mousedown', (e) => {
					if (editor && !readonly) {
						e.preventDefault();
						e.stopPropagation();
						editor.commands.focus();
					}
				});

				// 터치 이벤트도 처리
				element.addEventListener('touchstart', (e) => {
					if (editor && !readonly) {
						e.preventDefault();
						e.stopPropagation();
						editor.commands.focus();
					}
				});
			}
		}, 0);
	});

	onDestroy(() => {
		if (editor) {
			editor.destroy();
		}
	});

	// 툴바 함수들
	function toggleBold() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleBold().run();
		}
	}

	function toggleItalic() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleItalic().run();
		}
	}

	function toggleUnderline() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleUnderline().run();
		}
	}

	function toggleStrike() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleStrike().run();
		}
	}

	function toggleBulletList() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleBulletList().run();
		}
	}

	function toggleOrderedList() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleOrderedList().run();
		}
	}

	function setTextAlign(align: 'left' | 'center' | 'right') {
		if (editor && isEditorReady) {
			editor.chain().focus().setTextAlign(align).run();
		}
	}

	function setLink() {
		if (!editor || !isEditorReady) return;

		const url = window.prompt('URL을 입력하세요:');
		if (url) {
			editor.chain().focus().setLink({ href: url }).run();
		}
	}

	async function insertImage() {
		if (!onImageUpload || !editor || !isEditorReady) return;

		const input = document.createElement('input');
		input.type = 'file';
		input.accept = 'image/*';
		input.onchange = async (e) => {
			const file = (e.target as HTMLInputElement).files?.[0];
			if (file) {
				try {
					const imageUrl = await onImageUpload(file);
					editor.chain().focus().setImage({ src: imageUrl }).run();
				} catch (error) {
					console.error('이미지 업로드 실패:', error);
					alert('이미지 업로드에 실패했습니다.');
				}
			}
		};
		input.click();
	}

	function setTextColor() {
		if (!editor || !isEditorReady) return;

		const color = window.prompt('색상을 입력하세요 (예: #ff0000):');
		if (color) {
			editor.chain().focus().setColor(color).run();
		}
	}

	function toggleHighlight() {
		if (editor && isEditorReady) {
			editor.chain().focus().toggleHighlight().run();
		}
	}

	// 드래그 앤 드롭 이미지 업로드
	function handleDrop(e: DragEvent) {
		e.preventDefault();
		if (!onImageUpload || !editor || !isEditorReady) return;

		const files = e.dataTransfer?.files;
		if (files && files.length > 0) {
			const file = files[0];
			if (file.type.startsWith('image/')) {
				onImageUpload(file)
					.then((imageUrl) => {
						editor.chain().focus().setImage({ src: imageUrl }).run();
					})
					.catch((error) => {
						console.error('이미지 업로드 실패:', error);
						alert('이미지 업로드에 실패했습니다.');
					});
			}
		}
	}

	function handleDragOver(e: DragEvent) {
		e.preventDefault();
	}

	// 에디터 클릭 핸들러
	function handleEditorClick() {
		if (editor && isEditorReady && !readonly) {
			editor.commands.focus();
		}
	}
</script>

<div class="overflow-hidden rounded-lg border">
	<!-- 툴바 -->
	{#if !readonly}
		<div class="flex flex-wrap gap-1 border-b bg-gray-50 p-2">
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('bold')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleBold}
				title="굵게"
				type="button"
			>
				<span class="font-bold">B</span>
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('italic')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleItalic}
				title="기울임"
				type="button"
			>
				<span class="italic">I</span>
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('underline')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleUnderline}
				title="밑줄"
				type="button"
			>
				<span class="underline">U</span>
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('strike')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleStrike}
				title="취소선"
				type="button"
			>
				<span class="line-through">S</span>
			</button>

			<div class="mx-1 h-6 w-px bg-gray-300"></div>

			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('bulletList')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleBulletList}
				title="글머리 기호"
				type="button"
			>
				• 목록
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('orderedList')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleOrderedList}
				title="번호 매기기"
				type="button"
			>
				1. 목록
			</button>

			<div class="mx-1 h-6 w-px bg-gray-300"></div>

			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive({
					textAlign: 'left'
				})
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={() => setTextAlign('left')}
				title="왼쪽 정렬"
				type="button"
			>
				⬅
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive({
					textAlign: 'center'
				})
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={() => setTextAlign('center')}
				title="가운데 정렬"
				type="button"
			>
				↔
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive({
					textAlign: 'right'
				})
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={() => setTextAlign('right')}
				title="오른쪽 정렬"
				type="button"
			>
				➡
			</button>

			<div class="mx-1 h-6 w-px bg-gray-300"></div>

			{#if onImageUpload}
				<button
					class="rounded border border-gray-300 bg-white px-2 py-1 text-sm hover:bg-gray-100"
					onclick={insertImage}
					title="이미지 삽입"
					type="button"
				>
					🖼️
				</button>
			{/if}
			<button
				class="rounded border border-gray-300 bg-white px-2 py-1 text-sm hover:bg-gray-100"
				onclick={setLink}
				title="링크 삽입"
				type="button"
			>
				🔗
			</button>
			<button
				class="rounded border border-gray-300 bg-white px-2 py-1 text-sm hover:bg-gray-100"
				onclick={setTextColor}
				title="텍스트 색상"
				type="button"
			>
				🎨
			</button>
			<button
				class="rounded border px-2 py-1 text-sm hover:bg-gray-100 {editor?.isActive('highlight')
					? 'border-blue-300 bg-blue-100'
					: 'border-gray-300 bg-white'}"
				onclick={toggleHighlight}
				title="하이라이트"
				type="button"
			>
				🖍️
			</button>
		</div>
	{/if}

	<!-- 에디터 영역 -->
	<div
		bind:this={element}
		class="prose min-h-[300px] max-w-none cursor-text p-4 focus:outline-none"
		ondrop={handleDrop}
		ondragover={handleDragOver}
		role="textbox"
		aria-multiline="true"
		tabindex="0"
		style="user-select: text; -webkit-user-select: text; -moz-user-select: text; -ms-user-select: text;"
	></div>
</div>

<style>
	:global(.ProseMirror) {
		outline: none;
		min-height: 300px;
		cursor: text;
	}

	:global(.ProseMirror:focus) {
		outline: none;
	}

	:global(.ProseMirror p.is-editor-empty:first-child::before) {
		color: #adb5bd;
		content: attr(data-placeholder);
		float: left;
		height: 0;
		pointer-events: none;
	}

	:global(.ProseMirror img) {
		max-width: 100%;
		height: auto;
		border-radius: 0.5rem;
	}

	:global(.ProseMirror a) {
		color: #2563eb;
		text-decoration: underline;
	}

	:global(.ProseMirror ul),
	:global(.ProseMirror ol) {
		padding-left: 1.5rem;
	}

	:global(.ProseMirror blockquote) {
		border-left: 3px solid #e5e7eb;
		padding-left: 1rem;
		margin-left: 0;
		color: #6b7280;
	}
</style>
