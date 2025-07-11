-- 민들레센터 데이터베이스 초기화 스크립트
-- PostgreSQL 13 호환 버전
-- 생성일: 2025-01-08

-- 확장 활성화
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- ENUM 타입 정의
CREATE TYPE public.entity_type AS ENUM (
    'post',
    'gallery',
    'user_profile',
    'comment',
    'draft'
);

CREATE TYPE public.file_purpose AS ENUM (
    'attachment',
    'thumbnail',
    'content',
    'avatar',
    'editorimage'
);

CREATE TYPE public.file_status AS ENUM (
    'draft',
    'published',
    'orphaned',
    'processing'
);

CREATE TYPE public.file_type AS ENUM (
    'image',
    'video',
    'audio',
    'document',
    'archive',
    'other'
);

CREATE TYPE public.menu_type AS ENUM (
    'page',
    'board',
    'calendar',
    'url'
);

CREATE TYPE public.notification_type AS ENUM (
    'comment',
    'like',
    'system',
    'announcement'
);

CREATE TYPE public.post_status AS ENUM (
    'active',
    'hidden',
    'deleted',
    'published'
);

CREATE TYPE public.processing_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed'
);

CREATE TYPE public.user_role AS ENUM (
    'user',
    'admin'
);

CREATE TYPE public.user_status AS ENUM (
    'active',
    'inactive',
    'suspended'
);

-- 함수 정의
CREATE FUNCTION public.cleanup_expired_drafts() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 만료된 임시저장 글의 파일들 먼저 정리
    UPDATE files SET status = 'orphaned'
    WHERE id IN (
        SELECT fe.file_id
        FROM file_entities fe
        JOIN drafts d ON fe.entity_id = d.id
        WHERE d.expires_at < NOW() AND fe.entity_type = 'draft'
    );
    
    -- 만료된 임시저장 글 삭제
    DELETE FROM drafts WHERE expires_at < NOW();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

CREATE FUNCTION public.cleanup_orphaned_files() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 고아 파일들 삭제 (24시간 이상 된 것들)
    DELETE FROM files 
    WHERE status = 'orphaned' 
    AND created_at < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

