<script lang="ts">
	// 사업 데이터
	const services = [
		{
			title: 'IL지원사업',
			image: './images/services/mosa9QigoB.png',
			sections: [
				{
					subtitle: 'IL지원사업이란?',
					content: `장애인자립생활을 위한 법률과 지자체 조례에 근거하여 장애인이 지역사회에서 자립생활을 영위할 수 있도록 지자체로부터 지원받아 시행하는 지원 사업입니다. IL지원사업은 아래 항목으로 세부적으로 나누어서 진행하고 있습니다.`
				},
				{
					subtitle: '문의',
					content: `<strong>이건호(IL사업 팀장/동료상담가)</strong> <a href="tel:070-7865-1240" class="text-lime-700 underline">070-7865-1240</a>`
				},
				{
					subtitle: '권익옹호사업',
					content: `장애인의 권익증진을 위한 사업 및 캠페인 진행<br/>24년 기준: 요기어때(계양구 내 휠체어 이용 가능 업체 모니터링), 장애이해교육(직장, 대학생 등 대상), 권익옹호스터디(열사학교)`
				},
				{
					subtitle: '동료상담',
					content: `개별동료상담과 장애인복지 및 정책 제도 관련 정보제공, 동료상담양성 프로그램 진행<br/>24년 기준: 개별동료상담, 정보제공(달력, 소식지 제작)`
				},
				{
					subtitle: '개인별자립지원',
					content: `자립생활에 필요한 실질적인 교육과 사회활동 등을 지원<br/>24년 기준: 사례지원(다양한 욕구기반 장애인 상담 및 경제적 지원), 자조모임(6개 자조모임 운영), 무엇이든 배워보세요(현실 가이드 교육), 모여락(문화체험), 사례지원(지속적 사례관리)`
				},
				{
					subtitle: '탈시설지원',
					content: `지역사회 탈시설을 고민하는 장애인들을 위한 사업 진행<br/>24년 기준: 시친소(멘티 멘토 캠프), 자립생활교육(실생활 교육)`
				},
				{
					subtitle: '선택사업',
					content: `문화여가체육 활동의 주제로 한 특화 프로그램 진행<br/>24년 기준: 감정해방힐링여행(개인여행 지원), 토론회(정책 토론회), 파워사커대회(전동휠체어 축구 대회)`
				}
			]
		},
		{
			title: '자립(생활)주택 운영',
			image: './images/services/17168820772013523_7KCc66qp7J2E7J6F66Cl7ZW07KO87IS47JqU_00114.jpeg',
			sections: [
				{
					subtitle: '사업소개',
					content: `민들레장애인자립생활센터에서는 장애인의 자립생활을 위한 주택을 운영하고 있습니다.`
				},
				{
					subtitle: '모집대상',
					content: `인천광역시에 거주 중인 자립생활을 원하는 19세 이상 장애인(재가 장애인, 시설장애인)`
				},
				{
					subtitle: '모집인원',
					content: `주택별 상이(남녀 각각 개별 입주)`
				},
				{
					subtitle: '주요내용',
					content: `주택위치: 계양구 관내(아파트, 빌라)<br/>입주기간: 최대5년(생활주택 2년, 자립주택 5년)<br/>지원내용: 자립생활기술훈련, 자립생활 지원, 임대료, 공과금, 프로그램 경비 등(식비, 소모품비 등 일상생활비용은 개인 지출)`
				},
				{
					subtitle: '입주절차',
					content: `신청서 제출(구청) → 초기상담 → 구청 면접 → 최종 발표`
				},
				{
					subtitle: '문의사항',
					content: `남성문의 <a href="tel:070-7865-1245" class="text-lime-700 underline">070-7865-1245</a> / 조기석<br/>여성문의 <a href="tel:070-7865-1242" class="text-lime-700 underline">070-7865-1242</a> / 정유숙`
				}
			]
		},
		{
			title: '활동지원사업',
			image: './images/services/mosa2E9XQc.png',
			sections: [
				{
					subtitle: '장애인활동지원서비스란?',
					content: `장애로 인한 일상생활의 어려움을 갖고 있는 장애인과 그 가족을 지원하기 위한 사회서비스입니다. 이용자는 신체지원, 가사지원, 사회활동영역 등을 기관에서 파견된 활동지원사를 통해 서비스 제공받습니다.`
				},
				{
					subtitle: '신청자격',
					content: `만 6세 이상~만 65세 미만 장애인복지법상 등록장애인(소득수준 무관)<br/>제외대상: 장애인시설 입소자(퇴거예정자 사전신청 허용), 장기요양급여 수급자(예외 가능), 의료기관 30일 이상 입원자, 교정/치료감호시설 수용자, 기타 돌봄서비스 급여 수급자`
				},
				{
					subtitle: '신청방법',
					content: `방문신청: 주소지 읍면동(우편 가능)<br/>온라인: 복지로(www.bokjiro.go.kr)`
				},
				{
					subtitle: '신청서류',
					content: `주민센터 방문: 사회보장급여 신청서, 바우처카드 발급 신청서<br/>의료기관: 장애정도 심사용 진단서, 장애유형별 소견서/임상심리평가보고서(필요시)<br/>기타: 4대보험가입내역, 재학증명서, 가족관계증명서 등`
				},
				{
					subtitle: '신청절차',
					content: `1) 읍면동 문의(유선) → 2) 의료기관 서류 발급 → 3) 기타서류 구비 → 4) 주민센터 신청`
				},
				{
					subtitle: '선정절차',
					content: `신청 → 자료송부 → 방문조사 → 자격심사 → 최종선정`
				},
				{
					subtitle: '문의',
					content: `<a href="tel:032-556-9294" class="text-lime-700 underline">032-556-9294</a> (활동지원팀)`
				}
			]
		},
		{
			title: '기타 및 회원사업',
			image: './images/services/mosapHYVfp.jpeg',
			sections: [
				{
					subtitle: '회원사업이란?',
					content: `센터에 회비를 납부하여 총회 회원 또는 후원회원 자격을 갖춘 분들을 위한 사업입니다. (문의: <a href="tel:032-542-9294" class="text-lime-700 underline">032-542-9294</a>)`
				},
				{
					subtitle: '보장구 관련',
					content: `보장구 수리: 케어114와 협약, 매월 기관 방문 수리<br/>보장구 대여: 전동휠체어, 시각장애인 안내 지팡이, 수동 휠체어 등 대여 지원`
				},
				{
					subtitle: '행사 관련',
					content: `명절행사: 설·추석 합동 차례, 음식 나누기<br/>후원행사: 정회원·후원자 감사 증정품<br/>추모행사: 기일 맞춰 추모행사<br/>소풍·나들이: 회원·후원자와 소풍, 캠프(코로나 여부에 따라 상이)`
				},
				{
					subtitle: '회원교육',
					content: `장애인 인권 및 사회적 현상 교육 등 다양한 주제 교육`
				},
				{
					subtitle: '권익옹호 활동',
					content: `장애인 차별상담전화 운영, 편의시설 조사, 정책제안 등 인권 현장 활동`
				}
			]
		}
	];
