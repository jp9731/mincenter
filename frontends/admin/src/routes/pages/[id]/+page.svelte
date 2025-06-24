<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { ArrowLeft, Edit, Trash2, Calendar, User, Eye, Globe, ExternalLink } from 'lucide-svelte';
	import { getPage, deletePage } from '$lib/api/admin';
	import { goto } from '$app/navigation';

	let loading = true;
	let pageData: any = null;

	onMount(async () => {
		const pageId = $page.params.id;
		await loadPage(pageId);
	});

	async function loadPage(pageId: string) {
		try {
			pageData = await getPage(pageId);
		} catch (error) {
			console.error('페이지 로드 실패:', error);
			alert('페이지를 불러오는데 실패했습니다.');
			goto('/pages');
		} finally {
			loading = false;
		}
	}

	async function handleDelete() {
		if (!confirm(`"${pageData.title}" 페이지를 정말로 삭제하시겠습니까?`)) {
			return;
		}

		try {
			await deletePage(pageData.id);
			alert('페이지가 삭제되었습니다.');
			goto('/pages');
		} catch (error) {
			console.error('페이지 삭제 실패:', error);
			alert('페이지 삭제에 실패했습니다.');
		}
	}

	function getStatusBadge(status: string, isPublished: boolean) {
		if (isPublished && status === 'published') {
			return { variant: 'default', text: '발행됨' };
		} else if (status === 'draft') {
			return { variant: 'secondary', text: '임시저장' };
		} else if (status === 'archived') {
			return { variant: 'destructive', text: '보관됨' };
		} else {
			return { variant: 'outline', text: '미발행' };
		}
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
					<h1 class="text-3xl font-bold text-gray-900">{pageData.title}</h1>
					<p class="mt-2 text-gray-600">페이지 상세 정보</p>
				</div>
			</div>
			<div class="flex gap-2">
				<Button variant="outline" onclick={() => goto(`/pages/${pageData.id}/edit`)}>
					<Edit class="mr-2 h-4 w-4" />
					편집
				</Button>
				<Button variant="outline" class="text-red-600" onclick={handleDelete}>
					<Trash2 class="mr-2 h-4 w-4" />
					삭제
				</Button>
			</div>
		</div>

		<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
			<!-- 메인 콘텐츠 -->
			<div class="space-y-6 lg:col-span-2">
				<!-- 페이지 내용 -->
				<Card>
					<CardHeader>
						<CardTitle>페이지 내용</CardTitle>
					</CardHeader>
					<CardContent>
						{#if pageData.excerpt}
							<div class="mb-6 rounded-lg bg-gray-50 p-4">
								<p class="text-lg text-gray-700">{pageData.excerpt}</p>
							</div>
						{/if}
						<div class="prose max-w-none">
							{pageData.content}
						</div>
					</CardContent>
				</Card>

				<!-- SEO 정보 -->
				{#if pageData.meta_title || pageData.meta_description}
					<Card>
						<CardHeader>
							<CardTitle class="flex items-center gap-2">
								<Globe class="h-5 w-5" />
								SEO 정보
							</CardTitle>
						</CardHeader>
						<CardContent class="space-y-4">
							{#if pageData.meta_title}
								<div>
									<label class="mb-1 block text-sm font-medium text-gray-700">메타 제목</label>
									<p class="text-sm text-gray-900">{pageData.meta_title}</p>
								</div>
							{/if}
							{#if pageData.meta_description}
								<div>
									<label class="mb-1 block text-sm font-medium text-gray-700">메타 설명</label>
									<p class="text-sm text-gray-900">{pageData.meta_description}</p>
								</div>
							{/if}
						</CardContent>
					</Card>
				{/if}
			</div>

			<!-- 사이드바 -->
			<div class="space-y-6">
				<!-- 페이지 정보 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<Eye class="h-5 w-5" />
							페이지 정보
						</CardTitle>
					</CardHeader>
					<CardContent class="space-y-4">
						<div>
							<label class="mb-1 block text-sm font-medium text-gray-700">슬러그</label>
							<code class="rounded bg-gray-100 px-2 py-1 text-sm">
								{pageData.slug}
							</code>
						</div>

						<div>
							<label class="mb-1 block text-sm font-medium text-gray-700">상태</label>
							{@const statusBadge = getStatusBadge(pageData.status, pageData.is_published)}
							<Badge variant={statusBadge.variant}>
								{statusBadge.text}
							</Badge>
						</div>

						<div>
							<label class="mb-1 block text-sm font-medium text-gray-700">조회수</label>
							<p class="text-sm text-gray-900">{pageData.view_count}</p>
						</div>

						<div>
							<label class="mb-1 block text-sm font-medium text-gray-700">정렬 순서</label>
							<p class="text-sm text-gray-900">{pageData.sort_order}</p>
						</div>
					</CardContent>
				</Card>

				<!-- 시간 정보 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<Calendar class="h-5 w-5" />
							시간 정보
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
						{#if pageData.published_at}
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">발행일</span>
								<span class="text-sm font-medium">{formatDate(pageData.published_at)}</span>
							</div>
						{/if}
					</CardContent>
				</Card>

				<!-- 작성자 정보 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<User class="h-5 w-5" />
							작성자 정보
						</CardTitle>
					</CardHeader>
					<CardContent class="space-y-3">
						{#if pageData.created_by_name}
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">작성자</span>
								<span class="text-sm font-medium">{pageData.created_by_name}</span>
							</div>
						{/if}
						{#if pageData.updated_by_name}
							<div class="flex items-center justify-between">
								<span class="text-sm text-gray-600">최종 수정자</span>
								<span class="text-sm font-medium">{pageData.updated_by_name}</span>
							</div>
						{/if}
					</CardContent>
				</Card>

				<!-- 외부 링크 -->
				<Card>
					<CardHeader>
						<CardTitle class="flex items-center gap-2">
							<ExternalLink class="h-5 w-5" />
							외부 링크
						</CardTitle>
					</CardHeader>
					<CardContent>
						<Button
							variant="outline"
							class="w-full"
							on:click={() => window.open(`/pages/${pageData.slug}`, '_blank')}
						>
							<ExternalLink class="mr-2 h-4 w-4" />
							사이트에서 보기
						</Button>
					</CardContent>
				</Card>
			</div>
		</div>
	</div>
{/if}
