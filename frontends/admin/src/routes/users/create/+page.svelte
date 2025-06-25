<script lang="ts">
import { goto } from '$app/navigation';
import { onMount } from 'svelte';
import { Button } from '$lib/components/ui/button';
import { Input } from '$lib/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';

let name = '';
let username = '';
let email = '';
let password = '';
let role = 'user';
let status = 'active';
let error: string | null = null;
let loading = false;

async function handleSubmit(e: Event) {
  e.preventDefault();
  loading = true;
  error = null;
  // TODO: API 연동
  setTimeout(() => {
    loading = false;
    goto('/users');
  }, 1000);
}
</script>

<div class="max-w-xl mx-auto py-10">
  <h1 class="text-2xl font-bold mb-6">새 사용자 추가</h1>
  <form onsubmit={handleSubmit} class="space-y-6">
    <div>
      <label class="block mb-1 font-medium">이름</label>
      <Input bind:value={name} required placeholder="이름" />
    </div>
    <div>
      <label class="block mb-1 font-medium">사용자명</label>
      <Input bind:value={username} required placeholder="사용자명" />
    </div>
    <div>
      <label class="block mb-1 font-medium">이메일</label>
      <Input type="email" bind:value={email} required placeholder="이메일" />
    </div>
    <div>
      <label class="block mb-1 font-medium">비밀번호</label>
      <Input type="password" bind:value={password} required placeholder="비밀번호" />
    </div>
    <div>
      <label class="block mb-1 font-medium">역할</label>
      <Select type="single" bind:value={role}>
        <SelectTrigger>{role === 'admin' ? '관리자' : role === 'moderator' ? '모더레이터' : '일반 사용자'}</SelectTrigger>
        <SelectContent>
          <SelectItem value="user">일반 사용자</SelectItem>
          <SelectItem value="moderator">모더레이터</SelectItem>
          <SelectItem value="admin">관리자</SelectItem>
        </SelectContent>
      </Select>
    </div>
    <div>
      <label class="block mb-1 font-medium">상태</label>
      <Select type="single" bind:value={status}>
        <SelectTrigger>{status === 'active' ? '활성' : status === 'suspended' ? '정지' : '대기'}</SelectTrigger>
        <SelectContent>
          <SelectItem value="active">활성</SelectItem>
          <SelectItem value="suspended">정지</SelectItem>
          <SelectItem value="pending">대기</SelectItem>
        </SelectContent>
      </Select>
    </div>
    {#if error}
      <div class="text-red-600">{error}</div>
    {/if}
    <div class="flex gap-4 justify-end">
      <Button type="button" variant="outline" onclick={() => goto('/users')}>취소</Button>
      <Button type="submit" disabled={loading}>{loading ? '저장 중...' : '저장'}</Button>
    </div>
  </form>
</div> 