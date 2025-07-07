<script lang="ts">
	import { page } from '$app/stores';
</script>

<div class="container mx-auto px-4 py-8">
	<h1 class="text-2xl font-bold text-red-600 mb-4">에러 발생</h1>
	<p class="text-gray-600 mb-2">상태 코드: {$page.status}</p>
	<p class="text-gray-600 mb-2">에러 메시지: {$page.error?.message || '알 수 없는 에러'}</p>
	<p class="text-gray-600 mb-4">경로: {$page.url.pathname}</p>
	
	<pre class="bg-gray-100 p-4 rounded text-sm overflow-auto">
		{JSON.stringify($page, null, 2)}
	</pre>
</div> 