</script>

<svelte:head>
	<title>주요사업 - 민들레장애인자립생활센터</title>
	<meta name="description" content="민들레장애인자립생활센터의 주요사업 안내" />
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<section class="py-12 max-w-7xl mx-auto">
		<h1 class="mb-12 text-center text-4xl font-bold text-lime-700">주요사업 안내</h1>
		<div class="space-y-16">
			{#each services as service, idx}
				<div class="overflow-hidden rounded-lg bg-white shadow-md">
					<div class="flex flex-col md:flex-row">
						{#if idx % 2 === 0}
							<div class="md:w-1/3">
								<img src={service.image} alt={service.title} class="h-64 w-full object-cover md:h-full" />
							</div>
							<div class="flex items-center p-8 md:w-2/3">
								<div>
									<h2 class="mb-4 text-3xl font-bold text-lime-700">{service.title}</h2>
									{#each service.sections as section}
										{#if section.subtitle}
											<h3 class="text-xl font-semibold text-lime-600 mt-6 mb-2">{section.subtitle}</h3>
										{/if}
										{#if section.content}
											<div class="text-base text-gray-700 leading-relaxed">{@html section.content}</div>
										{/if}
									{/each}
								</div>
							</div>
						{:else}
							<div class="flex items-center p-8 md:w-2/3">
								<div>
									<h2 class="mb-4 text-3xl font-bold text-lime-700">{service.title}</h2>
									{#each service.sections as section}
										{#if section.subtitle}
											<h3 class="text-xl font-semibold text-lime-600 mt-6 mb-2">{section.subtitle}</h3>
										{/if}
										{#if section.content}
											<div class="text-base text-gray-700 leading-relaxed">{@html section.content}</div>
										{/if}
									{/each}
								</div>
							</div>
							<div class="md:w-1/3">
								<img src={service.image} alt={service.title} class="h-64 w-full object-cover md:h-full" />
							</div>
						{/if}
					</div>
				</div>
			{/each}
		</div>
	</section>
</div>
