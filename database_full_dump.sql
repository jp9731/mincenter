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

ALTER TABLE IF EXISTS ONLY public.user_social_accounts DROP CONSTRAINT IF EXISTS user_social_accounts_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_role_id_fkey;
ALTER TABLE IF EXISTS ONLY public.token_blacklist DROP CONSTRAINT IF EXISTS token_blacklist_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_role_id_fkey;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_permission_id_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_resolved_by_fkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_reporter_id_fkey;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.posts DROP CONSTRAINT IF EXISTS posts_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.posts DROP CONSTRAINT IF EXISTS posts_category_id_fkey;
ALTER TABLE IF EXISTS ONLY public.posts DROP CONSTRAINT IF EXISTS posts_board_id_fkey;
ALTER TABLE IF EXISTS ONLY public.point_transactions DROP CONSTRAINT IF EXISTS point_transactions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.pages DROP CONSTRAINT IF EXISTS pages_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY public.pages DROP CONSTRAINT IF EXISTS pages_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.menus DROP CONSTRAINT IF EXISTS menus_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY public.likes DROP CONSTRAINT IF EXISTS likes_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.image_sizes DROP CONSTRAINT IF EXISTS image_sizes_file_id_fkey;
ALTER TABLE IF EXISTS ONLY public.files DROP CONSTRAINT IF EXISTS files_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.file_entities DROP CONSTRAINT IF EXISTS file_entities_file_id_fkey;
ALTER TABLE IF EXISTS ONLY public.drafts DROP CONSTRAINT IF EXISTS drafts_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.drafts DROP CONSTRAINT IF EXISTS drafts_category_id_fkey;
ALTER TABLE IF EXISTS ONLY public.drafts DROP CONSTRAINT IF EXISTS drafts_board_id_fkey;
ALTER TABLE IF EXISTS ONLY public.comments DROP CONSTRAINT IF EXISTS comments_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.comments DROP CONSTRAINT IF EXISTS comments_post_id_fkey;
ALTER TABLE IF EXISTS ONLY public.comments DROP CONSTRAINT IF EXISTS comments_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_board_id_fkey;
ALTER TABLE IF EXISTS ONLY public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_user_id_fkey;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_sns_links_updated_at ON public.sns_links;
DROP TRIGGER IF EXISTS update_site_settings_updated_at ON public.site_settings;
DROP TRIGGER IF EXISTS update_site_info_updated_at ON public.site_info;
DROP TRIGGER IF EXISTS update_roles_updated_at ON public.roles;
DROP TRIGGER IF EXISTS update_posts_updated_at ON public.posts;
DROP TRIGGER IF EXISTS update_permissions_updated_at ON public.permissions;
DROP TRIGGER IF EXISTS update_pages_updated_at ON public.pages;
DROP TRIGGER IF EXISTS update_organization_info_updated_at ON public.organization_info;
DROP TRIGGER IF EXISTS update_menus_updated_at ON public.menus;
DROP TRIGGER IF EXISTS update_hero_sections_updated_at ON public.hero_sections;
DROP TRIGGER IF EXISTS update_galleries_updated_at ON public.galleries;
DROP TRIGGER IF EXISTS update_faqs_updated_at ON public.faqs;
DROP TRIGGER IF EXISTS update_drafts_updated_at ON public.drafts;
DROP TRIGGER IF EXISTS update_comments_updated_at ON public.comments;
DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
DROP TRIGGER IF EXISTS update_calendar_events_updated_at ON public.calendar_events;
DROP TRIGGER IF EXISTS update_boards_updated_at ON public.boards;
DROP INDEX IF EXISTS public.idx_users_status;
DROP INDEX IF EXISTS public.idx_users_email;
DROP INDEX IF EXISTS public.idx_user_roles_user_id;
DROP INDEX IF EXISTS public.idx_user_roles_role_id;
DROP INDEX IF EXISTS public.idx_sns_links_created_at;
DROP INDEX IF EXISTS public.idx_sns_links_active_order;
DROP INDEX IF EXISTS public.idx_site_info_created_at;
DROP INDEX IF EXISTS public.idx_roles_name;
DROP INDEX IF EXISTS public.idx_roles_active;
DROP INDEX IF EXISTS public.idx_role_permissions_role_id;
DROP INDEX IF EXISTS public.idx_role_permissions_permission_id;
DROP INDEX IF EXISTS public.idx_refresh_tokens_user_service;
DROP INDEX IF EXISTS public.idx_refresh_tokens_hash;
DROP INDEX IF EXISTS public.idx_posts_user_id;
DROP INDEX IF EXISTS public.idx_posts_title_gin;
DROP INDEX IF EXISTS public.idx_posts_status;
DROP INDEX IF EXISTS public.idx_posts_reading_time;
DROP INDEX IF EXISTS public.idx_posts_meta_title;
DROP INDEX IF EXISTS public.idx_posts_is_deleted;
DROP INDEX IF EXISTS public.idx_posts_created_at;
DROP INDEX IF EXISTS public.idx_posts_content_gin;
DROP INDEX IF EXISTS public.idx_posts_comment_count;
DROP INDEX IF EXISTS public.idx_posts_category_id;
DROP INDEX IF EXISTS public.idx_posts_board_id;
DROP INDEX IF EXISTS public.idx_point_transactions_user_id;
DROP INDEX IF EXISTS public.idx_permissions_resource_action;
DROP INDEX IF EXISTS public.idx_permissions_active;
DROP INDEX IF EXISTS public.idx_pages_status;
DROP INDEX IF EXISTS public.idx_pages_sort_order;
DROP INDEX IF EXISTS public.idx_pages_slug;
DROP INDEX IF EXISTS public.idx_pages_published;
DROP INDEX IF EXISTS public.idx_pages_created_at;
DROP INDEX IF EXISTS public.idx_notifications_user_id;
DROP INDEX IF EXISTS public.idx_notifications_read;
DROP INDEX IF EXISTS public.idx_menus_parent_id;
DROP INDEX IF EXISTS public.idx_menus_is_active;
DROP INDEX IF EXISTS public.idx_menus_display_order;
DROP INDEX IF EXISTS public.idx_likes_entity;
DROP INDEX IF EXISTS public.idx_files_user_id;
DROP INDEX IF EXISTS public.idx_files_status;
DROP INDEX IF EXISTS public.idx_file_entities_file_id;
DROP INDEX IF EXISTS public.idx_file_entities_entity;
DROP INDEX IF EXISTS public.idx_drafts_user_id;
DROP INDEX IF EXISTS public.idx_drafts_expires_at;
DROP INDEX IF EXISTS public.idx_comments_user_id;
DROP INDEX IF EXISTS public.idx_comments_post_id;
DROP INDEX IF EXISTS public.idx_comments_parent_id;
DROP INDEX IF EXISTS public.idx_categories_is_active;
DROP INDEX IF EXISTS public.idx_categories_board_id;
DROP INDEX IF EXISTS public.idx_calendar_events_is_public;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.user_social_accounts DROP CONSTRAINT IF EXISTS user_social_accounts_provider_provider_id_key;
ALTER TABLE IF EXISTS ONLY public.user_social_accounts DROP CONSTRAINT IF EXISTS user_social_accounts_pkey;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_role_id_key;
ALTER TABLE IF EXISTS ONLY public.user_roles DROP CONSTRAINT IF EXISTS user_roles_pkey;
ALTER TABLE IF EXISTS ONLY public.token_blacklist DROP CONSTRAINT IF EXISTS token_blacklist_token_jti_key;
ALTER TABLE IF EXISTS ONLY public.token_blacklist DROP CONSTRAINT IF EXISTS token_blacklist_pkey;
ALTER TABLE IF EXISTS ONLY public.sns_links DROP CONSTRAINT IF EXISTS sns_links_pkey;
ALTER TABLE IF EXISTS ONLY public.site_settings DROP CONSTRAINT IF EXISTS site_settings_pkey;
ALTER TABLE IF EXISTS ONLY public.site_settings DROP CONSTRAINT IF EXISTS site_settings_key_key;
ALTER TABLE IF EXISTS ONLY public.site_info DROP CONSTRAINT IF EXISTS site_info_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_name_key;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_role_id_permission_id_key;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.reports DROP CONSTRAINT IF EXISTS reports_pkey;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.posts DROP CONSTRAINT IF EXISTS posts_pkey;
ALTER TABLE IF EXISTS ONLY public.point_transactions DROP CONSTRAINT IF EXISTS point_transactions_pkey;
ALTER TABLE IF EXISTS ONLY public.permissions DROP CONSTRAINT IF EXISTS permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.permissions DROP CONSTRAINT IF EXISTS permissions_name_key;
ALTER TABLE IF EXISTS ONLY public.pages DROP CONSTRAINT IF EXISTS pages_slug_key;
ALTER TABLE IF EXISTS ONLY public.pages DROP CONSTRAINT IF EXISTS pages_pkey;
ALTER TABLE IF EXISTS ONLY public.organization_info DROP CONSTRAINT IF EXISTS organization_info_pkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.menus DROP CONSTRAINT IF EXISTS menus_pkey;
ALTER TABLE IF EXISTS ONLY public.likes DROP CONSTRAINT IF EXISTS likes_user_id_entity_type_entity_id_key;
ALTER TABLE IF EXISTS ONLY public.likes DROP CONSTRAINT IF EXISTS likes_pkey;
ALTER TABLE IF EXISTS ONLY public.image_sizes DROP CONSTRAINT IF EXISTS image_sizes_pkey;
ALTER TABLE IF EXISTS ONLY public.hero_sections DROP CONSTRAINT IF EXISTS hero_sections_pkey;
ALTER TABLE IF EXISTS ONLY public.galleries DROP CONSTRAINT IF EXISTS galleries_pkey;
ALTER TABLE IF EXISTS ONLY public.files DROP CONSTRAINT IF EXISTS files_pkey;
ALTER TABLE IF EXISTS ONLY public.file_entities DROP CONSTRAINT IF EXISTS file_entities_pkey;
ALTER TABLE IF EXISTS ONLY public.faqs DROP CONSTRAINT IF EXISTS faqs_pkey;
ALTER TABLE IF EXISTS ONLY public.drafts DROP CONSTRAINT IF EXISTS drafts_pkey;
ALTER TABLE IF EXISTS ONLY public.comments DROP CONSTRAINT IF EXISTS comments_pkey;
ALTER TABLE IF EXISTS ONLY public.categories DROP CONSTRAINT IF EXISTS categories_pkey;
ALTER TABLE IF EXISTS ONLY public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_pkey;
ALTER TABLE IF EXISTS ONLY public.boards DROP CONSTRAINT IF EXISTS boards_slug_unique;
ALTER TABLE IF EXISTS ONLY public.boards DROP CONSTRAINT IF EXISTS boards_slug_key;
ALTER TABLE IF EXISTS ONLY public.boards DROP CONSTRAINT IF EXISTS boards_pkey;
ALTER TABLE IF EXISTS ONLY public.boards DROP CONSTRAINT IF EXISTS boards_name_unique;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_social_accounts;
DROP TABLE IF EXISTS public.user_roles;
DROP TABLE IF EXISTS public.token_blacklist;
DROP TABLE IF EXISTS public.sns_links;
DROP TABLE IF EXISTS public.site_settings;
DROP TABLE IF EXISTS public.site_info;
DROP TABLE IF EXISTS public.roles;
DROP TABLE IF EXISTS public.role_permissions;
DROP TABLE IF EXISTS public.reports;
DROP TABLE IF EXISTS public.refresh_tokens;
DROP TABLE IF EXISTS public.posts;
DROP TABLE IF EXISTS public.point_transactions;
DROP TABLE IF EXISTS public.permissions;
DROP TABLE IF EXISTS public.pages;
DROP TABLE IF EXISTS public.organization_info;
DROP TABLE IF EXISTS public.notifications;
DROP TABLE IF EXISTS public.menus;
DROP TABLE IF EXISTS public.likes;
DROP TABLE IF EXISTS public.image_sizes;
DROP TABLE IF EXISTS public.hero_sections;
DROP TABLE IF EXISTS public.galleries;
DROP TABLE IF EXISTS public.files;
DROP TABLE IF EXISTS public.file_entities;
DROP TABLE IF EXISTS public.faqs;
DROP TABLE IF EXISTS public.drafts;
DROP TABLE IF EXISTS public.comments;
DROP TABLE IF EXISTS public.categories;
DROP TABLE IF EXISTS public.calendar_events;
DROP TABLE IF EXISTS public.boards;
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.increment_page_view_count(page_id uuid);
DROP FUNCTION IF EXISTS public.cleanup_orphaned_files();
DROP FUNCTION IF EXISTS public.cleanup_expired_drafts();
DROP TYPE IF EXISTS public.user_status;
DROP TYPE IF EXISTS public.user_role;
DROP TYPE IF EXISTS public.processing_status;
DROP TYPE IF EXISTS public.post_status;
DROP TYPE IF EXISTS public.notification_type;
DROP TYPE IF EXISTS public.menu_type;
DROP TYPE IF EXISTS public.file_type;
DROP TYPE IF EXISTS public.file_status;
DROP TYPE IF EXISTS public.file_purpose;
DROP TYPE IF EXISTS public.entity_type;
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pg_trgm;
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
-- Data for Name: boards; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.boards (id, name, slug, description, category, display_order, is_public, allow_anonymous, allow_file_upload, max_files, max_file_size, allowed_file_types, allow_rich_text, require_category, allow_comments, allow_likes, write_permission, list_permission, read_permission, reply_permission, comment_permission, download_permission, hide_list, editor_type, allow_search, allow_recommend, allow_disrecommend, show_author_name, show_ip, edit_comment_limit, delete_comment_limit, use_sns, use_captcha, title_length, posts_per_page, read_point, write_point, comment_point, download_point, created_at, updated_at, allowed_iframe_domains) FROM stdin;
30368058-a9be-49b5-a169-2c42e436e9b9	공지사항	notice	봉사단체의 공지사항을 전달합니다	notice	1	t	f	t	5	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-07 21:16:34.041214+00	\N
9dadb78e-a011-4ff0-8b5b-62b18e8cd443	봉사활동 후기	volunteer-review	봉사활동 참여 후기를 공유해주세요	review	2	t	f	t	5	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-07 21:16:34.041214+00	\N
0defeac6-ed18-40e1-b2e0-487781d4a4ac	자유게시판	free	자유롭게 소통하는 공간입니다	free	3	t	f	t	5	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-07 21:16:34.041214+00	\N
f632656c-fb87-4735-ab77-2e93ddb23f34	질문과 답변	qna	궁금한 것들을 질문해주세요	qna	4	t	f	t	5	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-07 21:16:34.041214+00	\N
b3b3b3b3-3333-3333-3333-333333333333	자료실	resource	유용한 자료를 공유하세요	resource	3	t	f	t	10	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.098662+00	2025-07-07 21:16:34.098662+00	\N
b4b4b4b4-4444-4444-4444-444444444444	갤러리	gallery	사진과 이미지를 공유하는 공간	media	4	t	f	t	20	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.098662+00	2025-07-07 21:16:34.098662+00	\N
8ec7b0bc-0b36-4865-8816-b476b1f390ca	익명게시판	abbs		\N	0	t	f	t	5	10485760	image/*	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-08 20:37:46.167403+00	2025-07-08 20:37:46.167403+00	\N
8800b948-9a32-4577-b2e9-b51429bd471a	센터소식	news		\N	0	t	f	t	5	10485760	image/*	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-08 20:39:21.551239+00	2025-07-08 20:39:21.551239+00	\N
\.


--
-- Data for Name: calendar_events; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.calendar_events (id, title, description, start_at, end_at, all_day, color, is_public, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.categories (id, board_id, name, description, display_order, is_active, created_at, updated_at) FROM stdin;
cf4dea4f-ae65-479f-bafd-771eae9109a2	8800b948-9a32-4577-b2e9-b51429bd471a	소식지		0	t	2025-07-08 20:39:47.621147+00	2025-07-08 20:39:47.621147+00
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.comments (id, post_id, user_id, parent_id, content, likes, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: drafts; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.drafts (id, user_id, board_id, category_id, title, content, auto_save_count, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: faqs; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.faqs (id, question, answer, category, display_order, is_active, created_at, updated_at) FROM stdin;
cde9c413-5b1a-4bb1-8dd8-b84eaba5428d	봉사활동에 참여하려면 어떻게 해야 하나요?	회원가입 후 원하는 봉사활동을 신청하시면 됩니다.	general	1	t	2025-07-07 21:16:34.042603+00	2025-07-07 21:16:34.042603+00
281e027d-6db7-47ed-89fa-ed70d596e1b4	봉사활동 참여 시 준비물이 있나요?	활동별로 다르며, 각 활동 상세페이지에서 확인할 수 있습니다.	general	2	t	2025-07-07 21:16:34.042603+00	2025-07-07 21:16:34.042603+00
653a1717-d933-4e22-9c5a-43a6151c7fc0	포인트는 어떻게 사용하나요?	포인트는 기부하거나 봉사활동 용품과 교환할 수 있습니다.	point	3	t	2025-07-07 21:16:34.042603+00	2025-07-07 21:16:34.042603+00
\.


--
-- Data for Name: file_entities; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.file_entities (id, file_id, entity_type, entity_id, file_purpose, display_order, created_at) FROM stdin;
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.files (id, user_id, original_name, stored_name, file_path, file_size, original_size, mime_type, file_type, status, compression_ratio, has_thumbnails, processing_status, created_at) FROM stdin;
\.


--
-- Data for Name: galleries; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.galleries (id, title, description, category, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: hero_sections; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.hero_sections (id, title, subtitle, description, image_url, button_text, button_link, is_active, display_order, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: image_sizes; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.image_sizes (id, file_id, size_name, width, height, file_path, file_size, format, created_at) FROM stdin;
\.


--
-- Data for Name: likes; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.likes (id, user_id, entity_type, entity_id, created_at) FROM stdin;
\.


--
-- Data for Name: menus; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.menus (id, name, description, menu_type, target_id, url, display_order, is_active, parent_id, created_at, updated_at) FROM stdin;
3f909e4d-b3e1-42d4-a939-041117449164	민들레는요	단체 소개	url	\N	/about	1	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
56213843-2ef9-40b3-9e32-1f0c67f15cbc	사업안내	봉사활동 안내	url	\N	/services	2	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
9d0c8ea9-d2c9-46b7-ae59-850423bda0e5	공지사항	회원 커뮤니티	board	30368058-a9be-49b5-a169-2c42e436e9b9		3	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
103202de-8d5f-482d-94d9-df9892a080c0	센터일정		calendar	\N	/calendar	4	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
7b3181bc-802f-48be-b2b3-4dbc59b0aaba	후원안내	후원 안내	url	\N	/donation	7	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
0c7bfe17-c05a-4b48-b2b5-8e00b20ac847	센터소식		board	8800b948-9a32-4577-b2e9-b51429bd471a		5	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
33a96986-e5c8-40e7-9792-b26bf2c8afbe	정보마당		board	0defeac6-ed18-40e1-b2e0-487781d4a4ac		6	t	\N	2025-07-08 20:46:38.420224+00	2025-07-08 20:46:38.420224+00
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.notifications (id, user_id, type, title, message, entity_type, entity_id, is_read, read_at, created_at) FROM stdin;
\.


--
-- Data for Name: organization_info; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.organization_info (id, name, description, address, phone, email, website, logo_url, established_year, created_at, updated_at) FROM stdin;
69260a1e-e09f-42a4-822b-03f537837e2d	따뜻한 마음 봉사단	장애인을 위한 다양한 봉사활동을 펼치는 단체입니다.	서울특별시 강남구 테헤란로 123	02-1234-5678	info@warmheart.org	\N	\N	\N	2025-07-07 21:16:34.04232+00	2025-07-07 21:16:34.04232+00
\.


--
-- Data for Name: pages; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.pages (id, slug, title, content, excerpt, meta_title, meta_description, status, is_published, published_at, created_by, created_at, updated_at, updated_by, view_count, sort_order) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.permissions (id, name, description, resource, action, is_active, created_at, updated_at) FROM stdin;
ec04bc0b-5eec-4989-ab20-a6d455cb80ba	users.read	사용자 목록 조회	users	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2	users.create	사용자 생성	users	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
e2af9343-75e3-42db-a678-c24cc1eb9dda	users.update	사용자 정보 수정	users	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
5cc786f4-510e-4e28-ab4d-f979ad2e90ab	users.delete	사용자 삭제	users	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05	users.roles	사용자 역할 관리	users	roles	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
188c9d63-b2a5-4f3a-88d3-4bf690ad715b	boards.read	게시판 목록 조회	boards	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
fc591480-ce7e-494a-abb1-f05da3b43c00	boards.create	게시판 생성	boards	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
c3f4db40-9e81-450e-884f-68f05a1b29ee	boards.update	게시판 수정	boards	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
05c8baa1-c491-4ad2-a35b-28028214048b	boards.delete	게시판 삭제	boards	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
dd955dd2-e944-4751-92b2-e9f4930d2171	posts.read	게시글 목록 조회	posts	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
7ee6b121-79d5-451a-882a-e10e4b65c7b2	posts.create	게시글 작성	posts	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
08e17652-fc1c-477f-874e-327ca6175930	posts.update	게시글 수정	posts	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
240e0131-8cae-4bd6-90ac-c8f17c8daced	posts.delete	게시글 삭제	posts	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
9eb4c166-f549-448f-9288-c1203f57f013	posts.moderate	게시글 중재	posts	moderate	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6	comments.read	댓글 목록 조회	comments	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a	comments.create	댓글 작성	comments	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
10d069a2-3995-45ff-a240-050f1fee0a7c	comments.update	댓글 수정	comments	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
586759ab-70e4-4909-81bc-cc9dbe76d64e	comments.delete	댓글 삭제	comments	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
5447679d-6216-4454-b8fa-f0bd7d8bb5f9	comments.moderate	댓글 중재	comments	moderate	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
38b38386-5b6a-4b4c-a774-dafb71663a9e	settings.read	사이트 설정 조회	settings	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
420d1ca8-24a1-4091-91ea-21e8fd898d36	settings.update	사이트 설정 수정	settings	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
53c54c43-725a-4ff2-96af-05b1f4a42600	menus.read	메뉴 목록 조회	menus	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
7ae0adf5-6894-4f27-b5e3-9a1252b64d48	menus.create	메뉴 생성	menus	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
c47f6b36-4cc9-43d9-bd58-6767eea06026	menus.update	메뉴 수정	menus	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
18329519-90f5-4c46-bae3-fe8a96440dcf	menus.delete	메뉴 삭제	menus	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
baf16a50-fe29-4664-ac57-aea87f27a8e1	pages.read	페이지 목록 조회	pages	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
53faa02c-0729-4db5-a672-47a689310388	pages.create	페이지 생성	pages	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae	pages.update	페이지 수정	pages	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
f3115d94-6574-4dcd-a693-cded458f6ec2	pages.delete	페이지 삭제	pages	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
d5fd800d-84e7-40d4-bb38-f802cbee49b3	calendar.read	일정 목록 조회	calendar	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
61a2391f-ed6a-47f7-a87e-e45087740bd3	calendar.create	일정 생성	calendar	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
c2083b31-4fa5-42dd-a264-679af6db51b2	calendar.update	일정 수정	calendar	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
90e15cca-f259-459b-a06d-ae7589882259	calendar.delete	일정 삭제	calendar	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
b819e4cd-d8f7-42b4-9adb-aeb96832dffd	roles.read	역할 목록 조회	roles	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
a71eebce-7bd1-4e1b-ba19-a87eefe1298a	roles.create	역할 생성	roles	create	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
06e77098-960c-4d8a-86a5-2919a5a463de	roles.update	역할 수정	roles	update	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
c87367bc-5722-47b9-a8d1-29664d67328a	roles.delete	역할 삭제	roles	delete	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
ba2168d1-a06b-491e-b73d-85f692a74fdb	permissions.read	권한 목록 조회	permissions	read	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
4ed5fa1f-bbb9-45fe-9e3c-95334b083c68	permissions.assign	권한 할당	permissions	assign	t	2025-07-07 21:16:34.091278+00	2025-07-07 21:16:34.091278+00
\.


--
-- Data for Name: point_transactions; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.point_transactions (id, user_id, type, amount, reason, reference_type, reference_id, created_at) FROM stdin;
\.


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.posts (id, board_id, category_id, user_id, title, content, views, likes, is_notice, status, created_at, updated_at, dislikes, meta_title, meta_description, meta_keywords, is_deleted, reading_time, comment_count, attached_files, thumbnail_urls) FROM stdin;
ea128cd1-e857-44f1-90bd-8fe4b3508918	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅅㄷㄴㅅ	<p>ㅁㅁㅁㅁ</p>	3	0	f	active	2025-07-08 05:20:38.320629+00	2025-07-08 05:28:05.781185+00	0	\N	\N	\N	f	\N	0	\N	\N
6cf46c4a-f972-4a9a-932a-b8fd063691d8	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	test	<p>aaaa</p>	0	0	f	active	2025-07-08 05:44:21.820352+00	2025-07-08 05:44:21.820352+00	0	\N	\N	\N	f	\N	0	\N	\N
41c1d208-be71-4b1b-ab57-b39855404258	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅁㅁㅁ	<p>ㅁㅁㅁㅁ</p>	0	0	f	active	2025-07-08 05:49:56.518586+00	2025-07-08 05:49:56.518586+00	0	\N	\N	\N	f	\N	0	\N	\N
a70fa13d-1df7-43db-a7b7-1a2e24185e6b	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㄱㄱㄱㄱㄱ	<p>ㄱㄱㄱㄱㄱㄱ</p>	0	0	f	active	2025-07-08 05:55:38.195796+00	2025-07-08 05:55:38.195796+00	0	\N	\N	\N	f	\N	0	\N	\N
aa919d94-b3a9-45fe-b36a-b6b147ee5031	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㄱㄱㄱㄱㄱ	<p>ㄱㄱㄱㄱㄱㄱ</p>	0	0	f	active	2025-07-08 05:59:11.772751+00	2025-07-08 05:59:11.772751+00	0	\N	\N	\N	f	\N	0	\N	\N
1b564544-2ea1-4305-a496-56ae7c9893c3	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	글쓰기 테스트	<p>ㅁㅁㅁㅁ</p>	2	0	f	active	2025-07-08 06:02:25.259406+00	2025-07-08 06:03:10.399075+00	0	\N	\N	\N	f	\N	0	\N	\N
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.refresh_tokens (id, user_id, token_hash, service_type, expires_at, created_at, is_revoked) FROM stdin;
e02575bf-87d0-4162-af0b-50a1e1c3d2ae	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d8f32d079d3112725e8c0d35300930b10b863dd37cd925ed547836f7da1cfe45	admin	2025-07-15 20:05:06.358821+00	2025-07-08 20:05:06.361705+00	t
423ed002-b305-4a4b-b08f-8f8ef19b9c2b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	0faad34240d13a0a95221a1d726b838affd104c5af3a26d426094ea457f72af1	admin	2025-08-06 21:43:52.080611+00	2025-07-07 21:43:52.086391+00	t
8b9f8919-3c81-4a07-aea2-dceba272d84f	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	1195dfbb84e5e4a7e23cff87046172ce28a08f6261d3f297cb181e9c0f8a211c	admin	2025-07-15 20:29:35.341625+00	2025-07-08 20:29:35.34182+00	f
1e759a9f-b8c8-4d7d-83b9-8ef972883a0d	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d25510e068a2d9ae22bc9742b71fff7b06352ca046fdc690d1801a61b58679a7	admin	2025-07-14 21:59:01.720444+00	2025-07-07 21:59:01.720816+00	t
83d30d81-cce7-46b4-bf8f-0c1cf8ef4078	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	8242668623f4b073dabd854543d297f555e01408cc0d16645019f88f34615e7a	admin	2025-08-07 20:37:26.021288+00	2025-07-08 20:37:26.027513+00	f
9feb4e06-2c7e-4702-ab74-2caf732d9a83	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	f4f2ef8e185e5a81aa6754c94cf924b21d6bd1367db1b89df17aa2e0e1334e1c	site	2025-07-15 05:55:27.917473+00	2025-07-08 05:55:27.918379+00	t
8bee1863-ad4f-43f1-b741-07944effc038	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8e4fd1e7ee2cace846ba455c3f9f4cb7d9c2272b3e445ab9fa4e2616aaf79bb9	site	2025-07-15 20:46:59.04733+00	2025-07-08 20:46:59.047523+00	f
d8c241ff-2833-49c2-aa4f-512573db7ed2	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e36b033816b158e52656cd85c090585793676c67147a674f2bebc3318cb628b2	admin	2025-07-15 04:00:03.665058+00	2025-07-08 04:00:03.664969+00	t
476d7da7-2a86-4c97-b73a-a768a92ff2f7	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	5fc254fce2536ac8f1e6749887e0b69c4b34d2b84ac78b6aa6c8158e5319080c	admin	2025-08-07 04:36:37.818005+00	2025-07-08 04:36:37.819834+00	f
d7e06050-f4c9-4bb6-b4ff-f5765856546e	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	075047cde831d81277312997bdbd9baa79751d6dd913437c4d238027a9daa2d0	admin	2025-08-07 04:38:17.807542+00	2025-07-08 04:38:17.813333+00	f
0494ee21-602b-48ea-9fbb-09394c240dfc	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	5f2f6ae3338edab559a347a21faa5ff20b8383cb9ca647ef7fbf9c39a0e8f3ce	admin	2025-07-15 04:33:35.23513+00	2025-07-08 04:33:35.235287+00	t
e408e44a-9123-4b39-a5ef-c76c50271474	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	8a7cabd7899e4ad2d3f9ae3a5b9d8ccbdb2b997dce9196d931d4e964a39d1c1e	admin	2025-07-15 04:51:06.524947+00	2025-07-08 04:51:06.525164+00	t
bf9bfbed-89e7-4d71-8d8f-a02d49cc7368	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e06eeabdcff8c04f6ab09c12b7f110cd5c2ab1dc4a9c7d6c24f75194e3be6144	admin	2025-07-15 05:06:32.8785+00	2025-07-08 05:06:32.885273+00	t
8bc16997-6605-4fa2-b4d0-cd18cc5075a2	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ac6af8b76d9ecd68539c24c818cd6f5c5c1b0a42091062b12614471f358974db	site	2025-07-14 21:48:51.626943+00	2025-07-07 21:48:51.627579+00	t
f0d5d335-f71f-4168-b630-a50f9186f4d8	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	2e9e2620a64ab3b4f8ddd11fdbc97241e3ccd99e7516ccd6d1b178f292205907	site	2025-07-14 21:48:58.418401+00	2025-07-07 21:48:58.418895+00	t
02bf1834-b001-43ae-9c0e-c47fbde44226	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	05ba4d03ba1f39eb487d3e9a61c979d72e4ef6b9a681657986969d6be339766c	site	2025-07-15 03:59:48.476648+00	2025-07-08 03:59:48.477262+00	t
0cfeee6b-2eef-401e-835d-71313c92bc03	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	edaf8cc0ac3594fd7fd571c7d56610fa35172d72124c29d94cf077b4694dd4fe	site	2025-07-15 04:23:21.848968+00	2025-07-08 04:23:21.85021+00	t
dfbd3ee6-904e-48b1-9d32-3159f970de37	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	96f9cf6b08247dccd88a2df25b7f36f43725f3f9b8610bd751af9bd09a318ceb	site	2025-07-15 04:40:54.174715+00	2025-07-08 04:40:54.174804+00	t
8bb9bdf0-617d-449c-bb96-5dfd60e8b46b	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	81c941593d9d1916d7b9724062682153e771f8719bd2106bc31e81f343272024	site	2025-07-15 05:20:28.126501+00	2025-07-08 05:20:28.127661+00	t
472a3de4-cb03-493c-8c23-ccb8181e6353	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	b8b7d7ad65f0259f57dc0fd96e543827de9efcebb67c7d571165e58445662e4b	site	2025-07-15 05:44:10.590677+00	2025-07-08 05:44:10.590969+00	t
1355e0af-0e53-4869-a38c-b4dbd9301fc0	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	f76e93e32f6e741e2a91d1c2a0bdeb7bf321248e444edd66ac71ec747f6ccf96	admin	2025-07-15 05:22:12.881687+00	2025-07-08 05:22:12.882435+00	t
6b183064-7a6f-4c9c-bd4b-0e89eab812a4	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	450752538ae148d3cd2bccd4ef001c4cf31915fa5a3b3ca1264b914841b289a4	admin	2025-07-15 06:16:08.266344+00	2025-07-08 06:16:08.266866+00	t
56ec508a-c095-4ec3-b914-f949e8229cbc	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	eb4659b2c954411d2b4db8e0b98d661bc348dcf81e8f5be8e3f6ebff808d7672	admin	2025-07-15 07:43:32.592079+00	2025-07-08 07:43:32.591902+00	t
aaecda40-9ae6-40aa-ab84-d56ff43381b7	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	936c5fb1e1d040771e53a4c066e85b4108cd09cd7ccbce9f353e20a396c13f48	admin	2025-07-15 08:20:17.141037+00	2025-07-08 08:20:17.141093+00	t
73ca649f-af7e-4be4-a08f-f3cf29a0d194	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d784ff87f5b71d83a19f7355f1e8824d60ddfa285eb0df7b4221978db146fee4	admin	2025-07-15 19:47:05.529629+00	2025-07-08 19:47:05.530326+00	t
\.


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.reports (id, reporter_id, entity_type, entity_id, reason, status, admin_note, resolved_by, resolved_at, created_at) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.role_permissions (id, role_id, permission_id, created_at) FROM stdin;
0779eeab-3716-411a-a377-0500995e1b5f	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	ec04bc0b-5eec-4989-ab20-a6d455cb80ba	2025-07-07 21:16:34.092155+00
2078dab8-36d2-4dd5-940f-b08d78b778ef	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2	2025-07-07 21:16:34.092155+00
22298d25-8a0f-4e52-bb6d-2f81b2c5fe32	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	e2af9343-75e3-42db-a678-c24cc1eb9dda	2025-07-07 21:16:34.092155+00
8546ea65-3123-49c1-be9e-cd28b9ec018d	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	5cc786f4-510e-4e28-ab4d-f979ad2e90ab	2025-07-07 21:16:34.092155+00
7e363ce9-bd58-4d0f-9427-24ac7b923a54	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05	2025-07-07 21:16:34.092155+00
8fa978ab-3c0d-4c3e-890a-d0a610b619d4	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	188c9d63-b2a5-4f3a-88d3-4bf690ad715b	2025-07-07 21:16:34.092155+00
ace5acfc-175a-4ddc-a3d8-d4ab8d0aa5e7	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	fc591480-ce7e-494a-abb1-f05da3b43c00	2025-07-07 21:16:34.092155+00
5048e6e5-9297-4ec9-9220-36aeac7f3c42	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	c3f4db40-9e81-450e-884f-68f05a1b29ee	2025-07-07 21:16:34.092155+00
96e069bb-3590-469e-8791-83588ed7c1b7	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	05c8baa1-c491-4ad2-a35b-28028214048b	2025-07-07 21:16:34.092155+00
b78df2a8-5b95-4f6b-84c1-9952014c9d75	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	dd955dd2-e944-4751-92b2-e9f4930d2171	2025-07-07 21:16:34.092155+00
5dcdb54e-5a7a-4184-9b53-0e00d815d30b	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	7ee6b121-79d5-451a-882a-e10e4b65c7b2	2025-07-07 21:16:34.092155+00
d5275b2f-f698-4745-a8a8-f811f830dc4b	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	08e17652-fc1c-477f-874e-327ca6175930	2025-07-07 21:16:34.092155+00
9b594d27-8b10-47bb-9e40-e754ae584121	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	240e0131-8cae-4bd6-90ac-c8f17c8daced	2025-07-07 21:16:34.092155+00
e8839c2c-2cf1-4a13-bd0a-39197b4ad3ad	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	9eb4c166-f549-448f-9288-c1203f57f013	2025-07-07 21:16:34.092155+00
e4640d9f-cad4-4807-92cf-13b6906348fc	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6	2025-07-07 21:16:34.092155+00
420b4e25-e7c6-405a-b5b0-5f25fad408ef	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a	2025-07-07 21:16:34.092155+00
0767e146-7ba8-410f-b670-55e1818f3362	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	10d069a2-3995-45ff-a240-050f1fee0a7c	2025-07-07 21:16:34.092155+00
a74ecb80-4089-4379-b809-1c21ddbccea3	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	586759ab-70e4-4909-81bc-cc9dbe76d64e	2025-07-07 21:16:34.092155+00
c042cbbf-0e70-4b35-a8a9-d4a5a12d00d5	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	5447679d-6216-4454-b8fa-f0bd7d8bb5f9	2025-07-07 21:16:34.092155+00
b7b1437e-255b-4032-a421-9ca04514a4b8	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	38b38386-5b6a-4b4c-a774-dafb71663a9e	2025-07-07 21:16:34.092155+00
f4b2e88e-caea-4a44-afd6-d64f95c9e5e8	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	420d1ca8-24a1-4091-91ea-21e8fd898d36	2025-07-07 21:16:34.092155+00
ee18b04a-eea9-4f18-b5a6-503e587bde85	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	53c54c43-725a-4ff2-96af-05b1f4a42600	2025-07-07 21:16:34.092155+00
404b09c8-7a54-417b-ab45-c5788b7edf4b	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	7ae0adf5-6894-4f27-b5e3-9a1252b64d48	2025-07-07 21:16:34.092155+00
9e0fab3f-85b2-4be7-b437-a4751e3deec9	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	c47f6b36-4cc9-43d9-bd58-6767eea06026	2025-07-07 21:16:34.092155+00
01af102f-561c-4217-90bc-4323d582af48	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	18329519-90f5-4c46-bae3-fe8a96440dcf	2025-07-07 21:16:34.092155+00
2a7aa6ff-05fa-4a52-a20f-ffbb083c98f7	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	baf16a50-fe29-4664-ac57-aea87f27a8e1	2025-07-07 21:16:34.092155+00
4961d76b-e0bb-4af8-87fb-5d69fb177be0	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	53faa02c-0729-4db5-a672-47a689310388	2025-07-07 21:16:34.092155+00
a6e58c74-b071-4605-beab-5b3dc39fc2af	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae	2025-07-07 21:16:34.092155+00
7174a42a-ece2-46e7-884e-470d09acbd01	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	f3115d94-6574-4dcd-a693-cded458f6ec2	2025-07-07 21:16:34.092155+00
ca17392b-2254-4d06-a47c-7aa503b2cb95	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	d5fd800d-84e7-40d4-bb38-f802cbee49b3	2025-07-07 21:16:34.092155+00
60880c49-15b5-4bc2-b90e-44206d137d53	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	61a2391f-ed6a-47f7-a87e-e45087740bd3	2025-07-07 21:16:34.092155+00
88224f53-24fd-45d1-bea0-dab8c3729cc3	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	c2083b31-4fa5-42dd-a264-679af6db51b2	2025-07-07 21:16:34.092155+00
2a739c33-905d-4ffc-aca1-b1e28a4d6707	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	90e15cca-f259-459b-a06d-ae7589882259	2025-07-07 21:16:34.092155+00
bdf2b4df-e269-4ccf-a297-f0df86421980	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	b819e4cd-d8f7-42b4-9adb-aeb96832dffd	2025-07-07 21:16:34.092155+00
3a5dad32-55fc-485d-a750-801fd6b787c6	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	a71eebce-7bd1-4e1b-ba19-a87eefe1298a	2025-07-07 21:16:34.092155+00
f552bcec-7834-48ce-b6fe-b03a1c48a30a	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	06e77098-960c-4d8a-86a5-2919a5a463de	2025-07-07 21:16:34.092155+00
8235fa9f-8e8e-41a4-aa4a-0374dc46d02a	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	c87367bc-5722-47b9-a8d1-29664d67328a	2025-07-07 21:16:34.092155+00
f009bcb2-1deb-49d0-b81a-6b2582f52aee	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	ba2168d1-a06b-491e-b73d-85f692a74fdb	2025-07-07 21:16:34.092155+00
c29c5b4d-c341-44fb-8fa4-41f21aa34292	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	4ed5fa1f-bbb9-45fe-9e3c-95334b083c68	2025-07-07 21:16:34.092155+00
23c04b3c-873a-467d-a67d-716edcac7b78	7f188600-b0ed-4dc6-bcdb-74c9916989ed	ec04bc0b-5eec-4989-ab20-a6d455cb80ba	2025-07-07 21:16:34.09402+00
6df4409e-bb34-4e47-97fc-41fcc9414042	7f188600-b0ed-4dc6-bcdb-74c9916989ed	6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2	2025-07-07 21:16:34.09402+00
785950b7-b7ac-476e-828b-6433b5430837	7f188600-b0ed-4dc6-bcdb-74c9916989ed	e2af9343-75e3-42db-a678-c24cc1eb9dda	2025-07-07 21:16:34.09402+00
a8ce7a39-0cea-4abf-bf8e-7797fe87bff1	7f188600-b0ed-4dc6-bcdb-74c9916989ed	5cc786f4-510e-4e28-ab4d-f979ad2e90ab	2025-07-07 21:16:34.09402+00
6828dff1-14df-45d2-8951-a3a21f953e74	7f188600-b0ed-4dc6-bcdb-74c9916989ed	05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05	2025-07-07 21:16:34.09402+00
624de6a9-d45b-493a-860e-54717a468b3c	7f188600-b0ed-4dc6-bcdb-74c9916989ed	188c9d63-b2a5-4f3a-88d3-4bf690ad715b	2025-07-07 21:16:34.09402+00
3b94c3a6-3ad4-4390-ab5e-0d2eb9de80af	7f188600-b0ed-4dc6-bcdb-74c9916989ed	fc591480-ce7e-494a-abb1-f05da3b43c00	2025-07-07 21:16:34.09402+00
55d0d454-81c0-49d2-b22b-e93f851db71d	7f188600-b0ed-4dc6-bcdb-74c9916989ed	c3f4db40-9e81-450e-884f-68f05a1b29ee	2025-07-07 21:16:34.09402+00
f6b34c3d-e4a9-4210-a41a-57f065098c7f	7f188600-b0ed-4dc6-bcdb-74c9916989ed	05c8baa1-c491-4ad2-a35b-28028214048b	2025-07-07 21:16:34.09402+00
b2d9748a-1e4f-48cb-97cc-017ebd83de04	7f188600-b0ed-4dc6-bcdb-74c9916989ed	dd955dd2-e944-4751-92b2-e9f4930d2171	2025-07-07 21:16:34.09402+00
b3e71174-c76c-4d21-b224-60a685b97584	7f188600-b0ed-4dc6-bcdb-74c9916989ed	7ee6b121-79d5-451a-882a-e10e4b65c7b2	2025-07-07 21:16:34.09402+00
a30890d0-2f65-43d5-bd80-2f0b32baed5f	7f188600-b0ed-4dc6-bcdb-74c9916989ed	08e17652-fc1c-477f-874e-327ca6175930	2025-07-07 21:16:34.09402+00
ba6bc1f8-ef24-4533-b3ad-c3e25f85978a	7f188600-b0ed-4dc6-bcdb-74c9916989ed	240e0131-8cae-4bd6-90ac-c8f17c8daced	2025-07-07 21:16:34.09402+00
3aac42e4-75fb-4338-84b3-4f1ac3074d51	7f188600-b0ed-4dc6-bcdb-74c9916989ed	9eb4c166-f549-448f-9288-c1203f57f013	2025-07-07 21:16:34.09402+00
942c9001-01c7-44d8-b386-53e6471d0293	7f188600-b0ed-4dc6-bcdb-74c9916989ed	0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6	2025-07-07 21:16:34.09402+00
03c5a632-402d-4afb-86a9-f845a01fbb1b	7f188600-b0ed-4dc6-bcdb-74c9916989ed	1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a	2025-07-07 21:16:34.09402+00
305ce1da-6638-4a88-a422-a322006f90c8	7f188600-b0ed-4dc6-bcdb-74c9916989ed	10d069a2-3995-45ff-a240-050f1fee0a7c	2025-07-07 21:16:34.09402+00
e4c7f1f8-e3f3-403f-9ec0-06a7b38d95ce	7f188600-b0ed-4dc6-bcdb-74c9916989ed	586759ab-70e4-4909-81bc-cc9dbe76d64e	2025-07-07 21:16:34.09402+00
575d13d6-7872-4e54-9df5-ebb7a7865a31	7f188600-b0ed-4dc6-bcdb-74c9916989ed	5447679d-6216-4454-b8fa-f0bd7d8bb5f9	2025-07-07 21:16:34.09402+00
59d2f403-fc32-422f-bd85-c45ff70ae45c	7f188600-b0ed-4dc6-bcdb-74c9916989ed	38b38386-5b6a-4b4c-a774-dafb71663a9e	2025-07-07 21:16:34.09402+00
d7624e50-1106-4692-9257-4254adae1d3f	7f188600-b0ed-4dc6-bcdb-74c9916989ed	420d1ca8-24a1-4091-91ea-21e8fd898d36	2025-07-07 21:16:34.09402+00
75c1c1a5-0f37-4d38-b372-eb8579083f33	7f188600-b0ed-4dc6-bcdb-74c9916989ed	53c54c43-725a-4ff2-96af-05b1f4a42600	2025-07-07 21:16:34.09402+00
baead867-4d08-49cd-96e5-9508db057bbf	7f188600-b0ed-4dc6-bcdb-74c9916989ed	7ae0adf5-6894-4f27-b5e3-9a1252b64d48	2025-07-07 21:16:34.09402+00
a4b5faaf-a0b4-4a2d-a9cd-3c07bc7714f8	7f188600-b0ed-4dc6-bcdb-74c9916989ed	c47f6b36-4cc9-43d9-bd58-6767eea06026	2025-07-07 21:16:34.09402+00
de086aad-33a1-45da-86bc-74332f0a3c0c	7f188600-b0ed-4dc6-bcdb-74c9916989ed	18329519-90f5-4c46-bae3-fe8a96440dcf	2025-07-07 21:16:34.09402+00
e918c10b-3912-47c9-b9cc-f8ab42502234	7f188600-b0ed-4dc6-bcdb-74c9916989ed	baf16a50-fe29-4664-ac57-aea87f27a8e1	2025-07-07 21:16:34.09402+00
8c9846fc-52d3-406d-a756-780dd441a05f	7f188600-b0ed-4dc6-bcdb-74c9916989ed	53faa02c-0729-4db5-a672-47a689310388	2025-07-07 21:16:34.09402+00
96a99fe4-de59-42ba-91fe-b7fa1f3cf1e1	7f188600-b0ed-4dc6-bcdb-74c9916989ed	5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae	2025-07-07 21:16:34.09402+00
f0dad0d7-87e3-4a39-a0d5-fe8ff5dc0d44	7f188600-b0ed-4dc6-bcdb-74c9916989ed	f3115d94-6574-4dcd-a693-cded458f6ec2	2025-07-07 21:16:34.09402+00
d83a401d-a9d6-44cc-9660-4ec779f81d9c	7f188600-b0ed-4dc6-bcdb-74c9916989ed	d5fd800d-84e7-40d4-bb38-f802cbee49b3	2025-07-07 21:16:34.09402+00
f3fcecca-5c1b-48c4-9dec-01eed650a489	7f188600-b0ed-4dc6-bcdb-74c9916989ed	61a2391f-ed6a-47f7-a87e-e45087740bd3	2025-07-07 21:16:34.09402+00
fbb0139d-8c54-4979-87ee-bec460a0c7d5	7f188600-b0ed-4dc6-bcdb-74c9916989ed	c2083b31-4fa5-42dd-a264-679af6db51b2	2025-07-07 21:16:34.09402+00
df8acee6-e8e7-4651-bace-8bc305464ce8	7f188600-b0ed-4dc6-bcdb-74c9916989ed	90e15cca-f259-459b-a06d-ae7589882259	2025-07-07 21:16:34.09402+00
159268e9-c42e-4f25-aa9a-12966492acf5	7f188600-b0ed-4dc6-bcdb-74c9916989ed	b819e4cd-d8f7-42b4-9adb-aeb96832dffd	2025-07-07 21:16:34.09402+00
bddc05f0-549f-4078-ac02-f50483acffe5	7f188600-b0ed-4dc6-bcdb-74c9916989ed	a71eebce-7bd1-4e1b-ba19-a87eefe1298a	2025-07-07 21:16:34.09402+00
6c875207-f52c-4daa-aee2-69e4b319325d	7f188600-b0ed-4dc6-bcdb-74c9916989ed	06e77098-960c-4d8a-86a5-2919a5a463de	2025-07-07 21:16:34.09402+00
c6e5b7f2-699d-4c59-a012-53598837825d	7f188600-b0ed-4dc6-bcdb-74c9916989ed	ba2168d1-a06b-491e-b73d-85f692a74fdb	2025-07-07 21:16:34.09402+00
b61d745c-e910-488f-8f7b-04e1033cb233	950fce82-5b3a-4b1b-b2f1-8f67557ed209	188c9d63-b2a5-4f3a-88d3-4bf690ad715b	2025-07-07 21:16:34.095625+00
2f69cc9d-3f9e-45e6-82db-a2458a731704	950fce82-5b3a-4b1b-b2f1-8f67557ed209	fc591480-ce7e-494a-abb1-f05da3b43c00	2025-07-07 21:16:34.095625+00
174a6f74-a70d-4022-9dd2-77cec15dac45	950fce82-5b3a-4b1b-b2f1-8f67557ed209	c3f4db40-9e81-450e-884f-68f05a1b29ee	2025-07-07 21:16:34.095625+00
8464a36d-84c2-48cd-ae9e-b48a0baad4e1	950fce82-5b3a-4b1b-b2f1-8f67557ed209	05c8baa1-c491-4ad2-a35b-28028214048b	2025-07-07 21:16:34.095625+00
31178319-88f5-4397-be58-0fe13f5ceb3a	950fce82-5b3a-4b1b-b2f1-8f67557ed209	dd955dd2-e944-4751-92b2-e9f4930d2171	2025-07-07 21:16:34.095625+00
ad7489be-49b1-4554-acba-ebf5e2fe3791	950fce82-5b3a-4b1b-b2f1-8f67557ed209	7ee6b121-79d5-451a-882a-e10e4b65c7b2	2025-07-07 21:16:34.095625+00
c88bfc13-b511-45bf-b974-5bdca8580ed5	950fce82-5b3a-4b1b-b2f1-8f67557ed209	08e17652-fc1c-477f-874e-327ca6175930	2025-07-07 21:16:34.095625+00
62f0d228-f6ef-4f2f-b266-4e77bb74828a	950fce82-5b3a-4b1b-b2f1-8f67557ed209	240e0131-8cae-4bd6-90ac-c8f17c8daced	2025-07-07 21:16:34.095625+00
1e14e978-0b33-44ae-9b8b-3bc5d05979b3	950fce82-5b3a-4b1b-b2f1-8f67557ed209	9eb4c166-f549-448f-9288-c1203f57f013	2025-07-07 21:16:34.095625+00
2b54290b-5ec0-4247-94c9-78a49329b3ee	950fce82-5b3a-4b1b-b2f1-8f67557ed209	0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6	2025-07-07 21:16:34.095625+00
3e43e7b8-b80f-4f37-9702-f5df2412bad8	950fce82-5b3a-4b1b-b2f1-8f67557ed209	1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a	2025-07-07 21:16:34.095625+00
e3fcb82a-0d05-48b8-ae98-77c9ab1a4537	950fce82-5b3a-4b1b-b2f1-8f67557ed209	10d069a2-3995-45ff-a240-050f1fee0a7c	2025-07-07 21:16:34.095625+00
f8444551-b528-4950-9054-64a1b4841b84	950fce82-5b3a-4b1b-b2f1-8f67557ed209	586759ab-70e4-4909-81bc-cc9dbe76d64e	2025-07-07 21:16:34.095625+00
808022d7-4116-4604-8118-3e9ab863f025	950fce82-5b3a-4b1b-b2f1-8f67557ed209	5447679d-6216-4454-b8fa-f0bd7d8bb5f9	2025-07-07 21:16:34.095625+00
5f3cb039-27c2-4104-8dff-b95b038afbab	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	7ee6b121-79d5-451a-882a-e10e4b65c7b2	2025-07-07 21:16:34.096305+00
5667bd8e-40c9-4d11-b6ad-56f6a4145ff2	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	08e17652-fc1c-477f-874e-327ca6175930	2025-07-07 21:16:34.096305+00
c899f505-255e-4904-8d08-cc7ffe71b90a	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a	2025-07-07 21:16:34.096305+00
46dc73e3-bdd7-4cbe-8e15-7002b9cd6040	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	10d069a2-3995-45ff-a240-050f1fee0a7c	2025-07-07 21:16:34.096305+00
c5617ea4-a1da-49e8-9728-681ac9f852a3	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	baf16a50-fe29-4664-ac57-aea87f27a8e1	2025-07-07 21:16:34.096305+00
3c5fb600-0320-4c37-b1d9-f129e97b74c9	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	53faa02c-0729-4db5-a672-47a689310388	2025-07-07 21:16:34.096305+00
52d65744-2a90-47b4-bddf-4d3715359221	4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae	2025-07-07 21:16:34.096305+00
9411ce75-3aeb-432b-82bb-93219d9035ef	3ae58427-d64c-417e-903c-fee48fd5b5e5	ec04bc0b-5eec-4989-ab20-a6d455cb80ba	2025-07-07 21:16:34.096691+00
f698901a-d95e-488b-8cf3-d457bca72071	3ae58427-d64c-417e-903c-fee48fd5b5e5	188c9d63-b2a5-4f3a-88d3-4bf690ad715b	2025-07-07 21:16:34.096691+00
1208f171-f1b9-486e-b366-ef39b03babe0	3ae58427-d64c-417e-903c-fee48fd5b5e5	dd955dd2-e944-4751-92b2-e9f4930d2171	2025-07-07 21:16:34.096691+00
2066e521-8e19-4e0e-bef0-02c3ce989e73	3ae58427-d64c-417e-903c-fee48fd5b5e5	0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6	2025-07-07 21:16:34.096691+00
1cb15376-1cef-470f-9e42-8203e62f05c1	3ae58427-d64c-417e-903c-fee48fd5b5e5	38b38386-5b6a-4b4c-a774-dafb71663a9e	2025-07-07 21:16:34.096691+00
952f8494-27cd-448b-bb48-1d09ab733f4c	3ae58427-d64c-417e-903c-fee48fd5b5e5	53c54c43-725a-4ff2-96af-05b1f4a42600	2025-07-07 21:16:34.096691+00
38fffee5-da00-41f0-af8d-2d804e9339b7	3ae58427-d64c-417e-903c-fee48fd5b5e5	baf16a50-fe29-4664-ac57-aea87f27a8e1	2025-07-07 21:16:34.096691+00
c715b251-5de0-4541-80be-e3bfa74369a9	3ae58427-d64c-417e-903c-fee48fd5b5e5	d5fd800d-84e7-40d4-bb38-f802cbee49b3	2025-07-07 21:16:34.096691+00
1a3d49ef-1737-4a00-92ae-c27e3cd8506d	3ae58427-d64c-417e-903c-fee48fd5b5e5	b819e4cd-d8f7-42b4-9adb-aeb96832dffd	2025-07-07 21:16:34.096691+00
7bef0c1c-b668-4601-90aa-720403648986	3ae58427-d64c-417e-903c-fee48fd5b5e5	ba2168d1-a06b-491e-b73d-85f692a74fdb	2025-07-07 21:16:34.096691+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.roles (id, name, description, is_active, created_at, updated_at) FROM stdin;
8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	super_admin	시스템 전체 관리자 - 모든 권한을 가짐	t	2025-07-07 21:16:34.090338+00	2025-07-07 21:16:34.090338+00
7f188600-b0ed-4dc6-bcdb-74c9916989ed	admin	일반 관리자 - 대부분의 관리 기능 사용 가능	t	2025-07-07 21:16:34.090338+00	2025-07-07 21:16:34.090338+00
950fce82-5b3a-4b1b-b2f1-8f67557ed209	moderator	중재자 - 게시글과 댓글 관리	t	2025-07-07 21:16:34.090338+00	2025-07-07 21:16:34.090338+00
4726d5b0-f6fb-4b9f-b65c-eec8df933dbc	editor	편집자 - 콘텐츠 작성 및 편집	t	2025-07-07 21:16:34.090338+00	2025-07-07 21:16:34.090338+00
3ae58427-d64c-417e-903c-fee48fd5b5e5	viewer	조회자 - 읽기 전용 권한	t	2025-07-07 21:16:34.090338+00	2025-07-07 21:16:34.090338+00
\.


--
-- Data for Name: site_info; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.site_info (id, site_name, catchphrase, address, phone, email, homepage, fax, representative_name, business_number, logo_image_url, created_at, updated_at) FROM stdin;
7486aeef-6900-41cc-954a-2d7eb82c449d	민들레장애인자립생활센터	함께 만들어가는 따뜻한 세상	인천광역시 계양구 계산새로71 A동 201~202호(계산동, 하이베라스)	032-542-9294	mincenter08@daum.net	https://mincenter.kr	032-232-0739	박길연	131-80-12554	\N	2025-07-07 21:16:34.097196+00	2025-07-07 21:16:34.097196+00
\.


--
-- Data for Name: site_settings; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.site_settings (id, key, value, description, created_at, updated_at) FROM stdin;
40c0b129-de44-48ae-bbbe-945c7ecdaf5f	site_name	따뜻한 마음 봉사단	사이트 이름	2025-07-07 21:16:34.042949+00	2025-07-07 21:16:34.042949+00
c65c5f20-5396-4ec5-b6ac-194ca71a411e	max_file_size	10485760	최대 파일 업로드 크기 (10MB)	2025-07-07 21:16:34.042949+00	2025-07-07 21:16:34.042949+00
2f7675c6-c8d3-4dff-964a-542e39dd6192	points_per_post	10	게시글 작성 시 적립 포인트	2025-07-07 21:16:34.042949+00	2025-07-07 21:16:34.042949+00
0890f05a-1c1a-431e-934b-d787ceb6c9d6	points_per_comment	5	댓글 작성 시 적립 포인트	2025-07-07 21:16:34.042949+00	2025-07-07 21:16:34.042949+00
e2f4fe32-95ce-4086-91ef-2860fdf1050b	draft_expire_days	7	임시저장 만료 일수	2025-07-07 21:16:34.042949+00	2025-07-07 21:16:34.042949+00
\.


--
-- Data for Name: sns_links; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.sns_links (id, name, url, icon, icon_type, display_order, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: token_blacklist; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.token_blacklist (id, token_jti, user_id, expires_at, created_at) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.user_roles (id, user_id, role_id, created_at) FROM stdin;
646a2c09-0ad0-4077-80db-a51162a3d890	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa	2025-07-07 21:16:34.097923+00
22c9676e-ee3c-45bb-8010-bf239ab5d194	16f15cc1-479e-4dc4-9acc-f874a0ac4f1a	7f188600-b0ed-4dc6-bcdb-74c9916989ed	2025-07-07 21:16:34.098446+00
\.


--
-- Data for Name: user_social_accounts; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.user_social_accounts (id, user_id, provider, provider_id, provider_email, access_token, refresh_token, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.users (id, email, password_hash, name, phone, profile_image, points, role, status, email_verified, email_verified_at, last_login_at, created_at, updated_at) FROM stdin;
e7e9319f-6c49-4b9c-9bbf-b86b5c2b6598	admin@example.com	$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e	관리자	\N	\N	0	admin	active	t	\N	\N	2025-07-07 21:16:34.043445+00	2025-07-07 21:16:34.043445+00
16f15cc1-479e-4dc4-9acc-f874a0ac4f1a	manager@mincenter.kr	$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG	센터 관리자	\N	\N	0	admin	active	t	\N	\N	2025-07-07 21:16:34.097526+00	2025-07-07 21:16:34.097526+00
81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	jp9731kr@gmail.com	$2b$12$sTEOv0xC8zobJqNE0aW3lOa/oxWQZoxVyDxpzrXFwk5U8ghJR71EK	임종필	\N	\N	0	user	active	f	\N	\N	2025-07-07 21:48:51.62173+00	2025-07-07 21:48:51.62173+00
0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	admin@mincenter.kr	$2b$12$zeKomcjdMt/y17Gp1mFMNuWZDWeSdsSVtJJEyfXgkl.0A6MhFg0mW	시스템 관리자	\N	\N	0	admin	active	t	\N	\N	2025-07-07 21:16:34.097526+00	2025-07-08 04:36:29.785397+00
\.


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

