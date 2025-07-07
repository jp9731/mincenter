import { writable, type Writable } from 'svelte/store';

// Quill 인스턴스를 저장할 스토어
export const quillInstanceStore: Writable<any> = writable(null);

// Quill 인스턴스 설정 함수
export function setQuillInstance(instance: any) {
	quillInstanceStore.set(instance);
}

// Quill 인스턴스 가져오기 함수
export function getQuillInstance() {
	let instance: any = null;
	quillInstanceStore.subscribe(value => {
		instance = value;
	})();
	return instance;
}

// Quill 인스턴스 정리 함수
export function clearQuillInstance() {
	quillInstanceStore.set(null);
} 