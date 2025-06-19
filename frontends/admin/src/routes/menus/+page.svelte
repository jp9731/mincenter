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
	import { PlusIcon, EditIcon, TrashIcon } from 'lucide-svelte';

	// 임시 메뉴 데이터
	const menus = [
		{
			id: 1,
			name: '회사안내',
			type: 'page',
			url: '/about',
			order: 1,
			is_active: true
		},
		{
			id: 2,
			name: '봉사활동',
			type: 'board',
			url: '/volunteer',
			order: 2,
			is_active: true
		},
		{
			id: 3,
			name: '후원하기',
			type: 'page',
			url: '/donate',
			order: 3,
			is_active: true
		},
		{
			id: 4,
			name: '공지사항',
			type: 'board',
			url: '/notice',
			order: 4,
			is_active: false
		}
	];

	function getTypeLabel(type: string) {
		switch (type) {
			case 'page':
				return '안내페이지';
			case 'board':
				return '게시판';
			case 'link':
				return '외부링크';
			default:
				return type;
		}
	}
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-2xl font-bold text-gray-900">메뉴 관리</h1>
			<p class="text-gray-600">사이트 상단 메뉴를 설정하세요</p>
		</div>
		<Button>
			<PlusIcon class="mr-2 h-4 w-4" />
			메뉴 추가
		</Button>
	</div>

	<!-- 메뉴 테이블 -->
	<Card>
		<CardHeader>
			<CardTitle>메뉴 목록</CardTitle>
			<CardDescription>사이트 상단에 표시되는 메뉴들을 관리합니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<Table>
				<TableHeader>
					<TableRow>
						<TableHead>순서</TableHead>
						<TableHead>메뉴명</TableHead>
						<TableHead>타입</TableHead>
						<TableHead>URL</TableHead>
						<TableHead>상태</TableHead>
						<TableHead class="text-right">액션</TableHead>
					</TableRow>
				</TableHeader>
				<TableBody>
					{#each menus as menu}
						<TableRow>
							<TableCell>{menu.order}</TableCell>
							<TableCell class="font-medium">{menu.name}</TableCell>
							<TableCell>
								<Badge variant="outline">{getTypeLabel(menu.type)}</Badge>
							</TableCell>
							<TableCell>{menu.url}</TableCell>
							<TableCell>
								<Badge variant={menu.is_active ? 'default' : 'secondary'}>
									{menu.is_active ? '활성' : '비활성'}
								</Badge>
							</TableCell>
							<TableCell class="text-right">
								<div class="flex items-center justify-end space-x-2">
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
