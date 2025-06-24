<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
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
	import { getPage, updatePage } from '$lib/api/admin';
	import { goto } from '$app/navigation';

	let loading = true;
	let saving = false;
	let showPreview = false;
	let pageData: any = null;

	// 페이지 데이터 초기화
	let formData = {
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

	onMount(async () => {
		const pageId = $page.params.id;
		await loadPage(pageId);
	});

	async function loadPage(pageId: string) {
		try {
			pageData = await getPage(pageId);
			formData = {
				title: pageData.title || '',
				slug: pageData.slug || '',
				content: pageData.content || '',
				excerpt: pageData.excerpt || '',
				meta_title: pageData.meta_title || '',
				meta_description: pageData.meta_description || '',
				status: pageData.status || 'draft',
				is_published: pageData.is_published || false,
				sort_order: pageData.sort_order || 0
			};
		} catch (error) {
			console.error('페이지 로드 실패:', error);
			alert('페이지를 불러오는데 실패했습니다.');
			goto('/pages');
		} finally {
			loading = false;
		}
	}

	async function handleSave(isPublished = false) {
		if (!formData.title.trim()) {
			alert('제목을 입력해주세요.');
			return;
		}

		if (!formData.slug.trim()) {
			alert('슬러그를 입력해주세요.');
			return;
		}

		if (!formData.content.trim()) {
			alert('내용을 입력해주세요.');
			return;
		}

		saving = true;
		try {
			const data = {
				...formData,
				is_published: isPublished,
				status: isPublished ? 'published' : formData.status
			};

			await updatePage(pageData.id, data);
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

	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleDateString('ko-KR', {
			year: 'numeric',
			month: '2-digit',
			day: '2-digit',
			hour: '2-digit',
			minute: '2-digit'
		});
	}
</script>

{#if loading}
	<div class="flex items-center justify-center py-12">
		<div class="border-primary h-8 w-8 animate-spin rounded-full border-b-2"></div>
	</div>
{:else}
	<div class="space-y-6">
		<!-- 페이지 헤더 -->
		<div class="flex items-center justify-between">
			<div class="flex items-center gap-4">
				<Button variant="outline" onclick={() => goto('/pages')}>
					<ArrowLeft class="mr-2 h-4 w-4" />
					목록으로
				</Button>
				<div>
					<h1 class="text-3xl font-bold text-gray-900">페이지 편집</h1>
					<p class="mt-2 text-gray-600">{pageData.title} 페이지를 편집합니다.</p>
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
						<h1>{formData.title || '제목을 입력하세요'}</h1>
						{#if formData.excerpt}
							<p class="text-lg text-gray-600">{formData.excerpt}</p>
						{/if}
						<div class="mt-6">
							{formData.content || '내용을 입력하세요'}
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
							<CardDescription>페이지의 기본적인 정보를 수정하세요</CardDescription>
						</CardHeader>
						<CardContent class="space-y-4">
							<div>
								<label for="title" class="mb-1 block text-sm font-medium text-gray-700">
									제목 <span class="text-red-500">*</span>
								</label>
								<Input
									id="title"
									bind:value={formData.title}
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
									bind:value={formData.slug}
									placeholder="URL 슬러그를 입력하세요"
									required
								/>
								<p class="mt-1 text-sm text-gray-500">
									예: /pages/{formData.slug || 'your-slug'}
								</p>
							</div>

							<div>
								<label for="excerpt" class="mb-1 block text-sm font-medium text-gray-700">
									요약
								</label>
								<Textarea
									id="excerpt"
									bind:value={formData.excerpt}
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
									bind:value={formData.content}
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
								<Switch bind:checked={formData.is_published} />
							</div>

							<div>
								<label for="status" class="mb-1 block text-sm font-medium text-gray-700">
									상태
								</label>
								<Select bind:value={formData.status}>
									<SelectTrigger>
										{formData.status === 'draft'
											? '임시저장'
											: formData.status === 'published'
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
								<Input id="sort_order" type="number" bind:value={formData.sort_order} min="0" />
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
									bind:value={formData.meta_title}
									placeholder="SEO용 제목을 입력하세요"
								/>
							</div>

							<div>
								<label for="meta_description" class="mb-1 block text-sm font-medium text-gray-700">
									메타 설명
								</label>
								<Textarea
									id="meta_description"
									bind:value={formData.meta_description}
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
								<span class="text-sm font-medium">{formatDate(pageData.created_at)}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">수정일</span>
								<span class="text-sm font-medium">{formatDate(pageData.updated_at)}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">조회수</span>
								<span class="text-sm font-medium">{pageData.view_count}</span>
							</div>
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">상태</span>
								<Badge variant={formData.is_published ? 'default' : 'secondary'}>
									{formData.is_published ? '발행됨' : '임시저장'}
								</Badge>
							</div>
							{#if pageData.created_by_name}
								<div class="flex items-center justify-between">
									<span class="text-sm text-gray-600">작성자</span>
									<span class="text-sm font-medium">{pageData.created_by_name}</span>
								</div>
							{/if}
						</CardContent>
					</Card>
				</div>
			</div>
		{/if}
	</div>
{/if}
