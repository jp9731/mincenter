<script lang="ts">
	// 후원 정보
	const donationInfo = {
		regularDonation: {
			title: '정기후원',
			description: '카드후원, 계좌출금 후원 가능',
			link: 'https://webcm.co.kr/system/platform/page1-1.html?id=pspdpspd&gid=mincenter12',
			note: '링크로 작성이 어려울 경우 아래 신청서 작성하여 메일로 보내주거나 담당자에게 문의해주세요.'
		},
		oneTimeDonation: {
			title: '일시후원',
			description: '국민은행 계좌로 입금',
			account: '국민(민들레장애인자립생활센터) 720537-01-002394',
			note: '기부금영수증 발급 원하실 경우 담당자 문의'
		},
		materialDonation: {
			title: '물품후원',
			description: '생활용품 등',
			note: '담당자에게 문의 주세요. 기부금영수증 발급 원하실 경우 담당자 문의'
		},
		contact: {
			email: 'mincenter08@daum.net',
			phone: '032-542-9294',
			person: '사무국장'
		}
	};

	// 후원신청서 다운로드 함수
	function downloadApplication() {
		// 실제 신청서 파일이 있다면 여기에 다운로드 로직 추가
		alert('후원신청서 다운로드 기능은 준비 중입니다. 담당자에게 문의해주세요.');
	}
</script>

