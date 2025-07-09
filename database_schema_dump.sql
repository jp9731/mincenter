--
-- PostgreSQL database dump
--

-- Dumped from database version 13.21
-- Dumped by pg_dump version 13.21

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: entity_type; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.entity_type AS ENUM (
    'post',
    'gallery',
    'user_profile',
    'comment',
    'draft'
);


ALTER TYPE public.entity_type OWNER TO mincenter;

--
-- Name: file_purpose; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.file_purpose AS ENUM (
    'attachment',
    'thumbnail',
    'content',
    'avatar',
    'editorimage'
);


ALTER TYPE public.file_purpose OWNER TO mincenter;

--
-- Name: file_status; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.file_status AS ENUM (
    'draft',
    'published',
    'orphaned',
    'processing'
);


ALTER TYPE public.file_status OWNER TO mincenter;

--
-- Name: file_type; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.file_type AS ENUM (
    'image',
    'video',
    'audio',
    'document',
    'archive',
    'other'
);


ALTER TYPE public.file_type OWNER TO mincenter;

--
-- Name: menu_type; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.menu_type AS ENUM (
    'page',
    'board',
    'calendar',
    'url'
);


ALTER TYPE public.menu_type OWNER TO mincenter;

--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.notification_type AS ENUM (
    'comment',
    'like',
    'system',
    'announcement'
);


ALTER TYPE public.notification_type OWNER TO mincenter;

--
-- Name: post_status; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.post_status AS ENUM (
    'active',
    'hidden',
    'deleted',
    'published'
);


ALTER TYPE public.post_status OWNER TO mincenter;

--
-- Name: processing_status; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.processing_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed'
);


ALTER TYPE public.processing_status OWNER TO mincenter;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.user_role AS ENUM (
    'user',
    'admin'
);


ALTER TYPE public.user_role OWNER TO mincenter;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: mincenter
--

CREATE TYPE public.user_status AS ENUM (
    'active',
    'inactive',
    'suspended'
);


ALTER TYPE public.user_status OWNER TO mincenter;

--
-- Name: cleanup_expired_drafts(); Type: FUNCTION; Schema: public; Owner: mincenter
--

CREATE FUNCTION public.cleanup_expired_drafts() RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.cleanup_expired_drafts() OWNER TO mincenter;

--
-- Name: cleanup_orphaned_files(); Type: FUNCTION; Schema: public; Owner: mincenter
--

CREATE FUNCTION public.cleanup_orphaned_files() RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.cleanup_orphaned_files() OWNER TO mincenter;

--
-- Name: increment_page_view_count(uuid); Type: FUNCTION; Schema: public; Owner: mincenter
--

