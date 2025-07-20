<script lang="ts">
	import { Input } from '$lib/components/ui/input';
	import { Button } from '$lib/components/ui/button';
	import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '$lib/components/ui/dialog';
	import { MapPin, Search, Map as MapIcon } from 'lucide-svelte';
	import type { MapBlock } from '$lib/types/blocks';

	interface Props {
		block: MapBlock;
		onupdate?: (data: Partial<MapBlock>) => void;
		ondelete?: () => void;
	}

	let { block, onupdate, ondelete }: Props = $props();

	let isSearchModalOpen = $state(false);
	let searchQuery = $state('');
	let searchResults = $state<any[]>([]);
	let isSearching = $state(false);
	let isApiLoading = $state(false);

	// 카카오 지도 API 함수들
	function initKakaoMap() {
		if (typeof window !== 'undefined' && (window as any).kakao && (window as any).kakao.maps) {
			return true;
		}
		return false;
	}

	async function searchAddress(query: string) {
		if (!block.apiKey) {
			alert('카카오 지도 API 키를 먼저 입력해주세요.');
			return;
		}

		// API 키가 있지만 스크립트가 로드되지 않은 경우
		if (!initKakaoMap()) {
			alert('카카오 지도 API가 아직 로드되지 않았습니다. 잠시 후 다시 시도해주세요.');
			return;
		}

		isSearching = true;
		searchResults = [];

		try {
			const geocoder = new (window as any).kakao.maps.services.Geocoder();
			
			geocoder.addressSearch(query, (result: any[], status: any) => {
				if (status === (window as any).kakao.maps.services.Status.OK) {
					searchResults = result.slice(0, 5); // 최대 5개 결과만 표시
				} else {
					alert('검색 결과가 없습니다.');
				}
				isSearching = false;
			});
		} catch (error) {
			console.error('주소 검색 실패:', error);
			alert('주소 검색에 실패했습니다.');
			isSearching = false;
		}
	}

	function selectAddress(result: any) {
		onupdate?.({
			address: result.address_name,
			latitude: parseFloat(result.y),
			longitude: parseFloat(result.x)
		});
		isSearchModalOpen = false;
		searchQuery = '';
		searchResults = [];
	}

	function handleApiKeyChange(event: Event) {
		const target = event.target as HTMLInputElement;
		const apiKey = target.value.trim();
		
		// API 키 형식 검증 (카카오 API 키는 보통 32자 이상)
		if (apiKey && apiKey.length < 20) {
			console.warn('API 키가 너무 짧습니다. 올바른 카카오 JavaScript 키인지 확인해주세요.');
		}
		
		// API 키가 변경되면 로딩 상태 초기화
		if (apiKey !== block.apiKey) {
			isApiLoading = false;
		}
		
		onupdate?.({ apiKey });
	}

	// API 키 테스트 함수
	function testApiKey() {
		if (!block.apiKey) {
			alert('먼저 API 키를 입력해주세요.');
			return;
		}
		
		console.log('API 키 테스트 시작...');
		console.log('API 키:', block.apiKey.substring(0, 10) + '...');
		
		// 간단한 테스트 요청
		fetch(`https://dapi.kakao.com/v2/maps/sdk.js?appkey=${block.apiKey}&libraries=services&autoload=false`)
			.then(response => {
				if (response.ok) {
					console.log('API 키 테스트 성공');
					alert('API 키가 유효합니다!');
				} else {
					console.error('API 키 테스트 실패:', response.status);
					alert('API 키가 유효하지 않습니다. JavaScript 키를 사용하고 있는지 확인해주세요.');
				}
			})
			.catch(error => {
				console.error('API 키 테스트 오류:', error);
				alert('API 키 테스트 중 오류가 발생했습니다.');
			});
	}

	function handleTitleChange(event: Event) {
		const target = event.target as HTMLInputElement;
		onupdate?.({ title: target.value });
	}

	function handleWidthChange(event: Event) {
		const target = event.target as HTMLInputElement;
		const value = parseInt(target.value) || 400;
		onupdate?.({ width: value });
	}

	function handleHeightChange(event: Event) {
		const target = event.target as HTMLInputElement;
		const value = parseInt(target.value) || 300;
		onupdate?.({ height: value });
	}

	function handleZoomChange(event: Event) {
		const target = event.target as HTMLInputElement;
		const value = parseInt(target.value) || 3;
		onupdate?.({ zoom: Math.min(14, Math.max(1, value)) });
	}

	// 카카오 맵 스크립트 로드
	function loadKakaoMapScript() {
		if (typeof window !== 'undefined' && !(window as any).kakao && block.apiKey) {
			isApiLoading = true;
			
			// 기존 스크립트가 있다면 제거
			const existingScript = document.querySelector('script[src*="dapi.kakao.com"]');
			if (existingScript) {
				existingScript.remove();
			}

			// API 키 검증
			const apiKey = block.apiKey.trim();
			if (!apiKey || apiKey.length < 20) {
				console.error('API 키가 유효하지 않습니다:', apiKey);
				alert('올바른 카카오 JavaScript API 키를 입력해주세요.');
				isApiLoading = false;
				return;
			}

			const script = document.createElement('script');
			script.async = true;
			script.src = `https://dapi.kakao.com/v2/maps/sdk.js?appkey=${apiKey}&libraries=services&autoload=false`;
			
			// 타임아웃 설정
			const timeout = setTimeout(() => {
				console.error('카카오 맵 스크립트 로드 타임아웃');
				alert('카카오 맵 API 로드가 시간 초과되었습니다. 네트워크 연결을 확인해주세요.');
				isApiLoading = false;
			}, 10000); // 10초 타임아웃
			
			script.onload = () => {
				clearTimeout(timeout);
				console.log('카카오 맵 스크립트 로드 성공');
				(window as any).kakao.maps.load(() => {
					console.log('카카오 맵 API 초기화 완료');
					isApiLoading = false;
				});
			};
			
			script.onerror = (error) => {
				clearTimeout(timeout);
				console.error('카카오 맵 스크립트 로드 실패:', error);
				console.error('API 키:', apiKey ? `${apiKey.substring(0, 10)}...` : '없음');
				console.error('스크립트 URL:', script.src);
				
				// 더 구체적인 오류 메시지
				let errorMessage = '카카오 맵 API 로드에 실패했습니다.\n\n';
				errorMessage += '가능한 원인:\n';
				errorMessage += '1. API 키가 올바르지 않습니다 (JavaScript 키를 사용해야 함)\n';
				errorMessage += '2. 카카오 개발자 콘솔에서 도메인이 등록되지 않았습니다\n';
				errorMessage += '3. 네트워크 연결을 확인해주세요\n';
				errorMessage += '4. 브라우저 콘솔에서 자세한 오류를 확인해주세요';
				
				alert(errorMessage);
				isApiLoading = false;
			};
			
			document.head.appendChild(script);
		}
	}

	// API 키가 변경될 때마다 스크립트 다시 로드
	$effect(() => {
		if (block.apiKey) {
			loadKakaoMapScript();
		}
	});
