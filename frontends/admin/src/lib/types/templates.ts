import type { Block } from './blocks';

export interface PageTemplate {
	id: string;
	name: string;
	description: string;
	category: 'basic' | 'content' | 'service' | 'about' | 'location';
	thumbnail: string;
	blocks: Block[];
	previewHtml?: string;
}

export const PAGE_TEMPLATES: PageTemplate[] = [
	{
		id: 'blank',
		name: '빈 페이지',
		description: '빈 페이지에서 시작하여 자유롭게 구성',
		category: 'basic',
		thumbnail: '/admin-assets/templates/blank.png',
		blocks: []
	},
	{
		id: 'basic-content',
		name: '기본 콘텐츠',
		description: '제목, 소개글, 본문으로 구성된 기본 페이지',
		category: 'basic',
		thumbnail: '/admin-assets/templates/basic-content.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '페이지 제목을 입력하세요',
				order: 0
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '이 페이지에 대한 간단한 소개를 작성해주세요.',
				order: 1
			},
			{
				id: 'divider-1',
				type: 'divider',
				order: 2
			},
			{
				id: 'heading-2',
				type: 'heading',
				level: 2,
				content: '주요 내용',
				order: 3
			},
			{
				id: 'paragraph-2',
				type: 'paragraph',
				content: '여기에 페이지의 주요 내용을 작성해주세요. 여러 문단으로 나누어서 작성할 수 있습니다.',
				order: 4
			}
		]
	},
	{
		id: 'service-intro',
		name: '서비스 소개',
		description: '서비스나 프로그램 소개에 적합한 구성',
		category: 'service',
		thumbnail: '/admin-assets/templates/service-intro.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '서비스명',
				order: 0
			},
			{
				id: 'quote-1',
				type: 'quote',
				content: '우리 서비스의 핵심 가치나 미션을 한 줄로 표현해보세요.',
				order: 1
			},
			{
				id: 'image-1',
				type: 'image',
				src: 'https://via.placeholder.com/800x400?text=서비스+대표+이미지',
				alt: '서비스 대표 이미지',
				caption: '서비스를 잘 보여주는 대표 이미지',
				order: 2
			},
			{
				id: 'heading-2',
				type: 'heading',
				level: 2,
				content: '서비스 개요',
				order: 3
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '서비스에 대한 전반적인 설명을 작성해주세요.',
				order: 4
			},
			{
				id: 'heading-3',
				type: 'heading',
				level: 2,
				content: '주요 특징',
				order: 5
			},
			{
				id: 'list-1',
				type: 'list',
				style: 'unordered',
				items: [
					'특징 1: 구체적인 장점 설명',
					'특징 2: 다른 서비스와의 차별점',
					'특징 3: 사용자가 얻을 수 있는 혜택'
				],
				order: 6
			}
		]
	},
	{
		id: 'about-us',
		name: '단체 소개',
		description: '단체나 조직 소개에 적합한 구성',
		category: 'about',
		thumbnail: '/admin-assets/templates/about-us.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '단체 소개',
				order: 0
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '우리 단체에 대한 간단한 소개 문구를 작성해주세요.',
				order: 1
			},
			{
				id: 'image-1',
				type: 'image',
				src: 'https://via.placeholder.com/600x300?text=단체+사진',
				alt: '단체 사진',
				caption: '함께하는 우리의 모습',
				order: 2
			},
			{
				id: 'heading-2',
				type: 'heading',
				level: 2,
				content: '설립 목적',
				order: 3
			},
			{
				id: 'paragraph-2',
				type: 'paragraph',
				content: '단체의 설립 목적과 비전을 설명해주세요.',
				order: 4
			},
			{
				id: 'heading-3',
				type: 'heading',
				level: 2,
				content: '주요 활동',
				order: 5
			},
			{
				id: 'list-1',
				type: 'list',
				style: 'ordered',
				items: [
					'주요 활동 1',
					'주요 활동 2',
					'주요 활동 3'
				],
				order: 6
			},
			{
				id: 'heading-4',
				type: 'heading',
				level: 2,
				content: '연혁',
				order: 7
			},
			{
				id: 'paragraph-3',
				type: 'paragraph',
				content: '단체의 주요한 발전 과정이나 이정표를 소개해주세요.',
				order: 8
			}
		]
	},
	{
		id: 'faq',
		name: '자주 묻는 질문',
		description: 'FAQ 형태의 질문과 답변 구성',
		category: 'content',
		thumbnail: '/admin-assets/templates/faq.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '자주 묻는 질문',
				order: 0
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '자주 문의하시는 내용들을 정리했습니다. 궁금한 점이 있으시면 참고해주세요.',
				order: 1
			},
			{
				id: 'divider-1',
				type: 'divider',
				order: 2
			},
			{
				id: 'heading-2',
				type: 'heading',
				level: 3,
				content: 'Q. 첫 번째 질문을 입력하세요',
				order: 3
			},
			{
				id: 'paragraph-2',
				type: 'paragraph',
				content: 'A. 첫 번째 질문에 대한 답변을 작성해주세요.',
				order: 4
			},
			{
				id: 'heading-3',
				type: 'heading',
				level: 3,
				content: 'Q. 두 번째 질문을 입력하세요',
				order: 5
			},
			{
				id: 'paragraph-3',
				type: 'paragraph',
				content: 'A. 두 번째 질문에 대한 답변을 작성해주세요.',
				order: 6
			},
			{
				id: 'heading-4',
				type: 'heading',
				level: 3,
				content: 'Q. 세 번째 질문을 입력하세요',
				order: 7
			},
			{
				id: 'paragraph-4',
				type: 'paragraph',
				content: 'A. 세 번째 질문에 대한 답변을 작성해주세요.',
				order: 8
			}
		]
	},
	{
		id: 'contact-info',
		name: '연락처 정보',
		description: '연락처와 오시는 길 정보 구성',
		category: 'content',
		thumbnail: '/admin-assets/templates/contact-info.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '연락처 정보',
				order: 0
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '언제든지 연락 주시면 친절하게 안내해드리겠습니다.',
				order: 1
			},
			{
				id: 'heading-2',
				type: 'heading',
				level: 2,
				content: '기본 정보',
				order: 2
			},
			{
				id: 'list-1',
				type: 'list',
				style: 'unordered',
				items: [
					'📞 전화번호: 000-0000-0000',
					'📧 이메일: info@example.com',
					'🏢 주소: 서울시 ○○구 ○○동 000-00',
					'🕒 운영시간: 평일 09:00 - 18:00'
				],
				order: 3
			},
			{
				id: 'heading-3',
				type: 'heading',
				level: 2,
				content: '오시는 길',
				order: 4
			},
			{
				id: 'paragraph-2',
				type: 'paragraph',
				content: '대중교통이나 자가용 이용 시 오시는 길을 안내해주세요.',
				order: 5
			},
			{
				id: 'map-1',
				type: 'map',
				address: '서울시 중구 명동 100-1',
				latitude: 37.5638,
				longitude: 126.9824,
				width: 600,
				height: 400,
				zoom: 3,
				title: '오시는 길',
				order: 6
			}
		]
	},
	{
		id: 'location-guide',
		name: '위치 안내',
		description: '카카오 지도와 상세한 위치 정보',
		category: 'location',
		thumbnail: '/admin-assets/templates/location-guide.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '찾아오시는 길',
				order: 0
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '저희 센터로 오시는 길을 안내해드립니다. 대중교통 이용 시 더욱 편리하게 방문하실 수 있습니다.',
				order: 1
			},
			{
				id: 'map-1',
				type: 'map',
				address: '서울시 강남구 역삼동 735-1',
				latitude: 37.5009,
				longitude: 127.0372,
				width: 700,
				height: 450,
				zoom: 2,
				title: '센터 위치',
				order: 2
			},
			{
				id: 'heading-2',
				type: 'heading',
				level: 2,
				content: '대중교통 이용 안내',
				order: 3
			},
			{
				id: 'list-1',
				type: 'list',
				style: 'unordered',
				items: [
					'🚇 지하철 2호선 강남역 3번 출구에서 도보 5분',
					'🚌 버스 146, 360, 740번 강남역 정류장 하차',
					'🚗 주차 공간이 제한적이니 대중교통 이용을 권합니다'
				],
				order: 4
			},
			{
				id: 'heading-3',
				type: 'heading',
				level: 2,
				content: '연락처',
				order: 5
			},
			{
				id: 'paragraph-2',
				type: 'paragraph',
				content: '방문 전 미리 연락주시면 더욱 원활한 상담이 가능합니다.',
				order: 6
			},
			{
				id: 'list-2',
				type: 'list',
				style: 'unordered',
				items: [
					'📞 전화: 02-1234-5678',
					'📧 이메일: info@center.or.kr',
					'🕒 운영시간: 평일 09:00~18:00'
				],
				order: 7
			}
		]
	},
	{
		id: 'feature-showcase',
		name: '기능 소개',
		description: '그리드 레이아웃으로 기능들을 소개',
		category: 'content',
		thumbnail: '/admin-assets/templates/feature-showcase.png',
		blocks: [
			{
				id: 'heading-1',
				type: 'heading',
				level: 1,
				content: '주요 기능',
				order: 0
			},
			{
				id: 'paragraph-1',
				type: 'paragraph',
				content: '저희 센터에서 제공하는 다양한 서비스와 기능들을 소개합니다.',
				order: 1
			},
			{
				id: 'grid-1',
				type: 'grid',
				columns: [
					{
						id: 'col-1',
						width: 4,
						widthTablet: 6,
						widthMobile: 12,
						blocks: [
							{
								id: 'heading-2',
								type: 'heading',
								level: 3,
								content: '상담 서비스',
								order: 0
							},
							{
								id: 'paragraph-2',
								type: 'paragraph',
								content: '전문 상담사가 1:1 맞춤 상담을 제공합니다.',
								order: 1
							}
						]
					},
					{
						id: 'col-2',
						width: 4,
						widthTablet: 6,
						widthMobile: 12,
						blocks: [
							{
								id: 'heading-3',
								type: 'heading',
								level: 3,
								content: '교육 프로그램',
								order: 0
							},
							{
								id: 'paragraph-3',
								type: 'paragraph',
								content: '다양한 교육 과정과 워크숍을 운영합니다.',
								order: 1
							}
						]
					},
					{
						id: 'col-3',
						width: 4,
						widthTablet: 12,
						widthMobile: 12,
						blocks: [
							{
								id: 'heading-4',
								type: 'heading',
								level: 3,
								content: '커뮤니티 활동',
								order: 0
							},
							{
								id: 'paragraph-4',
								type: 'paragraph',
								content: '함께하는 다양한 활동과 모임을 진행합니다.',
								order: 1
							}
						]
					}
				],
				gap: 6,
				alignment: 'start',
				order: 2
			},
			{
				id: 'heading-5',
				type: 'heading',
				level: 2,
				content: '더 자세한 정보',
				order: 3
			},
			{
				id: 'grid-2',
				type: 'grid',
				columns: [
					{
						id: 'col-4',
						width: 8,
						widthTablet: 12,
						widthMobile: 12,
						blocks: [
							{
								id: 'paragraph-5',
								type: 'paragraph',
								content: '각 서비스에 대한 자세한 내용은 개별 페이지에서 확인하실 수 있습니다. 궁금한 사항이 있으시면 언제든지 연락주세요.',
								order: 0
							}
						]
					},
					{
						id: 'col-5',
						width: 4,
						widthTablet: 12,
						widthMobile: 12,
						blocks: [
							{
								id: 'list-1',
								type: 'list',
								style: 'unordered',
								items: [
									'전화 상담 가능',
									'온라인 예약 시스템',
									'맞춤형 서비스 제공'
								],
								order: 0
							}
						]
					}
				],
				gap: 4,
				alignment: 'start',
				order: 4
			}
		]
	}
];

export const TEMPLATE_CATEGORIES = [
	{ id: 'basic', name: '기본' },
	{ id: 'content', name: '콘텐츠' },
	{ id: 'service', name: '서비스' },
	{ id: 'about', name: '소개' },
	{ id: 'location', name: '위치/지도' }
] as const;