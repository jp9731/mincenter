<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { ChartBarIcon, UsersIcon, EyeIcon, FileTextIcon } from 'lucide-svelte';

	const analyticsStats = {
		total_visitors: 15420,
		total_logins: 3245,
		total_posts: 892,
		total_comments: 2156
	};
</script>

<div class="space-y-6">
	<div>
		<h1 class="text-2xl font-bold text-gray-900">접속 통계</h1>
		<p class="text-gray-600">사이트 접속, 로그인, 게시글 등 통계를 확인하세요</p>
	</div>

	<div class="grid grid-cols-1 gap-6 md:grid-cols-4">
		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-blue-100 p-2">
						<EyeIcon class="h-6 w-6 text-blue-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 방문자</p>
						<p class="text-2xl font-bold text-gray-900">
							{analyticsStats.total_visitors.toLocaleString()}
						</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-green-100 p-2">
						<UsersIcon class="h-6 w-6 text-green-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 로그인</p>
						<p class="text-2xl font-bold text-gray-900">
							{analyticsStats.total_logins.toLocaleString()}
						</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-purple-100 p-2">
						<FileTextIcon class="h-6 w-6 text-purple-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 게시글</p>
						<p class="text-2xl font-bold text-gray-900">
							{analyticsStats.total_posts.toLocaleString()}
						</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-orange-100 p-2">
						<ChartBarIcon class="h-6 w-6 text-orange-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 댓글</p>
						<p class="text-2xl font-bold text-gray-900">
							{analyticsStats.total_comments.toLocaleString()}
						</p>
					</div>
				</div>
			</CardContent>
		</Card>
	</div>

	<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
		<!-- 사이트 통계 -->
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<EyeIcon class="mr-2 h-5 w-5" />
					사이트 통계
				</CardTitle>
				<CardDescription>방문자 수, 페이지뷰 등</CardDescription>
			</CardHeader>
			<CardContent>
				<div class="rounded-lg bg-gray-100 p-8 text-center">
					<ChartBarIcon class="mx-auto mb-4 h-16 w-16 text-gray-400" />
					<p class="text-gray-600">사이트 통계 차트</p>
					<p class="mt-2 text-sm text-gray-500">년월일시 선택 및 기간 선택</p>
				</div>
			</CardContent>
		</Card>

		<!-- 로그인 통계 -->
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<UsersIcon class="mr-2 h-5 w-5" />
					로그인 통계
				</CardTitle>
				<CardDescription>사용자 로그인 패턴 분석</CardDescription>
			</CardHeader>
			<CardContent>
				<div class="rounded-lg bg-gray-100 p-8 text-center">
					<ChartBarIcon class="mx-auto mb-4 h-16 w-16 text-gray-400" />
					<p class="text-gray-600">로그인 통계 차트</p>
					<p class="mt-2 text-sm text-gray-500">로그인 시간대, 요일별 분석</p>
				</div>
			</CardContent>
		</Card>
	</div>

	<div class="grid grid-cols-1 gap-6 md:grid-cols-3">
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<EyeIcon class="mr-2 h-5 w-5" />
					사이트 통계
				</CardTitle>
				<CardDescription>방문자 수, 페이지뷰 등</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/analytics/site" class="w-full">상세보기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<UsersIcon class="mr-2 h-5 w-5" />
					로그인 통계
				</CardTitle>
				<CardDescription>사용자 로그인 패턴 분석</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/analytics/login" class="w-full">상세보기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<FileTextIcon class="mr-2 h-5 w-5" />
					게시글 통계
				</CardTitle>
				<CardDescription>게시글 작성 및 조회 통계</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/analytics/posts" class="w-full">상세보기</Button>
			</CardContent>
		</Card>
	</div>
</div>
