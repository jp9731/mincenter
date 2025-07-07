<script lang="ts">
import Button from '$lib/components/ui/button/button.svelte';
</script>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  <div class="bg-card rounded-xl border shadow-sm flex flex-col gap-4 p-8">
    <div class="flex items-center justify-between mb-4">
      <h2 class="text-xl md:text-2xl font-bold text-primary-700">후원안내</h2>
      <Button as="a" href="/donation" variant="ghost" class="text-primary-600 text-sm">더보기 &gt;</Button>
    </div>
    <div class="flex flex-col md:flex-row gap-8 items-center">
      <div class="flex-shrink-0 w-full md:w-64 flex justify-center">
        <img src="/images/huwon.jpeg" alt="후원안내" class="rounded-lg w-40 h-40 md:w-64 md:h-64 object-contain bg-white border" />
      </div>
      <div class="flex-1 text-gray-700 text-sm md:text-base leading-relaxed">
        <ul class="list-disc pl-4 space-y-1">
          <li>정기후원 원하실 경우 상담 링크를 이용하여 신청해 주시기 바랍니다. 카드후원, 계좌출금 후원 가능. 링크로 작성이 어려운 경우 아래 신청서 작성하여 메일로 보내주시거나 담당자에게 문의해 주세요.</li>
          <li>기부금영수증 발급 원하실 경우 주민번호 뒷자리까지 작성, 꼭 홈페이지에서 확인 가능</li>
          <li>일시후원일 경우 국민(민들레장애인자립생활센터) 720537-01-002394 입금</li>
          <li>기부금영수증 발급 원하실 경우 담당자 문의</li>
          <li>물품후원(생활용품 등) 경우 담당자에게 문의</li>
          <li>기부금영수증 발급 원하실 경우 담당자 문의 이메일: mincenter08@daum.net, 문의: 032-542-9294(사무국장)</li>
        </ul>
      </div>
    </div>
  </div>
</div> 