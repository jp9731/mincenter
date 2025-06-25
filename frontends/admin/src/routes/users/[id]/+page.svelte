<script lang="ts">
import { goto } from '$app/navigation';
import { onMount } from 'svelte';
import { Button } from '$lib/components/ui/button';
import { Input } from '$lib/components/ui/input';
import { Label } from '$lib/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger } from '$lib/components/ui/select';
import { page } from '$app/stores';
import { updateUserRole, updateUserStatus, getUser, updateUser } from '$lib/api/admin';

let userId = '';
let user: any = null;
let loading = true;
let saving = false;
let error: string | null = null;

// 폼 데이터
let formData = {
  name: '',
  email: '',
  phone: '',
  role: 'user',
  status: 'active'
};

onMount(async () => {
  userId = $page.params.id;
  await loadUser();
});

async function loadUser() {
  try {
    loading = true;
    error = null;
    
    // 실제 API 호출
    const userData = await getUser(userId);
    user = userData;
    
    // 폼 데이터 초기화
    formData = {
      name: user.name || '',
      email: user.email || '',
      phone: user.phone || '',
      role: user.role || 'user',
      status: user.status || 'active'
    };
    
    loading = false;
  } catch (err) {
    error = '사용자 정보를 불러오는데 실패했습니다.';
    loading = false;
  }
}

async function handleSubmit(e: Event) {
  e.preventDefault();
  try {
    saving = true;
    error = null;
    
    // 실제 API 호출
    await updateUser(userId, {
      name: formData.name,
      email: formData.email,
      phone: formData.phone,
      role: formData.role,
      status: formData.status
    });
    
    saving = false;
    alert('사용자 정보가 수정되었습니다.');
    goto('/users');
  } catch (err) {
    error = '사용자 정보 수정에 실패했습니다.';
    saving = false;
  }
}

function handleCancel() {
  goto('/users');
}
</script>

<div class="max-w-2xl mx-auto py-10">
  {#if loading}
    <div class="text-center py-10">불러오는 중...</div>
  {:else if error}
    <div class="text-center text-red-600 py-10">{error}</div>
  {:else if user}
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold">사용자 정보 수정</h1>
        <div class="text-sm text-gray-500">
          가입일: {new Date(user.created_at).toLocaleString('ko-KR')}
        </div>
      </div>
      
      <form onsubmit={handleSubmit} class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- 이름 -->
          <div class="space-y-2">
            <Label for="name">이름 *</Label>
            <Input
              id="name"
              type="text"
              bind:value={formData.name}
              required
              placeholder="사용자 이름을 입력하세요"
            />
          </div>
          
          <!-- 이메일 -->
          <div class="space-y-2">
            <Label for="email">이메일 *</Label>
            <Input
              id="email"
              type="email"
              bind:value={formData.email}
              required
              placeholder="이메일을 입력하세요"
            />
          </div>
          
          <!-- 폰번호 -->
          <div class="space-y-2">
            <Label for="phone">폰번호</Label>
            <Input
              id="phone"
              type="tel"
              bind:value={formData.phone}
              placeholder="010-1234-5678"
            />
          </div>
          
          <!-- 역할 -->
          <div class="space-y-2">
            <Label for="role">역할</Label>
            <Select value={formData.role} type="single" onValueChange={(value) => formData.role = value}>
              <SelectTrigger>
                <span>{formData.role === 'admin' ? '관리자' : formData.role === 'moderator' ? '모더레이터' : '일반 사용자'}</span>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="user">일반 사용자</SelectItem>
                <SelectItem value="admin">관리자</SelectItem>
                <SelectItem value="moderator">모더레이터</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <!-- 상태 -->
          <div class="space-y-2">
            <Label for="status">상태</Label>
            <Select value={formData.status} type="single"  onValueChange={(value) => formData.status = value}>
              <SelectTrigger>
                <span>{formData.status === 'active' ? '활성' : formData.status === 'inactive' ? '비활성' : '정지'}</span>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="active">활성</SelectItem>
                <SelectItem value="inactive">비활성</SelectItem>
                <SelectItem value="suspended">정지</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
        
        <!-- 읽기 전용 정보 -->
        <div class="bg-gray-50 p-4 rounded-lg space-y-4">
          <h3 class="font-medium text-gray-900">기타 정보</h3>
          
          <!-- 프로필 이미지 -->
          <div class="space-y-2">
            <Label>프로필 이미지</Label>
            <div class="flex items-center space-x-4">
              {#if user.profile_image}
                <img 
                  src={user.profile_image} 
                  alt="프로필 이미지" 
                  class="w-16 h-16 rounded-full object-cover border-2 border-gray-200"
                />
              {:else}
                <div class="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center">
                  <span class="text-gray-500 text-lg">{user.name?.charAt(0) || '?'}</span>
                </div>
              {/if}
              <div class="flex-1">
                <Input
                  type="file"
                  accept="image/*"
                  class="text-sm"
                  placeholder="프로필 이미지 업로드"
                />
                <p class="text-xs text-gray-500 mt-1">JPG, PNG, GIF 파일만 업로드 가능합니다.</p>
              </div>
            </div>
          </div>
          
          <!-- 기본 정보 -->
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div><span class="text-gray-600">게시글 수:</span> {user.post_count || 0}</div>
            <div><span class="text-gray-600">포인트:</span> {(user.point_balance ?? 0).toLocaleString()}</div>
            <div><span class="text-gray-600">최근 접속일:</span> {user.last_login_at ? new Date(user.last_login_at).toLocaleString('ko-KR') : '없음'}</div>
            <div><span class="text-gray-600">계정 생성일:</span> {new Date(user.created_at).toLocaleString('ko-KR')}</div>
          </div>
        </div>
        
        <!-- 에러 메시지 -->
        {#if error}
          <div class="text-red-600 text-sm">{error}</div>
        {/if}
        
        <!-- 버튼 -->
        <div class="flex gap-4 justify-end">
          <a href="/users" class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">
            취소
          </a>
          <Button type="submit" disabled={saving}>
            {saving ? '저장 중...' : '저장'}
          </Button>
        </div>
      </form>
    </div>
  {:else}
    <div class="text-center py-10">사용자 정보를 찾을 수 없습니다.</div>
  {/if}
</div> 