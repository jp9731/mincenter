import { writable } from 'svelte/store';

interface AlertState {
	isOpen: boolean;
	title: string;
	description: string;
	confirmText: string;
	cancelText: string;
	variant: 'default' | 'destructive';
	onConfirm?: () => void | Promise<void>;
	onCancel?: () => void | Promise<void>;
}

const defaultState: AlertState = {
	isOpen: false,
	title: '',
	description: '',
	confirmText: '확인',
	cancelText: '취소',
	variant: 'default',
	onConfirm: undefined,
	onCancel: undefined
};

export const alertStore = writable<AlertState>(defaultState);

// 간단한 알림 (확인만)
export function showAlert(title: string, description: string, confirmText: string = '확인') {
	alertStore.set({
		...defaultState,
		isOpen: true,
		title,
		description,
		confirmText,
		cancelText: '',
		onConfirm: undefined
	});
}

// 확인/취소 다이얼로그
export function showConfirm(
	title: string,
	description: string,
	onConfirm: () => void | Promise<void>,
	onCancel?: () => void | Promise<void>,
	confirmText: string = '확인',
	cancelText: string = '취소',
	variant: 'default' | 'destructive' = 'default'
) {
	alertStore.set({
		isOpen: true,
		title,
		description,
		confirmText,
		cancelText,
		variant,
		onConfirm,
		onCancel
	});
}

// 위험한 작업 확인 (삭제 등)
export function showDestructiveConfirm(
	title: string,
	description: string,
	onConfirm: () => void | Promise<void>,
	onCancel?: () => void | Promise<void>,
	confirmText: string = '삭제',
	cancelText: string = '취소'
) {
	showConfirm(title, description, onConfirm, onCancel, confirmText, cancelText, 'destructive');
}

// 다이얼로그 닫기
export function closeAlert() {
	alertStore.set({ ...defaultState, isOpen: false });
}
