<script lang="ts">
	const currentYear = new Date().getFullYear();
</script>

<footer class="border-t bg-gray-50">
	<div class="mx-auto max-w-7xl px-4 py-12 sm:px-6 lg:px-8">
		<div class="grid grid-cols-1 gap-8 md:grid-cols-4">
			<!-- 센터 정보 -->
			<div class="col-span-1 md:col-span-2">
				<h3 class="mb-4 text-lg font-semibold text-gray-900">민들레장애인자립생활센터</h3>
				<p class="mb-4 text-gray-600">장애인의 자립생활을 지원하고 함께하는 사회를 만들어갑니다.</p>
				<div class="space-y-2 text-sm text-gray-600">
					<p>주소: 서울특별시 강남구 테헤란로 123</p>
					<p>전화: 02-123-4567</p>
					<p>이메일: info@minshool.org</p>
				</div>
			</div>

			<!-- 빠른 링크 -->
			<div>
				<h3 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-900">빠른 링크</h3>
				<ul class="space-y-3">
					<li>
						<a href="/about" class="hover:text-primary-600 text-gray-600">센터소개</a>
					</li>
					<li>
						<a href="/services" class="hover:text-primary-600 text-gray-600">사업안내</a>
					</li>
					<li>
						<a href="/community" class="hover:text-primary-600 text-gray-600">커뮤니티</a>
					</li>
					<li>
						<a href="/gallery" class="hover:text-primary-600 text-gray-600">갤러리</a>
					</li>
				</ul>
			</div>

			<!-- 후원하기 -->
			<div>
				<h3 class="mb-4 text-sm font-semibold uppercase tracking-wider text-gray-900">후원하기</h3>
				<ul class="space-y-3">
					<li>
						<a href="/participate/donate" class="hover:text-primary-600 text-gray-600">정기후원</a>
					</li>
					<li>
						<a href="/participate/volunteer" class="hover:text-primary-600 text-gray-600"
							>봉사신청</a
						>
					</li>
					<li>
						<a href="/participate/contact" class="hover:text-primary-600 text-gray-600">문의하기</a>
					</li>
				</ul>
			</div>
		</div>

		<!-- 저작권 -->
		<div class="mt-8 border-t border-gray-200 pt-8">
			<p class="text-center text-sm text-gray-500">
				© {currentYear} 민들레장애인자립생활센터. All rights reserved.
			</p>
		</div>
	</div>
</footer>
