<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { SettingsIcon, UsersIcon, CreditCardIcon } from 'lucide-svelte';
</script>

<div class="space-y-6">
	<!-- 페이지 헤더 -->
	<div>
		<h1 class="text-2xl font-bold text-gray-900">사이트 관리</h1>
		<p class="text-gray-600">사이트의 기본 설정을 관리하세요</p>
	</div>

	<!-- 설정 카드들 -->
	<div class="grid grid-cols-1 gap-6 md:grid-cols-3">
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<SettingsIcon class="mr-2 h-5 w-5" />
					기본 설정
				</CardTitle>
				<CardDescription>사이트명, 하단 내용, 연락처 정보 관리</CardDescription>
			</CardHeader>
			<CardContent>
				<p class="mb-4 text-sm text-gray-600">
					사이트의 기본 정보와 연락처, SNS 링크 등을 설정할 수 있습니다.
				</p>
				<Button href="/site/settings" class="w-full">설정하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<UsersIcon class="mr-2 h-5 w-5" />
					사용자 레벨
				</CardTitle>
				<CardDescription>사용자 등급 및 권한 설정</CardDescription>
			</CardHeader>
			<CardContent>
				<p class="mb-4 text-sm text-gray-600">사용자 등급별 권한과 혜택을 설정할 수 있습니다.</p>
				<Button href="/site/user-levels" class="w-full">설정하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<CreditCardIcon class="mr-2 h-5 w-5" />
					후원 계좌
				</CardTitle>
				<CardDescription>후원금 입금 계좌 정보 관리</CardDescription>
			</CardHeader>
			<CardContent>
				<p class="mb-4 text-sm text-gray-600">후원금 입금을 위한 계좌 정보를 설정할 수 있습니다.</p>
				<Button href="/site/donation-accounts" class="w-full">설정하기</Button>
			</CardContent>
		</Card>
	</div>
</div>
