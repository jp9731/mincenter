--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13 (Debian 15.13-1.pgdg120+1)
-- Dumped by pg_dump version 15.13 (Debian 15.13-1.pgdg120+1)

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
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: entity_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.entity_type AS ENUM (
    'post',
    'gallery',
    'user_profile',
    'comment',
    'draft'
);


--
-- Name: file_purpose; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.file_purpose AS ENUM (
    'attachment',
    'thumbnail',
    'content',
    'avatar',
    'editorimage'
);


--
-- Name: file_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.file_status AS ENUM (
    'draft',
    'published',
    'orphaned',
    'processing'
);


--
-- Name: file_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.file_type AS ENUM (
    'image',
    'video',
    'audio',
    'document',
    'archive',
    'other'
);


--
-- Name: menu_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.menu_type AS ENUM (
    'page',
    'board',
    'calendar',
    'url'
);


--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.notification_type AS ENUM (
    'comment',
    'like',
    'system',
    'announcement'
);


--
-- Name: post_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_status AS ENUM (
    'active',
    'hidden',
    'deleted',
    'published'
);


--
-- Name: processing_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.processing_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'user',
    'admin'
);


--
-- Name: user_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_status AS ENUM (
    'active',
    'inactive',
    'suspended'
);


--
-- Name: cleanup_expired_drafts(); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: cleanup_orphaned_files(); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: increment_page_view_count(uuid); Type: FUNCTION; Schema: public; Owner: -
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