</script>

<div class="space-y-4">
	{#if block.address && block.latitude && block.longitude}
		<div class="border-2 border-dashed border-gray-300 rounded-lg p-4 text-center bg-gray-50">
			<MapIcon class="mx-auto h-12 w-12 text-gray-400 mb-2" />
			<p class="text-sm font-medium text-gray-700">{block.title || '카카오 지도'}</p>
			<p class="text-xs text-gray-500 mt-1">{block.address}</p>
			<p class="text-xs text-gray-400 mt-1">
				위도: {block.latitude.toFixed(6)}, 경도: {block.longitude.toFixed(6)}
			</p>
			<div class="mt-2 text-xs text-gray-500">
				크기: {block.width || 400}px × {block.height || 300}px | 줌: {block.zoom || 3}
			</div>
		</div>
	{:else}
		<div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center">
			<MapPin class="mx-auto h-12 w-12 text-gray-400" />
			<p class="mt-2 text-sm text-gray-500">지도를 추가하세요</p>
		</div>
	{/if}

	<div class="space-y-3">
		<div>
			<label class="mb-1 block text-sm font-medium text-gray-700">
				카카오 지도 API 키 <span class="text-red-500">*</span>
			</label>
			<div class="flex gap-2">
				<Input
					value={block.apiKey || ''}
					placeholder="JavaScript 키를 입력하세요 (예: 1234567890abcdef1234567890abcdef)"
					oninput={handleApiKeyChange}
					type="text"
					class="flex-1"
				/>
				<Button
					variant="outline"
					size="sm"
					onclick={testApiKey}
					disabled={!block.apiKey}
				>
					테스트
				</Button>
			</div>
			<div class="mt-1 space-y-1">
				{#if block.apiKey}
					{#if isApiLoading}
						<div class="flex items-center gap-1 text-xs text-blue-600">
							<div class="h-3 w-3 animate-spin rounded-full border-2 border-blue-300 border-t-blue-600"></div>
							API 로딩 중...
						</div>
					{:else if initKakaoMap()}
						<div class="flex items-center gap-1 text-xs text-green-600">
							<div class="h-2 w-2 bg-green-500 rounded-full"></div>
							API 준비 완료
						</div>
					{:else}
						<div class="flex items-center gap-1 text-xs text-orange-600">
							<div class="h-2 w-2 bg-orange-500 rounded-full"></div>
							API 초기화 중...
						</div>
					{/if}
				{/if}
				<div class="flex items-center gap-2">
					<a href="https://developers.kakao.com/console/app" target="_blank" class="text-blue-500 hover:underline text-xs">
						JavaScript 키 발급받기
					</a>
					<span class="text-xs text-gray-500">•</span>
					<span class="text-xs text-gray-500">카카오 개발자 콘솔 → 앱 → 플랫폼 → Web → JavaScript 키 사용</span>
				</div>
				<div class="text-xs text-gray-500">
					💡 <strong>중요:</strong> 카카오 개발자 콘솔에서 "플랫폼 → Web"에 현재 도메인(localhost:5174)을 등록해야 합니다.
				</div>
			</div>
		</div>

		<div>
			<label class="mb-1 block text-sm font-medium text-gray-700">지도 제목</label>
			<Input
				value={block.title || ''}
				placeholder="지도 제목을 입력하세요"
				oninput={handleTitleChange}
			/>
		</div>

		<div>
			<label class="mb-1 block text-sm font-medium text-gray-700">주소</label>
			<div class="flex gap-2">
				<Input
					value={block.address || ''}
					placeholder="주소가 선택되면 여기에 표시됩니다"
					readonly
					class="flex-1"
				/>
				<Dialog bind:open={isSearchModalOpen}>
					<DialogTrigger>
						<Button
							variant="outline"
							disabled={!block.apiKey || isApiLoading}
						>
							{#if isApiLoading}
								<div class="h-4 w-4 animate-spin rounded-full border-2 border-gray-300 border-t-blue-600"></div>
							{:else}
								<Search class="h-4 w-4" />
							{/if}
						</Button>
					</DialogTrigger>
					<DialogContent class="sm:max-w-md">
						<DialogHeader>
							<DialogTitle>주소 검색</DialogTitle>
						</DialogHeader>
						<div class="space-y-4">
							<div class="flex gap-2">
								<Input
									bind:value={searchQuery}
									placeholder="주소를 입력하세요 (예: 서울시 강남구 역삼동)"
									class="flex-1"
									onkeydown={(e) => e.key === 'Enter' && searchAddress(searchQuery)}
								/>
								<Button
									onclick={() => searchAddress(searchQuery)}
									disabled={isSearching || !searchQuery.trim()}
								>
									{isSearching ? '검색 중...' : '검색'}
								</Button>
							</div>

							{#if searchResults.length > 0}
								<div class="space-y-2 max-h-64 overflow-y-auto">
									{#each searchResults as result}
										<button
											class="w-full text-left p-3 border rounded-lg hover:bg-gray-50 transition-colors"
											onclick={() => selectAddress(result)}
										>
											<div class="font-medium text-sm">{result.address_name}</div>
											{#if result.road_address_name}
												<div class="text-xs text-gray-500 mt-1">{result.road_address_name}</div>
											{/if}
										</button>
									{/each}
								</div>
							{:else if isSearching}
								<div class="text-center py-4 text-gray-500">검색 중...</div>
							{/if}
						</div>
					</DialogContent>
				</Dialog>
			</div>
		</div>

		<div class="grid grid-cols-2 gap-3">
			<div>
				<label class="mb-1 block text-sm font-medium text-gray-700">너비 (px)</label>
				<Input
					type="number"
					value={block.width || 400}
					min="200"
					max="1200"
					oninput={handleWidthChange}
				/>
			</div>
			<div>
				<label class="mb-1 block text-sm font-medium text-gray-700">높이 (px)</label>
				<Input
					type="number"
					value={block.height || 300}
					min="200"
					max="800"
					oninput={handleHeightChange}
				/>
			</div>
		</div>

		<div>
			<label class="mb-1 block text-sm font-medium text-gray-700">줌 레벨 (1-14)</label>
			<Input
				type="number"
				value={block.zoom || 3}
				min="1"
				max="14"
				oninput={handleZoomChange}
			/>
		</div>
	</div>
</div>