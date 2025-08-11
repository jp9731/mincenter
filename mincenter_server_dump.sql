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
-- Name: update_post_reply_count(); Type: FUNCTION; Schema: public; Owner: mincenter
--

CREATE FUNCTION public.update_post_reply_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- 새 댓글이 추가될 때 부모 게시글의 reply_count 증가
        UPDATE posts 
        SET reply_count = reply_count + 1 
        WHERE id = NEW.parent_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- 댓글이 삭제될 때 부모 게시글의 reply_count 감소
        UPDATE posts 
        SET reply_count = GREATEST(reply_count - 1, 0) 
        WHERE id = OLD.parent_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.update_post_reply_count() OWNER TO mincenter;

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

--
-- Name: korean; Type: TEXT SEARCH CONFIGURATION; Schema: public; Owner: mincenter
--

CREATE TEXT SEARCH CONFIGURATION public.korean (
    PARSER = pg_catalog."default" );

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR asciiword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR word WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR numword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR email WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR url WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR host WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR sfloat WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR version WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR hword_numpart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR hword_part WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR hword_asciipart WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR numhword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR asciihword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR hword WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR url_path WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR file WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR "float" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR "int" WITH simple;

ALTER TEXT SEARCH CONFIGURATION public.korean
    ADD MAPPING FOR uint WITH simple;