--
-- Name: restore_post(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restore_post(post_id uuid, restored_by_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE posts 
    SET 
        is_deleted = FALSE,
        deleted_at = NULL,
        deleted_by = NULL,
        status = 'active'::post_status
    WHERE id = post_id;
END;
$$;


--
-- Name: soft_delete_post(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.soft_delete_post(post_id uuid, deleted_by_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE posts 
    SET 
        is_deleted = TRUE,
        deleted_at = NOW(),
        deleted_by = deleted_by_user_id,
        status = 'deleted'::post_status
    WHERE id = post_id;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: korean; Type: TEXT SEARCH CONFIGURATION; Schema: public; Owner: -
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _sqlx_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._sqlx_migrations (
    version bigint NOT NULL,
    description text NOT NULL,
    installed_on timestamp with time zone DEFAULT now() NOT NULL,
    success boolean NOT NULL,
    checksum bytea NOT NULL,
    execution_time bigint NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
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
    thumbnail_url character varying(500),
    is_deleted boolean DEFAULT false,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    excerpt text,
    meta_title character varying(255),
    meta_description text,
    tags text[],
    is_featured boolean DEFAULT false,
    is_pinned boolean DEFAULT false,
    moderation_status character varying(20) DEFAULT 'approved'::character varying,
    moderated_by uuid,
    moderated_at timestamp with time zone,
    share_count integer DEFAULT 0,
    bookmark_count integer DEFAULT 0,
    version integer DEFAULT 1,
    last_edited_by uuid,
    edit_count integer DEFAULT 0,
    dislikes integer DEFAULT 0,
    CONSTRAINT posts_moderation_status_check CHECK (((moderation_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying])::text[])))
);


--
-- Name: COLUMN posts.thumbnail_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.thumbnail_url IS 'URL for post thumbnail image';


--
-- Name: COLUMN posts.is_deleted; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.is_deleted IS 'Soft delete flag';


--
-- Name: COLUMN posts.deleted_at; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.deleted_at IS 'Timestamp when post was deleted';


--
-- Name: COLUMN posts.deleted_by; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.deleted_by IS 'User who deleted the post';


--
-- Name: COLUMN posts.excerpt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.excerpt IS 'Short summary of post content';


--
-- Name: COLUMN posts.meta_title; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.meta_title IS 'SEO meta title';


--
-- Name: COLUMN posts.meta_description; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.meta_description IS 'SEO meta description';


--
-- Name: COLUMN posts.tags; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.tags IS 'Array of tags for categorization';


--
-- Name: COLUMN posts.is_featured; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.is_featured IS 'Featured post flag';


--
-- Name: COLUMN posts.is_pinned; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.is_pinned IS 'Pinned post flag';


--
-- Name: COLUMN posts.moderation_status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.moderation_status IS 'Post moderation status';


--
-- Name: COLUMN posts.share_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.share_count IS 'Number of times post was shared';


--
-- Name: COLUMN posts.bookmark_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.bookmark_count IS 'Number of times post was bookmarked';


--
-- Name: COLUMN posts.version; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.version IS 'Content version number';


--
-- Name: COLUMN posts.edit_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.posts.edit_count IS 'Number of times post was edited';


--
-- Name: active_posts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.active_posts AS
 SELECT posts.id,
    posts.board_id,
    posts.category_id,
    posts.user_id,
    posts.title,
    posts.content,
    posts.views,
    posts.likes,
    posts.is_notice,
    posts.status,
    posts.created_at,
    posts.updated_at,
    posts.thumbnail_url,
    posts.is_deleted,
    posts.deleted_at,
    posts.deleted_by,
    posts.excerpt,
    posts.meta_title,
    posts.meta_description,
    posts.tags,
    posts.is_featured,
    posts.is_pinned,
    posts.moderation_status,
    posts.moderated_by,
    posts.moderated_at,
    posts.share_count,
    posts.bookmark_count,
    posts.version,
    posts.last_edited_by,
    posts.edit_count
   FROM public.posts
  WHERE ((posts.is_deleted = false) AND ((posts.status = 'active'::public.post_status) OR (posts.status = 'published'::public.post_status) OR (posts.status IS NULL)));


--
-- Name: boards; Type: TABLE; Schema: public; Owner: -
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
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
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
    allowed_iframe_domains text
);


--
-- Name: calendar_events; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: categories; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: deleted_posts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.deleted_posts AS
 SELECT posts.id,
    posts.board_id,
    posts.category_id,
    posts.user_id,
    posts.title,
    posts.content,
    posts.views,
    posts.likes,
    posts.is_notice,
    posts.status,
    posts.created_at,
    posts.updated_at,
    posts.thumbnail_url,
    posts.is_deleted,
    posts.deleted_at,
    posts.deleted_by,
    posts.excerpt,
    posts.meta_title,
    posts.meta_description,
    posts.tags,
    posts.is_featured,
    posts.is_pinned,
    posts.moderation_status,
    posts.moderated_by,
    posts.moderated_at,
    posts.share_count,
    posts.bookmark_count,
    posts.version,
    posts.last_edited_by,
    posts.edit_count
   FROM public.posts
  WHERE (posts.is_deleted = true);


--
-- Name: drafts; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: faqs; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: file_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.file_entities (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    file_id uuid NOT NULL,
    entity_type public.entity_type NOT NULL,
    entity_id uuid NOT NULL,
    display_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: files; Type: TABLE; Schema: public; Owner: -
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
    status public.file_status DEFAULT 'draft'::public.file_status,
    compression_ratio numeric(5,2),
    has_thumbnails boolean DEFAULT false,
    processing_status public.processing_status DEFAULT 'pending'::public.processing_status,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: galleries; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: hero_sections; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: image_sizes; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: likes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.likes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: menus; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: organization_info; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    resource character varying(100) NOT NULL,
    action character varying(100) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: point_transactions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: popular_posts; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.popular_posts AS
 SELECT p.id,
    p.title,
    p.content,
    p.views,
    p.likes,
    p.created_at,
    u.name AS author_name,
    b.name AS board_name,
    (((p.views)::numeric * 0.1) + ((p.likes)::numeric * 1.0)) AS popularity_score
   FROM ((public.posts p
     JOIN public.users u ON ((p.user_id = u.id)))
     JOIN public.boards b ON ((p.board_id = b.id)))
  WHERE (p.status = 'active'::public.post_status)
  ORDER BY (((p.views)::numeric * 0.1) + ((p.likes)::numeric * 1.0)) DESC;


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: site_info; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_info (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    site_name character varying(255) DEFAULT '민센터 봉사단체'::character varying NOT NULL,
    catchphrase text,
    address text,
    phone character varying(50),
    email character varying(255),
    homepage character varying(500),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    fax character varying(50),
    representative_name character varying(100),
    business_number character varying(20),
    logo_image_url text
);


--
-- Name: site_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_settings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key character varying(100) NOT NULL,
    value text,
    description character varying(500),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: sns_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sns_links (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(100) NOT NULL,
    url character varying(500) NOT NULL,
    icon character varying(100) DEFAULT 'custom'::character varying NOT NULL,
    icon_type character varying(20) DEFAULT 'emoji'::character varying NOT NULL,
    display_order integer DEFAULT 0 NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: token_blacklist; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.token_blacklist (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    token_jti character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_activity_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.user_activity_stats AS
 SELECT u.id,
    u.name,
    u.email,
    u.points,
    count(DISTINCT p.id) AS post_count,
    count(DISTINCT c.id) AS comment_count,
    count(DISTINCT l.id) AS like_given_count,
    ( SELECT count(*) AS count
           FROM public.likes
          WHERE (((likes.entity_type)::text = 'post'::text) AND (likes.entity_id IN ( SELECT posts.id
                   FROM public.posts
                  WHERE (posts.user_id = u.id))))) AS likes_received_count
   FROM (((public.users u
     LEFT JOIN public.posts p ON (((u.id = p.user_id) AND (p.status = 'active'::public.post_status))))
     LEFT JOIN public.comments c ON (((u.id = c.user_id) AND (c.status = 'active'::public.post_status))))
     LEFT JOIN public.likes l ON ((u.id = l.user_id)))
  WHERE (u.status = 'active'::public.user_status)
  GROUP BY u.id, u.name, u.email, u.points;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_social_accounts; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: _sqlx_migrations _sqlx_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._sqlx_migrations
    ADD CONSTRAINT _sqlx_migrations_pkey PRIMARY KEY (version);


--
-- Name: boards boards_name_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_name_unique UNIQUE (name);


--
-- Name: boards boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_pkey PRIMARY KEY (id);


--
-- Name: boards boards_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_slug_key UNIQUE (slug);


--
-- Name: boards boards_slug_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boards
    ADD CONSTRAINT boards_slug_unique UNIQUE (slug);


--
-- Name: calendar_events calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: faqs faqs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faqs
    ADD CONSTRAINT faqs_pkey PRIMARY KEY (id);


--
-- Name: file_entities file_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_entities
    ADD CONSTRAINT file_entities_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: galleries galleries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.galleries
    ADD CONSTRAINT galleries_pkey PRIMARY KEY (id);


--
-- Name: hero_sections hero_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hero_sections
    ADD CONSTRAINT hero_sections_pkey PRIMARY KEY (id);


--
-- Name: image_sizes image_sizes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_sizes
    ADD CONSTRAINT image_sizes_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: likes likes_user_id_entity_type_entity_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_entity_type_entity_id_key UNIQUE (user_id, entity_type, entity_id);


--
-- Name: menus menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: organization_info organization_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_info
    ADD CONSTRAINT organization_info_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: pages pages_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_slug_key UNIQUE (slug);


--
-- Name: permissions permissions_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_name_key UNIQUE (name);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: point_transactions point_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.point_transactions
    ADD CONSTRAINT point_transactions_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: role_permissions role_permissions_role_id_permission_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_permission_id_key UNIQUE (role_id, permission_id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: site_info site_info_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_info
    ADD CONSTRAINT site_info_pkey PRIMARY KEY (id);


--
-- Name: site_settings site_settings_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_key_key UNIQUE (key);


--
-- Name: site_settings site_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_settings
    ADD CONSTRAINT site_settings_pkey PRIMARY KEY (id);


--
-- Name: sns_links sns_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sns_links
    ADD CONSTRAINT sns_links_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist token_blacklist_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_pkey PRIMARY KEY (id);


--
-- Name: token_blacklist token_blacklist_token_jti_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_token_jti_key UNIQUE (token_jti);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_user_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_role_id_key UNIQUE (user_id, role_id);


--
-- Name: user_social_accounts user_social_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_pkey PRIMARY KEY (id);


--
-- Name: user_social_accounts user_social_accounts_provider_provider_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_provider_provider_id_key UNIQUE (provider, provider_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_calendar_events_is_public; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_events_is_public ON public.calendar_events USING btree (is_public);


--
-- Name: idx_categories_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_board_id ON public.categories USING btree (board_id);


--
-- Name: idx_categories_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_categories_is_active ON public.categories USING btree (is_active);


--
-- Name: idx_comments_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_created_at ON public.comments USING btree (created_at DESC);


--
-- Name: idx_comments_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_parent_id ON public.comments USING btree (parent_id);


--
-- Name: idx_comments_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_post_id ON public.comments USING btree (post_id);


--
-- Name: idx_comments_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_comments_user_id ON public.comments USING btree (user_id);


--
-- Name: idx_drafts_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_drafts_expires_at ON public.drafts USING btree (expires_at);


--
-- Name: idx_drafts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_drafts_user_id ON public.drafts USING btree (user_id);


--
-- Name: idx_file_entities_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_entities_entity ON public.file_entities USING btree (entity_type, entity_id);


--
-- Name: idx_file_entities_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_file_entities_file_id ON public.file_entities USING btree (file_id);


--
-- Name: idx_files_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_files_created_at ON public.files USING btree (created_at);


--
-- Name: idx_files_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_files_status ON public.files USING btree (status);


--
-- Name: idx_files_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_files_user_id ON public.files USING btree (user_id);


--
-- Name: idx_likes_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_likes_entity ON public.likes USING btree (entity_type, entity_id);


--
-- Name: idx_likes_user_entity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_likes_user_entity ON public.likes USING btree (user_id, entity_type, entity_id);


--
-- Name: idx_menus_display_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menus_display_order ON public.menus USING btree (display_order);


--
-- Name: idx_menus_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menus_is_active ON public.menus USING btree (is_active);


--
-- Name: idx_menus_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_menus_parent_id ON public.menus USING btree (parent_id);


--
-- Name: idx_notifications_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_read ON public.notifications USING btree (is_read);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_pages_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pages_created_at ON public.pages USING btree (created_at);


--
-- Name: idx_pages_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pages_published ON public.pages USING btree (is_published);


--
-- Name: idx_pages_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pages_slug ON public.pages USING btree (slug);


--
-- Name: idx_pages_sort_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pages_sort_order ON public.pages USING btree (sort_order);


--
-- Name: idx_pages_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pages_status ON public.pages USING btree (status);


--
-- Name: idx_permissions_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissions_active ON public.permissions USING btree (is_active);


--
-- Name: idx_permissions_resource_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissions_resource_action ON public.permissions USING btree (resource, action);


--
-- Name: idx_point_transactions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_point_transactions_user_id ON public.point_transactions USING btree (user_id);


--
-- Name: idx_posts_board_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_board_id ON public.posts USING btree (board_id);


--
-- Name: idx_posts_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_category_id ON public.posts USING btree (category_id);


--
-- Name: idx_posts_content_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_content_gin ON public.posts USING gin (to_tsvector('public.korean'::regconfig, content));


--
-- Name: idx_posts_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_created_at ON public.posts USING btree (created_at DESC);


--
-- Name: idx_posts_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_deleted_at ON public.posts USING btree (deleted_at);


--
-- Name: idx_posts_is_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_is_deleted ON public.posts USING btree (is_deleted);


--
-- Name: idx_posts_is_featured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_is_featured ON public.posts USING btree (is_featured);


--
-- Name: idx_posts_is_pinned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_is_pinned ON public.posts USING btree (is_pinned);


--
-- Name: idx_posts_moderation_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_moderation_status ON public.posts USING btree (moderation_status);


--
-- Name: idx_posts_popularity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_popularity ON public.posts USING btree (((((views)::numeric * 0.1) + ((likes)::numeric * 1.0))) DESC);


--
-- Name: idx_posts_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_status ON public.posts USING btree (status);


--
-- Name: idx_posts_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_tags ON public.posts USING gin (tags);


--
-- Name: idx_posts_title_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_title_gin ON public.posts USING gin (to_tsvector('public.korean'::regconfig, (title)::text));


--
-- Name: idx_posts_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_posts_user_id ON public.posts USING btree (user_id);


--
-- Name: idx_refresh_tokens_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_hash ON public.refresh_tokens USING btree (token_hash);


--
-- Name: idx_refresh_tokens_user_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_user_service ON public.refresh_tokens USING btree (user_id, service_type);


--
-- Name: idx_role_permissions_permission_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_permission_id ON public.role_permissions USING btree (permission_id);


--
-- Name: idx_role_permissions_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_permissions_role_id ON public.role_permissions USING btree (role_id);


--
-- Name: idx_roles_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_roles_active ON public.roles USING btree (is_active);


--
-- Name: idx_roles_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_roles_name ON public.roles USING btree (name);


--
-- Name: idx_site_info_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_site_info_created_at ON public.site_info USING btree (created_at DESC);


--
-- Name: idx_sns_links_active_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sns_links_active_order ON public.sns_links USING btree (is_active, display_order);


--
-- Name: idx_sns_links_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sns_links_created_at ON public.sns_links USING btree (created_at);


--
-- Name: idx_user_roles_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_role_id ON public.user_roles USING btree (role_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: boards update_boards_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_boards_updated_at BEFORE UPDATE ON public.boards FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: calendar_events update_calendar_events_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: categories update_categories_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: comments update_comments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: drafts update_drafts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_drafts_updated_at BEFORE UPDATE ON public.drafts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: faqs update_faqs_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_faqs_updated_at BEFORE UPDATE ON public.faqs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: galleries update_galleries_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_galleries_updated_at BEFORE UPDATE ON public.galleries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: hero_sections update_hero_sections_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_hero_sections_updated_at BEFORE UPDATE ON public.hero_sections FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: menus update_menus_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_menus_updated_at BEFORE UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: organization_info update_organization_info_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_organization_info_updated_at BEFORE UPDATE ON public.organization_info FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: pages update_pages_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_pages_updated_at BEFORE UPDATE ON public.pages FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: posts update_posts_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON public.posts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: site_settings update_site_settings_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_site_settings_updated_at BEFORE UPDATE ON public.site_settings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: calendar_events calendar_events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: categories categories_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;


--
-- Name: comments comments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.comments(id) ON DELETE CASCADE;


--
-- Name: comments comments_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;


--
-- Name: comments comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: drafts drafts_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;


--
-- Name: drafts drafts_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: drafts drafts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: file_entities file_entities_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.file_entities
    ADD CONSTRAINT file_entities_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: files files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: image_sizes image_sizes_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.image_sizes
    ADD CONSTRAINT image_sizes_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: likes likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: menus menus_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.menus(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: pages pages_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: pages pages_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: point_transactions point_transactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.point_transactions
    ADD CONSTRAINT point_transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: posts posts_board_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_board_id_fkey FOREIGN KEY (board_id) REFERENCES public.boards(id) ON DELETE CASCADE;


--
-- Name: posts posts_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE SET NULL;


--
-- Name: posts posts_deleted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_deleted_by_fkey FOREIGN KEY (deleted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: posts posts_last_edited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_last_edited_by_fkey FOREIGN KEY (last_edited_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: posts posts_moderated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_moderated_by_fkey FOREIGN KEY (moderated_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: posts posts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: token_blacklist token_blacklist_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.token_blacklist
    ADD CONSTRAINT token_blacklist_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_social_accounts user_social_accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_social_accounts
    ADD CONSTRAINT user_social_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

