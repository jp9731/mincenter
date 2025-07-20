<script lang="ts">
	import { cn } from "$lib/utils.js";
	import type { HTMLAttributes } from 'svelte/elements';

	type $$Props = HTMLAttributes<HTMLLabelElement>;

	let className: $$Props['class'] = undefined;
	export { className as class };
</script>

<label
	class={cn(
		'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
		className
	)}
	on:click
	on:keydown
	on:keypress
	on:keyup
	on:focus
	on:blur
	on:change
	on:input
	{...$$restProps}
>
	<slot />
</label>
