<script lang="ts">
	import { onMount } from 'svelte';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Switch } from '$lib/components/ui/switch';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Tabs, TabsContent, TabsList, TabsTrigger } from '$lib/components/ui/tabs';
	import {
		Save,
		Eye,
		Globe,
		Settings,
		ArrowLeft,
		ExternalLink,
		Calendar,
		User
	} from 'lucide-svelte';
	import { createPage } from '$lib/api/admin';
	import { goto } from '$app/navigation';

	let loading = false;
	let saving = false;
	let showPreview = false;

	// 페이지 데이터
	let pageData = {
		title: '',
		slug: '',
		content: '',
		excerpt: '',
		meta_title: '',
		meta_description: '',
		status: 'draft',
		is_published: false,
		sort_order: 0
	};

	// 슬러그 자동 생성
	function generateSlug(title: string) {
		return title
			.toLowerCase()
			.replace(/[^a-z0-9가-힣\s-]/g, '')
			.replace(/\s+/g, '-')
			.replace(/-+/g, '-')
			.replace(/^-|-$/g, '');
	}

	// 제목 변경 시 슬러그 자동 생성
	// $: if (pageData.title && !pageData.slug) {
	// 	pageData.slug = generateSlug(pageData.title);
	// }

	async function handleSave(isPublished = false) {
		if (!pageData.title.trim()) {
			alert('제목을 입력해주세요.');
			return;
		}

		if (!pageData.slug.trim()) {
			alert('슬러그를 입력해주세요.');
			return;
		}

		if (!pageData.content.trim()) {
			alert('내용을 입력해주세요.');
			return;
		}

		saving = true;
		try {
			const data = {
				...pageData,
				is_published: isPublished,
				status: isPublished ? 'published' : pageData.status
			};

			await createPage(data);
			alert(isPublished ? '페이지가 발행되었습니다.' : '페이지가 저장되었습니다.');
			goto('/pages');
		} catch (error) {
			console.error('페이지 저장 실패:', error);
			alert('페이지 저장에 실패했습니다.');
		} finally {
			saving = false;
		}
	}

	function handlePreview() {
		showPreview = !showPreview;
	}

	function formatDate(date: Date) {
		return date.toLocaleDateString('ko-KR', {
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit'
		});
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div class="flex items-center gap-4">
			<Button variant="outline" onclick={() => goto('/pages')}>
				<ArrowLeft class="mr-2 h-4 w-4" />
				목록으로
			</Button>
			<div>
				<h1 class="text-3xl font-bold text-gray-900">새 페이지 생성</h1>
				<p class="mt-2 text-gray-600">새로운 안내 페이지를 생성합니다.</p>
			</div>
		</div>
		<div class="flex gap-2">
			<Button variant="outline" onclick={handlePreview}>
				<Eye class="mr-2 h-4 w-4" />
				{showPreview ? '편집' : '미리보기'}
			</Button>
			<Button variant="outline" onclick={() => handleSave(false)} disabled={saving}>
				<Save class="mr-2 h-4 w-4" />
				임시저장
			</Button>
			<Button onclick={() => handleSave(true)} disabled={saving}>
				<Globe class="mr-2 h-4 w-4" />
				{saving ? '저장 중...' : '발행'}
			</Button>
		</div>
	</div>

	{#if showPreview}
		<!-- 미리보기 모드 -->
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center gap-2">
					<Eye class="h-5 w-5" />
					미리보기
				</CardTitle>
			</CardHeader>
			<CardContent>
				<div class="prose max-w-none">
					<h1>{pageData.title || '제목을 입력하세요'}</h1>
					{#if pageData.excerpt}
						<p class="text-lg text-gray-600">{pageData.excerpt}</p>
					{/if}
					<div class="mt-6">
						{pageData.content || '내용을 입력하세요'}
					</div>
				</div>
			</CardContent>
		</Card>
	{:else}
		<!-- 편집 모드 -->
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
			<!-- 메인 편집 영역 -->
			<div class="space-y-6 lg:col-span-2">
				<!-- 기본 정보 -->
				<Card>
					<CardHeader>
						<CardTitle>기본 정보</CardTitle>
						<CardDescription>페이지의 기본적인 정보를 입력하세요</CardDescription>
					</CardHeader>
					<CardContent class="space-y-4">
						<div>
							<label for="title" class="mb-1 block text-sm font-medium text-gray-700">
								제목 <span class="text-red-500">*</span>
							</label>
							<Input
								id="title"
								bind:value={pageData.title}
								placeholder="페이지 제목을 입력하세요"
								required
							/>
						</div>

						<div>
							<label for="slug" class="mb-1 block text-sm font-medium text-gray-700">
								슬러그 <span class="text-red-500">*</span>
							</label>
							<Input
								id="slug"
								bind:value={pageData.slug}
								placeholder="URL 슬러그를 입력하세요"
								required
							/>
							<p class="mt-1 text-sm text-gray-500">
								예: /pages/{pageData.slug || 'your-slug'}
							</p>
						</div>

						<div>
							<label for="excerpt" class="mb-1 block text-sm font-medium text-gray-700">
								요약
							</label>
							<Textarea
								id="excerpt"
								bind:value={pageData.excerpt}
								placeholder="페이지 요약을 입력하세요"
								rows="3"
							/>
						</div>

						<div>
							<label for="content" class="mb-1 block text-sm font-medium text-gray-700">
								내용 <span class="text-red-500">*</span>
							</label>
							<Textarea
								id="content"
								bind:value={pageData.content}
								placeholder="페이지 내용을 입력하세요"
								rows="15"
								required
							/>
						</div>
					</CardContent>
				</Card>
			</div>

			<!-- 사이드바 -->
			<div class="space-y-6">
				<!-- 발행 설정 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<Settings class="h-5 w-5" />
							발행 설정
						</CardTitle>
					</CardHeader>
					<CardContent class="space-y-4">
						<div class="flex items-center justify-between">
							<label class="text-sm font-medium text-gray-700">발행 상태</label>
							<Switch bind:checked={pageData.is_published} />
						</div>

						<div>
							<label for="status" class="mb-1 block text-sm font-medium text-gray-700">
								상태
							</label>
							<Select bind:value={pageData.status}>
								<SelectTrigger>
									{pageData.status === 'draft'
										? '임시저장'
										: pageData.status === 'published'
											? '발행됨'
											: '보관됨'}
								</SelectTrigger>
								<SelectContent>
									<SelectItem value="draft">임시저장</SelectItem>
									<SelectItem value="published">발행됨</SelectItem>
									<SelectItem value="archived">보관됨</SelectItem>
								</SelectContent>
							</Select>
						</div>

						<div>
							<label for="sort_order" class="mb-1 block text-sm font-medium text-gray-700">
								정렬 순서
							</label>
							<Input id="sort_order" type="number" bind:value={pageData.sort_order} min="0" />
						</div>
					</CardContent>
				</Card>

				<!-- SEO 설정 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<Globe class="h-5 w-5" />
							SEO 설정
						</CardTitle>
					</CardHeader>
					<CardContent class="space-y-4">
						<div>
							<label for="meta_title" class="mb-1 block text-sm font-medium text-gray-700">
								메타 제목
							</label>
							<Input
								id="meta_title"
								bind:value={pageData.meta_title}
								placeholder="SEO용 제목을 입력하세요"
							/>
						</div>

						<div>
							<label for="meta_description" class="mb-1 block text-sm font-medium text-gray-700">
								메타 설명
							</label>
							<Textarea
								id="meta_description"
								bind:value={pageData.meta_description}
								placeholder="SEO용 설명을 입력하세요"
								rows="3"
							/>
						</div>
					</CardContent>
				</Card>

				<!-- 페이지 정보 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<Calendar class="h-5 w-5" />
							페이지 정보
						</CardTitle>
					</CardHeader>
					<CardContent class="space-y-3">
						<div class="flex items-center justify-between">
							<span class="text-sm text-gray-600">생성일</span>
							<span class="text-sm font-medium">{formatDate(new Date())}</span>
						</div>
						<div class="flex items-center justify-between">
							<span class="text-sm text-gray-600">수정일</span>
							<span class="text-sm font-medium">{formatDate(new Date())}</span>
						</div>
						<div class="flex items-center justify-between">
							<span class="text-sm text-gray-600">상태</span>
							<Badge variant={pageData.is_published ? 'default' : 'secondary'}>
								{pageData.is_published ? '발행됨' : '임시저장'}
							</Badge>
						</div>
					</CardContent>
				</Card>
			</div>
		</div>
	{/if}
</div>
