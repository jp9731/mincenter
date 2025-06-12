<script lang="ts">
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { login, error, isLoading } from '$lib/stores/auth';

	let email = '';
	let password = '';
	let formError = '';

	async function handleSubmit() {
		formError = '';
		const success = await login(email, password);
		if (success) {
			goto('/');
		}
	}
</script>

<div class="flex min-h-[calc(100vh-4rem)] items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
	<div class="w-full max-w-md space-y-8">
		<div>
			<h2 class="mt-6 text-center text-3xl font-bold text-gray-900">로그인</h2>
			<p class="mt-2 text-center text-sm text-gray-600">
				또는{' '}
				<a href="/auth/register" class="text-primary-600 hover:text-primary-500 font-medium">
					회원가입
				</a>
			</p>
		</div>

		<form class="mt-8 space-y-6" on:submit|preventDefault={handleSubmit}>
			<div class="space-y-4 rounded-md shadow-sm">
				<div>
					<label for="email" class="sr-only">이메일</label>
					<Input
						id="email"
						name="email"
						type="email"
						bind:value={email}
						required
						placeholder="이메일"
						class="focus:ring-primary-500 focus:border-primary-500 relative block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:outline-none sm:text-sm"
					/>
				</div>
				<div>
					<label for="password" class="sr-only">비밀번호</label>
					<Input
						id="password"
						name="password"
						type="password"
						bind:value={password}
						required
						placeholder="비밀번호"
						class="focus:ring-primary-500 focus:border-primary-500 relative block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:outline-none sm:text-sm"
					/>
				</div>
			</div>

			<div class="flex items-center justify-between">
				<div class="text-sm">
					<a
						href="/auth/forgot-password"
						class="text-primary-600 hover:text-primary-500 font-medium"
					>
						비밀번호를 잊으셨나요?
					</a>
				</div>
			</div>

			{#if $error}
				<div class="text-center text-sm text-red-500">
					{$error}
				</div>
			{/if}

			<div>
				<Button type="submit" class="w-full" disabled={$isLoading}>
					{$isLoading ? '로그인 중...' : '로그인'}
				</Button>
			</div>

			<div class="mt-6">
				<div class="relative">
					<div class="absolute inset-0 flex items-center">
						<div class="w-full border-t border-gray-300"></div>
					</div>
					<div class="relative flex justify-center text-sm">
						<span class="bg-white px-2 text-gray-500"> 또는 다음으로 계속하기 </span>
					</div>
				</div>

				<div class="mt-6 grid grid-cols-2 gap-3">
					<Button type="button" variant="outline" class="w-full" href="/auth/callback/google">
						Google
					</Button>
					<Button type="button" variant="outline" class="w-full" href="/auth/callback/kakao">
						Kakao
					</Button>
				</div>
			</div>
		</form>
	</div>
</div>
