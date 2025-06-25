-- 장애인 봉사단체 웹사이트 데이터베이스 스키마
-- PostgreSQL 초기화 스크립트

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ENUM 타입 정의
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('user', 'admin');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        CREATE TYPE user_status AS ENUM ('active', 'inactive', 'suspended');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_status') THEN
        CREATE TYPE post_status AS ENUM ('active', 'hidden', 'deleted');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_type') THEN
        CREATE TYPE file_type AS ENUM ('image', 'document', 'video', 'audio');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_status') THEN
        CREATE TYPE file_status AS ENUM ('draft', 'published', 'orphaned', 'processing');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'processing_status') THEN
        CREATE TYPE processing_status AS ENUM ('pending', 'processing', 'completed', 'failed');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_type') THEN
        CREATE TYPE entity_type AS ENUM ('post', 'gallery', 'user_profile', 'comment', 'draft');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_purpose') THEN
        CREATE TYPE file_purpose AS ENUM ('main', 'attachment', 'thumbnail');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM ('comment', 'like', 'system', 'announcement');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'menu_type') THEN
        CREATE TYPE menu_type AS ENUM ('page', 'board', 'calendar', 'url');
    END IF;
END $$;

-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_image VARCHAR(500),
    points INTEGER DEFAULT 0,
    role user_role DEFAULT 'user',
    status user_status DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 소셜 로그인 연동 테이블
CREATE TABLE IF NOT EXISTS user_social_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL, -- google, naver, kakao, facebook
    provider_id VARCHAR(255) NOT NULL,
    provider_email VARCHAR(255),
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(provider, provider_id)
);

-- 포인트 내역 테이블
CREATE TABLE IF NOT EXISTS point_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- earn, use
    amount INTEGER NOT NULL,
    reason VARCHAR(255) NOT NULL,
    reference_type VARCHAR(50), -- post, comment, event
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 게시판 테이블
CREATE TABLE IF NOT EXISTS boards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    category VARCHAR(50),
    display_order INTEGER DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    allow_anonymous BOOLEAN DEFAULT FALSE,
    -- 파일 업로드 설정
    allow_file_upload BOOLEAN DEFAULT TRUE,
    max_files INTEGER DEFAULT 5,
    max_file_size BIGINT DEFAULT 10485760, -- 10MB
    allowed_file_types TEXT[], -- ['image/*', 'application/pdf']
    -- 리치 텍스트 에디터 설정
    allow_rich_text BOOLEAN DEFAULT TRUE,
    -- 기타 설정
    require_category BOOLEAN DEFAULT FALSE,
    allow_comments BOOLEAN DEFAULT TRUE,
    allow_likes BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- boards.name에 UNIQUE 제약조건 추가
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'boards_name_unique'
    ) THEN
        ALTER TABLE boards ADD CONSTRAINT boards_name_unique UNIQUE (name);
    END IF;
END $$;

-- boards.slug에 UNIQUE 제약조건 추가
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'boards_slug_unique'
    ) THEN
        ALTER TABLE boards ADD CONSTRAINT boards_slug_unique UNIQUE (slug);
    END IF;
END $$;

-- 메뉴 테이블
CREATE TABLE IF NOT EXISTS menus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    menu_type menu_type NOT NULL,
    target_id UUID, -- 페이지 ID 또는 게시판 ID
    url VARCHAR(500), -- 외부 링크 URL
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    parent_id UUID REFERENCES menus(id) ON DELETE CASCADE, -- 2단 메뉴인 경우 1단 메뉴 ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 카테고리 테이블 (게시판 내부 구분용)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 임시저장 테이블
CREATE TABLE IF NOT EXISTS drafts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    title VARCHAR(200),
    content TEXT,
    auto_save_count INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 게시글 테이블
CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    views INTEGER DEFAULT 0,
    likes INTEGER DEFAULT 0,
    is_notice BOOLEAN DEFAULT FALSE,
    status post_status DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 댓글 테이블
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes INTEGER DEFAULT 0,
    status post_status DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 파일 테이블
