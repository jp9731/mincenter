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
	import { ServerIcon, AlertTriangleIcon, InfoIcon } from 'lucide-svelte';

	// 임시 시스템 로그 데이터
	const systemLogs = [
		{
			id: 1,
			level: 'info',
			message: '사용자 로그인 성공',
			user_name: '김철수',
			ip_address: '192.168.1.100',
			created_at: '2024-01-20 14:30:25'
		},
		{
			id: 2,
			level: 'warning',
			message: '로그인 시도 실패',
			user_name: '알 수 없음',
			ip_address: '192.168.1.101',
			created_at: '2024-01-20 14:25:10'
		},
		{
			id: 3,
			level: 'error',
			message: '데이터베이스 연결 오류',
			user_name: '시스템',
			ip_address: '127.0.0.1',
			created_at: '2024-01-20 14:20:15'
		},
		{
			id: 4,
			level: 'info',
			message: '새 게시글 작성',
			user_name: '이영희',
			ip_address: '192.168.1.102',
			created_at: '2024-01-20 14:15:30'
		}
	];

	function getLevelLabel(level: string) {
		switch (level) {
			case 'info':
				return '정보';
			case 'warning':
				return '경고';
			case 'error':
				return '오류';
			case 'critical':
				return '심각';
			default:
				return level;
		}
	}

	function getLevelVariant(level: string) {
		switch (level) {
			case 'info':
				return 'default';
			case 'warning':
				return 'secondary';
			case 'error':
				return 'destructive';
			case 'critical':
				return 'destructive';
			default:
				return 'secondary';
		}
	}
</script>

<div class="space-y-6">
	<div>
		<h1 class="text-2xl font-bold text-gray-900">시스템 로그</h1>
		<p class="text-gray-600">모든 시스템 이벤트를 확인하세요</p>
	</div>

	<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
		<!-- 시스템 이벤트 -->
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<ServerIcon class="mr-2 h-5 w-5" />
					시스템 이벤트
				</CardTitle>
				<CardDescription>최근 시스템 이벤트 로그</CardDescription>
			</CardHeader>
			<CardContent>
				<Table>
					<TableHeader>
						<TableRow>
							<TableHead>레벨</TableHead>
							<TableHead>메시지</TableHead>
							<TableHead>사용자</TableHead>
							<TableHead>시간</TableHead>
						</TableRow>
					</TableHeader>
					<TableBody>
						{#each systemLogs as log}
							<TableRow>
								<TableCell>
									<Badge variant={getLevelVariant(log.level)}>
										{getLevelLabel(log.level)}
									</Badge>
								</TableCell>
								<TableCell class="max-w-xs truncate">{log.message}</TableCell>
								<TableCell>{log.user_name}</TableCell>
								<TableCell class="text-sm text-gray-500">{log.created_at}</TableCell>
							</TableRow>
						{/each}
					</TableBody>
				</Table>
			</CardContent>
		</Card>

		<!-- 에러 로그 -->
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<AlertTriangleIcon class="mr-2 h-5 w-5" />
					에러 로그
				</CardTitle>
				<CardDescription>시스템 오류 및 경고 로그</CardDescription>
			</CardHeader>
			<CardContent>
				<div class="space-y-4">
					{#each systemLogs.filter((log) => log.level === 'error' || log.level === 'warning') as log}
						<div class="border-l-4 border-red-500 py-2 pl-4">
							<div class="flex items-center justify-between">
								<Badge variant={getLevelVariant(log.level)}>
									{getLevelLabel(log.level)}
								</Badge>
								<span class="text-sm text-gray-500">{log.created_at}</span>
							</div>
							<p class="mt-1 text-sm font-medium">{log.message}</p>
							<p class="text-xs text-gray-500">IP: {log.ip_address} | 사용자: {log.user_name}</p>
						</div>
					{/each}
				</div>
			</CardContent>
		</Card>
	</div>

	<div class="grid grid-cols-1 gap-6 md:grid-cols-2">
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<ServerIcon class="mr-2 h-5 w-5" />
					시스템 이벤트
				</CardTitle>
				<CardDescription>모든 시스템 이벤트 로그</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/system/events" class="w-full">상세보기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<AlertTriangleIcon class="mr-2 h-5 w-5" />
					에러 로그
				</CardTitle>
				<CardDescription>시스템 오류 및 경고 로그</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/system/errors" class="w-full">상세보기</Button>
			</CardContent>
		</Card>
	</div>
</div>
