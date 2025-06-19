<script lang="ts">
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { GiftIcon, CreditCardIcon, ReceiptIcon } from 'lucide-svelte';

	const donationStats = {
		total_donors: 89,
		total_amount: 12500000,
		pending_donations: 12,
		completed_donations: 156
	};
</script>

<div class="space-y-6">
	<div>
		<h1 class="text-2xl font-bold text-gray-900">후원 관리</h1>
		<p class="text-gray-600">후원 신청자와 입금 내역을 관리하세요</p>
	</div>

	<div class="grid grid-cols-1 gap-6 md:grid-cols-4">
		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-blue-100 p-2">
						<GiftIcon class="h-6 w-6 text-blue-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 후원자</p>
						<p class="text-2xl font-bold text-gray-900">{donationStats.total_donors}</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-green-100 p-2">
						<CreditCardIcon class="h-6 w-6 text-green-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">총 후원금</p>
						<p class="text-2xl font-bold text-gray-900">
							{(donationStats.total_amount / 10000).toFixed(0)}만원
						</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-yellow-100 p-2">
						<GiftIcon class="h-6 w-6 text-yellow-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">대기 후원</p>
						<p class="text-2xl font-bold text-gray-900">{donationStats.pending_donations}</p>
					</div>
				</div>
			</CardContent>
		</Card>

		<Card>
			<CardContent class="p-6">
				<div class="flex items-center">
					<div class="rounded-lg bg-purple-100 p-2">
						<ReceiptIcon class="h-6 w-6 text-purple-600" />
					</div>
					<div class="ml-4">
						<p class="text-sm font-medium text-gray-600">완료 후원</p>
						<p class="text-2xl font-bold text-gray-900">{donationStats.completed_donations}</p>
					</div>
				</div>
			</CardContent>
		</Card>
	</div>

	<div class="grid grid-cols-1 gap-6 md:grid-cols-3">
		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<GiftIcon class="mr-2 h-5 w-5" />
					신청자 목록
				</CardTitle>
				<CardDescription>후원 신청자들을 관리합니다</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/donations/applications" class="w-full">관리하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<CreditCardIcon class="mr-2 h-5 w-5" />
					입금 내역
				</CardTitle>
				<CardDescription>후원금 입금 내역 관리</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/donations/payments" class="w-full">관리하기</Button>
			</CardContent>
		</Card>

		<Card>
			<CardHeader>
				<CardTitle class="flex items-center">
					<ReceiptIcon class="mr-2 h-5 w-5" />
					계산서 발행
				</CardTitle>
				<CardDescription>후원금 계산서 발행 관리</CardDescription>
			</CardHeader>
			<CardContent>
				<Button href="/donations/receipts" class="w-full">관리하기</Button>
			</CardContent>
		</Card>
	</div>
</div>
