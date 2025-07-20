export type BlockType = 
  | 'paragraph'
  | 'heading'
  | 'image'
  | 'list'
  | 'quote'
  | 'code'
  | 'divider'
  | 'html'
  | 'map'
  | 'grid'
  | 'post-list'
  | 'button';

export interface BaseBlock {
  id: string;
  type: BlockType;
  order: number;
}

export interface TextStyles {
  fontFamily?: 'sans' | 'serif' | 'mono' | 'cursive';
  fontSize?: 'xs' | 'sm' | 'base' | 'lg' | 'xl' | '2xl' | '3xl' | '4xl' | '5xl';
  fontWeight?: 'light' | 'normal' | 'medium' | 'semibold' | 'bold' | 'extrabold';
  fontStyle?: 'normal' | 'italic';
  textColor?: string; // hex color or Tailwind color class
  backgroundColor?: string;
  textDecoration?: 'none' | 'underline' | 'line-through';
  textAlign?: 'left' | 'center' | 'right' | 'justify';
  letterSpacing?: 'tighter' | 'tight' | 'normal' | 'wide' | 'wider' | 'widest';
  lineHeight?: 'none' | 'tight' | 'snug' | 'normal' | 'relaxed' | 'loose';
  customStyles?: string; // 추가 CSS 클래스
}

export interface LinkSettings {
  url: string;
  target?: '_self' | '_blank' | '_parent' | '_top';
  rel?: string; // noopener, noreferrer 등
}

export interface ParagraphBlock extends BaseBlock {
  type: 'paragraph';
  content: string;
  styles?: TextStyles;
  link?: LinkSettings;
}

export interface HeadingBlock extends BaseBlock {
  type: 'heading';
  level: 1 | 2 | 3 | 4 | 5 | 6;
  content: string;
  styles?: TextStyles;
  link?: LinkSettings;
}

export interface ImageBlock extends BaseBlock {
  type: 'image';
  src: string;
  alt: string;
  caption?: string;
  width?: number;
  height?: number;
}

export interface ListBlock extends BaseBlock {
  type: 'list';
  style: 'ordered' | 'unordered';
  items: string[];
  styles?: TextStyles;
}

export interface QuoteBlock extends BaseBlock {
  type: 'quote';
  content: string;
  author?: string;
  styles?: TextStyles;
}

export interface CodeBlock extends BaseBlock {
  type: 'code';
  content: string;
  language?: string;
  styles?: TextStyles;
}

export interface DividerBlock extends BaseBlock {
  type: 'divider';
}

export interface HtmlBlock extends BaseBlock {
  type: 'html';
  content: string;
}

export interface MapBlock extends BaseBlock {
  type: 'map';
  address: string;
  latitude: number;
  longitude: number;
  apiKey?: string;
  width?: number;
  height?: number;
  zoom?: number;
  title?: string;
}

export interface GridColumn {
  id: string;
  width: number; // 1-12 (Bootstrap grid system)
  blocks: Block[];
  // Responsive breakpoints
  widthMobile?: number; // mobile width (1-12), defaults to 12 (full width)
  widthTablet?: number; // tablet width (1-12), defaults to width
}

export interface GridBlock extends BaseBlock {
  type: 'grid';
  columns: GridColumn[];
  gap?: number; // gap between columns (0-8)
  alignment?: 'start' | 'center' | 'end' | 'stretch';
}

export interface PostListBlock extends BaseBlock {
  type: 'post-list';
  title?: string; // 섹션 제목
  category?: string; // 특정 카테고리 필터 (빈 값이면 전체)
  boardType?: 'community' | 'news' | 'notice' | 'event'; // 게시판 타입
  limit: number; // 표시할 게시글 수 (기본 5개)
  sortBy: 'recent' | 'popular' | 'likes'; // 정렬 방식
  layout: 'list' | 'card' | 'minimal' | 'carousel'; // 레이아웃 스타일
  showImage: boolean; // 이미지 표시 여부
  showCategory: boolean; // 카테고리 표시 여부
  showExcerpt: boolean; // 요약글 표시 여부
  showDate: boolean; // 날짜 표시 여부
  truncateTitle?: number; // 제목 글자 수 제한 (기본 50자)
  // Carousel 전용 설정
  carouselOptions?: {
    itemsPerView: number; // 한번에 보일 아이템 수 (1-5)
    autoPlay: boolean; // 자동 전환 여부
    autoPlayInterval: number; // 자동 전환 간격 (초)
    showImageOnly: boolean; // 이미지만 표시 여부
    showDots: boolean; // 도트 인디케이터 표시
    showArrows: boolean; // 화살표 버튼 표시
  };
}

export interface ButtonBlock extends BaseBlock {
  type: 'button';
  text: string;
  link: LinkSettings;
  styles: {
    variant: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive' | 'link';
    size: 'sm' | 'md' | 'lg' | 'xl';
    color?: string; // hex color or Tailwind color class
    backgroundColor?: string;
    borderColor?: string;
    borderRadius?: 'none' | 'sm' | 'md' | 'lg' | 'xl' | 'full';
    textAlign?: 'left' | 'center' | 'right';
    width?: 'auto' | 'full' | 'fit';
    customStyles?: string;
  };
}

export type Block = 
  | ParagraphBlock
  | HeadingBlock
  | ImageBlock
  | ListBlock
  | QuoteBlock
  | CodeBlock
  | DividerBlock
  | HtmlBlock
  | MapBlock
  | GridBlock
  | PostListBlock
  | ButtonBlock;

export interface BlocksData {
  blocks: Block[];
  version: string;
}

export interface BlockTemplate {
  id: string;
  name: string;
  description?: string;
  category: 'layout' | 'content' | 'media' | 'interactive' | 'custom';
  thumbnail?: string;
  blocks: Block[];
  tags?: string[];
  isDefault?: boolean;
}

export interface TemplateCategory {
  id: string;
  name: string;
  description?: string;
  templates: BlockTemplate[];
}