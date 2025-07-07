<script lang="ts">
	import { Select as SelectPrimitive } from "bits-ui";
	import { cn } from "$lib/utils";
	import type { HTMLAttributes } from "svelte/elements";

	type $$Props = SelectPrimitive.Value.Props & HTMLAttributes<HTMLSpanElement>;

	let className: $$Props["class"] = undefined;
	export { className as class };
</script>

<SelectPrimitive.Value
	class={cn("pointer-events-none block truncate", className)}
	{...$$restProps}
>
	<slot />
</SelectPrimitive.Value> 