<svelte:head>
	<title>후원안내 - 민들레장애인자립생활센터</title>
	<meta name="description" content="민들레장애인자립생활센터 후원 안내" />
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- 히어로 섹션 -->
	<section class="bg-gradient-to-r from-lime-600 to-lime-800 py-16 text-white">
		<div class="text-center">
			<h1 class="mb-6 text-4xl font-bold md:text-6xl">후원안내</h1>
			<p class="text-xl opacity-90 md:text-2xl">
				여러분의 따뜻한 마음이 장애인의 자립생활을 지원합니다
			</p>
		</div>
	</section>

	<div class="py-12 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<!-- 후원 이미지 -->
		<section class="mb-12">
			<div class="overflow-hidden rounded-lg bg-white shadow-md">
				<img
					src="/images/huwon.jpeg"
					alt="후원 안내"
					class="h-auto w-full object-contain"
				/>
			</div>
		</section>

		<!-- 후원신청서 링크 -->
		<section class="mb-12">
			<div class="rounded-lg bg-white p-8 text-center shadow-md">
				<h2 class="mb-4 text-2xl font-bold text-lime-700">정기후원 신청</h2>
				<p class="mb-6 text-gray-600">
					정기후원을 원하시는 경우 아래 링크를 이용하여 신청해 주시기 바랍니다.
				</p>
				<div class="flex flex-col justify-center gap-4 sm:flex-row">
					<a
						href={donationInfo.regularDonation.link}
						target="_blank"
						rel="noopener noreferrer"
						class="inline-flex items-center justify-center rounded-lg bg-lime-600 px-8 py-3 font-semibold text-white transition-colors hover:bg-lime-700"
					>
						<span>후원신청서 링크</span>
						<svg class="ml-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
							/>
						</svg>
					</a>
					<button
						onclick={downloadApplication}
						class="inline-flex items-center justify-center rounded-lg border border-lime-600 px-8 py-3 font-semibold text-lime-600 transition-colors hover:bg-lime-50"
					>
						<span>신청서 다운로드</span>
						<svg class="ml-2 h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
							/>
						</svg>
					</button>
				</div>
				<div class="mt-4 text-sm text-gray-500">
					* 기부금영수증 발급 원하실 경우 주민번호 뒷자리까지 작성 꼭! 홈텍스에서 확인 가능
				</div>
			</div>
		</section>

		<!-- 후원 방법 안내 -->
		<section class="mb-12">
			<div class="grid gap-8 md:grid-cols-3">
				<!-- 정기후원 -->
				<div class="rounded-lg bg-white p-6 shadow-md">
					<div class="mb-4 text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-lime-100"
						>
							<svg
								class="h-8 w-8 text-lime-600"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
								/>
							</svg>
						</div>
						<h3 class="text-xl font-bold text-lime-700">{donationInfo.regularDonation.title}</h3>
					</div>
					<div class="space-y-2 text-gray-700">
						<p class="font-medium">{donationInfo.regularDonation.description}</p>
						<p class="text-sm text-gray-600">{donationInfo.regularDonation.note}</p>
					</div>
				</div>

				<!-- 일시후원 -->
				<div class="rounded-lg bg-white p-6 shadow-md">
					<div class="mb-4 text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-lime-100"
						>
							<svg
								class="h-8 w-8 text-lime-600"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"
								/>
							</svg>
						</div>
						<h3 class="text-xl font-bold text-lime-700">{donationInfo.oneTimeDonation.title}</h3>
					</div>
					<div class="space-y-2 text-gray-700">
						<p class="font-medium">{donationInfo.oneTimeDonation.description}</p>
						<div class="rounded-lg bg-gray-50 p-3">
							<p class="break-all font-mono text-sm">{donationInfo.oneTimeDonation.account}</p>
						</div>
						<p class="text-sm text-gray-600">{donationInfo.oneTimeDonation.note}</p>
					</div>
				</div>

				<!-- 물품후원 -->
				<div class="rounded-lg bg-white p-6 shadow-md">
					<div class="mb-4 text-center">
						<div
							class="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-lime-100"
						>
							<svg
								class="h-8 w-8 text-lime-600"
								fill="none"
								stroke="currentColor"
								viewBox="0 0 24 24"
							>
								<path
									stroke-linecap="round"
									stroke-linejoin="round"
									stroke-width="2"
									d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
								/>
							</svg>
						</div>
						<h3 class="text-xl font-bold text-lime-700">{donationInfo.materialDonation.title}</h3>
					</div>
					<div class="space-y-2 text-gray-700">
						<p class="font-medium">{donationInfo.materialDonation.description}</p>
						<p class="text-sm text-gray-600">{donationInfo.materialDonation.note}</p>
					</div>
				</div>
			</div>
		</section>

		<!-- 연락처 정보 -->
		<section class="mb-12">
			<div class="rounded-lg border border-lime-200 bg-lime-50 p-8">
				<h3 class="mb-6 text-center text-2xl font-bold text-lime-700">문의사항</h3>
				<div class="grid gap-6 md:grid-cols-2">
					<div class="flex items-center gap-3">
						<div class="flex h-5 w-5 items-center justify-center rounded-full bg-lime-600">
							<span class="text-xs text-white">📞</span>
						</div>
						<div>
							<div class="font-medium">전화</div>
							<div class="text-sm text-gray-600">
								<a href="tel:{donationInfo.contact.phone}" class="underline hover:text-lime-600">
									{donationInfo.contact.phone} ({donationInfo.contact.person})
								</a>
							</div>
						</div>
					</div>
					<div class="flex items-center gap-3">
						<div class="flex h-5 w-5 items-center justify-center rounded-full bg-lime-600">
							<span class="text-xs text-white">✉️</span>
						</div>
						<div>
							<div class="font-medium">이메일</div>
							<div class="text-sm text-gray-600">
								<a
									href="mailto:{donationInfo.contact.email}"
									class="underline hover:text-lime-600"
								>
									{donationInfo.contact.email}
								</a>
							</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- 후원 참여 CTA -->
		<section class="text-center">
			<div class="rounded-lg bg-gradient-to-r from-lime-600 to-lime-800 p-12 text-white">
				<h2 class="mb-4 text-3xl font-bold">함께 후원에 참여해보세요</h2>
				<p class="mb-8 text-xl opacity-90">작은 후원이 큰 변화를 만들어갑니다.</p>
				<div class="flex flex-col justify-center gap-4 sm:flex-row">
					<a
						href={donationInfo.regularDonation.link}
						target="_blank"
						rel="noopener noreferrer"
						class="inline-block rounded-lg bg-white px-8 py-3 font-semibold text-lime-600 transition-colors hover:bg-gray-100"
					>
						정기후원 신청하기
					</a>
					<a
						href="tel:{donationInfo.contact.phone}"
						class="inline-block rounded-lg border-2 border-white px-8 py-3 font-semibold text-white transition-colors hover:bg-white hover:text-lime-600"
					>
						문의하기
					</a>
				</div>
			</div>
		</section>
	</div>
</div>