ALTER TEXT SEARCH CONFIGURATION public.korean OWNER TO mincenter;

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
    updated_at timestamp with time zone DEFAULT now(),
    depth integer DEFAULT 0,
    is_deleted boolean DEFAULT false
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
    CONSTRAINT pages_status_check CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('published'::character varying)::text, ('archived'::character varying)::text])))
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
    thumbnail_urls jsonb,
    parent_id uuid,
    depth integer DEFAULT 0,
    reply_count integer DEFAULT 0
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
9dadb78e-a011-4ff0-8b5b-62b18e8cd443	봉사활동 후기	volunteer-review	봉사활동 참여 후기를 공유해주세요	review	2	t	f	t	5	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-07 21:16:34.041214+00	\N
f632656c-fb87-4735-ab77-2e93ddb23f34	질문과 답변	qna	궁금한 것들을 질문해주세요	qna	4	t	f	t	5	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-07 21:16:34.041214+00	\N
b3b3b3b3-3333-3333-3333-333333333333	자료실	resource	유용한 자료를 공유하세요	resource	3	t	f	t	10	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.098662+00	2025-07-07 21:16:34.098662+00	\N
b4b4b4b4-4444-4444-4444-444444444444	갤러리	gallery	사진과 이미지를 공유하는 공간	media	4	t	f	t	20	10485760	\N	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.098662+00	2025-07-07 21:16:34.098662+00	\N
8ec7b0bc-0b36-4865-8816-b476b1f390ca	익명게시판	abbs		\N	0	t	f	t	5	10485760	image/*	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-08 20:37:46.167403+00	2025-07-08 20:37:46.167403+00	\N
30368058-a9be-49b5-a169-2c42e436e9b9	공지사항	notice	봉사단체의 공지사항을 전달합니다	notice	1	t	f	t	5	10485760	image/*	t	f	t	t	admin	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-16 04:14:56.533245+00	
8800b948-9a32-4577-b2e9-b51429bd471a	센터소식	news			0	t	f	t	5	10485760	image/*	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	0	0	f	f	200	20	0	0	0	0	2025-07-08 20:39:21.551239+00	2025-07-20 14:08:57.553462+00	
0defeac6-ed18-40e1-b2e0-487781d4a4ac	정보마당	free	자유롭게 소통하는 공간입니다	free	3	t	f	t	5	10485760	image/*	t	f	t	t	member	guest	guest	member	member	member	f	rich	t	t	f	t	f	3	5	f	f	200	20	0	0	0	0	2025-07-07 21:16:34.041214+00	2025-07-20 18:05:21.773193+00	youtube.com,youtu.be,vimeo.com
\.


--
-- Data for Name: calendar_events; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.calendar_events (id, title, description, start_at, end_at, all_day, color, is_public, user_id, created_at, updated_at) FROM stdin;
dc2a3f27-e46e-406d-902d-91f5f8efdaad	청소하기	\N	2025-07-22 00:00:00+00	2025-07-23 00:00:00+00	t	\N	t	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	2025-07-20 18:10:08.868869+00	2025-07-20 18:10:08.868869+00
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

COPY public.comments (id, post_id, user_id, parent_id, content, likes, status, created_at, updated_at, depth, is_deleted) FROM stdin;
d4325d0b-54a6-47ec-8cdd-7ff9cd945b65	1b564544-2ea1-4305-a496-56ae7c9893c3	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅁㅁㅁㅁ	0	active	2025-07-16 18:50:11.296328+00	2025-07-16 18:50:11.296328+00	0	f
1a35937d-dba6-4e80-a7e3-4d6baea5e03d	1b564544-2ea1-4305-a496-56ae7c9893c3	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅍㅍㅍㅍㅍ	0	active	2025-07-16 18:50:20.149561+00	2025-07-16 18:50:20.149561+00	0	f
fb986d70-c994-47c2-b335-67421b8b5124	1b564544-2ea1-4305-a496-56ae7c9893c3	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅂㅁㅁㅁ	0	active	2025-07-16 18:56:18.244856+00	2025-07-16 18:56:18.244856+00	0	f
083ce5f7-2e62-4e05-a3e6-34088b2b4434	0913d32d-4888-40b6-a957-6b36d40d2c56	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	\N	테스트 댓글입니다.	0	active	2025-07-20 14:01:47.189666+00	2025-07-20 14:01:47.189666+00	0	f
dacbca76-5c68-40a3-a388-a198ad2b70ee	0913d32d-4888-40b6-a957-6b36d40d2c56	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	083ce5f7-2e62-4e05-a3e6-34088b2b4434	테스트 대댓글입니다.	0	active	2025-07-20 14:01:56.83442+00	2025-07-20 14:01:56.83442+00	1	f
a2ab6316-7f82-4c3e-b6a2-37361a86916b	0913d32d-4888-40b6-a957-6b36d40d2c56	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	\N	API 테스트 댓글	0	active	2025-07-20 14:04:11.381552+00	2025-07-20 14:04:11.381552+00	0	f
6d532cd9-c659-495b-9f8d-2dc3a63bc869	4e7c9fd6-478f-4d1a-9662-86e4659fe209	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	99858385-bc59-4c3d-ad30-ed6ac94897f3	ㅎㅎㅎㅎㅎ	0	active	2025-07-20 14:49:47.387768+00	2025-07-20 14:49:54.29741+00	1	t
99858385-bc59-4c3d-ad30-ed6ac94897f3	4e7c9fd6-478f-4d1a-9662-86e4659fe209	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅅㄷㅁㅁㅁㅁㅁㅁㄹㄹㄹㄹㄹ	0	active	2025-07-20 14:49:43.055057+00	2025-07-20 14:49:59.567224+00	0	f
fca7833d-11b6-415f-a638-5f4ee39ec4fb	4e7c9fd6-478f-4d1a-9662-86e4659fe209	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	aaaa	0	active	2025-08-03 13:07:50.096333+00	2025-08-03 13:07:50.096333+00	0	f
d6117fae-4cd4-4d79-bca1-36cbc80581f4	4e7c9fd6-478f-4d1a-9662-86e4659fe209	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	fca7833d-11b6-415f-a638-5f4ee39ec4fb	cccc	0	active	2025-08-03 13:07:55.427089+00	2025-08-03 13:07:55.427089+00	1	f
7f4a7e4f-3fdc-45f2-865a-6d0f3c4da2d9	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	42a6dc33-72a2-45f8-9e50-0144b9b877af	답글 달기 9999	0	active	2025-07-20 14:07:24.299565+00	2025-08-11 00:04:28.742467+00	1	t
42a6dc33-72a2-45f8-9e50-0144b9b877af	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	99999	0	active	2025-07-20 14:07:05.385768+00	2025-08-11 00:04:30.842917+00	0	t
7b1ed24c-0fab-4687-baca-87d09d58ab1f	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅂㅂㅂ	0	active	2025-07-20 14:06:56.504213+00	2025-08-11 00:04:33.42286+00	0	t
6d5b42a4-dcc7-4cff-8b5e-6d5c0e2329b1	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㄹㄹㄹㄹ	0	active	2025-07-16 18:57:54.123135+00	2025-08-11 00:04:36.844867+00	0	t
8eb730e3-5a5e-4921-88a3-431488c59d84	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅁㅁㅁㅁ	0	active	2025-07-16 18:57:39.319431+00	2025-08-11 00:04:38.03716+00	0	t
28d166fd-fc98-418f-be0d-a293cdd4865b	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅁㅁㅁㅁ	0	active	2025-07-16 18:53:38.898619+00	2025-08-11 00:04:39.164516+00	0	t
fbbb4b91-bf14-4933-a07a-eeeeab7ae80b	0913d32d-4888-40b6-a957-6b36d40d2c56	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	\N	ㅅㄷㄴㅅ	0	active	2025-07-16 18:49:57.481025+00	2025-08-11 00:04:41.811589+00	0	t
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
42a0b412-e079-4273-a8f4-89f13dc9ba15	21862d2f-7e93-4ea6-b8d6-0400bf09610d	post	e3a7fea6-3c48-41d9-bad4-5982553e0175	attachment	0	2025-07-16 04:33:31.741072+00
ba5df34d-a887-4a42-910c-c1a3a8b7ce08	222a54ce-aa43-4a5b-b08f-3c117ef34801	post	fcce5f93-5075-4799-8017-80ddce017620	attachment	0	2025-07-16 04:36:40.451079+00
425a6425-4f30-4aa7-bc65-40756725376c	9e157530-9585-481e-aa97-97c00a3a497b	post	8dd519b7-3ad0-49a8-8877-a25ab4e2c159	attachment	0	2025-07-20 15:13:06.091425+00
15ffd751-ad21-4a35-a634-cf478c558ed6	3e1d6226-fd6c-4dd5-b87f-25924abada80	post	6585e051-3fb9-4097-a00b-8f8e283582c6	attachment	0	2025-07-20 15:33:39.58116+00
ecf616a8-33c2-42e7-a19b-e691fbf8d566	37056637-bc3a-4c06-8f31-6f1e0efb4395	post	40cfdd72-e5b5-4572-b613-7bf0f31f3468	attachment	0	2025-07-20 16:24:42.148226+00
9a77eb42-f3e3-4ecc-83cb-e8ba417f62b0	b778bb15-3b06-429c-ac28-2d246e521a16	post	0fc64dbc-4aff-461b-a7e9-94da7153b22a	attachment	0	2025-07-20 16:26:42.830696+00
723dcfa0-6126-4f98-a173-e2c42a682620	f15b4b70-afb1-4101-bc47-f29183537bbe	post	6b9ad304-782e-4018-a705-dfc1d138fcd7	attachment	0	2025-07-20 16:33:39.177953+00
1b37011d-b60c-4ba9-92fc-0d12fab08981	48e24720-d419-46b6-a553-11aed6ea3dca	post	ead5a029-747d-4b24-be89-6b5cd74877f3	attachment	0	2025-07-20 17:15:56.003738+00
43ef6f7f-aaa3-419f-8aab-a2000f1c8579	2fd8582c-b7b8-4bd3-a605-6d49eae42aee	post	b346ceea-63dc-44f7-9311-3d780538adc4	attachment	0	2025-07-20 17:24:47.326296+00
01781247-1351-4a02-a53c-b4315dbeb576	9b8cac27-affc-4614-a083-4c62918e0578	post	4ffe3258-65e2-4c97-9eae-cbb58546d1a3	attachment	0	2025-07-20 17:29:27.246973+00
21e358da-67bb-40e3-8964-ff1de1af5736	76c579b8-13ef-411d-a294-ece02abac8a7	post	880b541d-e717-4162-9845-182b59cfceec	attachment	0	2025-07-20 17:55:21.123538+00
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.files (id, user_id, original_name, stored_name, file_path, file_size, original_size, mime_type, file_type, status, compression_ratio, has_thumbnails, processing_status, created_at) FROM stdin;
73ceec4c-3ab5-478b-a73f-ff761e4bc542	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	mosaIPqi3H.png	6578fe05-92d3-4f0e-ae11-8517c346aefb_1752639922_mosaIPqi3H.png	static/uploads/posts/images/6578fe05-92d3-4f0e-ae11-8517c346aefb_1752639922_mosaIPqi3H.png	183747	\N	image/png	image	published	\N	f	completed	2025-07-16 04:25:24.549841+00
a2e285d2-a729-4e8f-be4b-05f8f3f24505	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	mosaUgI4Ft.jpeg	f82eb55b-0e5c-47e6-9f58-06a1e064559d_1752639966_mosaUgI4Ft.jpeg	static/uploads/posts/images/f82eb55b-0e5c-47e6-9f58-06a1e064559d_1752639966_mosaUgI4Ft.jpeg	81892	\N	image/jpeg	image	published	\N	f	completed	2025-07-16 04:26:08.176462+00
a1a820d3-ab18-4d47-97fd-192dbdff817f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	mosaloYcTZ.jpeg	09741f28-08fb-43c6-86bc-b727faa8425c_1752640214_mosaloYcTZ.jpeg	static/uploads/posts/images/09741f28-08fb-43c6-86bc-b727faa8425c_1752640214_mosaloYcTZ.jpeg	99228	\N	image/jpeg	image	published	\N	f	completed	2025-07-16 04:30:16.777422+00
a6b49ff3-7a2e-4fed-8ed4-30bb02a61e1f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	mosajPI3fF.png	4745bf20-5ad6-4deb-9170-c11949556e83_1752640301_mosajPI3fF.png	static/uploads/posts/images/4745bf20-5ad6-4deb-9170-c11949556e83_1752640301_mosajPI3fF.png	247329	\N	image/png	image	published	\N	f	completed	2025-07-16 04:31:43.708622+00
21862d2f-7e93-4ea6-b8d6-0400bf09610d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	mosajPI3fF.png	f1ba6a00-ac7b-4e7f-91ce-197bbdcd238a_1752640407_mosajPI3fF.png	static/uploads/posts/images/f1ba6a00-ac7b-4e7f-91ce-197bbdcd238a_1752640407_mosajPI3fF.png	247329	\N	image/png	image	published	\N	f	completed	2025-07-16 04:33:29.744974+00
222a54ce-aa43-4a5b-b08f-3c117ef34801	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	mosanvHTPb.jpeg	6996e8e3-5cfc-462c-bad1-314f4e9cdcca_1752640595_mosanvHTPb.jpeg	static/uploads/posts/images/6996e8e3-5cfc-462c-bad1-314f4e9cdcca_1752640595_mosanvHTPb.jpeg	64439	\N	image/jpeg	image	published	\N	f	completed	2025-07-16 04:36:37.637242+00
9e157530-9585-481e-aa97-97c00a3a497b	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	Gemini_Generated_Image_r3fkmrr3fkmrr3fk.png	b048f2da-6c93-41ce-aa0e-93e2c73ae0d9_1753024313_Gemini_Generated_Image_r3fkmrr3fkmrr3fk.png	static/uploads/posts/images/b048f2da-6c93-41ce-aa0e-93e2c73ae0d9_1753024313_Gemini_Generated_Image_r3fkmrr3fkmrr3fk.png	1897712	\N	image/png	image	published	\N	f	completed	2025-07-20 15:11:57.763325+00
3e1d6226-fd6c-4dd5-b87f-25924abada80	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	hero_bg.jpeg	23717f8d-d1ba-4806-8c1d-33852a4beb1c_1753025606_hero_bg.jpeg	static/uploads/posts/images/23717f8d-d1ba-4806-8c1d-33852a4beb1c_1753025606_hero_bg.jpeg	258880	\N	image/jpeg	image	published	\N	f	completed	2025-07-20 15:33:30.358705+00
4946aa26-05a1-4236-b99d-7ba5158f5abf	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	천안공실3.png	3f2da447-8c21-4119-a4b7-10989d10c0c1_1753026152_천안공실3.png	static/uploads/posts/images/3f2da447-8c21-4119-a4b7-10989d10c0c1_1753026152_천안공실3.png	217933	\N	image/png	image	draft	\N	f	completed	2025-07-20 15:42:39.718322+00
cb2c4b5d-ab1c-44a3-b38e-06b2bda4ec09	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	천안공실3.png	79221d7f-8971-476b-b5a7-be4020580954_1753027138_천안공실3.png	static/uploads/posts/images/79221d7f-8971-476b-b5a7-be4020580954_1753027138_천안공실3.png	217933	\N	image/png	image	draft	\N	f	completed	2025-07-20 15:59:06.109748+00
abf6b5f6-cddd-44f5-bc4a-bf0e30d8ddcd	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	8fafbc8a-a5da-4edc-a743-b87240bb8972_1753028195_copy_img.png	static/uploads/posts/images/8fafbc8a-a5da-4edc-a743-b87240bb8972_1753028195_copy_img.png	3584747	\N	image/png	image	draft	\N	f	completed	2025-07-20 16:16:40.490698+00
a0e5f03b-d6aa-44d4-8c01-b8f311a37d08	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	28cb72d1-2466-441d-9fba-4a66a61ecc27_1753028398_copy_img.png	static/uploads/posts/images/28cb72d1-2466-441d-9fba-4a66a61ecc27_1753028398_copy_img.png	3584747	\N	image/png	image	draft	\N	f	completed	2025-07-20 16:20:03.263759+00
37056637-bc3a-4c06-8f31-6f1e0efb4395	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	d9f233d1-5867-4627-9187-afc923f20c2a_1753028564_copy_img.png	static/uploads/posts/images/d9f233d1-5867-4627-9187-afc923f20c2a_1753028564_copy_img.png	3584747	\N	image/png	image	published	\N	f	completed	2025-07-20 16:22:49.318766+00
b778bb15-3b06-429c-ac28-2d246e521a16	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	0aaf5121-f4a8-4de0-81ab-74d828186bb7_1753028786_copy_img.png	static/uploads/posts/images/0aaf5121-f4a8-4de0-81ab-74d828186bb7_1753028786_copy_img.png	3584747	\N	image/png	image	published	\N	f	completed	2025-07-20 16:26:31.376384+00
9b8cac27-affc-4614-a083-4c62918e0578	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	bd66ff90-6076-499e-b610-6933a31e1f92_1753032561_copy_img.png	static/uploads/posts/images/bd66ff90-6076-499e-b610-6933a31e1f92_1753032561_copy_img.png	3584747	\N	image/png	image	published	\N	f	completed	2025-07-20 17:29:21.844361+00
f15b4b70-afb1-4101-bc47-f29183537bbe	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	5ab54bfb-90ba-4933-8641-c2d7c42308af_1753029212_copy_img.png	static/uploads/posts/images/5ab54bfb-90ba-4933-8641-c2d7c42308af_1753029212_copy_img.png	3584747	\N	image/png	image	published	\N	f	completed	2025-07-20 16:33:33.578854+00
48e24720-d419-46b6-a553-11aed6ea3dca	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	87b3a3fc-a3d6-45b4-8b86-7e2f4daa1b92_1753031749_copy_img.png	static/uploads/posts/images/87b3a3fc-a3d6-45b4-8b86-7e2f4daa1b92_1753031749_copy_img.png	3584747	\N	image/png	image	published	\N	f	completed	2025-07-20 17:15:50.594019+00
2fd8582c-b7b8-4bd3-a605-6d49eae42aee	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	copy_img.png	8a7f2854-ccd8-4380-9a3b-1ec05a9d4bf8_1753032281_copy_img.png	static/uploads/posts/images/8a7f2854-ccd8-4380-9a3b-1ec05a9d4bf8_1753032281_copy_img.png	3584747	\N	image/png	image	published	\N	f	completed	2025-07-20 17:24:41.939965+00
76c579b8-13ef-411d-a294-ece02abac8a7	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	3155_9113_28.jpg	e642d96f-7e23-457f-83b0-e4e1a94fa0a7_1753034118_3155_9113_28.jpg	static/uploads/posts/images/e642d96f-7e23-457f-83b0-e4e1a94fa0a7_1753034118_3155_9113_28.jpg	138224	\N	image/jpeg	image	published	\N	f	completed	2025-07-20 17:55:18.336937+00
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
e903b6b3-9d9d-4e13-bee2-510b70df1e56	about	민들레는요	{"blocks":[{"id":"008pwdr03","type":"map","address":"충남 천안시 서북구 두정동 1011","latitude":36.8362760026265,"longitude":127.13603501764,"width":400,"height":300,"zoom":3,"title":"지도","order":0,"apiKey":"726539b2a607fd8b1878003bbfee0384"},{"id":"8naa8a43t","type":"heading","level":2,"content":"","order":1},{"id":"idhkx0x5c","type":"paragraph","content":"","order":2},{"id":"aekmikzxp","type":"button","text":"버튼 텍스트","link":{"url":"#","target":"_self"},"styles":{"variant":"primary","size":"md","textAlign":"center","width":"auto"},"order":3},{"id":"gka85jy69","type":"paragraph","content":"","order":4}],"version":"1.0"}				published	t	2025-07-20 04:01:08.634741+00	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	2025-07-19 08:49:24.659735+00	2025-07-20 04:14:32.770208+00	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	12	0
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

COPY public.posts (id, board_id, category_id, user_id, title, content, views, likes, is_notice, status, created_at, updated_at, dislikes, meta_title, meta_description, meta_keywords, is_deleted, reading_time, comment_count, attached_files, thumbnail_urls, parent_id, depth, reply_count) FROM stdin;
40cfdd72-e5b5-4572-b613-7bf0f31f3468	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	vvv	<p>vvv</p>	3	0	f	deleted	2025-07-20 16:24:42.086852+00	2025-07-20 17:55:43.999717+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/d9f233d1-5867-4627-9187-afc923f20c2a_1753028564_copy_img_card.png", "large": "/uploads/posts/images/d9f233d1-5867-4627-9187-afc923f20c2a_1753028564_copy_img_large.png", "thumb": "/uploads/posts/images/d9f233d1-5867-4627-9187-afc923f20c2a_1753028564_copy_img_thumb.png"}	\N	0	0
4ffe3258-65e2-4c97-9eae-cbb58546d1a3	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅁㅁㅁㅁ	<p>ㄹㄹㄹㄹ</p>	15	0	f	deleted	2025-07-20 17:29:23.357064+00	2025-07-20 17:49:21.657901+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/bd66ff90-6076-499e-b610-6933a31e1f92_1753032561_copy_img_card.png", "large": "/uploads/posts/images/bd66ff90-6076-499e-b610-6933a31e1f92_1753032561_copy_img_large.png", "thumb": "/uploads/posts/images/bd66ff90-6076-499e-b610-6933a31e1f92_1753032561_copy_img_thumb.png"}	\N	0	0
41c1d208-be71-4b1b-ab57-b39855404258	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅁㅁㅁ	<p>ㅁㅁㅁㅁ</p>	0	0	f	active	2025-07-08 05:49:56.518586+00	2025-07-20 14:01:04.330102+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
aa919d94-b3a9-45fe-b36a-b6b147ee5031	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㄱㄱㄱㄱㄱ	<p>ㄱㄱㄱㄱㄱㄱ</p>	0	0	f	active	2025-07-08 05:59:11.772751+00	2025-07-20 14:01:04.330102+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
a70fa13d-1df7-43db-a7b7-1a2e24185e6b	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㄱㄱㄱㄱㄱ	<p>ㄱㄱㄱㄱㄱㄱ</p>	1	0	f	active	2025-07-08 05:55:38.195796+00	2025-07-20 14:01:04.330102+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
63c437d5-be40-4757-b5f0-b1546bf094c4	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	test	<p>test</p>	5	0	f	deleted	2025-07-20 16:11:13.14345+00	2025-07-20 16:14:28.370357+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
6b9ad304-782e-4018-a705-dfc1d138fcd7	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅇㅇㅇㅇ	<p>ㅇㅇㅇㅇ</p>	12	0	f	deleted	2025-07-20 16:33:35.497835+00	2025-07-20 17:28:35.357711+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/5ab54bfb-90ba-4933-8641-c2d7c42308af_1753029212_copy_img_card.png", "large": "/uploads/posts/images/5ab54bfb-90ba-4933-8641-c2d7c42308af_1753029212_copy_img_large.png", "thumb": "/uploads/posts/images/5ab54bfb-90ba-4933-8641-c2d7c42308af_1753029212_copy_img_thumb.png"}	\N	0	0
b346ceea-63dc-44f7-9311-3d780538adc4	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅁㅁㅁㅁ	<p>ㅁㅁㅁㅁ</p>	5	0	f	deleted	2025-07-20 17:24:43.625712+00	2025-07-20 17:54:33.667982+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/8a7f2854-ccd8-4380-9a3b-1ec05a9d4bf8_1753032281_copy_img_card.png", "large": "/uploads/posts/images/8a7f2854-ccd8-4380-9a3b-1ec05a9d4bf8_1753032281_copy_img_large.png", "thumb": "/uploads/posts/images/8a7f2854-ccd8-4380-9a3b-1ec05a9d4bf8_1753032281_copy_img_thumb.png"}	\N	0	0
ead5a029-747d-4b24-be89-6b5cd74877f3	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	본문에 썸네일이 나오는건지 확인	<p>ㅁㅁㅁ</p>	3	0	f	deleted	2025-07-20 17:15:52.381263+00	2025-07-20 17:54:18.489233+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/87b3a3fc-a3d6-45b4-8b86-7e2f4daa1b92_1753031749_copy_img_card.png", "large": "/uploads/posts/images/87b3a3fc-a3d6-45b4-8b86-7e2f4daa1b92_1753031749_copy_img_large.png", "thumb": "/uploads/posts/images/87b3a3fc-a3d6-45b4-8b86-7e2f4daa1b92_1753031749_copy_img_thumb.png"}	\N	0	0
0fc64dbc-4aff-461b-a7e9-94da7153b22a	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ccc	<p>cccc</p>	7	0	f	deleted	2025-07-20 16:26:42.785698+00	2025-07-20 17:55:35.976311+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/0aaf5121-f4a8-4de0-81ab-74d828186bb7_1753028786_copy_img_card.png", "large": "/uploads/posts/images/0aaf5121-f4a8-4de0-81ab-74d828186bb7_1753028786_copy_img_large.png", "thumb": "/uploads/posts/images/0aaf5121-f4a8-4de0-81ab-74d828186bb7_1753028786_copy_img_thumb.png"}	\N	0	0
8dd519b7-3ad0-49a8-8877-a25ab4e2c159	8800b948-9a32-4577-b2e9-b51429bd471a	cf4dea4f-ae65-479f-bafd-771eae9109a2	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅅㄷㄴㅅ	<p>ㅁㅁㅁㅁ</p>	5	0	f	deleted	2025-07-20 15:13:06.047988+00	2025-08-03 13:06:03.53034+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
dd7cd253-f186-46b1-b138-7e9bbf143a09	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ttt	<p>ttt</p>	5	0	f	deleted	2025-07-20 15:54:05.898023+00	2025-08-03 13:07:32.285048+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
348f926a-a4cb-4c35-b7a1-547c082048ee	8800b948-9a32-4577-b2e9-b51429bd471a	cf4dea4f-ae65-479f-bafd-771eae9109a2	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	센터소식	<p>ㅁㅁㅁㅁ</p>	5	0	f	deleted	2025-07-16 18:53:53.932136+00	2025-08-03 13:06:23.178404+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
fcce5f93-5075-4799-8017-80ddce017620	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ccc	<p>ccc</p>	104	0	f	deleted	2025-07-16 04:36:40.434474+00	2025-08-03 13:07:41.063171+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
14396a42-e019-40c6-877c-4ba55d84b083	8800b948-9a32-4577-b2e9-b51429bd471a	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	센터 소식1	<p>ㅁㅁㅁ</p>	13	0	f	deleted	2025-07-20 14:13:42.985876+00	2025-08-03 13:06:11.73077+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
6585e051-3fb9-4097-a00b-8f8e283582c6	8800b948-9a32-4577-b2e9-b51429bd471a	cf4dea4f-ae65-479f-bafd-771eae9109a2	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	이미지 썸네일 등록 테스트	<p>ㅁㅁㅁㅁㅁ</p>	3	0	f	deleted	2025-07-20 15:33:39.540649+00	2025-08-03 13:06:30.50707+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/23717f8d-d1ba-4806-8c1d-33852a4beb1c_1753025606_hero_bg_card.jpeg", "large": "/uploads/posts/images/23717f8d-d1ba-4806-8c1d-33852a4beb1c_1753025606_hero_bg_large.jpeg", "thumb": "/uploads/posts/images/23717f8d-d1ba-4806-8c1d-33852a4beb1c_1753025606_hero_bg_thumb.jpeg"}	\N	0	0
43bea71c-0448-4179-8516-7e5636912fee	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	test	<p>ttt</p>	7	0	f	deleted	2025-07-16 04:22:13.868209+00	2025-08-03 13:06:43.867797+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
ac2cbd99-bd09-4638-adc4-6a1f831967fc	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅅㄷㄴㅅ	<p>ㅁㅁㅁㅁ</p>	4	0	f	deleted	2025-07-16 04:25:39.765544+00	2025-08-03 13:06:48.914633+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
048e104f-9bd3-4592-80ed-1aa9e0b5ce3f	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ttt	<p>test</p>	1	0	f	deleted	2025-07-16 04:26:12.84458+00	2025-08-03 13:06:55.408292+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
98d76161-babe-4fbe-ba09-7f8ba3823a2e	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ttt	<p>test</p>	2	0	f	deleted	2025-07-16 04:27:10.201736+00	2025-08-03 13:07:00.592694+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
52c7e653-4388-4b3d-860c-4188167b3822	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅁㅁㅁ	<p>ㅁㅁㅁ</p>	1	0	f	deleted	2025-07-16 04:30:19.796008+00	2025-08-03 13:07:07.440352+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
8d3cb9e0-ff6c-4407-a7dd-c5aeaa53ebd3	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	aaa	<p>aaa</p>	1	0	f	deleted	2025-07-16 04:31:45.890971+00	2025-08-03 13:07:12.260466+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
f102c91f-2b00-4dec-bb81-a3d54fb08c3d	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	aaa	<p>aaa</p>	2	0	f	deleted	2025-07-16 04:33:14.936525+00	2025-08-03 13:07:17.943713+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
e3a7fea6-3c48-41d9-bad4-5982553e0175	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	bbb	<p>bbb</p>	12	0	f	deleted	2025-07-16 04:33:31.729687+00	2025-08-03 13:07:23.8794+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
ea128cd1-e857-44f1-90bd-8fe4b3508918	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ㅅㄷㄴㅅ	<p>ㅁㅁㅁㅁ</p>	11	0	f	active	2025-07-08 05:20:38.320629+00	2025-08-11 00:04:56.167335+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
4e7c9fd6-478f-4d1a-9662-86e4659fe209	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	Free 게시판 테스트 글	<p>자유게시판 테스트입니다.</p>	21	0	f	deleted	2025-07-20 14:10:47.181123+00	2025-08-04 16:13:37.513236+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
1b564544-2ea1-4305-a496-56ae7c9893c3	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	글쓰기 테스트	<p>ㅁㅁㅁㅁ</p>	12	0	f	active	2025-07-08 06:02:25.259406+00	2025-08-11 00:04:51.766208+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
0913d32d-4888-40b6-a957-6b36d40d2c56	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	aaa	<p>bbb</p>	13	0	f	active	2025-07-11 11:41:26.74482+00	2025-08-11 00:04:23.568591+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
817e9e63-b158-422b-bc21-9f2fdbf23f94	0defeac6-ed18-40e1-b2e0-487781d4a4ac	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	aaa	<p>aaa</p>	5	0	f	deleted	2025-07-20 15:41:56.752196+00	2025-08-11 00:04:01.556889+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
6cf46c4a-f972-4a9a-932a-b8fd063691d8	30368058-a9be-49b5-a169-2c42e436e9b9	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	test	<p>aaaa</p>	3	0	f	active	2025-07-08 05:44:21.820352+00	2025-08-11 00:04:59.925308+00	0	\N	\N	\N	f	\N	0	\N	\N	\N	0	0
880b541d-e717-4162-9845-182b59cfceec	8800b948-9a32-4577-b2e9-b51429bd471a	\N	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	신규 글이 최근글 노출 여부 확인	<p>ㅁㅁㅁㅁ</p>	12	0	f	deleted	2025-07-20 17:55:19.880812+00	2025-08-11 00:04:10.396349+00	0	\N	\N	\N	f	\N	0	\N	{"card": "/uploads/posts/images/e642d96f-7e23-457f-83b0-e4e1a94fa0a7_1753034118_3155_9113_28_card.jpg", "large": "/uploads/posts/images/e642d96f-7e23-457f-83b0-e4e1a94fa0a7_1753034118_3155_9113_28_large.jpg", "thumb": "/uploads/posts/images/e642d96f-7e23-457f-83b0-e4e1a94fa0a7_1753034118_3155_9113_28_thumb.jpg"}	\N	0	0
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: mincenter
--

COPY public.refresh_tokens (id, user_id, token_hash, service_type, expires_at, created_at, is_revoked) FROM stdin;
e02575bf-87d0-4162-af0b-50a1e1c3d2ae	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d8f32d079d3112725e8c0d35300930b10b863dd37cd925ed547836f7da1cfe45	admin	2025-07-15 20:05:06.358821+00	2025-07-08 20:05:06.361705+00	t
423ed002-b305-4a4b-b08f-8f8ef19b9c2b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	0faad34240d13a0a95221a1d726b838affd104c5af3a26d426094ea457f72af1	admin	2025-08-06 21:43:52.080611+00	2025-07-07 21:43:52.086391+00	t
8b9f8919-3c81-4a07-aea2-dceba272d84f	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	1195dfbb84e5e4a7e23cff87046172ce28a08f6261d3f297cb181e9c0f8a211c	admin	2025-07-15 20:29:35.341625+00	2025-07-08 20:29:35.34182+00	f
1e759a9f-b8c8-4d7d-83b9-8ef972883a0d	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d25510e068a2d9ae22bc9742b71fff7b06352ca046fdc690d1801a61b58679a7	admin	2025-07-14 21:59:01.720444+00	2025-07-07 21:59:01.720816+00	t
d8c241ff-2833-49c2-aa4f-512573db7ed2	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e36b033816b158e52656cd85c090585793676c67147a674f2bebc3318cb628b2	admin	2025-07-15 04:00:03.665058+00	2025-07-08 04:00:03.664969+00	t
476d7da7-2a86-4c97-b73a-a768a92ff2f7	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	5fc254fce2536ac8f1e6749887e0b69c4b34d2b84ac78b6aa6c8158e5319080c	admin	2025-08-07 04:36:37.818005+00	2025-07-08 04:36:37.819834+00	f
d7e06050-f4c9-4bb6-b4ff-f5765856546e	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	075047cde831d81277312997bdbd9baa79751d6dd913437c4d238027a9daa2d0	admin	2025-08-07 04:38:17.807542+00	2025-07-08 04:38:17.813333+00	f
83d30d81-cce7-46b4-bf8f-0c1cf8ef4078	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	8242668623f4b073dabd854543d297f555e01408cc0d16645019f88f34615e7a	admin	2025-08-07 20:37:26.021288+00	2025-07-08 20:37:26.027513+00	t
8e8dbe9b-5cc5-46a9-abfd-b8712e27f5c9	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	a8ffa39e0cda65af05b95422f8cfc78b4e2d223e4c1bbc648c9d078d2edaec14	admin	2025-07-27 18:04:27.336458+00	2025-07-20 18:04:27.336333+00	t
0494ee21-602b-48ea-9fbb-09394c240dfc	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	5f2f6ae3338edab559a347a21faa5ff20b8383cb9ca647ef7fbf9c39a0e8f3ce	admin	2025-07-15 04:33:35.23513+00	2025-07-08 04:33:35.235287+00	t
e408e44a-9123-4b39-a5ef-c76c50271474	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	8a7cabd7899e4ad2d3f9ae3a5b9d8ccbdb2b997dce9196d931d4e964a39d1c1e	admin	2025-07-15 04:51:06.524947+00	2025-07-08 04:51:06.525164+00	t
65f8e588-13ff-4504-924a-96af8e648731	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	13c74595714be8ba3b88475173fcffd2edaa323351651ded3ef84be7f6278a1c	admin	2025-07-15 21:42:46.120742+00	2025-07-08 21:42:46.120521+00	f
bf9bfbed-89e7-4d71-8d8f-a02d49cc7368	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e06eeabdcff8c04f6ab09c12b7f110cd5c2ab1dc4a9c7d6c24f75194e3be6144	admin	2025-07-15 05:06:32.8785+00	2025-07-08 05:06:32.885273+00	t
1355e0af-0e53-4869-a38c-b4dbd9301fc0	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	f76e93e32f6e741e2a91d1c2a0bdeb7bf321248e444edd66ac71ec747f6ccf96	admin	2025-07-15 05:22:12.881687+00	2025-07-08 05:22:12.882435+00	t
6b183064-7a6f-4c9c-bd4b-0e89eab812a4	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	450752538ae148d3cd2bccd4ef001c4cf31915fa5a3b3ca1264b914841b289a4	admin	2025-07-15 06:16:08.266344+00	2025-07-08 06:16:08.266866+00	t
56ec508a-c095-4ec3-b914-f949e8229cbc	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	eb4659b2c954411d2b4db8e0b98d661bc348dcf81e8f5be8e3f6ebff808d7672	admin	2025-07-15 07:43:32.592079+00	2025-07-08 07:43:32.591902+00	t
aaecda40-9ae6-40aa-ab84-d56ff43381b7	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	936c5fb1e1d040771e53a4c066e85b4108cd09cd7ccbce9f353e20a396c13f48	admin	2025-07-15 08:20:17.141037+00	2025-07-08 08:20:17.141093+00	t
73ca649f-af7e-4be4-a08f-f3cf29a0d194	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d784ff87f5b71d83a19f7355f1e8824d60ddfa285eb0df7b4221978db146fee4	admin	2025-07-15 19:47:05.529629+00	2025-07-08 19:47:05.530326+00	t
0d133d1b-62e9-46dc-934f-06e5bf8235c5	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	32c661792416f7ca9cf98ae6917d2915de7822264e4cc910cba5e0e5f11ac0a9	admin	2025-09-02 21:41:30.432282+00	2025-08-03 21:41:30.436162+00	f
a9db3a20-d43a-47fc-ae28-33fcd40594ee	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	27721f6b5d95f82c7a1bafad66d1fa9832f41341753af78f563223b25b9f1fe2	admin	2025-09-02 22:07:22.867811+00	2025-08-03 22:07:22.871548+00	f
69c8f0ef-4937-4385-932f-6b7a78166320	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	2df5ee6e36f39a475c724bca1a603c92a764149b59700ecebb9e531e97612d70	admin	2025-09-03 00:16:54.221091+00	2025-08-04 00:16:54.221556+00	f
55b9422b-112a-4fca-a571-3531ceedcf07	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	1c18cb187bb217f13cca57183ca1c5854cadf4100d8f2dccb2741db74c0ec049	admin	2025-09-03 00:22:02.2832+00	2025-08-04 00:22:02.283331+00	f
bf1e5d62-b52a-40f3-9655-f449cdec548a	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	3823822d4483e12f9168a8dc1bc64018744f32fc4239cd89495de42b69538953	admin	2025-07-27 18:25:24.191603+00	2025-07-20 18:25:24.192396+00	t
cc3ed2ec-a3e9-4937-af91-c863db43c41f	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	84be3a3e8a9ac542c2791ff6d40e3ce8efb02e2615dd41d87e644568ceaeddd5	site	2025-07-27 14:54:22.167275+00	2025-07-20 14:54:22.167498+00	t
1b719891-c982-4a38-b373-aaa818bdfc7b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d4946431cde4f9eb66a8963006917a910a6ad1a15f72e0db2851dc4b8144ce18	site	2025-08-17 22:31:10.46206+00	2025-08-10 22:31:10.462872+00	t
b56ebef5-b919-4e40-9cd3-7dc5daa12a0f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	f7b12212fbfb402f31eeab68ad464205359aa0f3c4c30e5fa3b973102a57ca7e	site	2025-08-11 16:12:19.804534+00	2025-08-04 16:12:19.80559+00	t
a3da3472-880e-46d8-b8ea-3afb529a523e	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	9e7ea67c73eb03b54e4fb7e86929290663a017bace4b4093d0d86b261f84acbc	site	2025-07-26 13:25:56.321852+00	2025-07-19 13:25:56.323219+00	t
5f5506a3-9e4b-45d4-9fa2-15630429d8a8	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	e7dd96cf8ea7267a81b0985363826e42ac313adf7f7aa7632354905cd0cceb47	site	2025-07-25 21:54:16.998029+00	2025-07-18 21:54:16.998054+00	t
cbb086a4-8380-4502-ad6f-e8ecbe4f8521	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	cec17df44ab2bfd7107abc46a3085e109c947e1680e24ab80007b9413cda937a	site	2025-07-26 03:53:45.875255+00	2025-07-19 03:53:47.930638+00	t
5f047cbf-14c4-4133-abac-cc98c15071b1	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	647cf67d8f530f35d966827ec9b18fea96c2e09f31d3f6d35d4bc5a8caf3db22	site	2025-07-26 16:34:14.841035+00	2025-07-19 16:34:14.841977+00	t
97a862e3-e5f0-4906-bfd5-87f1d045abce	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	82eba218584356209150e377a7a2484495b4ec7cdd9f205166abd9c6f31bd2bc	site	2025-07-26 05:59:40.453032+00	2025-07-19 05:59:40.455333+00	t
89e15ca2-c195-4b7c-a9b3-b9148ba7dcf6	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	27233803ce1cbaef34ce2eef7aa0b6183641138ff06a453c8895253860f55f44	site	2025-07-26 09:01:05.551258+00	2025-07-19 09:01:05.550684+00	t
bdae33ab-b49a-4a83-b982-0e380fd99ebf	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	fcbd835e34ee0364c9869fee41af03200b448b385444db4a5bf67901bd0a0528	site	2025-07-26 11:21:33.372628+00	2025-07-19 11:21:33.369195+00	t
62d4b6d6-dc0d-478f-a518-e8860f18f363	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	4159e44020921dbacec0e8cea3e051993a01351b74ee0dd05e37c7b36a67a506	site	2025-07-26 12:40:34.473849+00	2025-07-19 12:40:34.474189+00	t
848baf56-67f7-451d-8654-59be8754c001	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	c804d31129a36310c71a21c7ba65a4f7445f9f834eb5897a39e1ad4c06e3a790	site	2025-07-27 12:17:34.317284+00	2025-07-20 12:17:34.317544+00	t
0cfeee6b-2eef-401e-835d-71313c92bc03	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	edaf8cc0ac3594fd7fd571c7d56610fa35172d72124c29d94cf077b4694dd4fe	site	2025-07-15 04:23:21.848968+00	2025-07-08 04:23:21.85021+00	t
dfbd3ee6-904e-48b1-9d32-3159f970de37	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	96f9cf6b08247dccd88a2df25b7f36f43725f3f9b8610bd751af9bd09a318ceb	site	2025-07-15 04:40:54.174715+00	2025-07-08 04:40:54.174804+00	t
8bb9bdf0-617d-449c-bb96-5dfd60e8b46b	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	81c941593d9d1916d7b9724062682153e771f8719bd2106bc31e81f343272024	site	2025-07-15 05:20:28.126501+00	2025-07-08 05:20:28.127661+00	t
472a3de4-cb03-493c-8c23-ccb8181e6353	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	b8b7d7ad65f0259f57dc0fd96e543827de9efcebb67c7d571165e58445662e4b	site	2025-07-15 05:44:10.590677+00	2025-07-08 05:44:10.590969+00	t
dc53ce58-6a2d-4857-9ca6-01049a162e4c	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	83b9ec4849c31db87b023e6405fb2d96b8f0cf0c94223198c13965a35acd5e92	site	2025-07-18 11:40:46.614369+00	2025-07-11 11:40:46.615263+00	t
8cb35a51-ed70-48e2-a377-ce12907185c4	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	2911f6a8fbd7ce3cd88709cfca782f6a0eb49a6a45599f56a68bda732e8533cc	site	2025-07-27 12:56:06.345533+00	2025-07-20 12:56:06.347091+00	t
14952df2-2155-492a-8687-3a78b1177563	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	fb8e019b96eaa4f672b4874491b54c85ad6a020de5a2f133b73f350c7c87cde9	site	2025-07-27 17:46:20.405856+00	2025-07-20 17:46:20.401027+00	t
bd4b14f4-2daf-419f-b779-0340e66bd1ac	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	0bc44e8256c1b6942af1cb93b0516e9a41161df1e7e90957b5ef3dd6560e498d	admin	2025-09-03 13:39:01.939503+00	2025-08-04 13:39:01.943305+00	f
da2d38ae-b5a4-4df7-ad21-1292553cb00e	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	3bb839e753092564c86659abeec8a9d30d2b68c5403e95a81b4a295c3eafc0f1	admin	2025-07-27 19:12:31.239303+00	2025-07-20 19:12:31.24029+00	f
00386b3e-b7ea-458d-bde0-48d21d6132d1	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	3ad5511fb380be058e45c1dc353a3105c385f542082960662397080c6d5db1a3	admin	2025-07-23 03:51:18.19504+00	2025-07-16 03:51:18.197908+00	t
7b6b8e8f-22c6-49bd-9383-67a83620d4dd	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	9720ac3ab4bcf0706a1bc27de5cb436f93d045438a5b79429d05583e54d4882d	admin	2025-07-23 04:14:56.527905+00	2025-07-16 04:14:56.528315+00	t
d2f73548-e173-4837-b69f-5cc716cf87ac	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	7fa9dcd79220485b1898c48bc703cd162652daa8a0c85ae23064f4dd9c207d1e	site	2025-08-17 12:51:26.310721+00	2025-08-10 12:51:26.311463+00	t
5d77c1bf-4f17-4099-9fae-0efbc1725879	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d6a99ae9353cc43b2b5fb2ab7a55a7e153124926ddd57a69c0b00094e068f94b	site	2025-08-17 23:45:49.878144+00	2025-08-10 23:45:49.879271+00	t
e7ae8543-2830-4f7c-9cde-eeb9bce0f7fd	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	4ee0a020a053e72c213f9cec18fd9f0c2dfa329c51383d55580326c36f218ace	admin	2025-08-14 20:53:24.671704+00	2025-07-15 20:53:24.673547+00	t
6c17051b-0088-4900-819d-9ee36df31ad3	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	54fa441c9e16a764d68b55abe64eb87b6b95179ea2e5803e4b20b62a220f7442	admin	2025-07-22 21:20:15.763268+00	2025-07-15 21:20:15.764466+00	t
6c73b0a3-c974-4ede-b579-7039d216528f	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	29e4e03d79d806c6f654098dbaf0ba4c0ec2d9a400748e1e3c902ae4601f4a6b	admin	2025-07-22 21:36:01.73515+00	2025-07-15 21:36:01.736438+00	t
0f5b4de4-6fe2-444b-994d-dcac04c7d2b2	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	4570740687bb15fd2b8b2167bfda1245a0c2e5792056c55646a398efeee7c928	admin	2025-07-22 22:00:20.518065+00	2025-07-15 22:00:20.516798+00	t
d6e5ca87-fae3-494e-bc85-18373a7b0689	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	86b0a7430d15c304273332eb36662d14d45f2553efcefc7fab16659324300bd1	admin	2025-07-23 04:38:25.533555+00	2025-07-16 04:38:25.535334+00	t
11a8895a-093e-4112-b839-fc9ff31c3ee2	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	1c009ba05c4091696bc992ca558b9a3b223f236b24c1562608514f0f4bff1a34	admin	2025-07-23 05:23:26.6396+00	2025-07-16 05:23:26.643142+00	t
49e470d3-3bad-482e-8711-28524e58fd1e	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	373702518a1ba565fa7edaaeb0385964147f19ba14df75dc1e8de0f2bb5fd186	admin	2025-07-23 07:07:41.254004+00	2025-07-16 07:07:41.25336+00	t
b6900f7e-4716-4bbe-a436-78a93a259095	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e79ffbeb543cef3f48ce693434999b28b5891aa8afef2825d75f452464c05e66	admin	2025-07-23 08:11:44.552156+00	2025-07-16 08:11:44.552725+00	t
c64a3161-1238-4905-88e8-7e5bc7d62556	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	ce8df12cc0e5f0a75eb785d753c9bdc0f28cc8eb4a642cba266dfea062f7ce51	admin	2025-07-23 18:54:06.606751+00	2025-07-16 18:54:06.612885+00	t
f1c687a3-839f-44ce-a8a3-f49f9665f6dc	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	403e73749183c308507ed4980f5b2601a5493b6c5ada6bee70d24f524e7475d8	admin	2025-07-23 19:41:08.045006+00	2025-07-16 19:41:08.046245+00	t
c38d3e68-7bce-4f06-92ab-175e1dc7f6f0	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	693eb0ad526e3f9533f2b13b997009481d060ce73df1596525cd7db2d2aa0764	admin	2025-07-23 21:04:35.901036+00	2025-07-16 21:04:35.9012+00	t
7daddfd9-e1e3-4292-835c-4d099dd80508	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	0b57c5cc3fe1421abe43ef43d1b709f48f6b59898b8bff89ad7333e94bec5f86	admin	2025-07-24 06:27:54.082839+00	2025-07-17 06:27:54.083298+00	t
c249fe80-94ae-4426-893b-e894a80b6c3b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	136cff9f5a42f11d3ac264526d2fa1bc018fb4027874dc3d6cf0ffc971b477a6	admin	2025-07-24 07:26:58.899608+00	2025-07-17 07:26:58.900343+00	t
56afbd52-91a3-402b-9c00-d78d314e0bbf	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e9fd895061fc72f942371e4d8157b54fb0ec8b4b2cbf512014729eed92b10829	admin	2025-07-24 08:11:44.374402+00	2025-07-17 08:11:44.375353+00	t
5f299490-1ae3-4c20-b092-58293b95c0be	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	aefd2f9885a449d86be7f0ca6782ff169f83640f34ff0901ed5d7f9c60f12d32	admin	2025-07-24 18:57:30.038567+00	2025-07-17 18:57:29.974367+00	t
5e03922a-a9b9-492b-980c-3969abd053d5	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	89f0fd9574538a2e7e34866cc3b9c3bf702e779ca664e8037303bd5358d17b49	admin	2025-07-24 19:49:22.193606+00	2025-07-17 19:49:22.193702+00	t
602e7375-1911-4616-8eff-5158dbcb4590	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	414aa9c47e91276d754cfafbc5754b0b6d28f0ca97316e4433ca4ecfab7b76fc	admin	2025-07-24 20:47:01.559964+00	2025-07-17 20:47:01.55997+00	t
97cdd4b8-66f4-4142-834f-846907b9bb74	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	b1ca038242e897ac2ed9863c1f62bc89a2494122972cec4fba1a500f1106dcfc	admin	2025-07-25 05:16:04.056434+00	2025-07-18 05:16:04.056126+00	t
e23cf6f2-15e5-4205-99b4-b43745d424a6	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	5fbbeac11afbc181f0da9f6bea7d30e32e55272179080ff572acfc10ea6019e8	admin	2025-08-19 12:05:44.867257+00	2025-07-20 12:05:44.86919+00	t
12292bbb-188e-45e3-9907-5c77f300ba66	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	b6fae017752af1c76fea454b46d05c76c930fe768534272ac8e77b4a983e5a17	admin	2025-07-25 06:00:09.942122+00	2025-07-18 06:00:09.942282+00	t
0716d77e-3d9f-4bd1-bf2c-1641ed5a79f7	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	a5b18b163077310bd13706135a910bc05f0d75808f738f3e181cbe907509e525	admin	2025-07-25 07:56:11.329383+00	2025-07-18 07:56:11.33035+00	t
521be12b-ab9e-47e1-ad4b-cc5e88337186	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	f8435fe96524be8bf2593970e398162efdc79d322fbd3740ec126d3bc51b6b5e	admin	2025-07-25 21:54:16.567232+00	2025-07-18 21:54:16.567235+00	t
71444538-ef6d-4e68-887a-9adf18cef070	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	fc8ebb496a63a16ab174f5cdf109f90c669904fc89fbf86e9cf402722f0aa6c0	admin	2025-07-26 03:28:02.20222+00	2025-07-19 03:28:02.201838+00	t
5d81113e-4963-4949-bc4b-3f736681b79f	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	fc8ebb496a63a16ab174f5cdf109f90c669904fc89fbf86e9cf402722f0aa6c0	admin	2025-07-26 03:28:02.203686+00	2025-07-19 03:28:02.203417+00	t
b793b3d2-f88b-415d-88ef-2d5cbc08caed	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	06a5367fbd996fc0b5a5d2e1a18fcfd9b1586ba0d7b33892a56b11cfeb4ba0b3	admin	2025-07-26 03:53:45.967786+00	2025-07-19 03:53:48.02327+00	t
2d049872-afb5-424a-9ae3-09f3bbdf8393	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	cd137e6a4d0cc1fb686e4f7e400d16dc6f8029fe688909143d1e8f266137bb30	admin	2025-07-26 05:59:40.290682+00	2025-07-19 05:59:40.29276+00	t
350704be-fd34-4bc8-aa1c-9d5b4e80093e	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	f01842798e5fc8dcea747f76e643fad10838463ff2bd8ce32b717fd55b7d2717	admin	2025-07-26 08:49:03.113586+00	2025-07-19 08:49:03.113319+00	t
2a1bfc58-679a-46da-978e-422d7e091528	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	f01842798e5fc8dcea747f76e643fad10838463ff2bd8ce32b717fd55b7d2717	admin	2025-07-26 08:49:03.114645+00	2025-07-19 08:49:03.114244+00	t
fcbe1d77-9d5a-41f4-bc51-744f6ca55673	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	a7b9d81b25e2104c2078c125e14815b2535eab0ba7e83832f81f455dd499813a	admin	2025-07-26 11:21:33.357614+00	2025-07-19 11:21:33.360773+00	f
cb8fb025-49bf-4bc5-820a-ec5d827cdfb1	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	be855b647a7dab8b75f94d0b58455c1ab9d243c95204946f96df2a9469af8907	admin	2025-08-18 12:54:46.818458+00	2025-07-19 12:54:46.831231+00	t
bcea0bbe-142b-4f5d-9080-ac02086a761c	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	7b0988b6a782f7d807c4a26c273e09bd41ebae8d8984d6c5a6a09277994fa1da	admin	2025-07-26 13:11:16.789564+00	2025-07-19 13:11:16.789721+00	t
ed0c25f1-db85-409a-b8cd-40e3b4fad839	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	7b0988b6a782f7d807c4a26c273e09bd41ebae8d8984d6c5a6a09277994fa1da	admin	2025-07-26 13:11:16.789092+00	2025-07-19 13:11:16.789645+00	t
a666035e-45eb-4d34-82fe-46176ab60465	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	e65d4be96deba2b61f2831690b0bcc478f86fbe0494bec70dab433ce7e2ed331	admin	2025-07-26 16:24:59.705529+00	2025-07-19 16:24:59.705754+00	f
99982c93-9f58-48a7-b490-b5413d3fb62b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	fb6c7d55e6aac9392de76c97c46f4ea34c27b3ff87fd787e28bafb561fbdfb2c	admin	2025-08-18 17:24:51.211085+00	2025-07-19 17:24:51.249839+00	t
77a37691-84f5-4225-a50e-746c022bb749	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	d40dd2f6df02bab013911d8998eb73a047391a01f9dc3fa7727e37f484a6b246	admin	2025-07-26 17:39:53.914431+00	2025-07-19 17:39:53.915041+00	t
7a1480c1-1aec-4a9e-821a-07d2db35e774	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	8d9a3a5b907c9c43aac1170211a81c04d39ec4415b0ff97006a3dca9e84a0925	admin	2025-07-26 17:57:23.531961+00	2025-07-19 17:57:23.532437+00	t
2595a601-0945-45c5-a459-5fb18ffb0889	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	cf401768ff741de0290d81735b686fe015dadb0817f2ae791ca446434b966d3b	admin	2025-07-26 18:18:56.650143+00	2025-07-19 18:18:56.649939+00	t
ea151058-e92a-44f2-b34d-5e19c08e575b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	25a346b823ab7fef27fe5f7f082463142da72b12a2ee6cc4021e9d47d3d1e470	admin	2025-07-26 18:34:50.831887+00	2025-07-19 18:34:50.832368+00	t
df28462e-1a46-4bdc-8967-91ac334ef8fc	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	16e58f1ff222d379a7f11e5796229acca0b7f73e762cede68fca43f73038b459	admin	2025-07-26 18:51:11.735498+00	2025-07-19 18:51:11.735908+00	t
4453b308-5ac2-44fa-8b4c-9bb962566aae	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	5769e9cd6e3127af26418454e7fa7d7a5ec73710aab3c4ad2e9a10f723ab6af3	admin	2025-07-26 19:06:28.429138+00	2025-07-19 19:06:28.435041+00	t
6a3f091e-8b09-4222-8e67-adce2994d920	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	83e985e298a8df7bb98fd8ff2a82fb568e95afc45c031c2be505622886e9ab26	admin	2025-07-26 19:35:39.245648+00	2025-07-19 19:35:39.246224+00	t
3e926578-c541-4878-92b1-74311050823b	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	711a8f7b72c81c8157ddbb5d804ec191004cdced16d509d99b52a9be6c0d6818	admin	2025-07-26 19:56:25.555749+00	2025-07-19 19:56:25.556268+00	t
0b3c9da7-483e-45f0-93b1-904f82b66890	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	bdf93e51f8860fc7f5955802eb9797386b9e4d789b7cbcb35fa8cc1e5cbc7071	admin	2025-07-26 20:12:20.179206+00	2025-07-19 20:12:20.235321+00	t
4337cdf1-42e9-44f2-b675-3c0bb1dce944	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	6e62bef50539afca40700ac4434d2ede4253ff724296b44fb18e6f3536d58812	admin	2025-07-26 20:27:29.683987+00	2025-07-19 20:27:29.684323+00	t
8469a855-aced-4849-8476-2f78375773da	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	9b6ba772ada0d32928be0433ecb87d9a74c1cbf75ad4b42d8336bf10e1982313	admin	2025-07-26 20:45:05.551795+00	2025-07-19 20:45:05.576156+00	t
6f835cd1-2cdd-473f-81fc-263764b42d70	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	586c028b87e54c2764d5a377fe372966405355b8cfd9fbadabee829214805619	admin	2025-07-26 21:01:43.287847+00	2025-07-19 21:01:43.291884+00	t
2cb10a57-cd00-49d8-9a2a-1c536e134293	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	fb940a374f84f882b481fe0a3c5b5ec8406dad2e27169d33a829600b251dd0ee	admin	2025-07-26 21:24:53.140862+00	2025-07-19 21:24:53.141283+00	t
01d150f1-58d6-4834-a61f-3f26989d7d12	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	b269c516e8600db6c2af3faeae32fcc43e99236c391d0061b1f20f3f34653a58	admin	2025-07-27 03:51:06.717717+00	2025-07-20 03:51:06.718179+00	t
db293af5-930f-4ca8-8a96-93e0152931b6	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	6556120e5e27ab3e760bbb8592db1a40beb909b90ae6e72eee157b47b8112393	admin	2025-07-26 21:44:54.028229+00	2025-07-19 21:44:54.09351+00	t
49361677-f7ec-4712-a7d4-1cfbf6f6b5a1	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	b269c516e8600db6c2af3faeae32fcc43e99236c391d0061b1f20f3f34653a58	admin	2025-07-27 03:51:06.718685+00	2025-07-20 03:51:06.723192+00	t
d03cd2fc-93ef-4d53-960a-a61479adfd1c	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	06616f6dfcadb481d59cba2de14ce12b145e1278a6ff7d2d7ba15f8da3fc6592	admin	2025-07-27 04:14:32.55831+00	2025-07-20 04:14:32.558539+00	t
59ef08c7-7ccd-4c13-8ca0-e27fd3f6d5d6	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	6dbf1969c02d58b1a98d21a9aa7c4b64208ccd25f57890c9fad3a8048ec3aa9c	admin	2025-07-27 12:05:32.639202+00	2025-07-20 12:05:32.641734+00	f
d524eab3-67a6-48a0-af48-4747ed0b4417	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	1aae1aaa2dcf8c7688006b36c233a9e7edcb464cc39497b33c454b09c0e1f6b2	admin	2025-07-27 14:30:17.158305+00	2025-07-20 14:30:17.158558+00	t
e6d560bb-0b27-4008-98d7-c21093600d72	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	1eed95550c072f09789709c87764a9e8057d78ab883558d52805d2f3975adbe6	admin	2025-07-27 13:57:02.716038+00	2025-07-20 13:57:02.717355+00	t
f524a0d5-8161-47a1-b13e-ab0fe5fccc00	4168fa21-b149-4cb2-929e-692fa11041e6	1dbba1997ad5aa68d458ec97f4d6abea56387ff07ef288fb5c9841ee60f4e2e9	site	2025-07-27 14:42:42.206389+00	2025-07-20 14:42:42.206365+00	f
0f0823bc-9b8a-44b5-ab9d-b2497e9d6434	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	af3131bc20240d99029eae20210ee5aaea0c8d2737612189c54b8812f84ceac1	site	2025-07-27 14:01:39.972365+00	2025-07-20 14:01:39.972382+00	t
a7c3e5bf-ef2b-4e56-b9b0-70e3df4a22cb	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	74091939aee886af123c66390a4e6aeeb4d2589fe6164b3139c2a03efa3f5d90	site	2025-07-27 14:11:49.029683+00	2025-07-20 14:11:49.029569+00	t
adf1d5be-1390-4d2b-a0d6-0b0134be3b5a	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	2b2bf2e9e5a4237cb28ed13b6179ff61b098161ab15810098b06b0a2b84b3221	site	2025-07-27 14:12:47.478961+00	2025-07-20 14:12:47.476549+00	t
d4bf3958-6874-4fd7-9a60-6557deadad63	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	ea5a1d93fe78de3091a7238678abd3ffaeb6393fcbae724dfd06c9cfc5f0e05a	site	2025-07-27 14:17:30.253974+00	2025-07-20 14:17:30.253671+00	t
e04addac-26e3-46cc-a625-3a63316754b5	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8655f826dd1693223a46b744e2793cb07760a04dea1aff1d6e2e07081462e579	site	2025-07-27 16:22:33.732099+00	2025-07-20 16:22:33.734362+00	t
3d826c17-dcb0-48e9-8606-20557f0117bc	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	4a87be5c910a9d3d2cc868599d0374dc16dcb8f33338ce9ee0c9c8d1d1f22b2b	site	2025-07-27 15:47:42.621105+00	2025-07-20 15:47:42.621542+00	t
9feb4e06-2c7e-4702-ab74-2caf732d9a83	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	f4f2ef8e185e5a81aa6754c94cf924b21d6bd1367db1b89df17aa2e0e1334e1c	site	2025-07-15 05:55:27.917473+00	2025-07-08 05:55:27.918379+00	t
8bee1863-ad4f-43f1-b741-07944effc038	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8e4fd1e7ee2cace846ba455c3f9f4cb7d9c2272b3e445ab9fa4e2616aaf79bb9	site	2025-07-15 20:46:59.04733+00	2025-07-08 20:46:59.047523+00	t
acc5c7d0-834b-429e-be11-f7e554789783	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	5c7445551f6c65f46b8ab087a84b064ead045b67a86e751f883b355bfd6dc718	site	2025-07-25 07:56:11.948884+00	2025-07-18 07:56:11.95115+00	t
af0aba78-2221-424e-bc64-6fffe0373d70	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	45a047488665e5fc0c47a69b6b9a66129327451389d5bd17ca6063f39cc6f7b1	site	2025-08-18 00:03:53.046708+00	2025-08-11 00:03:53.04694+00	t
1709d9a9-6603-4535-80a3-dfe7f331da2d	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	4f76ef10ffb56c1a3ad0807cb0bf8f763eee9a7109621dcd7a50d5cdfbd07f61	admin	2025-09-09 12:51:41.681935+00	2025-08-10 12:51:41.682336+00	f
6b1327a1-ce13-40e0-9ced-231aaf87b211	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	922dee6a1fefcdd0eaf35066a4bb292b174e6e8980e3b048e116ce2ed7da89b8	site	2025-08-11 16:13:02.07094+00	2025-08-04 16:13:02.071586+00	t
70aae68a-490d-4a71-967d-a1b7feb1ab31	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	91a889c672eb39d3da1c88e360c704e1e72d6d1f0f7b9bbc4f0d5c0463f230c8	site	2025-08-18 00:03:25.303634+00	2025-08-11 00:03:25.304623+00	t
05d7dca5-cf31-4fb4-b34d-7d239ff3beec	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	c894babbfe7298be57f2dfd8685bf927d5fe9cc7d27803c1adba208ebd433263	site	2025-07-22 22:00:21.532431+00	2025-07-15 22:00:21.528669+00	t
520e0fe5-87d1-410a-9798-2a66bdde9339	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	9cb728a83fab2ec594a790aef2fbfd94458d3ee0eebd1b15f4a337dba76b2db7	site	2025-07-27 17:46:55.305007+00	2025-07-20 17:46:55.305043+00	t
87a37e57-55a0-4a7c-8c2f-c5c370bdeb4d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	d775b9375023269d6c8f15c5a9e0e53074977321166a30dff4ad5e94668ad761	site	2025-07-18 19:47:16.504105+00	2025-07-11 19:47:16.504225+00	t
c023f1f0-9e79-46e2-a0d0-796dda0496b0	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	c8b0b772d6cba0ffc5a30fc099e5517ab43e563df646257fe4249a019224f1e0	site	2025-07-27 17:04:56.760898+00	2025-07-20 17:04:56.758783+00	t
e14ebcca-09f7-45f2-81c8-174839925165	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	e86c1dae3f8d4fd10d56658ba936907ec9c2ae8966afd78c29108577235f45d9	site	2025-07-27 16:07:18.808186+00	2025-07-20 16:07:18.80503+00	t
0b717d2e-7583-474b-a1ac-d0a7e98ffee0	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	47408290a6afc12cb69a00b74172f8aed4564e76fff01ada691eebfe66befe86	site	2025-07-18 20:15:00.484656+00	2025-07-11 20:15:00.424654+00	t
742f07e3-d29b-4ace-978a-67eb5b31f993	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	09e127b79a6e8e2018d22477bc41d87a57e5dbac5ab45ec7c8465d3cbc19ed3e	site	2025-07-18 23:25:32.690076+00	2025-07-11 23:25:32.690036+00	t
d0778945-ccc9-4579-b66d-7f68c0096ddb	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	397cd0fc24edf9cf352ae9ad05046505c738e7bc9d6fa48a2c0c6a07b609de52	site	2025-07-19 09:47:44.568377+00	2025-07-12 09:47:44.568266+00	t
245660a0-b850-4b37-bf05-d874a6231b04	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	3f524f267949140197cdb030c3d65ce1eecc6d74d17e0c147364a01d43c1f9d1	site	2025-07-22 20:52:17.137575+00	2025-07-15 20:52:17.137828+00	t
98eeea3e-8f12-4200-baf1-70caa270ad29	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	b40cc15994639ea78441c7bb01e3b01842ab2bfc2a8d918e04d3d4c6a59fdd18	site	2025-07-22 21:20:14.922757+00	2025-07-15 21:20:14.923658+00	t
bc325b8e-1a80-4be2-bb40-adb5804f602d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	6b3b91c0926d1288d595496584bcf88d6569e6625a1312e92172113afce8cb93	site	2025-07-22 21:35:17.926587+00	2025-07-15 21:35:17.926842+00	t
d14a41b4-e85b-4d49-8dba-2aed8a54bd87	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	36235254f702f050787f44fc1ccf1f2755aba96a6fda525be165607fabe7e603	site	2025-07-23 04:59:24.796868+00	2025-07-16 04:59:24.797392+00	t
58246e06-8f69-4753-89c1-f077e7243c0f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	33ceff1e69331aef2f9cd06971630c5446ab4330ce1ab7d635699c8e94f966f9	site	2025-07-23 05:23:27.233417+00	2025-07-16 05:23:27.233103+00	t
08bad1b5-06e7-4d2b-8506-128800dda47f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	568e9dd46e3ac95edfe46d95f5bbc86e71767c22d25aaeb4988cfecbec8f4875	site	2025-07-23 07:07:41.772597+00	2025-07-16 07:07:41.772572+00	t
b2a04a14-e055-42f0-a928-8900bb8195c8	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8945932c6e2380c6c92264523e7c9f488bd46d81bf58b6a165d85d2dee6df829	site	2025-07-23 08:11:45.2442+00	2025-07-16 08:11:45.245345+00	t
a0b695f3-534d-4a41-ae5a-59098f409f24	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	fddf33590a94275b74d219a1b1d54440989e4e7aca0231a1926370c6f5b8174f	site	2025-07-23 18:49:53.140648+00	2025-07-16 18:49:53.140438+00	t
7ab18549-dc91-4dc3-8030-ae238e5a1ce7	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	0f6421d5446ee89fd695bf30990f95b8188f62c263542d7b15e20f2f32ce73b9	site	2025-07-27 17:23:46.976405+00	2025-07-20 17:23:46.97626+00	t
25a2f75c-6459-4c29-8759-6c9042788197	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	d3939f3eed6ef743ccb72bcb2f16e66e05f2ff8624c6f5d1fb16995b6be728fb	site	2025-08-10 03:56:14.095709+00	2025-08-03 03:56:14.095995+00	t
aaeb2228-040e-4df5-845d-7ef64ddc999f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	a7b65f71f71ba33d016c182cbe7aa7a402b30cfd38e99d44f0045f8721f468a8	site	2025-08-10 13:05:49.137861+00	2025-08-03 13:05:49.138563+00	t
917904b3-a58a-4aa3-814a-01572afbcce2	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	411c0eb62d59a39b13c99142eee094b50b85c97e51b03d0b0ef8c61ccf970ff9	admin	2025-09-02 03:56:38.424883+00	2025-08-03 03:56:38.425297+00	f
69a6ebf3-b982-4a78-862d-1f92a289a146	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	912565b08d2e38ddde03f3506645992174e15b5bd5d39925d4e46dad2c2bb17c	admin	2025-09-02 04:15:24.860718+00	2025-08-03 04:15:24.864162+00	f
71fdec36-d849-4811-bb2c-89be5a8503ff	0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5	9fdecb0e3573dda8226aecafac12c66d8fd32b45b1aab16b6be7ef6b2eaf51ec	admin	2025-09-02 13:04:03.981677+00	2025-08-03 13:04:03.982209+00	f
8bc16997-6605-4fa2-b4d0-cd18cc5075a2	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ac6af8b76d9ecd68539c24c818cd6f5c5c1b0a42091062b12614471f358974db	site	2025-07-14 21:48:51.626943+00	2025-07-07 21:48:51.627579+00	t
f0d5d335-f71f-4168-b630-a50f9186f4d8	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	2e9e2620a64ab3b4f8ddd11fdbc97241e3ccd99e7516ccd6d1b178f292205907	site	2025-07-14 21:48:58.418401+00	2025-07-07 21:48:58.418895+00	t
02bf1834-b001-43ae-9c0e-c47fbde44226	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	05ba4d03ba1f39eb487d3e9a61c979d72e4ef6b9a681657986969d6be339766c	site	2025-07-15 03:59:48.476648+00	2025-07-08 03:59:48.477262+00	t
1b4ab149-825e-4d16-80ca-d550f8e46c7d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	7863747568fcf3c804f9405b104b3912df3190a317ce6126cca059d1f933c239	site	2025-07-27 16:47:00.440838+00	2025-07-20 16:47:00.444483+00	t
95474a57-8d24-44c3-8e79-1caba681f0aa	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	37e2116dbee870037b932fb9ec86802ef245b70fb3c61f0603ade557dc85be5c	site	2025-07-18 12:00:52.61363+00	2025-07-11 12:00:52.614233+00	t
d9bca01d-65bb-49a3-8315-2c47eaa5bfa4	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	48c2136aa21bb4c04e8b37b0bd59c947dcb1fa042af33b4b9805854d9021fb32	site	2025-07-23 19:41:09.062496+00	2025-07-16 19:41:09.064802+00	t
b7e39fb4-65ca-4819-afc2-6d0915a043e8	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	aa435c0755ef584ad4e2ad975a127ea230981cd3c3c5d18e26322e826d3d0ee4	site	2025-07-23 21:04:37.070506+00	2025-07-16 21:04:37.071475+00	t
855348a9-8e1b-47db-905e-e96486610bba	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	721c7b674bf3638873c5ee955be6e78c46e71db1ff2d434f05598e6504b62be6	site	2025-07-24 06:27:55.428618+00	2025-07-17 06:27:55.429336+00	t
74a31c52-0942-4b2f-b9e5-28132ec77411	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	68cd5fb42ee0e94698021a34909837163cd9e1c3766f3ba1cc0c5c4fb1bf0a76	site	2025-07-24 07:27:00.113483+00	2025-07-17 07:27:00.114422+00	t
e630e3c9-a15b-4803-b204-bc504fcf276d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	70a2f77fa2df272c136ddbced46465cb35cb03e1e2b9fd0b8886446b2d3fa5e1	site	2025-07-24 08:11:45.405205+00	2025-07-17 08:11:45.405889+00	t
5ffcaf3b-d71f-4926-a3ed-5777e939cfd3	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	e7a10a30f610012beb4d156d7cc0d7021ac6f87d829df489a64737c4878ec54e	site	2025-07-24 18:57:31.156562+00	2025-07-17 18:57:31.093835+00	t
87cd92aa-7c5a-4135-a6d7-b80a817850c3	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	a652a84cdb7c0aab7de289a7269fd2278c41cfa38b9320b385e079a94192bc16	site	2025-07-24 19:49:23.859361+00	2025-07-17 19:49:23.859831+00	t
6c864330-3734-4334-bdcf-99c875b7be4f	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	64efe9f1c383939e8ba2b3ccd0823f332f794de710ff66ac2a0d4fee9c6fd472	site	2025-07-24 20:47:02.658179+00	2025-07-17 20:47:02.658035+00	t
33b82326-d6f6-43af-964d-0f9aac89208e	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	467f56869c7b23e305e102632895d3b060f70f423f1993c062cd59b15bee31d0	site	2025-07-25 05:16:05.039144+00	2025-07-18 05:16:05.047911+00	t
22c69c81-3ccf-44f3-b4ab-65d16c44eb63	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	01cd6bc6ce52b2fdb3ee5241c7e4822f6154481799f13f3aa1405411140d4474	site	2025-07-25 06:00:11.154349+00	2025-07-18 06:00:11.154282+00	t
b8f3cb2d-0bf1-4f84-a528-6cfd2923a469	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8f4210243b7a8ef2fbf2c3831d681433f0fa97913d2f536a243c141894175359	site	2025-07-27 15:53:31.938722+00	2025-07-20 15:53:31.93965+00	t
275600a2-32b8-4b62-a725-4af71ec96b48	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	e073f0ab0022fa8d06ce967f72c67d86cb554117a9994aac7d31a4a784ac8d74	site	2025-07-18 13:17:35.697558+00	2025-07-11 13:17:35.697797+00	t
efd2e3fb-b001-4c8a-8842-37a4e1080e98	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	7a414b1f9fbc2f853e9960d306285b837c4d460d0200f3dd3031d0028e07c24c	site	2025-07-27 13:52:30.603428+00	2025-07-20 13:52:30.604631+00	t
f70c731c-11ba-4800-a57c-87f35034c318	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	acc30febb74e13d6bb42a1fa049acf69d0b39050d9007579a808f7faa7ad14d6	site	2025-07-27 14:13:32.363734+00	2025-07-20 14:13:32.36345+00	t
82571ca3-54d9-4368-93ce-465b738ef8ba	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	d096dc0aeadd5adbd51406e72e9ecac310125c2fb34ad0e208498276b27f2e28	site	2025-07-27 14:49:28.113374+00	2025-07-20 14:49:28.114523+00	t
30be9290-4584-4082-8305-c8d260133dd6	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	b23e0086d71ca3c7a523110022100ff7e51cd49cd3448f4b0b36cf06dabb2d31	site	2025-07-27 14:30:16.950327+00	2025-07-20 14:30:16.950507+00	t
5d310cc9-f117-4d3b-b522-37173ce64e02	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	970ab210026e5a1303b075ae84c680224d25680eb2c7d4643011b24e81595f20	site	2025-07-23 04:05:03.844112+00	2025-07-16 04:05:03.844227+00	t
fcc304fb-7720-4dbd-b027-1a643fd4dc1d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	872846683b49166987b4e77cbab43060065519e37c079a9b55864ebe51583099	site	2025-07-23 04:21:56.407847+00	2025-07-16 04:21:56.408064+00	t
f661816e-7b69-4119-81aa-89a69d38058e	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	1bf96b7ab6ee710d15ff76b18455b67a380a44973622ee5f0ae79b254b49307a	site	2025-07-23 04:43:11.374586+00	2025-07-16 04:43:11.379794+00	t
29f0784a-c529-4323-a192-81e9d3ac6976	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	da8fc462f7643526cb2aef87398465f9dc56025c080174841684f3fe93b6cc6c	site	2025-07-18 12:02:30.456973+00	2025-07-11 12:02:30.456905+00	t
772e6b8d-0ba2-4947-99fa-c029f35ff2bf	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	ce72284f309d8bb60e7720dba1a9fa732382e2e39657cf6c1cd4a513eb4ae5af	site	2025-07-18 12:18:30.602751+00	2025-07-11 12:18:30.604838+00	t
f67c5b67-6f7e-4552-aed9-7a4f0b4cf57b	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	09cdee0460600796a70c4ff85358eae0925952bfb5f413468a7bf3f347429107	site	2025-07-27 13:14:02.382591+00	2025-07-20 13:14:02.382831+00	t
133c32aa-1922-40a5-ad5b-e703d2c3112e	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	afb0d9166fe256fe64ee7b9dcb6b3abfbf6cd6129d2e117ef68b9376a82cd7ba	site	2025-07-27 15:05:36.01509+00	2025-07-20 15:05:36.023493+00	t
da2162fc-fee9-4482-ba59-b6d3fb55e77d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8879cf49095d69be0e6d3e966b88ae852cbb460fe496d5052b4995e481b31e7c	site	2025-07-27 15:32:27.16979+00	2025-07-20 15:32:27.170561+00	t
8cbc918d-4b68-4e54-a9e4-267a5419e97d	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	5c6751c57810b56170d4fcfd4fae2878b76db37add149bac805733f81ac293a4	site	2025-07-18 14:50:37.60256+00	2025-07-11 14:50:37.602551+00	t
02181d00-d9b0-480a-a5ea-15400ee880b5	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	2013b44d6bd490e214b241a19cf79c1ce230598a2a7e271da3fc85842adb1028	site	2025-07-18 14:51:59.962441+00	2025-07-11 14:51:59.963028+00	t
1d287c53-cc52-4b4f-85a3-2d790342163c	81fe86cf-ca4e-4c79-80b7-81dc0e03d78d	8bc88aedcc154f56efe407c2ed1addd42a0a5fb0a351c6578e7ea87d088733af	site	2025-07-18 18:11:41.78084+00	2025-07-11 18:11:41.780706+00	t
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
4168fa21-b149-4cb2-929e-692fa11041e6	test@example.com	$2b$12$BSRjiL4G0zQ5zsrwVn4PmeFegU0tWmN6tWezdQOftqlEhW0gx0VXm	Test User	\N	\N	0	user	active	f	\N	\N	2025-07-20 14:42:42.201028+00	2025-07-20 14:42:42.201028+00
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
-- Name: idx_comments_depth; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_comments_depth ON public.comments USING btree (depth);


--
-- Name: idx_comments_is_deleted; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_comments_is_deleted ON public.comments USING btree (is_deleted);


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
-- Name: idx_posts_depth; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_depth ON public.posts USING btree (depth);


--
-- Name: idx_posts_is_deleted; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_is_deleted ON public.posts USING btree (is_deleted);


--
-- Name: idx_posts_meta_title; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_meta_title ON public.posts USING btree (meta_title);


--
-- Name: idx_posts_parent_id; Type: INDEX; Schema: public; Owner: mincenter
--

CREATE INDEX idx_posts_parent_id ON public.posts USING btree (parent_id);


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
-- Name: posts update_post_reply_count_trigger; Type: TRIGGER; Schema: public; Owner: mincenter
--

CREATE TRIGGER update_post_reply_count_trigger AFTER INSERT OR DELETE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.update_post_reply_count();


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
-- Name: posts posts_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: mincenter
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.posts(id) ON DELETE CASCADE;


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

