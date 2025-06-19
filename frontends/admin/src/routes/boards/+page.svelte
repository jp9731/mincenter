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
	import { PlusIcon, EditIcon, SettingsIcon, TrashIcon } from 'lucide-svelte';

	// 임시 게시판 데이터
	const boards = [
		{
			id: 1,
			name: '공지사항',
			description: '중요한 공지사항을 게시합니다',
			category: '공지',
			post_count: 15,
			created_at: '2024-01-01',
			is_active: true,
			sort_order: 1
		},
		{
			id: 2,
			name: '봉사활동',
			description: '봉사활동 관련 게시글',
			category: '봉사',
			post_count: 42,
			created_at: '2024-01-05',
			is_active: true,
			sort_order: 2
		},
		{
			id: 3,
			name: '후원소식',
			description: '후원 관련 소식과 감사인사',
			category: '후원',
			post_count: 28,
			created_at: '2024-01-10',
			is_active: true,
			sort_order: 3
		},
		{
			id: 4,
			name: '자유게시판',
			description: '자유로운 의견을 나누는 공간',
			category: '일반',
			post_count: 156,
			created_at: '2024-01-15',
			is_active: false,
			sort_order: 4
		}
	];
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">게시판 관리</h1>
			<p class="text-gray-600">게시판을 생성하고 카테고리를 관리하세요</p>
		</div>
		<Button>
			<PlusIcon class="mr-2 h-4 w-4" />
			게시판 추가
		</Button>
	</div>

	<!-- 게시판 테이블 -->
	<Card>
		<CardHeader>
			<CardTitle>게시판 목록</CardTitle>
			<CardDescription>사이트에 등록된 게시판들을 관리합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>순서</TableHead>
						<TableHead>게시판명</TableHead>
						<TableHead>카테고리</TableHead>
						<TableHead>게시글 수</TableHead>
						<TableHead>상태</TableHead>
						<TableHead>생성일</TableHead>
						<TableHead class="text-right">액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#each boards as board}
						<TableRow>
							<TableCell>{board.sort_order}</TableCell>
							<TableCell>
								<div>
									<div class="font-medium">{board.name}</div>
									<div class="text-sm text-gray-500">{board.description}</div>
								</div>
							</TableCell>
							<TableCell>
								<Badge variant="outline">{board.category}</Badge>
							</TableCell>
							<TableCell>{board.post_count}</TableCell>
							<TableCell>
								<Badge variant={board.is_active ? 'default' : 'secondary'}>
									{board.is_active ? '활성' : '비활성'}
								</Badge>
							</TableCell>
							<TableCell>{board.created_at}</TableCell>
							<TableCell class="text-right">
								<div class="flex items-center justify-end space-x-2">
									<Button variant="ghost" size="sm">
										<SettingsIcon class="h-4 w-4" />
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
