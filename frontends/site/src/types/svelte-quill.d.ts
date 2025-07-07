declare module 'svelte-quill' {
	import { SvelteComponentTyped } from 'svelte';

	interface QuillEditorProps {
		value?: string;
		options?: any;
		class?: string;
	}

	interface QuillEditorEvents {
		change: CustomEvent<{ html: string; text: string }>;
	}

	export default class QuillEditor extends SvelteComponentTyped<
		QuillEditorProps,
		QuillEditorEvents
	> {}
} 