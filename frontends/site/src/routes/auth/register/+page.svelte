<script lang="ts">
	import { goto } from '$app/navigation';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { register, error, isLoading } from '$lib/stores/auth';

	let form = {
		email: '',
		password: '',
		passwordConfirm: '',
		name: ''
	};

	let formError = '';

	async function handleSubmit() {
		formError = '';

		if (form.password !== form.passwordConfirm) {
			formError = '비밀번호가 일치하지 않습니다.';
			return;
		}

		const success = await register({
			email: form.email,
			password: form.password,
			name: form.name
		});

		if (success) {
			goto('/auth/login?registered=true');
		}
	}
</script>

<div class="flex min-h-[calc(100vh-4rem)] items-center justify-center px-4 py-12 sm:px-6 lg:px-8">
	<div class="w-full max-w-md space-y-8">
		<div>
			<h2 class="mt-6 text-center text-3xl font-bold text-gray-900">회원가입</h2>
			<p class="mt-2 text-center text-sm text-gray-600">
				이미 계정이 있으신가요?{' '}
				<a href="/auth/login" class="text-primary-600 hover:text-primary-500 font-medium">
					로그인
				</a>
			</p>
		</div>

		<form class="mt-8 space-y-6" on:submit|preventDefault={handleSubmit}>
			<div class="space-y-4 rounded-md shadow-sm">
				<div>
					<label for="name" class="sr-only">이름</label>
					<Input
						id="name"
						name="name"
						type="text"
						bind:value={form.name}
						required
						placeholder="이름"
						class="focus:ring-primary-500 focus:border-primary-500 relative block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:outline-none sm:text-sm"
					/>
				</div>
				<div>
					<label for="email" class="sr-only">이메일</label>
					<Input
						id="email"
						name="email"
						type="email"
						bind:value={form.email}
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
						bind:value={form.password}
						required
						placeholder="비밀번호"
						class="focus:ring-primary-500 focus:border-primary-500 relative block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:outline-none sm:text-sm"
					/>
				</div>
				<div>
					<label for="passwordConfirm" class="sr-only">비밀번호 확인</label>
					<Input
						id="passwordConfirm"
						name="passwordConfirm"
						type="password"
						bind:value={form.passwordConfirm}
						required
						placeholder="비밀번호 확인"
						class="focus:ring-primary-500 focus:border-primary-500 relative block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:z-10 focus:outline-none sm:text-sm"
					/>
				</div>
			</div>

			{#if formError}
				<div class="text-center text-sm text-red-500">
					{formError}
				</div>
			{/if}

			{#if $error}
				<div class="text-center text-sm text-red-500">
					{$error}
				</div>
			{/if}

			<div>
				<Button type="submit" class="w-full" disabled={$isLoading}>
					{$isLoading ? '가입 중...' : '회원가입'}
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