CREATE FUNCTION public.increment_page_view_count(page_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pages 
    SET view_count = view_count + 1 
    WHERE id = page_id;
END;
$$;

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 테이블 생성
CREATE TABLE public.boards (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    description text,
    category character varying(50),
    display_order integer DEFAULT 0,
    is_public boolean DEFAULT true,
    allow_anonymous boolean DEFAULT false,
    allow_file_upload boolean DEFAULT true,
    max_files integer DEFAULT 5,
    max_file_size bigint DEFAULT 10485760,
    allowed_file_types text,
    allow_rich_text boolean DEFAULT true,
    require_category boolean DEFAULT false,
    allow_comments boolean DEFAULT true,
    allow_likes boolean DEFAULT true,
    write_permission character varying(50) DEFAULT 'member',
    list_permission character varying(50) DEFAULT 'guest',
    read_permission character varying(50) DEFAULT 'guest',
    reply_permission character varying(50) DEFAULT 'member',
    comment_permission character varying(50) DEFAULT 'member',
    download_permission character varying(50) DEFAULT 'member',
    hide_list boolean DEFAULT false,
    editor_type character varying(50) DEFAULT 'rich',
    allow_search boolean DEFAULT true,
    allow_recommend boolean DEFAULT true,
    allow_disrecommend boolean DEFAULT false,
    show_author_name boolean DEFAULT true,
    show_ip boolean DEFAULT false,
    edit_comment_limit integer DEFAULT 0,
    delete_comment_limit integer DEFAULT 0,
    use_sns boolean DEFAULT false,
    use_captcha boolean DEFAULT false,
    title_length integer DEFAULT 200,
    posts_per_page integer DEFAULT 20,
    read_point integer DEFAULT 0,
    write_point integer DEFAULT 0,
    comment_point integer DEFAULT 0,
    download_point integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    allowed_iframe_domains text
);

CREATE TABLE public.calendar_events (
    id uuid NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone,
    all_day boolean DEFAULT false,
    color character varying(20),
    is_public boolean DEFAULT true,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.categories (
    id uuid NOT NULL,
    board_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.comments (
    id uuid NOT NULL,
    post_id uuid NOT NULL,
    user_id uuid NOT NULL,
    parent_id uuid,
    content text NOT NULL,
    likes integer DEFAULT 0,
    status character varying(20) DEFAULT 'active',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.drafts (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    board_id uuid NOT NULL,
    category_id uuid,
    title character varying(200),
    content text,
    auto_save_count integer DEFAULT 0,
    expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.faqs (
    id uuid NOT NULL,
    question text NOT NULL,
    answer text NOT NULL,
    category character varying(50),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.file_entities (
    id uuid NOT NULL,
    file_id uuid NOT NULL,
    entity_type entity_type NOT NULL,
    entity_id uuid NOT NULL,
    file_purpose file_purpose DEFAULT 'attachment',
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.files (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    original_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    original_size bigint,
    mime_type character varying(100),
    file_type file_type,
    status file_status DEFAULT 'draft',
    compression_ratio numeric(5,2),
    has_thumbnails boolean DEFAULT false,
    processing_status processing_status DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.galleries (
    id uuid NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    category character varying(50),
    status character varying(20) DEFAULT 'active',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.hero_sections (
    id uuid NOT NULL,
    title character varying(200) NOT NULL,
    subtitle character varying(200),
    description text,
    image_url character varying(500),
    button_text character varying(100),
    button_link character varying(500),
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.image_sizes (
    id uuid NOT NULL,
    file_id uuid NOT NULL,
    size_name character varying(50) NOT NULL,
    width integer,
    height integer,
    file_path character varying(500) NOT NULL,
    file_size bigint,
    format character varying(20),
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.likes (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    entity_type entity_type NOT NULL,
    entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.menus (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    menu_type menu_type NOT NULL,
    target_id uuid,
    url character varying(500),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    parent_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.notifications (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    type notification_type NOT NULL,
    title character varying(200) NOT NULL,
    message text,
    entity_type entity_type,
    entity_id uuid,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.organization_info (
    id uuid NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    address text,
    phone character varying(20),
    email character varying(255),
    website character varying(255),
    logo_url character varying(500),
    established_year integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.pages (
    id uuid NOT NULL,
    slug character varying(200) UNIQUE NOT NULL,
    title character varying(200) NOT NULL,
    content text,
    excerpt text,
    meta_title character varying(200),
    meta_description text,
    status character varying(20) DEFAULT 'draft',
    is_published boolean DEFAULT false,
    published_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    view_count integer DEFAULT 0,
    sort_order integer DEFAULT 0
);

CREATE TABLE public.permissions (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    resource character varying(50) NOT NULL,
    action character varying(50) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.point_transactions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    amount integer NOT NULL,
    reason character varying(255) NOT NULL,
    reference_type character varying(50),
    reference_id uuid,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.posts (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    board_id uuid NOT NULL,
    category_id uuid,
    user_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    content text,
    views integer DEFAULT 0,
    likes integer DEFAULT 0,
    is_notice boolean DEFAULT false,
    status post_status DEFAULT 'active',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    dislikes integer DEFAULT 0,
    meta_title character varying(200),
    meta_description text,
    meta_keywords text,
    is_deleted boolean DEFAULT false,
    reading_time integer,
    comment_count integer DEFAULT 0,
    attached_files text,
    thumbnail_urls text
);

CREATE TABLE public.refresh_tokens (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    service_type character varying(50) DEFAULT 'web',
    expires_at timestamp with time zone NOT NULL,
    is_revoked boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.reports (
    id uuid NOT NULL,
    reporter_id uuid NOT NULL,
    entity_type entity_type NOT NULL,
    entity_id uuid NOT NULL,
    reason character varying(100) NOT NULL,
    description text,
    status character varying(20) DEFAULT 'pending',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.role_permissions (
    id uuid NOT NULL,
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.roles (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.site_info (
    id uuid NOT NULL,
    site_name character varying(200) NOT NULL,
    site_description text,
    site_keywords text,
    site_author character varying(100),
    site_url character varying(255),
    site_logo character varying(500),
    site_favicon character varying(500),
    contact_email character varying(255),
    contact_phone character varying(20),
    contact_address text,
    social_facebook character varying(255),
    social_twitter character varying(255),
    social_instagram character varying(255),
    social_youtube character varying(255),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.site_settings (
    id uuid NOT NULL,
    key character varying(100) NOT NULL,
    value text,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.sns_links (
    id uuid NOT NULL,
    platform character varying(50) NOT NULL,
    url character varying(500) NOT NULL,
    display_name character varying(100),
    icon_class character varying(100),
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.token_blacklist (
    id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.user_roles (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.user_social_accounts (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    provider character varying(50) NOT NULL,
    provider_id character varying(255) NOT NULL,
    provider_email character varying(255),
    access_token text,
    refresh_token text,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE public.users (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    email character varying(255) NOT NULL,
    password_hash character varying(255),
    name character varying(100) NOT NULL,
    phone character varying(20),
    profile_image character varying(500),
    points integer DEFAULT 0,
    role user_role DEFAULT 'user',
    status user_status DEFAULT 'active',
    email_verified boolean DEFAULT false,
    email_verified_at timestamp with time zone,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 인덱스 생성
CREATE INDEX idx_calendar_events_is_public ON public.calendar_events USING btree (is_public);
CREATE INDEX idx_categories_board_id ON public.categories USING btree (board_id);
CREATE INDEX idx_categories_is_active ON public.categories USING btree (is_active);
CREATE INDEX idx_comments_parent_id ON public.comments USING btree (parent_id);
CREATE INDEX idx_comments_post_id ON public.comments USING btree (post_id);
CREATE INDEX idx_comments_user_id ON public.comments USING btree (user_id);
CREATE INDEX idx_drafts_expires_at ON public.drafts USING btree (expires_at);
CREATE INDEX idx_drafts_user_id ON public.drafts USING btree (user_id);
CREATE INDEX idx_file_entities_entity ON public.file_entities USING btree (entity_type, entity_id);
CREATE INDEX idx_file_entities_file_id ON public.file_entities USING btree (file_id);
CREATE INDEX idx_files_status ON public.files USING btree (status);
CREATE INDEX idx_files_user_id ON public.files USING btree (user_id);
CREATE INDEX idx_likes_entity ON public.likes USING btree (entity_type, entity_id);
CREATE INDEX idx_menus_display_order ON public.menus USING btree (display_order);
CREATE INDEX idx_menus_is_active ON public.menus USING btree (is_active);
CREATE INDEX idx_menus_parent_id ON public.menus USING btree (parent_id);
CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);
CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);
CREATE INDEX idx_pages_created_at ON public.pages USING btree (created_at);
CREATE INDEX idx_pages_published ON public.pages USING btree (is_published);
CREATE INDEX idx_pages_slug ON public.pages USING btree (slug);
CREATE INDEX idx_pages_sort_order ON public.pages USING btree (sort_order);
CREATE INDEX idx_pages_status ON public.pages USING btree (status);
CREATE INDEX idx_permissions_active ON public.permissions USING btree (is_active);
CREATE INDEX idx_permissions_resource_action ON public.permissions USING btree (resource, action);
CREATE INDEX idx_point_transactions_user_id ON public.point_transactions USING btree (user_id);
CREATE INDEX idx_posts_board_id ON public.posts USING btree (board_id);
CREATE INDEX idx_posts_category_id ON public.posts USING btree (category_id);
CREATE INDEX idx_posts_comment_count ON public.posts USING btree (comment_count DESC);
CREATE INDEX idx_posts_content_gin ON public.posts USING gin (to_tsvector('simple'::regconfig, content));
CREATE INDEX idx_posts_created_at ON public.posts USING btree (created_at DESC);
CREATE INDEX idx_posts_is_deleted ON public.posts USING btree (is_deleted);
CREATE INDEX idx_posts_meta_title ON public.posts USING btree (meta_title);
CREATE INDEX idx_posts_reading_time ON public.posts USING btree (reading_time);
CREATE INDEX idx_posts_status ON public.posts USING btree (status);
CREATE INDEX idx_posts_title_gin ON public.posts USING gin (to_tsvector('simple'::regconfig, (title)::text));
CREATE INDEX idx_posts_user_id ON public.posts USING btree (user_id);
CREATE INDEX idx_refresh_tokens_hash ON public.refresh_tokens USING btree (token_hash);
CREATE INDEX idx_refresh_tokens_user_service ON public.refresh_tokens USING btree (user_id, service_type);
CREATE INDEX idx_role_permissions_permission_id ON public.role_permissions USING btree (permission_id);
CREATE INDEX idx_role_permissions_role_id ON public.role_permissions USING btree (role_id);
CREATE INDEX idx_roles_active ON public.roles USING btree (is_active);
CREATE INDEX idx_roles_name ON public.roles USING btree (name);
CREATE INDEX idx_site_info_created_at ON public.site_info USING btree (created_at DESC);
CREATE INDEX idx_sns_links_active_order ON public.sns_links USING btree (is_active, display_order);
CREATE INDEX idx_sns_links_created_at ON public.sns_links USING btree (created_at);
CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);
CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);
CREATE INDEX idx_users_email ON public.users USING btree (email);
CREATE INDEX idx_users_status ON public.users USING btree (status);

-- 트리거 생성
CREATE TRIGGER update_boards_updated_at BEFORE UPDATE ON public.boards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_drafts_updated_at BEFORE UPDATE ON public.drafts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_faqs_updated_at BEFORE UPDATE ON public.faqs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_galleries_updated_at BEFORE UPDATE ON public.galleries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_hero_sections_updated_at BEFORE UPDATE ON public.hero_sections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_menus_updated_at BEFORE UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_organization_info_updated_at BEFORE UPDATE ON public.organization_info FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON public.pages FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_permissions_updated_at BEFORE UPDATE ON public.permissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_site_info_updated_at BEFORE UPDATE ON public.site_info FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_sns_links_updated_at BEFORE UPDATE ON public.sns_links FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- 제약조건 설정
ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.faqs
    ADD CONSTRAINT faqs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.file_entities
    ADD CONSTRAINT file_entities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.galleries
    ADD CONSTRAINT galleries_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.hero_sections
    ADD CONSTRAINT hero_sections_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.image_sizes
    ADD CONSTRAINT image_sizes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.organization_info
    ADD CONSTRAINT organization_info_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.point_transactions
    ADD CONSTRAINT point_transactions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.site_info
    ADD CONSTRAINT site_info_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.sns_links
    ADD CONSTRAINT sns_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

-- 외래키 제약조건
ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.file_entities
    ADD CONSTRAINT file_entities_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.image_sizes
    ADD CONSTRAINT image_sizes_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.menus(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.point_transactions
    ADD CONSTRAINT point_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- UNIQUE 제약조건
ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_slug_key UNIQUE (slug);

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_slug_key UNIQUE (slug);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_provider_provider_id_key UNIQUE (provider, provider_id);

-- 시퀀스 설정 (필요한 경우)
-- PostgreSQL 13에서는 UUID를 사용하므로 별도 시퀀스가 필요하지 않음 