CREATE TABLE IF NOT EXISTS files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_name VARCHAR(255) NOT NULL,
    stored_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    original_size BIGINT,
    mime_type VARCHAR(100) NOT NULL,
    file_type file_type NOT NULL,
    status file_status DEFAULT 'draft',
    compression_ratio DECIMAL(5,2),
    has_thumbnails BOOLEAN DEFAULT FALSE,
    processing_status processing_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 파일 사이즈 테이블 (이미지 다중 사이즈)
CREATE TABLE IF NOT EXISTS image_sizes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    size_name VARCHAR(50) NOT NULL, -- thumbnail, medium, large, original
    width INTEGER,
    height INTEGER,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    format VARCHAR(10) NOT NULL, -- webp, jpeg, png
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 파일-엔티티 연결 테이블
CREATE TABLE IF NOT EXISTS file_entities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    entity_type entity_type NOT NULL,
    entity_id UUID NOT NULL,
    file_purpose file_purpose DEFAULT 'attachment',
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 갤러리 테이블
CREATE TABLE IF NOT EXISTS galleries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    status post_status DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- FAQ 테이블
CREATE TABLE IF NOT EXISTS faqs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question VARCHAR(500) NOT NULL,
    answer TEXT NOT NULL,
    category VARCHAR(50),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 단체 정보 테이블
CREATE TABLE IF NOT EXISTS organization_info (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255),
    logo_url VARCHAR(500),
    established_year INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 메인 페이지 히어로 섹션
CREATE TABLE IF NOT EXISTS hero_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    subtitle VARCHAR(500),
    description TEXT,
    image_url VARCHAR(500),
    button_text VARCHAR(100),
    button_link VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 좋아요 테이블
CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- post, comment
    entity_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, entity_type, entity_id)
);

-- 신고 테이블
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL, -- post, comment, user
    entity_id UUID NOT NULL,
    reason VARCHAR(500) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, reviewed, resolved
    admin_note TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 알림 테이블
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 사이트 설정 테이블
CREATE TABLE IF NOT EXISTS site_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(100) UNIQUE NOT NULL,
    value TEXT,
    description VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- JWT 토큰 블랙리스트 (로그아웃 처리)
CREATE TABLE IF NOT EXISTS token_blacklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    token_jti VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- refresh_tokens 테이블 추가
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    service_type VARCHAR(20) NOT NULL DEFAULT 'site', -- 'site', 'admin', 'mobile' 등
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_revoked BOOLEAN DEFAULT FALSE
);

-- refresh_tokens 인덱스 생성
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_class WHERE relname = 'idx_refresh_tokens_user_service'
    ) THEN
        CREATE INDEX idx_refresh_tokens_user_service ON refresh_tokens(user_id, service_type);
    END IF;
END $$;
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_class WHERE relname = 'idx_refresh_tokens_hash'
    ) THEN
        CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
    END IF;
END $$;

-- 나머지 인덱스 생성
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_users_email') THEN CREATE INDEX idx_users_email ON users(email); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_users_status') THEN CREATE INDEX idx_users_status ON users(status); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_board_id') THEN CREATE INDEX idx_posts_board_id ON posts(board_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_category_id') THEN CREATE INDEX idx_posts_category_id ON posts(category_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_user_id') THEN CREATE INDEX idx_posts_user_id ON posts(user_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_status') THEN CREATE INDEX idx_posts_status ON posts(status); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_created_at') THEN CREATE INDEX idx_posts_created_at ON posts(created_at DESC); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_comments_post_id') THEN CREATE INDEX idx_comments_post_id ON comments(post_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_comments_user_id') THEN CREATE INDEX idx_comments_user_id ON comments(user_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_comments_parent_id') THEN CREATE INDEX idx_comments_parent_id ON comments(parent_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_files_user_id') THEN CREATE INDEX idx_files_user_id ON files(user_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_files_status') THEN CREATE INDEX idx_files_status ON files(status); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_file_entities_entity') THEN CREATE INDEX idx_file_entities_entity ON file_entities(entity_type, entity_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_file_entities_file_id') THEN CREATE INDEX idx_file_entities_file_id ON file_entities(file_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_drafts_user_id') THEN CREATE INDEX idx_drafts_user_id ON drafts(user_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_drafts_expires_at') THEN CREATE INDEX idx_drafts_expires_at ON drafts(expires_at); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_likes_entity') THEN CREATE INDEX idx_likes_entity ON likes(entity_type, entity_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_notifications_user_id') THEN CREATE INDEX idx_notifications_user_id ON notifications(user_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_notifications_read') THEN CREATE INDEX idx_notifications_read ON notifications(is_read); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_point_transactions_user_id') THEN CREATE INDEX idx_point_transactions_user_id ON point_transactions(user_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_categories_board_id') THEN CREATE INDEX idx_categories_board_id ON categories(board_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_categories_is_active') THEN CREATE INDEX idx_categories_is_active ON categories(is_active); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_menus_parent_id') THEN CREATE INDEX idx_menus_parent_id ON menus(parent_id); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_menus_display_order') THEN CREATE INDEX idx_menus_display_order ON menus(display_order); END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_menus_is_active') THEN CREATE INDEX idx_menus_is_active ON menus(is_active); END IF;
END $$;

