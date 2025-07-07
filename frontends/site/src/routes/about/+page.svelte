<script lang="ts">
	// 조직 정보
	const organizationInfo = {
		name: '민들레장애인자립생활센터',
		description: '장애인의 자립생활을 지원하고 함께하는 사회를 만들어갑니다',
		established: '2008년',
		address: '인천광역시 계양구 계산동 1062 A-202',
		phone: '1577-1330',
		email: 'info@mindulle.org',
		website: 'https://mindulle.org'
	};

	// 연혁 데이터
	const history = [
		{ year: '2008.05.28', event: '민들레장애인자립생활센터 설립', detail: '소장: 박길연' },
		{ year: '2008.10.06', event: '자립생활주택(민들레홀씨1호)개소' },
		{ year: '2009.06.18', event: '1577-1330 장애인차별상담전화 운영단체 협약 체결' },
		{ year: '2010.01.16', event: '장애인보장구 무상점검 및 수리 자매결연-케어114' },
		{ year: '2010.07.14', event: '인천시 지원 자립생활주택(민들레홀씨2호)위탁기관 선정' },
		{ year: '2011.03.02', event: '인천시 지원 자립주택 1호 위탁기관 선정' },
		{ year: '2011.11.30', event: '장애인활동지원서비스제공기관 선정' },
		{ year: '2013.07.01', event: '인천시 지원 자립주택 2호 위탁기관 선정' },
		{ year: '2014.01.01', event: '소장: 김순미' },
		{ year: '2014.03.05', event: '인천시장애인체육회 생활체육교실(보치아) 선정' },
		{ year: '2014.10.27~29', event: "탈시설캠프 '시친소(시설친구를소개합니다.)' 1회" },
		{ year: '2015.03.05', event: '인천시장애인체육회 생활체육교실(전동휠체어축구) 선정' },
		{ year: '2015.12.26', event: '제1회 민들레센터 발달장애인 말하기대회 개최' },
		{ year: '2016.02', event: '권익옹호 배움터 달달학교 진행' },
		{ year: '2016.02.26', event: '인천광역시 중증장애인자립지원센터 선정' },
		{ year: '2016.04.02', event: '전국장애인부모연대 계양지회 협약 체결' },
		{ year: '2016.11', event: '2016 전국장애인전동휠체어축구대회 우승' },
		{ year: '2016.11.16~18', event: "탈시설캠프 '시친소(시설친구를소개합니다.)' 2회" },
		{ year: '2017.02.03', event: '인천시장애인체육회 생활체육교실(전동휠체어축구) 선정' },
		{ year: '2017.04.01', event: '소장: 박길연' },
		{ year: '2017.11.16~18', event: "탈시설캠프 '시친소(시설친구를소개합니다.)' 3회" },
		{ year: '2017.11', event: '탈시설안내책자 및 사례집 발간' },
		{ year: '2017.11', event: '2017 전국장애인전동휠체어축구대회 우승' },
		{ year: '2018.05', event: '지방선거 정당 정책토론회 주관' },
		{ year: '2018.07', event: '인천시 지원 자립생활주택3호 위탁기관 지정' },
		{ year: '2018.10', event: '경인지역 장애인전동휠체어축구대회 준우승' },
		{ year: '2018.10.10~12', event: "탈시설캠프 '시친소(시설친구를소개합니다.)' 4회" },
		{ year: '2019.01.07', event: '인천 중증장애인자립생활센터 지원사업 위탁기관 협약 체결' },
		{ year: '2019.02.11', event: '2019 장애포럼 참석' },
		{ year: '2019.03.01', event: '정태수열사상 수상(정명호 권익옹호팀 팀장)' },
		{ year: '2019.06.17', event: '고 권오진 동지 1주기 추모제' },
		{ year: '2019.07.01', event: '장애등급제 진짜 폐지 전동행진 참여' },
		{ year: '2019.09.18~19', event: '2019 전동휠체어축구 전국대회 개최' },
		{ year: '2019.09.18~19', event: '2019 전동휠체어축구 전국대회 4위 입상' },
		{ year: '2019.09.30~10.02', event: "탈시설캠프 '시친소(시설친구를소개합니다.)' 5회" },
		{ year: '2019.12.06~07', event: '자립생활대회(인천, 강원, 서울 센터 기관 모임)' },
		{ year: '2019.12.26', event: '권익옹호 활동가워크숍' },
		{ year: '2020.01.21', event: '민들레장애인자립생활센터 정기총회' },
		{ year: '2020.02.23', event: '고 한민희 동지 추모제' },
		{ year: '2020.04.08', event: '고 한민희 동지 49제' },
		{ year: '2020.06.17', event: '고 권오진 동지 2주기 추모제' },
		{ year: '2021.04', event: '인천장애인체육회 생활체육지원사업(동호인클럽) 선정' },
		{ year: '2021.06.01', event: '소장: 양준호' },
		{ year: '2021.06.11', event: '케어114 업무협약 체결' },
		{ year: '2021.07.08', event: '연세힐링맘 상담센터 업무협약 체결' },
		{ year: '2022.05.08', event: '고 김은경 동지 기일' },
		{ year: '2023.07.09', event: '고 김은아 동지 기일' },
		{ year: '2024.03.12', event: '소장: 박길연 취임(법인대표 겸임)' },
		{ year: '2025.01.01', event: '소장: 서권일 취임' }
	];

	// 주요사업
	const services = [
		{
			title: 'IL사업',
			description: '동료상담, 권익옹호활동, 정보제공, 자조모임 등 다양한 사업기획 및 지원',
			image:
				'./images/about/mosa98dr3Z.jpeg'
		},
		{
			title: '자립지원사업',
			description: '탈시설 및 탈재가장애인의 자립생활전환으로 거주공간을 마련, 자립생활기술 습득',
			image:
				'./images/about/mosaL1e4NQ.jpeg'
		},
		{
			title: '활동지원사업',
			description: '장애인이 지역사회에서 사회구성원으로 동등하게 살아갈 수 있도록 활동지원사 파견',
			image:
				'./images/about/mosaZxU8EE.jpeg'
		},
		{
			title: '기타',
			description: '차별상담전화, 보장구수리 및 점검, 회원교육, 명절행사, 투쟁활동참여',
			image:
				'./images/about/mosa7psFmt.jpeg'
		}
	];

	// SNS 정보
	const snsInfo = [
		{
			title: '유튜브(Youtube)',
			description: "'민들레장애인자립생활센터'를 검색해주세요.",
			image:
				'./images/about/mosa7xtBCY.png'
		},
		{
			title: '카카오톡플러스친구',
			description: "카카오톡 친구추가에서 '민들레장애인자립생활센터'를 검색해주세요.",
			image:
				'./images/about/mosa2p4VoB.png'
		}
	];

	import MapEmbed from '$lib/components/about/MapEmbed.svelte';
	import { onMount } from 'svelte';
	let mapContainer: HTMLDivElement | null = null;

	function loadKakaoMap() {
		const width = mapContainer?.offsetWidth || 640;
		const height = Math.round(width * 9 / 16);
		// 기존 roughmap이 있으면 제거(중복 방지)
		const oldMap = document.getElementById('daumRoughmapContainer1751856074840');
		if (oldMap) oldMap.innerHTML = '';
		// 스크립트가 이미 있으면 실행만, 없으면 삽입
		if (!window['daum'] || !window['daum'].roughmap) {
			const script = document.createElement('script');
			script.src = 'https://ssl.daumcdn.net/dmaps/map_js_init/roughmapLoader.js';
			script.charset = 'UTF-8';
			script.onload = () => {
				new window['daum'].roughmap.Lander({
					"timestamp": "1751856074840",
					"key": "58zax7beg8c",
					"mapWidth": width,
					"mapHeight": height
				}).render();
			};
			document.body.appendChild(script);
		} else {
			new window['daum'].roughmap.Lander({
				"timestamp": "1751856074840",
				"key": "58zax7beg8c",
				"mapWidth": width,
				"mapHeight": height
			}).render();
		}
	}

	onMount(() => {
		loadKakaoMap();
		window.addEventListener('resize', loadKakaoMap);
		return () => window.removeEventListener('resize', loadKakaoMap);
	});
