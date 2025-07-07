<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { Textarea } from '$lib/components/ui/textarea';
	import { Label } from '$lib/components/ui/label';
	import { ImageIcon, TypeIcon, LayoutIcon } from 'lucide-svelte';

	let heroTitle = '저희 사이트에 오신 것을 환영합니다';
	let heroSubtitle = '함께 만들어가는 따뜻한 세상';
	let heroBackground = '/images/hero-bg.jpg';
	let recentPostsCount = 6;
	let showGuide = true;
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div>
		<h1 class="text-2xl font-bold text-gray-900">랜딩 페이지 관리</h1>
		<p class="text-gray-600">메인 페이지의 디자인과 내용을 설정하세요</p>
	</div>

	<!-- 히어로 섹션 -->
	<Card>
		<CardHeader>
			<CardTitle class="flex items-center">
				<TypeIcon class="mr-2 h-5 w-5" />
				히어로 섹션
			</CardTitle>
			<CardDescription>메인 페이지 상단의 제목과 배경 이미지를 설정합니다.</CardDescription>
		</CardHeader>
		<CardContent class="space-y-4">
			<div>
				<Label for="heroTitle">메인 제목</Label>
				<Input id="heroTitle" bind:value={heroTitle} placeholder="메인 제목을 입력하세요" />
			</div>
			<div>
				<Label for="heroSubtitle">부제목</Label>
				<Input id="heroSubtitle" bind:value={heroSubtitle} placeholder="부제목을 입력하세요" />
			</div>
			<div>
				<Label for="heroBackground">배경 이미지 URL</Label>
				<Input
					id="heroBackground"
					bind:value={heroBackground}
					placeholder="배경 이미지 URL을 입력하세요"
				/>
			</div>
		</CardContent>
	</Card>

	<!-- 최근글 섹션 -->
	<Card>
		<CardHeader>
			<CardTitle class="flex items-center">
				<LayoutIcon class="mr-2 h-5 w-5" />
				최근글 섹션
			</CardTitle>
			<CardDescription>메인 페이지에 표시될 최근 게시글 설정</CardDescription>
		</CardHeader>
		<CardContent class="space-y-4">
			<div>
				<Label for="recentPostsCount">표시할 게시글 수</Label>
				<Input id="recentPostsCount" type="number" bind:value={recentPostsCount} min="1" max="12" />
			</div>
			<div class="flex items-center space-x-2">
				<input type="checkbox" id="showGuide" bind:checked={showGuide} />
				<Label for="showGuide">안내 섹션 표시</Label>
			</div>
		</CardContent>
	</Card>

	<!-- 미리보기 -->
	<Card>
		<CardHeader>
			<CardTitle>미리보기</CardTitle>
			<CardDescription>설정한 내용의 미리보기입니다.</CardDescription>
		</CardHeader>
		<CardContent>
			<div class="rounded-lg bg-gray-100 p-6">
				<div class="space-y-4 text-center">
					<h2 class="text-3xl font-bold text-gray-900">{heroTitle}</h2>
					<p class="text-xl text-gray-600">{heroSubtitle}</p>
					<div class="flex h-32 items-center justify-center rounded bg-gray-200">
						<ImageIcon class="h-8 w-8 text-gray-400" />
						<span class="ml-2 text-gray-500">배경 이미지</span>
					</div>
				</div>
			</div>
		</CardContent>
	</Card>

	<!-- 저장 버튼 -->
	<div class="flex justify-end">
		<Button>설정 저장</Button>
	</div>
</div>
