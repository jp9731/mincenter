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
		ChevronDownIcon,
		FanIcon,
		UserIcon,
		BuildingIcon,
		ImageIcon
	} from 'lucide-svelte';
	import { getSiteSettings, saveSiteSettings, uploadSiteFile } from '$lib/api/admin';

	interface SiteInfo {
		siteName: string;
		siteDescription: string;
		siteKeywords: string;
		siteAuthor: string;
		siteUrl: string;
		siteLogo: string;
		siteFavicon: string;
		contactEmail: string;
		contactPhone: string;
		contactFax: string;
		contactAddress: string;
		businessNumber: string;
		socialFacebook: string;
		socialTwitter: string;
		socialInstagram: string;
		socialYoutube: string;
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
		siteDescription: '',
		siteKeywords: '',
		siteAuthor: '',
		siteUrl: '',
		siteLogo: '',
		siteFavicon: '',
		contactEmail: '',
		contactPhone: '',
		contactFax: '',
		contactAddress: '',
		businessNumber: '',
		socialFacebook: '',
		socialTwitter: '',
		socialInstagram: '',
		socialYoutube: ''
	};

	let snsLinks: SnsLink[] = [];
	let loading = true;
	let saving = false;
	let errorMessage: string | null = null;
	let logoUploading = false;
	let logoFile: File | null = null;

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
			if (data.site_info) {
				// 백엔드 snake_case를 프론트엔드 camelCase로 변환
				siteInfo = {
					siteName: data.site_info.site_name || '',
					siteDescription: data.site_info.site_description || '',
					siteKeywords: data.site_info.site_keywords || '',
					siteAuthor: data.site_info.site_author || '',
					siteUrl: data.site_info.site_url || '',
					siteLogo: data.site_info.site_logo || '',
					siteFavicon: data.site_info.site_favicon || '',
					contactEmail: data.site_info.contact_email || '',
					contactPhone: data.site_info.contact_phone || '',
					contactFax: data.site_info.contact_fax || '',
					contactAddress: data.site_info.contact_address || '',
					businessNumber: data.site_info.business_number || '',
					socialFacebook: data.site_info.social_facebook || '',
					socialTwitter: data.site_info.social_twitter || '',
					socialInstagram: data.site_info.social_instagram || '',
					socialYoutube: data.site_info.social_youtube || ''
				};
			}
			if (data.sns_links) {
				// SNS 링크도 변환
				snsLinks = data.sns_links.map((link: any) => ({
					id: link.id || Date.now().toString(),
					name: link.name || '',
					url: link.url || '',
					icon: link.icon || 'custom',
					iconType: link.icon_type || 'svg',
					order: link.display_order || 1
				}));
			}
		} catch (error) {
			console.error('설정 로드 실패:', error);
			errorMessage = error instanceof Error ? error.message : '설정을 불러오는데 실패했습니다.';

			// 에러 시 기본값 설정
			siteInfo = {
				siteName: '민들레장애인자립생활센터',
				siteDescription: '함께 만들어가는 따뜻한 세상',
				siteKeywords: '장애인자립생활센터, 민들레, 봉사, 복지',
				siteAuthor: '박길연',
				siteUrl: 'https://mincenter.org',
				siteLogo: '',
				siteFavicon: '',
				contactEmail: 'mincenter08@daum.net',
				contactPhone: '032-542-9294',
				contactFax: '032-232-0739',
				contactAddress: '인천광역시 계양구 계산새로71 A동 201~202호 (계산동, 하이베라스)',
				businessNumber: '131-80-12554',
				socialFacebook: '',
				socialTwitter: '',
				socialInstagram: 'https://www.instagram.com/mincenter08?igsh=bTZyM2Qxa2t4ajJv',
				socialYoutube: ''
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
			
			// 프론트엔드 데이터를 백엔드 형식으로 변환
			const settingsData = {
				siteInfo: {
					site_name: siteInfo.siteName,
					site_description: siteInfo.siteDescription,
					site_keywords: siteInfo.siteKeywords,
					site_author: siteInfo.siteAuthor,
					site_url: siteInfo.siteUrl,
					site_logo: siteInfo.siteLogo,
					site_favicon: siteInfo.siteFavicon,
					contact_email: siteInfo.contactEmail,
					contact_phone: siteInfo.contactPhone,
					contact_fax: siteInfo.contactFax,
					contact_address: siteInfo.contactAddress,
					business_number: siteInfo.businessNumber,
					social_facebook: siteInfo.socialFacebook,
					social_twitter: siteInfo.socialTwitter,
					social_instagram: siteInfo.socialInstagram,
					social_youtube: siteInfo.socialYoutube
				},
				snsLinks: snsLinks.map(link => ({
					name: link.name,
					url: link.url,
					icon: link.icon,
					icon_type: link.iconType,
					display_order: link.order,
					is_active: true
				}))
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

	async function handleLogoUpload(event: Event) {
		const target = event.target as HTMLInputElement;
		if (!target.files || target.files.length === 0) return;

		const file = target.files[0];
		
		// 파일 타입 검증 (이미지만 허용)
		if (!file.type.startsWith('image/')) {
			alert('이미지 파일만 업로드 가능합니다.');
			return;
		}

		// 파일 크기 검증 (5MB 제한)
		if (file.size > 5 * 1024 * 1024) {
			alert('파일 크기는 5MB 이하여야 합니다.');
			return;
		}

		logoFile = file;
		logoUploading = true;

		try {
			const result = await uploadSiteFile(file);
			siteInfo.siteLogo = result.url;
			alert('로고 이미지가 업로드되었습니다.');
		} catch (error) {
			console.error('로고 업로드 실패:', error);
			alert('로고 업로드에 실패했습니다.');
		} finally {
			logoUploading = false;
			// 파일 입력 초기화
			target.value = '';
		}
	}

	function removeLogo() {
		siteInfo.siteLogo = '';
		logoFile = null;
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
							<label for="siteAuthor" class="mb-1 block text-sm font-medium text-gray-700">
								대표자명
							</label>
							<div class="flex items-center gap-2">
								<UserIcon class="h-4 w-4 text-gray-400" />
								<Input
									id="siteAuthor"
									bind:value={siteInfo.siteAuthor}
									placeholder="대표자명을 입력하세요"
								/>
							</div>
						</div>
					</div>

					<div>
						<label for="siteDescription" class="mb-1 block text-sm font-medium text-gray-700">
							사이트 설명
						</label>
						<Input
							id="siteDescription"
							bind:value={siteInfo.siteDescription}
							placeholder="사이트 설명을 입력하세요"
						/>
					</div>

					<div>
						<label for="siteKeywords" class="mb-1 block text-sm font-medium text-gray-700">
							사이트 키워드
						</label>
						<Input
							id="siteKeywords"
							bind:value={siteInfo.siteKeywords}
							placeholder="키워드를 쉼표로 구분하여 입력하세요"
						/>
					</div>

					<div>
						<label for="siteUrl" class="mb-1 block text-sm font-medium text-gray-700">
							홈페이지 주소
						</label>
						<Input
							id="siteUrl"
							bind:value={siteInfo.siteUrl}
							placeholder="https://example.com"
							type="url"
						/>
					</div>

					<div>
						<label for="contactAddress" class="mb-1 block text-sm font-medium text-gray-700"> 주소 </label>
						<div class="flex items-center gap-2">
							<MapPinIcon class="h-4 w-4 text-gray-400" />
							<Input id="contactAddress" bind:value={siteInfo.contactAddress} placeholder="주소를 입력하세요" />
						</div>
					</div>

					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="contactPhone" class="mb-1 block text-sm font-medium text-gray-700">
								연락처
							</label>
							<div class="flex items-center gap-2">
								<PhoneIcon class="h-4 w-4 text-gray-400" />
								<Input id="contactPhone" bind:value={siteInfo.contactPhone} placeholder="연락처를 입력하세요" />
							</div>
						</div>
						<div>
							<label for="contactEmail" class="mb-1 block text-sm font-medium text-gray-700">
								이메일
							</label>
							<div class="flex items-center gap-2">
								<MailIcon class="h-4 w-4 text-gray-400" />
								<Input
									id="contactEmail"
									type="email"
									bind:value={siteInfo.contactEmail}
									placeholder="이메일을 입력하세요"
								/>
							</div>
						</div>
					</div>

					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="contactFax" class="mb-1 block text-sm font-medium text-gray-700">
								팩스
							</label>
							<div class="flex items-center gap-2">
								<FanIcon class="h-4 w-4 text-gray-400" />
								<Input id="contactFax" bind:value={siteInfo.contactFax} placeholder="팩스번호를 입력하세요" />
							</div>
						</div>
						<div>
							<label for="businessNumber" class="mb-1 block text-sm font-medium text-gray-700">
								사업자번호
							</label>
							<div class="flex items-center gap-2">
								<BuildingIcon class="h-4 w-4 text-gray-400" />
								<Input
									id="businessNumber"
									bind:value={siteInfo.businessNumber}
									placeholder="사업자등록번호를 입력하세요 (예: 123-45-67890)"
								/>
							</div>
						</div>
					</div>

					<div>
						<label for="siteLogo" class="mb-1 block text-sm font-medium text-gray-700">
							로고 이미지
						</label>
						<div class="space-y-3">
							{#if siteInfo.siteLogo}
								<div class="flex items-center gap-3">
									<img
										src={siteInfo.siteLogo}
										alt="로고 미리보기"
										class="h-16 w-auto rounded border"
										onerror={(e) => {
											const target = e.target as HTMLImageElement;
											if (target) target.style.display = 'none';
										}}
									/>
									<Button
										type="button"
										variant="outline"
										size="sm"
										onclick={removeLogo}
										class="text-red-600"
									>
										삭제
									</Button>
								</div>
							{/if}
							
							
							
							
						</div>
					</div>
				</CardContent>
			</Card>

			<!-- 소셜 미디어 -->
			<Card>
				<CardHeader>
					<CardTitle class="flex items-center gap-2">
						<Share2Icon class="h-5 w-5" />
						소셜 미디어
					</CardTitle>
					<CardDescription>소셜 미디어 계정 정보를 설정합니다</CardDescription>
				</CardHeader>
				<CardContent class="space-y-4">
					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="socialFacebook" class="mb-1 block text-sm font-medium text-gray-700">
								Facebook
							</label>
							<Input
								id="socialFacebook"
								bind:value={siteInfo.socialFacebook}
								placeholder="https://facebook.com/yourpage"
								type="url"
							/>
						</div>
						<div>
							<label for="socialTwitter" class="mb-1 block text-sm font-medium text-gray-700">
								Twitter
							</label>
							<Input
								id="socialTwitter"
								bind:value={siteInfo.socialTwitter}
								placeholder="https://twitter.com/yourpage"
								type="url"
							/>
						</div>
					</div>

					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="socialInstagram" class="mb-1 block text-sm font-medium text-gray-700">
								Instagram
							</label>
							<Input
								id="socialInstagram"
								bind:value={siteInfo.socialInstagram}
								placeholder="https://instagram.com/yourpage"
								type="url"
							/>
						</div>
						<div>
							<label for="socialYoutube" class="mb-1 block text-sm font-medium text-gray-700">
								YouTube
							</label>
							<Input
								id="socialYoutube"
								bind:value={siteInfo.socialYoutube}
								placeholder="https://youtube.com/channel/yourchannel"
								type="url"
							/>
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
