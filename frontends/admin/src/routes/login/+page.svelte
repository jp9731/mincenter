<script lang="ts">
	import { goto } from '$app/navigation';
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { adminUser } from '$lib/stores/admin';
	import { adminLogin } from '$lib/api/admin.js';

	let email = '';
	let password = '';
	let isLoading = false;
	let error = '';

	async function handleLogin() {
		if (!email || !password) {
			error = '이메일과 비밀번호를 입력해주세요.';
			return;
		}

		isLoading = true;
		error = '';

		try {
			const result = await adminLogin(email, password);

			// 토큰 저장
			localStorage.setItem('admin_token', result.token);
			adminUser.set(result.user);

			// 대시보드로 이동 (완전한 페이지 새로고침)
			window.location.href = '/';
		} catch (e: any) {
			error = e.message || '로그인에 실패했습니다.';
		} finally {
			isLoading = false;
		}
	}

	function handleKeydown(event: KeyboardEvent) {
		if (event.key === 'Enter') {
			handleLogin();
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-gray-50 px-4 py-12 sm:px-6 lg:px-8">
	<div class="w-full max-w-md space-y-8">
		<div class="text-center">
			<h2 class="mt-6 text-3xl font-extrabold text-gray-900">관리자 로그인</h2>
			<p class="mt-2 text-sm text-gray-600">장애인 봉사단체 관리 시스템</p>
		</div>

		<Card>
			<CardHeader>
				<CardTitle>로그인</CardTitle>
				<CardDescription>관리자 계정으로 로그인하여 시스템을 관리하세요.</CardDescription>
			</CardHeader>
			<CardContent>
				<form class="space-y-6" on:submit|preventDefault={handleLogin}>
					{#if error}
						<div class="rounded-md border border-red-200 bg-red-50 p-3">
							<p class="text-sm text-red-700">{error}</p>
						</div>
					{/if}

					<div>
						<label for="email" class="mb-2 block text-sm font-medium text-gray-700"> 이메일 </label>
						<Input
							id="email"
							type="email"
							bind:value={email}
							on:keydown={handleKeydown}
							placeholder="관리자 이메일을 입력하세요"
							required
							disabled={isLoading}
						/>
					</div>

					<div>
						<label for="password" class="mb-2 block text-sm font-medium text-gray-700">
							비밀번호
						</label>
						<Input
							id="password"
							type="password"
							bind:value={password}
							on:keydown={handleKeydown}
							placeholder="비밀번호를 입력하세요"
							required
							disabled={isLoading}
						/>
					</div>

					<Button type="submit" class="w-full" disabled={isLoading}>
						{isLoading ? '로그인 중...' : '로그인'}
					</Button>
				</form>

				<div class="mt-6 rounded-md border border-blue-200 bg-blue-50 p-4">
					<p class="text-sm text-blue-700">
						<strong>테스트 계정:</strong><br />
						이메일: admin@example.com<br />
						비밀번호: admin123
					</p>
				</div>
			</CardContent>
		</Card>
	</div>
</div>
