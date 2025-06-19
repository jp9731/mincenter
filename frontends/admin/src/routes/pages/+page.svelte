<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { Badge } from '$lib/components/ui/badge';
	import { PlusIcon, EditIcon, EyeIcon, TrashIcon } from 'lucide-svelte';

	// 임시 페이지 데이터
	const pages = [
		{
			id: 1,
			title: '회사안내',
			slug: 'about',
			status: 'published',
			created_at: '2024-01-15',
			updated_at: '2024-01-20'
		},
		{
			id: 2,
			title: '후원안내',
			slug: 'donate',
			status: 'published',
			created_at: '2024-01-10',
			updated_at: '2024-01-10'
		},
		{
			id: 3,
			title: '오시는 길',
			slug: 'location',
			status: 'draft',
			created_at: '2024-01-05',
			updated_at: '2024-01-05'
		},
		{
			id: 4,
			title: '개인정보처리방침',
			slug: 'privacy',
			status: 'published',
			created_at: '2024-01-01',
			updated_at: '2024-01-01'
		}
	];

	function getStatusLabel(status: string) {
		switch (status) {
			case 'published':
				return '발행됨';
			case 'draft':
				return '임시저장';
			case 'hidden':
				return '숨김';
			default:
				return status;
		}
	}

	function getStatusVariant(status: string) {
		switch (status) {
			case 'published':
				return 'default';
			case 'draft':
				return 'secondary';
			case 'hidden':
				return 'outline';
			default:
				return 'secondary';
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">안내 페이지 관리</h1>
			<p class="text-gray-600">단일 페이지를 등록하고 편집하세요</p>
		</div>
		<Button>
			<PlusIcon class="mr-2 h-4 w-4" />
			페이지 추가
		</Button>
	</div>

	<!-- 페이지 테이블 -->
	<Card>
		<CardHeader>
			<CardTitle>페이지 목록</CardTitle>
			<CardDescription>사이트에 등록된 안내 페이지들을 관리합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>제목</TableHead>
						<TableHead>슬러그</TableHead>
						<TableHead>상태</TableHead>
						<TableHead>생성일</TableHead>
						<TableHead>수정일</TableHead>
						<TableHead class="text-right">액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#each pages as page}
						<TableRow>
							<TableCell class="font-medium">{page.title}</TableCell>
							<TableCell>{page.slug}</TableCell>
							<TableCell>
								<Badge variant={getStatusVariant(page.status)}>
									{getStatusLabel(page.status)}
								</Badge>
							</TableCell>
							<TableCell>{page.created_at}</TableCell>
							<TableCell>{page.updated_at}</TableCell>
							<TableCell class="text-right">
								<div class="flex items-center justify-end space-x-2">
									<Button variant="ghost" size="sm">
										<EyeIcon class="h-4 w-4" />
									</Button>
									<Button variant="ghost" size="sm">
										<EditIcon class="h-4 w-4" />
									</Button>
									<Button variant="ghost" size="sm" class="text-red-600">
										<TrashIcon class="h-4 w-4" />
									</Button>
								</div>
							</TableCell>
						</TableRow>
					{/each}
				</TableBody>
			</Table>
		</CardContent>
	</Card>
</div>