CREATE FUNCTION public.increment_page_view_count(page_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pages 
    SET view_count = view_count + 1 
    WHERE id = page_id;
END;
$$;


ALTER FUNCTION public.increment_page_view_count(page_id uuid) OWNER TO mincenter;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: mincenter
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO mincenter;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: boards; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.boards (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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
    write_permission character varying(50) DEFAULT 'member'::character varying,
    list_permission character varying(50) DEFAULT 'guest'::character varying,
    read_permission character varying(50) DEFAULT 'guest'::character varying,
    reply_permission character varying(50) DEFAULT 'member'::character varying,
    comment_permission character varying(50) DEFAULT 'member'::character varying,
    download_permission character varying(50) DEFAULT 'member'::character varying,
    hide_list boolean DEFAULT false,
    editor_type character varying(50) DEFAULT 'rich'::character varying,
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


ALTER TABLE public.boards OWNER TO mincenter;

--
-- Name: calendar_events; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.calendar_events (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    start_at timestamp with time zone NOT NULL,
    end_at timestamp with time zone,
    all_day boolean DEFAULT false,
    color character varying(20),
    is_public boolean DEFAULT false,
    user_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.calendar_events OWNER TO mincenter;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.categories (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    board_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.categories OWNER TO mincenter;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.comments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    post_id uuid NOT NULL,
    user_id uuid NOT NULL,
    parent_id uuid,
    content text NOT NULL,
    likes integer DEFAULT 0,
    status public.post_status DEFAULT 'active'::public.post_status,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.comments OWNER TO mincenter;

--
-- Name: drafts; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.drafts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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


ALTER TABLE public.drafts OWNER TO mincenter;

--
-- Name: faqs; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.faqs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    question character varying(500) NOT NULL,
    answer text NOT NULL,
    category character varying(50),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.faqs OWNER TO mincenter;

--
-- Name: file_entities; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.file_entities (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    file_id uuid NOT NULL,
    entity_type public.entity_type NOT NULL,
    entity_id uuid NOT NULL,
    file_purpose public.file_purpose DEFAULT 'attachment'::public.file_purpose,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.file_entities OWNER TO mincenter;

--
-- Name: files; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.files (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    original_name character varying(255) NOT NULL,
    stored_name character varying(255) NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    original_size bigint,
    mime_type character varying(100) NOT NULL,
    file_type public.file_type NOT NULL,
    status public.file_status DEFAULT 'draft'::public.file_status,
    compression_ratio numeric(5,2),
    has_thumbnails boolean DEFAULT false,
    processing_status public.processing_status DEFAULT 'pending'::public.processing_status,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.files OWNER TO mincenter;

--
-- Name: galleries; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.galleries (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    category character varying(50),
    status public.post_status DEFAULT 'active'::public.post_status,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.galleries OWNER TO mincenter;

--
-- Name: hero_sections; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.hero_sections (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(200) NOT NULL,
    subtitle character varying(500),
    description text,
    image_url character varying(500),
    button_text character varying(100),
    button_link character varying(500),
    is_active boolean DEFAULT true,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.hero_sections OWNER TO mincenter;

--
-- Name: image_sizes; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.image_sizes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    file_id uuid NOT NULL,
    size_name character varying(50) NOT NULL,
    width integer,
    height integer,
    file_path character varying(500) NOT NULL,
    file_size bigint NOT NULL,
    format character varying(10) NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.image_sizes OWNER TO mincenter;

--
-- Name: likes; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.likes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.likes OWNER TO mincenter;

--
-- Name: menus; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.menus (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    menu_type public.menu_type NOT NULL,
    target_id uuid,
    url character varying(500),
    display_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    parent_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.menus OWNER TO mincenter;

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.notifications (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type public.notification_type NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    entity_type character varying(50),
    entity_id uuid,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.notifications OWNER TO mincenter;

--
-- Name: organization_info; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.organization_info (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    address text,
    phone character varying(50),
    email character varying(255),
    website character varying(255),
    logo_url character varying(500),
    established_year integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.organization_info OWNER TO mincenter;

--
-- Name: pages; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.pages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug character varying(255) NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    excerpt text,
    meta_title character varying(255),
    meta_description text,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    published_at timestamp with time zone,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    updated_by uuid,
    view_count integer DEFAULT 0,
    sort_order integer DEFAULT 0,
    CONSTRAINT pages_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'published'::character varying, 'archived'::character varying])::text[])))
);


ALTER TABLE public.pages OWNER TO mincenter;

--
-- Name: permissions; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    resource character varying(100) NOT NULL,
    action character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.permissions OWNER TO mincenter;

--
-- Name: point_transactions; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.point_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    amount integer NOT NULL,
    reason character varying(255) NOT NULL,
    reference_type character varying(50),
    reference_id uuid,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.point_transactions OWNER TO mincenter;

--
-- Name: posts; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.posts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    board_id uuid NOT NULL,
    category_id uuid,
    user_id uuid NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    views integer DEFAULT 0,
    likes integer DEFAULT 0,
    is_notice boolean DEFAULT false,
    status public.post_status DEFAULT 'active'::public.post_status,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    dislikes integer DEFAULT 0,
    meta_title character varying(255),
    meta_description text,
    meta_keywords text,
    is_deleted boolean DEFAULT false,
    reading_time integer,
    comment_count integer DEFAULT 0,
    attached_files text[],
    thumbnail_urls jsonb
);


ALTER TABLE public.posts OWNER TO mincenter;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    service_type character varying(20) DEFAULT 'site'::character varying NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    is_revoked boolean DEFAULT false
);


ALTER TABLE public.refresh_tokens OWNER TO mincenter;

--
-- Name: reports; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.reports (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    reporter_id uuid NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    reason character varying(500) NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying,
    admin_note text,
    resolved_by uuid,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.reports OWNER TO mincenter;

--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.role_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.role_permissions OWNER TO mincenter;

--
-- Name: roles; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.roles OWNER TO mincenter;

--
-- Name: site_info; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.site_info (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    site_name character varying(255) DEFAULT '민센터 봉사단체'::character varying NOT NULL,
    catchphrase text,
    address text,
    phone character varying(50),
    email character varying(255),
    homepage character varying(500),
    fax character varying(50),
    representative_name character varying(100),
    business_number character varying(20),
    logo_image_url text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.site_info OWNER TO mincenter;

--
-- Name: site_settings; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.site_settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key character varying(100) NOT NULL,
    value text,
    description character varying(500),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.site_settings OWNER TO mincenter;

--
-- Name: sns_links; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.sns_links (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(100) NOT NULL,
    url character varying(500) NOT NULL,
    icon character varying(100) DEFAULT 'custom'::character varying NOT NULL,
    icon_type character varying(20) DEFAULT 'emoji'::character varying NOT NULL,
    display_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.sns_links OWNER TO mincenter;

--
-- Name: token_blacklist; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.token_blacklist (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    token_jti character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.token_blacklist OWNER TO mincenter;

--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_roles OWNER TO mincenter;

--
-- Name: user_social_accounts; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.user_social_accounts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
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


ALTER TABLE public.user_social_accounts OWNER TO mincenter;

--
-- Name: users; Type: TABLE; Schema: public; Owner: mincenter
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255),
    name character varying(100) NOT NULL,
    phone character varying(20),
    profile_image character varying(500),
    points integer DEFAULT 0,
    role public.user_role DEFAULT 'user'::public.user_role,
    status public.user_status DEFAULT 'active'::public.user_status,
    email_verified boolean DEFAULT false,
    email_verified_at timestamp with time zone,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO mincenter;

--
-- Name: boards boards_name_unique; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_name_unique UNIQUE (name);


--
-- Name: boards boards_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: boards boards_slug_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_slug_key UNIQUE (slug);


--
-- Name: boards boards_slug_unique; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_slug_unique UNIQUE (slug);


--
-- Name: calendar_events calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: faqs faqs_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.faqs
    ADD CONSTRAINT faqs_pkey PRIMARY KEY (id);


--
-- Name: file_entities file_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.file_entities
    ADD CONSTRAINT file_entities_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: galleries galleries_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.galleries
    ADD CONSTRAINT galleries_pkey PRIMARY KEY (id);


--
-- Name: hero_sections hero_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.hero_sections
    ADD CONSTRAINT hero_sections_pkey PRIMARY KEY (id);


--
-- Name: image_sizes image_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.image_sizes
    ADD CONSTRAINT image_sizes_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: likes likes_user_id_entity_type_entity_id_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_entity_type_entity_id_key UNIQUE (user_id, entity_type, entity_id);


--
-- Name: menus menus_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: organization_info organization_info_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.organization_info
    ADD CONSTRAINT organization_info_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: pages pages_slug_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_slug_key UNIQUE (slug);


--
-- Name: permissions permissions_name_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_key UNIQUE (name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: point_transactions point_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.point_transactions
    ADD CONSTRAINT point_transactions_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_role_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_permission_id_key UNIQUE (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: site_info site_info_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.site_info
    ADD CONSTRAINT site_info_pkey PRIMARY KEY (id);


--
-- Name: site_settings site_settings_key_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_key_key UNIQUE (key);


--
-- Name: site_settings site_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);


--
-- Name: sns_links sns_links_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.sns_links
    ADD CONSTRAINT sns_links_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist token_blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist token_blacklist_token_jti_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_token_jti_key UNIQUE (token_jti);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- Name: user_social_accounts user_social_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_pkey PRIMARY KEY (id);


--
-- Name: user_social_accounts user_social_accounts_provider_provider_id_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_provider_provider_id_key UNIQUE (provider, provider_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_calendar_events_is_public; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_calendar_events_is_public ON public.calendar_events USING btree (is_public);


--
-- Name: idx_categories_board_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_categories_board_id ON public.categories USING btree (board_id);


--
-- Name: idx_categories_is_active; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_categories_is_active ON public.categories USING btree (is_active);


--
-- Name: idx_comments_parent_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_comments_parent_id ON public.comments USING btree (parent_id);


--
-- Name: idx_comments_post_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_comments_post_id ON public.comments USING btree (post_id);


--
-- Name: idx_comments_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_comments_user_id ON public.comments USING btree (user_id);


--
-- Name: idx_drafts_expires_at; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_drafts_expires_at ON public.drafts USING btree (expires_at);


--
-- Name: idx_drafts_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_drafts_user_id ON public.drafts USING btree (user_id);


--
-- Name: idx_file_entities_entity; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_file_entities_entity ON public.file_entities USING btree (entity_type, entity_id);


--
-- Name: idx_file_entities_file_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_file_entities_file_id ON public.file_entities USING btree (file_id);


--
-- Name: idx_files_status; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_files_status ON public.files USING btree (status);


--
-- Name: idx_files_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_files_user_id ON public.files USING btree (user_id);


--
-- Name: idx_likes_entity; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_likes_entity ON public.likes USING btree (entity_type, entity_id);


--
-- Name: idx_menus_display_order; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_menus_display_order ON public.menus USING btree (display_order);


--
-- Name: idx_menus_is_active; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_menus_is_active ON public.menus USING btree (is_active);


--
-- Name: idx_menus_parent_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_menus_parent_id ON public.menus USING btree (parent_id);


--
-- Name: idx_notifications_read; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_pages_created_at; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_pages_created_at ON public.pages USING btree (created_at);


--
-- Name: idx_pages_published; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_pages_published ON public.pages USING btree (is_published);


--
-- Name: idx_pages_slug; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_pages_slug ON public.pages USING btree (slug);


--
-- Name: idx_pages_sort_order; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_pages_sort_order ON public.pages USING btree (sort_order);


--
-- Name: idx_pages_status; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_pages_status ON public.pages USING btree (status);


--
-- Name: idx_permissions_active; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_permissions_active ON public.permissions USING btree (is_active);


--
-- Name: idx_permissions_resource_action; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_permissions_resource_action ON public.permissions USING btree (resource, action);


--
-- Name: idx_point_transactions_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_point_transactions_user_id ON public.point_transactions USING btree (user_id);


--
-- Name: idx_posts_board_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_board_id ON public.posts USING btree (board_id);


--
-- Name: idx_posts_category_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_category_id ON public.posts USING btree (category_id);


--
-- Name: idx_posts_comment_count; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_comment_count ON public.posts USING btree (comment_count DESC);


--
-- Name: idx_posts_content_gin; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_content_gin ON public.posts USING gin (to_tsvector('simple'::regconfig, content));


--
-- Name: idx_posts_created_at; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_created_at ON public.posts USING btree (created_at DESC);


--
-- Name: idx_posts_is_deleted; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_is_deleted ON public.posts USING btree (is_deleted);


--
-- Name: idx_posts_meta_title; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_meta_title ON public.posts USING btree (meta_title);


--
-- Name: idx_posts_reading_time; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_reading_time ON public.posts USING btree (reading_time);


--
-- Name: idx_posts_status; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_status ON public.posts USING btree (status);


--
-- Name: idx_posts_title_gin; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_title_gin ON public.posts USING gin (to_tsvector('simple'::regconfig, (title)::text));


--
-- Name: idx_posts_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_user_id ON public.posts USING btree (user_id);


--
-- Name: idx_refresh_tokens_hash; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_refresh_tokens_hash ON public.refresh_tokens USING btree (token_hash);


--
-- Name: idx_refresh_tokens_user_service; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_refresh_tokens_user_service ON public.refresh_tokens USING btree (user_id, service_type);


--
-- Name: idx_role_permissions_permission_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_role_permissions_permission_id ON public.role_permissions USING btree (permission_id);


--
-- Name: idx_role_permissions_role_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_role_permissions_role_id ON public.role_permissions USING btree (role_id);


--
-- Name: idx_roles_active; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_roles_active ON public.roles USING btree (is_active);


--
-- Name: idx_roles_name; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_roles_name ON public.roles USING btree (name);


--
-- Name: idx_site_info_created_at; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_site_info_created_at ON public.site_info USING btree (created_at DESC);


--
-- Name: idx_sns_links_active_order; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_sns_links_active_order ON public.sns_links USING btree (is_active, display_order);


--
-- Name: idx_sns_links_created_at; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_sns_links_created_at ON public.sns_links USING btree (created_at);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: boards update_boards_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_boards_updated_at BEFORE UPDATE ON public.boards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: calendar_events update_calendar_events_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: categories update_categories_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: comments update_comments_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: drafts update_drafts_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_drafts_updated_at BEFORE UPDATE ON public.drafts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: faqs update_faqs_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_faqs_updated_at BEFORE UPDATE ON public.faqs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: galleries update_galleries_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_galleries_updated_at BEFORE UPDATE ON public.galleries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: hero_sections update_hero_sections_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_hero_sections_updated_at BEFORE UPDATE ON public.hero_sections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: menus update_menus_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_menus_updated_at BEFORE UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: organization_info update_organization_info_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_organization_info_updated_at BEFORE UPDATE ON public.organization_info FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: pages update_pages_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON public.pages FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: permissions update_permissions_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_permissions_updated_at BEFORE UPDATE ON public.permissions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: posts update_posts_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: roles update_roles_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: site_info update_site_info_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_site_info_updated_at BEFORE UPDATE ON public.site_info FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: site_settings update_site_settings_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: sns_links update_sns_links_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_sns_links_updated_at BEFORE UPDATE ON public.sns_links FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: calendar_events calendar_events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: categories categories_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;


--
-- Name: comments comments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id) ON DELETE CASCADE;


--
-- Name: comments comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: drafts drafts_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;


--
-- Name: drafts drafts_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: drafts drafts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: file_entities file_entities_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.file_entities
    ADD CONSTRAINT file_entities_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: files files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: image_sizes image_sizes_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.image_sizes
    ADD CONSTRAINT image_sizes_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: likes likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: menus menus_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.menus(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: pages pages_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: pages pages_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: point_transactions point_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.point_transactions
    ADD CONSTRAINT point_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: posts posts_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;


--
-- Name: posts posts_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: posts posts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: token_blacklist token_blacklist_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_social_accounts user_social_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

