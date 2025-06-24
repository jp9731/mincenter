<script lang="ts">
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Badge } from '$lib/components/ui/badge';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
	import { Plus, Edit, Eye, Trash2, Search, Filter } from 'lucide-svelte';
	import { deletePage, updatePageStatus } from '$lib/api/admin';
	import { goto, invalidate } from '$app/navigation';

	export let data: {
		pages: any[];
		pagination: {
			page: number;
			limit: number;
			total: number;
			totalPages: number;
		};
		filters: {
			search: string;
			status: string;
		};
		error?: string;
	};

	let searchQuery = data.filters.search;
	let statusFilter = data.filters.status;

	const statusOptions = [
		{ value: '', label: '전체' },
		{ value: 'draft', label: '임시저장' },
		{ value: 'published', label: '발행됨' },
		{ value: 'archived', label: '보관됨' }
	];

	async function handleSearch() {
		const url = new URL(window.location.href);
		url.searchParams.set('page', '1');
		if (searchQuery) {
			url.searchParams.set('search', searchQuery);
		} else {
			url.searchParams.delete('search');
		}
		if (statusFilter) {
			url.searchParams.set('status', statusFilter);
		} else {
			url.searchParams.delete('status');
		}
		goto(url.pathname + url.search);
	}

	function handleStatusFilter() {
		handleSearch();
	}

	function handlePageChange(page: number) {
		const url = new URL(window.location.href);
		url.searchParams.set('page', page.toString());
		goto(url.pathname + url.search);
	}

	async function handleStatusChange(pageId: string, newStatus: string, isPublished: boolean) {
		try {
			await updatePageStatus(pageId, {
				status: newStatus,
				is_published: isPublished
			});
			await invalidate('$app.stores'); // 페이지 데이터 새로고침
		} catch (error) {
			console.error('상태 변경 실패:', error);
		}
	}

	async function handleDelete(pageId: string, title: string) {
		if (!confirm(`"${title}" 페이지를 정말로 삭제하시겠습니까?`)) {
			return;
		}

		try {
			await deletePage(pageId);
			await invalidate('$app.stores'); // 페이지 데이터 새로고침
		} catch (error) {
			console.error('페이지 삭제 실패:', error);
		}
	}

	function getStatusBadge(status: string, isPublished: boolean) {
		if (isPublished && status === 'published') {
			return { variant: 'default' as const, text: '발행됨' };
		} else if (status === 'draft') {
			return { variant: 'secondary' as const, text: '임시저장' };
		} else if (status === 'archived') {
			return { variant: 'destructive' as const, text: '보관됨' };
		} else {
			return { variant: 'outline' as const, text: '미발행' };
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

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-gray-900">안내 페이지 관리</h1>
			<p class="mt-2 text-gray-600">회사소개, 서비스 안내 등의 단일 페이지를 관리합니다.</p>
		</div>
		<Button onclick={() => goto('/pages/create')}>
			<Plus class="mr-2 h-4 w-4" />
			새 페이지
		</Button>
	</div>

	<!-- 검색 및 필터 -->
	<Card>
		<CardContent class="pt-6">
			<div class="flex gap-4">
				<div class="flex-1">
					<div class="relative">
						<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
						<Input
							placeholder="제목, 내용, 슬러그로 검색..."
							bind:value={searchQuery}
							onkeydown={(e) => e.key === 'Enter' && handleSearch()}
							class="pl-10"
						/>
					</div>
				</div>
				<div class="w-48">
					<Select bind:value={statusFilter} onchange={handleStatusFilter}>
						<SelectTrigger>
							<Filter class="mr-2 h-4 w-4" />
							{statusOptions.find((opt) => opt.value === statusFilter)?.label || '상태'}
						</SelectTrigger>
						<SelectContent>
							{#each statusOptions as option}
								<SelectItem value={option.value}>{option.label}</SelectItem>
							{/each}
						</SelectContent>
					</Select>
				</div>
				<Button variant="outline" onclick={handleSearch}>검색</Button>
			</div>
		</CardContent>
	</Card>

	<!-- 페이지 목록 -->
	<Card>
		<CardHeader>
			<CardTitle>페이지 목록</CardTitle>
			<CardDescription>총 {data.pagination.total}개의 페이지가 있습니다.</CardDescription>
		</CardHeader>
		<CardContent>
			{#if data.error}
				<div class="py-12 text-center text-red-500">
					<p>{data.error}</p>
				</div>
			{:else}
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>제목</TableHead>
							<TableHead>슬러그</TableHead>
							<TableHead>상태</TableHead>
							<TableHead>조회수</TableHead>
							<TableHead>생성일</TableHead>
							<TableHead>수정일</TableHead>
							<TableHead class="text-right">액션</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{#each data.pages as page}
							<TableRow>
								<TableCell>
									<div>
										<div class="font-medium">{page.title}</div>
										{#if page.excerpt}
											<div class="max-w-xs truncate text-sm text-gray-500">
												{page.excerpt}
											</div>
										{/if}
									</div>
								</TableCell>
								<TableCell>
									<code class="rounded bg-gray-100 px-2 py-1 text-xs">
										{page.slug}
									</code>
								</TableCell>
								<TableCell>
									{@const statusBadge = getStatusBadge(page.status, page.is_published)}
									<Badge variant={statusBadge.variant}>
										{statusBadge.text}
									</Badge>
								</TableCell>
								<TableCell>{page.view_count}</TableCell>
								<TableCell>{formatDate(page.created_at)}</TableCell>
								<TableCell>{formatDate(page.updated_at)}</TableCell>
								<TableCell class="text-right">
									<div class="flex items-center justify-end gap-2">
										<Button variant="ghost" size="sm" onclick={() => goto(`/pages/${page.id}`)}>
											<Eye class="mr-2 h-4 w-4" />
											보기
										</Button>
										<Button
											variant="ghost"
											size="sm"
											onclick={() => goto(`/pages/${page.id}/edit`)}
										>
											<Edit class="mr-2 h-4 w-4" />
											편집
										</Button>
										<Button
											variant="ghost"
											size="sm"
											onclick={() => handleDelete(page.id, page.title)}
										>
											<Trash2 class="mr-2 h-4 w-4" />
											삭제
										</Button>
									</div>
								</TableCell>
							</TableRow>
						{/each}
					</TableBody>
				</Table>

				<!-- 페이지네이션 -->
				{#if data.pagination.totalPages > 1}
					<div class="mt-6 flex items-center justify-between">
						<div class="text-sm text-gray-500">
							총 {data.pagination.total}개 중 {(data.pagination.page - 1) * data.pagination.limit +
								1}-{Math.min(data.pagination.page * data.pagination.limit, data.pagination.total)}개
						</div>
						<div class="flex gap-2">
							<Button
								variant="outline"
								size="sm"
								disabled={data.pagination.page === 1}
								onclick={() => handlePageChange(data.pagination.page - 1)}
							>
								이전
							</Button>
							{#each Array.from({ length: data.pagination.totalPages }, (_, i) => i + 1) as pageNum}
								<Button
									variant={data.pagination.page === pageNum ? 'default' : 'outline'}
									size="sm"
									onclick={() => handlePageChange(pageNum)}
								>
									{pageNum}
								</Button>
							{/each}
							<Button
								variant="outline"
								size="sm"
								disabled={data.pagination.page === data.pagination.totalPages}
								onclick={() => handlePageChange(data.pagination.page + 1)}
							>
								다음
							</Button>
						</div>
					</div>
				{/if}
			{/if}
		</CardContent>
	</Card>
</div>
