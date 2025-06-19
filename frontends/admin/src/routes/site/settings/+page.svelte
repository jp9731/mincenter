<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Badge } from '$lib/components/ui/badge';
	import { Separator } from '$lib/components/ui/separator';
	import {
		PlusIcon,
		TrashIcon,
		SaveIcon,
		GlobeIcon,
		MapPinIcon,
		PhoneIcon,
		MailIcon,
		ShareIcon
	} from 'lucide-svelte';

	// 사이트 기본 정보
	let siteInfo = {
		siteName: '',
		catchphrase: '',
		address: '',
		phone: '',
		email: ''
	};

	// SNS 링크 목록
	let snsLinks: Array<{
		id: string;
		name: string;
		url: string;
		icon: string;
		iconType: 'image' | 'svg';
		order: number;
	}> = [];

	let loading = false;
	let saving = false;

	// SNS 아이콘 옵션
	const snsIconOptions = [
		{ value: 'facebook', label: 'Facebook', icon: '📘' },
		{ value: 'twitter', label: 'Twitter', icon: '🐦' },
		{ value: 'instagram', label: 'Instagram', icon: '📷' },
		{ value: 'youtube', label: 'YouTube', icon: '📺' },
		{ value: 'linkedin', label: 'LinkedIn', icon: '💼' },
		{ value: 'blog', label: 'Blog', icon: '📝' },
		{ value: 'kakao', label: 'KakaoTalk', icon: '💛' },
		{ value: 'naver', label: 'Naver', icon: '🟢' },
		{ value: 'custom', label: 'Custom', icon: '🔗' }
	];

	onMount(async () => {
		await loadSiteSettings();
	});

	async function loadSiteSettings() {
		loading = true;
		try {
			// TODO: API 호출로 실제 데이터 로드
			// const response = await fetch('/api/admin/site/settings');
			// const data = await response.json();

			// 임시 목 데이터
			siteInfo = {
				siteName: '민센터 봉사단체',
				catchphrase: '함께 만들어가는 따뜻한 세상',
				address: '서울특별시 강남구 테헤란로 123',
				phone: '02-1234-5678',
				email: 'info@mincenter.org'
			};

			snsLinks = [
				{
					id: '1',
					name: 'Facebook',
					url: 'https://facebook.com/mincenter',
					icon: 'facebook',
					iconType: 'svg',
					order: 1
				},
				{
					id: '2',
					name: 'Instagram',
					url: 'https://instagram.com/mincenter',
					icon: 'instagram',
					iconType: 'svg',
					order: 2
				},
				{
					id: '3',
					name: 'Blog',
					url: 'https://blog.naver.com/mincenter',
					icon: 'blog',
					iconType: 'svg',
					order: 3
				}
			];
		} catch (error) {
			console.error('설정 로드 실패:', error);
		} finally {
			loading = false;
		}
	}

	async function saveSiteSettings(event: Event) {
		event.preventDefault();
		saving = true;
		try {
			// TODO: API 호출로 실제 데이터 저장
			// const response = await fetch('/api/admin/site/settings', {
			// 	method: 'PUT',
			// 	headers: { 'Content-Type': 'application/json' },
			// 	body: JSON.stringify({ siteInfo, snsLinks })
			// });

			console.log('저장할 데이터:', { siteInfo, snsLinks });

			// 성공 메시지 표시
			alert('설정이 저장되었습니다.');
		} catch (error) {
			console.error('설정 저장 실패:', error);
			alert('설정 저장에 실패했습니다.');
		} finally {
			saving = false;
		}
	}

	function addSnsLink() {
		const newLink = {
			id: Date.now().toString(),
			name: '',
			url: '',
			icon: 'custom',
			iconType: 'svg' as const,
			order: snsLinks.length + 1
		};
		snsLinks = [...snsLinks, newLink];
	}

	function removeSnsLink(id: string) {
		snsLinks = snsLinks.filter((link) => link.id !== id);
		// 순서 재정렬
		snsLinks = snsLinks.map((link, index) => ({
			...link,
			order: index + 1
		}));
	}

	function moveSnsLink(id: string, direction: 'up' | 'down') {
		const index = snsLinks.findIndex((link) => link.id === id);
		if (index === -1) return;

		const newLinks = [...snsLinks];
		if (direction === 'up' && index > 0) {
			[newLinks[index], newLinks[index - 1]] = [newLinks[index - 1], newLinks[index]];
		} else if (direction === 'down' && index < newLinks.length - 1) {
			[newLinks[index], newLinks[index + 1]] = [newLinks[index + 1], newLinks[index]];
		}

		// 순서 재정렬
		snsLinks = newLinks.map((link, idx) => ({
			...link,
			order: idx + 1
		}));
	}

	function getIconDisplay(icon: string, iconType: string) {
		const option = snsIconOptions.find((opt) => opt.value === icon);
		return option ? option.icon : '🔗';
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div>
		<h1 class="text-2xl font-bold text-gray-900">사이트 기본 설정</h1>
		<p class="text-gray-600">사이트의 기본 정보와 SNS 링크를 관리하세요</p>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="border-primary-600 h-8 w-8 animate-spin rounded-full border-b-2"></div>
		</div>
	{:else}
		<form onsubmit={saveSiteSettings} class="space-y-6">
			<!-- 기본 정보 -->
			<Card>
				<CardHeader>
					<CardTitle class="flex items-center gap-2">
						<GlobeIcon class="h-5 w-5" />
						기본 정보
					</CardTitle>
					<CardDescription>사이트의 기본적인 정보를 설정합니다</CardDescription>
				</CardHeader>
				<CardContent class="space-y-4">
					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="siteName" class="mb-1 block text-sm font-medium text-gray-700">
								사이트명 <span class="text-red-500">*</span>
							</label>
							<Input
								id="siteName"
								bind:value={siteInfo.siteName}
								placeholder="사이트명을 입력하세요"
								required
							/>
						</div>
						<div>
							<label for="catchphrase" class="mb-1 block text-sm font-medium text-gray-700">
								캐치프라이즈
							</label>
							<Input
								id="catchphrase"
								bind:value={siteInfo.catchphrase}
								placeholder="캐치프라이즈를 입력하세요"
							/>
						</div>
					</div>

					<div>
						<label for="address" class="mb-1 block text-sm font-medium text-gray-700"> 주소 </label>
						<div class="flex items-center gap-2">
							<MapPinIcon class="h-4 w-4 text-gray-400" />
							<Input id="address" bind:value={siteInfo.address} placeholder="주소를 입력하세요" />
						</div>
					</div>

					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="phone" class="mb-1 block text-sm font-medium text-gray-700">
								연락처
							</label>
							<div class="flex items-center gap-2">
								<PhoneIcon class="h-4 w-4 text-gray-400" />
								<Input id="phone" bind:value={siteInfo.phone} placeholder="연락처를 입력하세요" />
							</div>
						</div>
						<div>
							<label for="email" class="mb-1 block text-sm font-medium text-gray-700">
								이메일
							</label>
							<div class="flex items-center gap-2">
								<MailIcon class="h-4 w-4 text-gray-400" />
								<Input
									id="email"
									type="email"
									bind:value={siteInfo.email}
									placeholder="이메일을 입력하세요"
								/>
							</div>
						</div>
					</div>
				</CardContent>
			</Card>

			<!-- SNS 링크 관리 -->
			<Card>
				<CardHeader>
					<CardTitle class="flex items-center gap-2">
						<ShareIcon class="h-5 w-5" />
						SNS 링크 관리
					</CardTitle>
					<CardDescription>SNS 계정 링크를 추가하고 관리합니다</CardDescription>
				</CardHeader>
				<CardContent>
					<div class="space-y-4">
						<!-- SNS 링크 목록 -->
						{#if snsLinks.length === 0}
							<div class="py-8 text-center text-gray-500">
								<ShareIcon class="mx-auto mb-2 h-12 w-12 text-gray-300" />
								<p>등록된 SNS 링크가 없습니다.</p>
								<p class="text-sm">아래 버튼을 클릭하여 SNS 링크를 추가하세요.</p>
							</div>
						{:else}
							<div class="space-y-3">
								{#each snsLinks as link, index}
									<div class="rounded-lg border bg-gray-50 p-4">
										<div class="flex items-center gap-4">
											<!-- 순서 표시 -->
											<div class="flex flex-col gap-1">
												<button
													type="button"
													class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-50"
													disabled={index === 0}
													onclick={() => moveSnsLink(link.id, 'up')}
												>
													↑
												</button>
												<Badge variant="secondary" class="text-xs">
													{link.order}
												</Badge>
												<button
													type="button"
													class="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-50"
													disabled={index === snsLinks.length - 1}
													onclick={() => moveSnsLink(link.id, 'down')}
												>
													↓
												</button>
											</div>

											<!-- 아이콘 -->
											<div
												class="flex h-10 w-10 items-center justify-center rounded-lg border bg-white"
											>
												<span class="text-lg">{getIconDisplay(link.icon, link.iconType)}</span>
											</div>

											<!-- 입력 필드들 -->
											<div class="grid flex-1 grid-cols-1 gap-3 md:grid-cols-3">
												<div>
													<label class="mb-1 block text-xs font-medium text-gray-600">
														SNS명
													</label>
													<Input bind:value={link.name} placeholder="SNS명" class="text-sm" />
												</div>
												<div>
													<label class="mb-1 block text-xs font-medium text-gray-600"> URL </label>
													<Input bind:value={link.url} placeholder="https://" class="text-sm" />
												</div>
												<div>
													<label class="mb-1 block text-xs font-medium text-gray-600">
														아이콘
													</label>
													<select
														bind:value={link.icon}
														class="focus:ring-primary-500 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:outline-none focus:ring-2"
													>
														{#each snsIconOptions as option}
															<option value={option.value}>
																{option.icon}
																{option.label}
															</option>
														{/each}
													</select>
												</div>
											</div>

											<!-- 삭제 버튼 -->
											<button
												type="button"
												class="rounded-lg p-2 text-red-500 hover:bg-red-50"
												onclick={() => removeSnsLink(link.id)}
											>
												<TrashIcon class="h-4 w-4" />
											</button>
										</div>
									</div>
								{/each}
							</div>
						{/if}

						<Separator />

						<!-- SNS 링크 추가 버튼 -->
						<Button type="button" variant="outline" onclick={addSnsLink} class="w-full">
							<PlusIcon class="mr-2 h-4 w-4" />
							SNS 링크 추가
						</Button>
					</div>
				</CardContent>
			</Card>

			<!-- 저장 버튼 -->
			<div class="flex justify-end gap-3">
				<Button type="button" variant="outline" onclick={loadSiteSettings}>취소</Button>
				<Button type="submit" disabled={saving}>
					{#if saving}
						<div class="mr-2 h-4 w-4 animate-spin rounded-full border-b-2 border-white"></div>
						저장 중...
					{:else}
						<SaveIcon class="mr-2 h-4 w-4" />
						저장
					{/if}
				</Button>
			</div>
		</form>
	{/if}
</div>
