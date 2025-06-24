<script lang="ts">
	import { onMount } from 'svelte';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Label } from '$lib/components/ui/label';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import {
		GlobeIcon,
		MapPinIcon,
		PhoneIcon,
		MailIcon,
		Share2Icon,
		PlusIcon,
		TrashIcon,
		ChevronUpIcon,
		ChevronDownIcon
	} from 'lucide-svelte';
	import { getSiteSettings, saveSiteSettings } from '$lib/api/admin';

	interface SiteInfo {
		siteName: string;
		catchphrase: string;
		address: string;
		phone: string;
		email: string;
	}

	interface SnsLink {
		id: string;
		name: string;
		url: string;
		icon: string;
		iconType: 'svg' | 'emoji';
		order: number;
	}

	let siteInfo: SiteInfo = {
		siteName: '',
		catchphrase: '',
		address: '',
		phone: '',
		email: ''
	};

	let snsLinks: SnsLink[] = [];
	let loading = true;
	let saving = false;
	let errorMessage: string | null = null;

	const snsIconOptions = [
		{ value: 'facebook', label: 'Facebook', icon: '📘' },
		{ value: 'instagram', label: 'Instagram', icon: '📷' },
		{ value: 'twitter', label: 'Twitter', icon: '🐦' },
		{ value: 'youtube', label: 'YouTube', icon: '📺' },
		{ value: 'blog', label: 'Blog', icon: '📝' },
		{ value: 'kakao', label: 'KakaoTalk', icon: '💬' },
		{ value: 'naver', label: 'Naver', icon: '🟢' },
		{ value: 'custom', label: 'Custom', icon: '🔗' }
	];

	onMount(async () => {
		await loadSiteSettings();
	});

	async function loadSiteSettings() {
		loading = true;
		try {
			errorMessage = null;
			const data = await getSiteSettings();

			// API 응답 구조에 따라 데이터 설정
			if (data.siteInfo) {
				siteInfo = data.siteInfo;
			}
			if (data.snsLinks) {
				snsLinks = data.snsLinks;
			}
		} catch (error) {
			console.error('설정 로드 실패:', error);
			errorMessage = error instanceof Error ? error.message : '설정을 불러오는데 실패했습니다.';

			// 에러 시 기본값 설정
			siteInfo = {
				siteName: '민센터 봉사단체',
				catchphrase: '함께 만들어가는 따뜻한 세상',
				address: '서울특별시 강남구 테헤란로 123',
				phone: '02-1234-5678',
				email: 'info@mincenter.org'
			};
			snsLinks = [];
		} finally {
			loading = false;
		}
	}

	async function handleSaveSettings(event: Event) {
		event.preventDefault();
		saving = true;
		try {
			errorMessage = null;
			const settingsData = {
				siteInfo,
				snsLinks
			};
			await saveSiteSettings(settingsData);

			// 성공 메시지 표시
			alert('설정이 저장되었습니다.');
		} catch (error) {
			console.error('설정 저장 실패:', error);
			errorMessage = error instanceof Error ? error.message : '설정 저장에 실패했습니다.';
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

	<!-- 에러 메시지 -->
	{#if errorMessage}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4">
			<p class="text-red-600">{errorMessage}</p>
		</div>
	{/if}

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="border-primary-600 h-8 w-8 animate-spin rounded-full border-b-2"></div>
		</div>
	{:else}
		<form onsubmit={handleSaveSettings} class="space-y-6">
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

			<!-- SNS 링크 -->
			<Card>
				<CardHeader>
					<CardTitle class="flex items-center gap-2">
						<Share2Icon class="h-5 w-5" />
						SNS 링크
					</CardTitle>
					<CardDescription>소셜 미디어 링크를 추가하고 관리하세요</CardDescription>
				</CardHeader>
				<CardContent class="space-y-4">
					<div class="flex items-center justify-between">
						<h3 class="text-lg font-medium">등록된 SNS 링크</h3>
						<Button type="button" variant="outline" onclick={addSnsLink}>
							<PlusIcon class="mr-2 h-4 w-4" />
							SNS 링크 추가
						</Button>
					</div>

					{#if snsLinks.length === 0}
						<div class="py-8 text-center text-gray-500">
							<p>등록된 SNS 링크가 없습니다.</p>
							<p class="text-sm">위의 "SNS 링크 추가" 버튼을 클릭하여 추가하세요.</p>
						</div>
					{:else}
						<div class="space-y-3">
							{#each snsLinks as link, index}
								<div class="space-y-3 rounded-lg border p-4">
									<div class="flex items-center justify-between">
										<div class="flex items-center gap-2">
											<span class="text-lg">{getIconDisplay(link.icon, link.iconType)}</span>
											<span class="font-medium">SNS 링크 #{index + 1}</span>
										</div>
										<div class="flex items-center gap-2">
											<Button
												type="button"
												variant="ghost"
												size="sm"
												onclick={() => moveSnsLink(link.id, 'up')}
												disabled={index === 0}
											>
												<ChevronUpIcon class="h-4 w-4" />
											</Button>
											<Button
												type="button"
												variant="ghost"
												size="sm"
												onclick={() => moveSnsLink(link.id, 'down')}
												disabled={index === snsLinks.length - 1}
											>
												<ChevronDownIcon class="h-4 w-4" />
											</Button>
											<Button
												type="button"
												variant="ghost"
												size="sm"
												class="text-red-600"
												onclick={() => removeSnsLink(link.id)}
											>
												<TrashIcon class="h-4 w-4" />
											</Button>
										</div>
									</div>

									<div class="grid grid-cols-1 gap-3 md:grid-cols-3">
										<div>
											<Label for="sns-name-{link.id}">SNS 이름</Label>
											<Input
												id="sns-name-{link.id}"
												bind:value={link.name}
												placeholder="예: Facebook, Instagram"
											/>
										</div>
										<div>
											<Label for="sns-icon-{link.id}">아이콘</Label>
											<Select type="single" bind:value={link.icon}>
												<SelectTrigger>
													<span class="flex items-center gap-2">
														<span>{getIconDisplay(link.icon, link.iconType)}</span>
														<span>
															{snsIconOptions.find((opt) => opt.value === link.icon)?.label ||
																'Custom'}
														</span>
													</span>
												</SelectTrigger>
												<SelectContent>
													{#each snsIconOptions as option}
														<SelectItem value={option.value}>
															<span class="flex items-center gap-2">
																<span>{option.icon}</span>
																<span>{option.label}</span>
															</span>
														</SelectItem>
													{/each}
												</SelectContent>
											</Select>
										</div>
										<div>
											<Label for="sns-url-{link.id}">URL</Label>
											<Input
												id="sns-url-{link.id}"
												bind:value={link.url}
												placeholder="https://example.com"
												type="url"
											/>
										</div>
									</div>
								</div>
							{/each}
						</div>
					{/if}
				</CardContent>
			</Card>

			<!-- 저장 버튼 -->
			<div class="flex justify-end">
				<Button type="submit" disabled={saving}>
					{saving ? '저장 중...' : '설정 저장'}
				</Button>
			</div>
		</form>
	{/if}
</div>