</script>

<svelte:head>
	<title>민들레는요 - {organizationInfo.name}</title>
	<meta name="description" content={organizationInfo.description} />
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- 히어로 섹션 -->
	<section class="relative bg-gradient-to-r from-lime-600 to-lime-800 py-20 text-white">
		<div>
			<div class="mx-auto max-w-4xl text-center">
				<h1 class="mb-6 text-4xl font-bold md:text-6xl">민들레는요</h1>
				<p class="mb-8 text-xl opacity-90 md:text-2xl">
					{organizationInfo.description}
				</p>
				<div class="flex flex-wrap justify-center gap-8 text-center">
					<div>
						<div class="text-3xl font-bold">{organizationInfo.established}</div>
						<div class="text-sm opacity-80">설립</div>
					</div>
					<div>
						<div class="text-3xl font-bold">17년+</div>
						<div class="text-sm opacity-80">운영</div>
					</div>
					<div>
						<div class="text-3xl font-bold">4개</div>
						<div class="text-sm opacity-80">주요사업</div>
					</div>
				</div>
			</div>
		</div>
	</section>

	<div class="py-12 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<!-- 메인 이미지 -->
		<section class="mb-16">
			<div class="overflow-hidden rounded-lg bg-white shadow-md">
				<img
					src="./images/about/hero_bg.jpeg"
					alt="민들레장애인자립생활센터"
					class="h-64 w-full object-cover md:h-96"
				/>
			</div>
		</section>

		<!-- 연혁 -->
		<section class="mb-16">
			<div class="mb-12 text-center">
				<h2 class="mb-4 text-3xl font-bold text-lime-700">연혁</h2>
				<p class="mx-auto max-w-2xl text-gray-600">
					2008년 설립 이후 지속적인 성장과 발전을 이어가고 있습니다.
				</p>
			</div>
			<div class="rounded-lg bg-white p-8 shadow-md">
				<div class="space-y-4 ">
					{#each history as item}
						<div class="flex items-start gap-4 rounded-lg p-3 transition-colors hover:bg-gray-50">
							<div class="w-24 flex-shrink-0 text-sm font-semibold text-lime-600">
								{item.year}
							</div>
							<div class="flex-1">
								<div class="font-medium text-gray-900">{item.event}</div>
								{#if item.detail}
									<div class="mt-1 text-sm text-gray-600">{item.detail}</div>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			</div>
		</section>

		<!-- 주요사업 -->
		<section class="mb-16">
			<div class="mb-12 text-center">
				<h2 class="mb-4 text-3xl font-bold text-lime-700">주요사업</h2>
				<p class="mx-auto max-w-2xl text-gray-600">
					장애인의 자립생활을 위한 다양한 사업을 운영하고 있습니다.
				</p>
			</div>
			<div class="space-y-8">
				{#each services as service, index}
					<div class="overflow-hidden rounded-lg bg-white shadow-md">
						<div class="flex flex-col md:flex-row">
							{#if index % 2 === 0}
								<!-- 이미지가 왼쪽 -->
								<div class="md:w-1/3">
									<img
										src={service.image}
										alt={service.title}
										class="h-48 w-full object-cover md:h-full"
									/>
								</div>
								<div class="flex items-center p-6 md:w-2/3">
									<div>
										<h3 class="mb-3 text-2xl font-bold text-lime-700">{service.title}</h3>
										<p class="leading-relaxed text-gray-700">{service.description}</p>
									</div>
								</div>
							{:else}
								<!-- 이미지가 오른쪽 -->
								<div class="flex items-center p-6 md:w-2/3">
									<div>
										<h3 class="mb-3 text-2xl font-bold text-lime-700">{service.title}</h3>
										<p class="leading-relaxed text-gray-700">{service.description}</p>
									</div>
								</div>
								<div class="md:w-1/3">
									<img
										src={service.image}
										alt={service.title}
										class="h-48 w-full object-cover md:h-full"
									/>
								</div>
							{/if}
						</div>
					</div>
				{/each}
			</div>
		</section>

		<!-- 위치 -->
		<section class="mb-16">
			<div class="mb-12 text-center">
				<h2 class="mb-4 text-3xl font-bold text-lime-700">위치</h2>
				<p class="mx-auto max-w-2xl text-gray-600">민들레장애인자립생활센터의 위치를 확인하세요.</p>
			</div>
			<MapEmbed />
		</section>

		<!-- SNS 안내 -->
		<section class="mb-16">
			<div class="mb-12 text-center">
				<h2 class="mb-4 text-3xl font-bold text-lime-700">SNS 안내</h2>
				<p class="mx-auto max-w-2xl text-gray-600">
					다양한 소셜미디어를 통해 민들레의 소식을 받아보세요.
				</p>
			</div>
			<div class="grid gap-8 md:grid-cols-2">
				{#each snsInfo as sns}
					<div class="overflow-hidden rounded-lg bg-white shadow-md">
						<div class="flex items-center p-6">
							<div class="mr-6 flex-shrink-0">
								<img src={sns.image} alt={sns.title} class="h-20 w-20 rounded-lg object-cover" />
							</div>
							<div class="flex-1">
								<h3 class="mb-2 text-xl font-bold text-lime-700">{sns.title}</h3>
								<p class="text-gray-700">{sns.description}</p>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<!-- 연락처 정보 -->
		<section class="mb-16">
			<div class="rounded-lg border border-lime-200 bg-lime-50 p-8">
				<h3 class="mb-6 text-2xl font-bold text-lime-700">연락처 정보</h3>
				<p class="mb-6 text-gray-600">궁금한 점이 있으시면 언제든 연락주세요.</p>
				<div class="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
					<div class="flex items-center gap-3">
						<div class="flex h-5 w-5 items-center justify-center rounded-full bg-lime-600">
							<span class="text-xs text-white">📍</span>
						</div>
						<div>
							<div class="font-medium">주소</div>
							<div class="text-sm text-gray-600">{organizationInfo.address}</div>
						</div>
					</div>
					<div class="flex items-center gap-3">
						<div class="flex h-5 w-5 items-center justify-center rounded-full bg-lime-600">
							<span class="text-xs text-white">📞</span>
						</div>
						<div>
							<div class="font-medium">전화</div>
							<div class="text-sm text-gray-600">{organizationInfo.phone}</div>
						</div>
					</div>
					<div class="flex items-center gap-3">
						<div class="flex h-5 w-5 items-center justify-center rounded-full bg-lime-600">
							<span class="text-xs text-white">✉️</span>
						</div>
						<div>
							<div class="font-medium">이메일</div>
							<div class="text-sm text-gray-600">{organizationInfo.email}</div>
						</div>
					</div>
					<div class="flex items-center gap-3">
						<div class="flex h-5 w-5 items-center justify-center rounded-full bg-lime-600">
							<span class="text-xs text-white">🌐</span>
						</div>
						<div>
							<div class="font-medium">웹사이트</div>
							<div class="text-sm text-gray-600">{organizationInfo.website}</div>
						</div>
					</div>
				</div>
			</div>
		</section>

		<!-- 봉사 참여 CTA -->
		<!-- <section class="text-center">
			<div class="rounded-lg bg-gradient-to-r from-lime-600 to-lime-800 p-12 text-white">
				<h2 class="mb-4 text-3xl font-bold">함께 봉사에 참여해보세요</h2>
				<p class="mb-8 text-xl opacity-90">작은 관심과 참여가 큰 변화를 만들어갑니다.</p>
				<div class="flex flex-col justify-center gap-4 sm:flex-row">
					<a
						href="/volunteer"
						class="inline-block rounded-lg bg-white px-8 py-3 font-semibold text-lime-600 transition-colors hover:bg-gray-100"
					>
						봉사 신청하기
					</a>
					<a
						href="/contact"
						class="inline-block rounded-lg border-2 border-white px-8 py-3 font-semibold text-white transition-colors hover:bg-white hover:text-lime-600"
					>
						문의하기
					</a>
				</div>
			</div>
		</section> -->
	</div>
</div>