-- 전문 검색을 위한 인덱스
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_title_gin') THEN
        CREATE INDEX idx_posts_title_gin ON posts USING gin(to_tsvector('korean', title));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_posts_content_gin') THEN
        CREATE INDEX idx_posts_content_gin ON posts USING gin(to_tsvector('korean', content));
    END IF;
END $$;

-- 트리거 함수: updated_at 자동 업데이트
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 기본 데이터 삽입
INSERT INTO boards (id, name, slug, description, category, display_order) VALUES
    (uuid_generate_v4(), '공지사항', 'notice', '봉사단체의 공지사항을 전달합니다', 'notice', 1),
    (uuid_generate_v4(), '봉사활동 후기', 'volunteer-review', '봉사활동 참여 후기를 공유해주세요', 'review', 2),
    (uuid_generate_v4(), '자유게시판', 'free', '자유롭게 소통하는 공간입니다', 'free', 3),
    (uuid_generate_v4(), '질문과 답변', 'qna', '궁금한 것들을 질문해주세요', 'qna', 4)
ON CONFLICT (name) DO NOTHING;

-- 기본 메뉴 데이터
INSERT INTO menus (id, name, description, menu_type, display_order, is_active) VALUES
    (uuid_generate_v4(), '소개', '봉사단체 소개', 'page', 1, true),
    (uuid_generate_v4(), '봉사활동', '봉사활동 안내', 'page', 2, true),
    (uuid_generate_v4(), '커뮤니티', '회원 커뮤니티', 'board', 3, true),
    (uuid_generate_v4(), '후원', '후원 안내', 'page', 4, true),
    (uuid_generate_v4(), '문의', '문의하기', 'page', 5, true)
ON CONFLICT DO NOTHING;

INSERT INTO organization_info (name, description, address, phone, email) VALUES
    ('따뜻한 마음 봉사단', '장애인을 위한 다양한 봉사활동을 펼치는 단체입니다.', '서울특별시 강남구 테헤란로 123', '02-1234-5678', 'info@warmheart.org')
ON CONFLICT DO NOTHING;

INSERT INTO faqs (question, answer, category, display_order) VALUES
    ('봉사활동에 참여하려면 어떻게 해야 하나요?', '회원가입 후 원하는 봉사활동을 신청하시면 됩니다.', 'general', 1),
    ('봉사활동 참여 시 준비물이 있나요?', '활동별로 다르며, 각 활동 상세페이지에서 확인할 수 있습니다.', 'general', 2),
    ('포인트는 어떻게 사용하나요?', '포인트는 기부하거나 봉사활동 용품과 교환할 수 있습니다.', 'point', 3)
ON CONFLICT DO NOTHING;

INSERT INTO site_settings (key, value, description) VALUES
    ('site_name', '따뜻한 마음 봉사단', '사이트 이름'),
    ('max_file_size', '10485760', '최대 파일 업로드 크기 (10MB)'),
    ('points_per_post', '10', '게시글 작성 시 적립 포인트'),
    ('points_per_comment', '5', '댓글 작성 시 적립 포인트'),
    ('draft_expire_days', '7', '임시저장 만료 일수')
