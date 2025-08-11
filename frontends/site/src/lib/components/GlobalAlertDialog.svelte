<script lang="ts">
	import * as AlertDialog from '$lib/components/ui/alert-dialog';
	import { alertStore, closeAlert } from '$lib/stores/alert';

	$: ({ isOpen, title, description, confirmText, cancelText, variant, onConfirm, onCancel } = $alertStore);

	async function handleConfirm() {
		try {
			if (onConfirm) {
				await onConfirm();
			}
		} finally {
			closeAlert();
		}
	}

	async function handleCancel() {
		try {
			if (onCancel) {
				await onCancel();
			}
		} finally {
			closeAlert();
		}
	}
</script>

<AlertDialog.Root bind:open={isOpen}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>{title}</AlertDialog.Title>
			<AlertDialog.Description>
				{description}
			</AlertDialog.Description>
		</AlertDialog.Header>
		<AlertDialog.Footer>
			{#if cancelText}
				<AlertDialog.Cancel onclick={handleCancel}>
					{cancelText}
				</AlertDialog.Cancel>
			{/if}
			<AlertDialog.Action 
				class={variant === 'destructive' ? 'bg-destructive text-destructive-foreground hover:bg-destructive/90' : ''}
				onclick={handleConfirm}
			>
				{confirmText}
			</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
