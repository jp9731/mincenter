import type { BlockTemplate, TemplateCategory } from '$lib/types/blocks';
import { v4 as uuidv4 } from 'uuid';

// 기본 블록 생성 헬퍼 함수
function createBlock(type: string, content: any, order: number) {
  return {
    id: uuidv4(),
    type,
    order,
    ...content
  };
}

export const defaultTemplates: BlockTemplate[] = [
  // 헤로 섹션 템플릿
  {
    id: 'hero-section',
    name: '헤로 섹션',
    description: '메인 제목과 설명, CTA 버튼이 포함된 헤로 섹션',
    category: 'layout',
    blocks: [
      createBlock('heading', { level: 1, content: '환영합니다', styles: { fontSize: '5xl', fontWeight: 'bold', textAlign: 'center' } }, 0),
      createBlock('paragraph', { content: '멋진 콘텐츠를 시작해보세요. 이 템플릿은 메인 제목과 설명, 그리고 행동 유도 버튼을 포함합니다.', styles: { fontSize: 'lg', textAlign: 'center', textColor: 'text-gray-600' } }, 1),
      createBlock('button', { 
        text: '시작하기', 
        link: { url: '#', target: '_self' },
        styles: { variant: 'primary', size: 'lg', textAlign: 'center', width: 'fit' }
      }, 2)
    ],
    tags: ['hero', 'main', 'cta']
  },

  // 소개 섹션 템플릿
  {
    id: 'intro-section',
    name: '소개 섹션',
    description: '제목, 설명, 이미지가 포함된 소개 섹션',
    category: 'content',
    blocks: [
      createBlock('heading', { level: 2, content: '우리에 대해', styles: { fontSize: '3xl', fontWeight: 'semibold' } }, 0),
      createBlock('paragraph', { content: '우리는 혁신적인 솔루션을 제공하는 전문 팀입니다. 고객의 요구사항을 정확히 파악하고 최적의 결과를 만들어냅니다.', styles: { fontSize: 'base', lineHeight: 'relaxed' } }, 1),
      createBlock('image', { src: '/images/placeholder.jpg', alt: '팀 소개 이미지', caption: '우리 팀의 모습' }, 2)
    ],
    tags: ['intro', 'about', 'team']
  },

  // 기능 소개 템플릿
  {
    id: 'features-section',
    name: '기능 소개',
    description: '3개 컬럼으로 구성된 기능 소개 섹션',
    category: 'layout',
    blocks: [
      createBlock('heading', { level: 2, content: '주요 기능', styles: { fontSize: '3xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
      createBlock('grid', { 
        columns: [
          {
            id: uuidv4(),
            width: 4,
            blocks: [
              createBlock('heading', { level: 3, content: '빠른 속도', styles: { fontSize: 'xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
              createBlock('paragraph', { content: '최적화된 성능으로 빠른 로딩 속도를 제공합니다.', styles: { textAlign: 'center' } }, 1)
            ]
          },
          {
            id: uuidv4(),
            width: 4,
            blocks: [
              createBlock('heading', { level: 3, content: '안전성', styles: { fontSize: 'xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
              createBlock('paragraph', { content: '엄격한 보안 기준을 통해 안전한 서비스를 제공합니다.', styles: { textAlign: 'center' } }, 1)
            ]
          },
          {
            id: uuidv4(),
            width: 4,
            blocks: [
              createBlock('heading', { level: 3, content: '사용 편의성', styles: { fontSize: 'xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
              createBlock('paragraph', { content: '직관적인 인터페이스로 누구나 쉽게 사용할 수 있습니다.', styles: { textAlign: 'center' } }, 1)
            ]
          }
        ],
        gap: 6
      }, 1)
    ],
    tags: ['features', 'grid', '3-column']
  },

  // 가격표 템플릿
  {
    id: 'pricing-section',
    name: '가격표',
    description: '2개 컬럼으로 구성된 가격표 섹션',
    category: 'layout',
    blocks: [
      createBlock('heading', { level: 2, content: '요금제', styles: { fontSize: '3xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
      createBlock('grid', { 
        columns: [
          {
            id: uuidv4(),
            width: 6,
            blocks: [
              createBlock('heading', { level: 3, content: '기본 플랜', styles: { fontSize: '2xl', fontWeight: 'bold', textAlign: 'center' } }, 0),
              createBlock('paragraph', { content: '₩29,000/월', styles: { fontSize: 'xl', fontWeight: 'bold', textAlign: 'center', textColor: 'text-blue-600' } }, 1),
              createBlock('list', { style: 'unordered', items: ['기본 기능', '이메일 지원', '5GB 저장공간'] }, 2),
              createBlock('button', { 
                text: '시작하기', 
                link: { url: '#', target: '_self' },
                styles: { variant: 'outline', size: 'md', textAlign: 'center', width: 'full' }
              }, 3)
            ]
          },
          {
            id: uuidv4(),
            width: 6,
            blocks: [
              createBlock('heading', { level: 3, content: '프리미엄 플랜', styles: { fontSize: '2xl', fontWeight: 'bold', textAlign: 'center' } }, 0),
              createBlock('paragraph', { content: '₩59,000/월', styles: { fontSize: 'xl', fontWeight: 'bold', textAlign: 'center', textColor: 'text-blue-600' } }, 1),
              createBlock('list', { style: 'unordered', items: ['모든 기본 기능', '우선 지원', '무제한 저장공간', '고급 기능'] }, 2),
              createBlock('button', { 
                text: '시작하기', 
                link: { url: '#', target: '_self' },
                styles: { variant: 'primary', size: 'md', textAlign: 'center', width: 'full' }
              }, 3)
            ]
          }
        ],
        gap: 6
      }, 1)
    ],
    tags: ['pricing', 'plans', '2-column']
  },

  // 문의 섹션 템플릿
  {
    id: 'contact-section',
    name: '문의 섹션',
    description: '연락처 정보와 문의 버튼이 포함된 섹션',
    category: 'interactive',
    blocks: [
      createBlock('heading', { level: 2, content: '문의하기', styles: { fontSize: '3xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
      createBlock('paragraph', { content: '궁금한 점이 있으시면 언제든 연락주세요. 빠른 시일 내에 답변드리겠습니다.', styles: { fontSize: 'lg', textAlign: 'center', textColor: 'text-gray-600' } }, 1),
      createBlock('button', { 
        text: '이메일 보내기', 
        link: { url: 'mailto:contact@example.com', target: '_blank' },
        styles: { variant: 'primary', size: 'lg', textAlign: 'center', width: 'fit' }
      }, 2)
    ],
    tags: ['contact', 'email', 'cta']
  },

  // 갤러리 템플릿
  {
    id: 'gallery-section',
    name: '갤러리',
    description: '3개 컬럼으로 구성된 이미지 갤러리',
    category: 'media',
    blocks: [
      createBlock('heading', { level: 2, content: '갤러리', styles: { fontSize: '3xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
      createBlock('grid', { 
        columns: [
          {
            id: uuidv4(),
            width: 4,
            blocks: [
              createBlock('image', { src: '/images/placeholder1.jpg', alt: '갤러리 이미지 1' }, 0)
            ]
          },
          {
            id: uuidv4(),
            width: 4,
            blocks: [
              createBlock('image', { src: '/images/placeholder2.jpg', alt: '갤러리 이미지 2' }, 0)
            ]
          },
          {
            id: uuidv4(),
            width: 4,
            blocks: [
              createBlock('image', { src: '/images/placeholder3.jpg', alt: '갤러리 이미지 3' }, 0)
            ]
          }
        ],
        gap: 4
      }, 1)
    ],
    tags: ['gallery', 'images', '3-column']
  },

  // FAQ 템플릿
  {
    id: 'faq-section',
    name: 'FAQ',
    description: '자주 묻는 질문과 답변 섹션',
    category: 'content',
    blocks: [
      createBlock('heading', { level: 2, content: '자주 묻는 질문', styles: { fontSize: '3xl', fontWeight: 'semibold', textAlign: 'center' } }, 0),
      createBlock('heading', { level: 3, content: '서비스는 어떻게 이용하나요?', styles: { fontSize: 'lg', fontWeight: 'semibold' } }, 1),
      createBlock('paragraph', { content: '간단한 가입 절차를 통해 서비스를 이용하실 수 있습니다. 회원가입 후 바로 이용 가능합니다.', styles: { fontSize: 'base' } }, 2),
      createBlock('heading', { level: 3, content: '요금은 어떻게 되나요?', styles: { fontSize: 'lg', fontWeight: 'semibold' } }, 3),
      createBlock('paragraph', { content: '다양한 요금제를 제공하고 있습니다. 사용 목적에 맞는 플랜을 선택하실 수 있습니다.', styles: { fontSize: 'base' } }, 4)
    ],
    tags: ['faq', 'questions', 'help']
  }
];

export const templateCategories: TemplateCategory[] = [
  {
    id: 'layout',
    name: '레이아웃',
    description: '페이지 구조를 위한 템플릿',
    templates: defaultTemplates.filter(t => t.category === 'layout')
  },
  {
    id: 'content',
    name: '콘텐츠',
    description: '텍스트와 정보를 위한 템플릿',
    templates: defaultTemplates.filter(t => t.category === 'content')
  },
  {
    id: 'media',
    name: '미디어',
    description: '이미지와 미디어를 위한 템플릿',
    templates: defaultTemplates.filter(t => t.category === 'media')
  },
  {
    id: 'interactive',
    name: '인터랙티브',
    description: '버튼과 링크가 포함된 템플릿',
    templates: defaultTemplates.filter(t => t.category === 'interactive')
  }
]; 