ON CONFLICT (key) DO NOTHING;

-- 관리자 계정 생성 (비밀번호: admin123 - 실제 운영시 변경 필요)
INSERT INTO users (email, password_hash, name, role, status, email_verified) VALUES
    ('admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e', '관리자', 'admin', 'active', true)
ON CONFLICT (email) DO NOTHING;

-- 청리 작업을 위한 함수
CREATE OR REPLACE FUNCTION cleanup_expired_drafts()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 만료된 임시저장 글의 파일들 먼저 정리
    UPDATE files SET status = 'orphaned'
    WHERE id IN (
        SELECT f.id FROM files f
        JOIN file_entities fe ON f.id = fe.file_id
        JOIN drafts d ON fe.entity_id = d.id
        WHERE fe.entity_type = 'draft' AND d.expires_at < NOW()
    );
    
    -- 만료된 임시저장 글 삭제
    DELETE FROM drafts WHERE expires_at < NOW();
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 고아 파일 정리 함수
CREATE OR REPLACE FUNCTION cleanup_orphaned_files()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 어디에도 연결되지 않은 파일들을 고아 상태로 마킹
    UPDATE files SET status = 'orphaned'
    WHERE id NOT IN (SELECT DISTINCT file_id FROM file_entities)
    AND status != 'orphaned'
    AND created_at < NOW() - INTERVAL '1 day';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 안내 페이지 테이블
CREATE TABLE IF NOT EXISTS pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    meta_title VARCHAR(255),
    meta_description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    view_count INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0
);

-- 페이지 인덱스
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_pages_slug') THEN
        CREATE INDEX idx_pages_slug ON pages(slug);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_pages_status') THEN
        CREATE INDEX idx_pages_status ON pages(status);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_pages_published') THEN
        CREATE INDEX idx_pages_published ON pages(is_published);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_pages_sort_order') THEN
        CREATE INDEX idx_pages_sort_order ON pages(sort_order);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_pages_created_at') THEN
        CREATE INDEX idx_pages_created_at ON pages(created_at);
    END IF;
END $$;

-- 페이지 조회수 증가 함수
CREATE OR REPLACE FUNCTION increment_page_view_count(page_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE pages 
    SET view_count = view_count + 1 
    WHERE id = page_id;
END;
$$ LANGUAGE plpgsql;

-- 일정(캘린더) 테이블
CREATE TABLE IF NOT EXISTS calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    end_at TIMESTAMP WITH TIME ZONE,
    all_day BOOLEAN DEFAULT FALSE,
    color VARCHAR(20),
    is_public BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for is_public field
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_calendar_events_is_public') THEN
        CREATE INDEX idx_calendar_events_is_public ON calendar_events(is_public);
    END IF;
END $$;

-- Update existing events to be public by default
UPDATE calendar_events SET is_public = TRUE WHERE is_public IS NULL;

-- 트리거 적용 (모든 테이블 생성 후)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_boards_updated_at') THEN
        CREATE TRIGGER update_boards_updated_at BEFORE UPDATE ON boards FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_menus_updated_at') THEN
        CREATE TRIGGER update_menus_updated_at BEFORE UPDATE ON menus FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_categories_updated_at') THEN
        CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_posts_updated_at') THEN
        CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_comments_updated_at') THEN
        CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_galleries_updated_at') THEN
        CREATE TRIGGER update_galleries_updated_at BEFORE UPDATE ON galleries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_faqs_updated_at') THEN
        CREATE TRIGGER update_faqs_updated_at BEFORE UPDATE ON faqs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_organization_info_updated_at') THEN
        CREATE TRIGGER update_organization_info_updated_at BEFORE UPDATE ON organization_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_hero_sections_updated_at') THEN
        CREATE TRIGGER update_hero_sections_updated_at BEFORE UPDATE ON hero_sections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_site_settings_updated_at') THEN
        CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON site_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_drafts_updated_at') THEN
        CREATE TRIGGER update_drafts_updated_at BEFORE UPDATE ON drafts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_pages_updated_at') THEN
        CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON pages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_calendar_events_updated_at') THEN
        CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$; 