-- 서버 데이터베이스 스키마 동기화 스크립트
-- 개발 컴퓨터의 최신 스키마로 서버를 업데이트

-- 1. posts 테이블 스키마 동기화
DO $$
BEGIN
    -- content 필드를 NOT NULL로 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'posts' AND column_name = 'content' AND is_nullable = 'YES') THEN
        -- 기존 NULL 값들을 빈 문자열로 변경
        UPDATE posts SET content = '' WHERE content IS NULL;
        -- NOT NULL 제약 조건 추가
        ALTER TABLE posts ALTER COLUMN content SET NOT NULL;
        RAISE NOTICE 'Updated posts.content to NOT NULL';
    ELSE
        RAISE NOTICE 'posts.content is already NOT NULL';
    END IF;

    -- attached_files를 text[]로 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'posts' AND column_name = 'attached_files' AND data_type = 'text') THEN
        -- 기존 데이터 백업
        CREATE TEMP TABLE temp_attached_files AS 
        SELECT id, attached_files FROM posts WHERE attached_files IS NOT NULL AND attached_files != '';
        
        -- 컬럼 타입 변경
        ALTER TABLE posts ALTER COLUMN attached_files TYPE text[] USING 
            CASE 
                WHEN attached_files IS NULL OR attached_files = '' THEN NULL
                ELSE string_to_array(attached_files, ',')
            END;
        RAISE NOTICE 'Updated posts.attached_files to text[]';
    ELSE
        RAISE NOTICE 'posts.attached_files is already text[]';
    END IF;

    -- thumbnail_urls를 jsonb로 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'posts' AND column_name = 'thumbnail_urls' AND data_type = 'text') THEN
        -- 기존 데이터 백업
        CREATE TEMP TABLE temp_thumbnail_urls AS 
        SELECT id, thumbnail_urls FROM posts WHERE thumbnail_urls IS NOT NULL AND thumbnail_urls != '';
        
        -- 컬럼 타입 변경
        ALTER TABLE posts ALTER COLUMN thumbnail_urls TYPE jsonb USING 
            CASE 
                WHEN thumbnail_urls IS NULL OR thumbnail_urls = '' THEN NULL
                ELSE thumbnail_urls::jsonb
            END;
        RAISE NOTICE 'Updated posts.thumbnail_urls to jsonb';
    ELSE
        RAISE NOTICE 'posts.thumbnail_urls is already jsonb';
    END IF;
END $$;

-- 2. files 테이블 스키마 동기화
DO $$
BEGIN
    -- mime_type을 NOT NULL로 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'files' AND column_name = 'mime_type' AND is_nullable = 'YES') THEN
        -- 기존 NULL 값들을 기본값으로 변경
        UPDATE files SET mime_type = 'application/octet-stream' WHERE mime_type IS NULL;
        -- NOT NULL 제약 조건 추가
        ALTER TABLE files ALTER COLUMN mime_type SET NOT NULL;
        RAISE NOTICE 'Updated files.mime_type to NOT NULL';
    ELSE
        RAISE NOTICE 'files.mime_type is already NOT NULL';
    END IF;

    -- file_type을 NOT NULL로 변경
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'files' AND column_name = 'file_type' AND is_nullable = 'YES') THEN
        -- 기존 NULL 값들을 기본값으로 변경
        UPDATE files SET file_type = 'other'::file_type WHERE file_type IS NULL;
        -- NOT NULL 제약 조건 추가
        ALTER TABLE files ALTER COLUMN file_type SET NOT NULL;
        RAISE NOTICE 'Updated files.file_type to NOT NULL';
    ELSE
        RAISE NOTICE 'files.file_type is already NOT NULL';
    END IF;
END $$;

-- 3. 누락된 인덱스 추가
DO $$
BEGIN
    -- posts 테이블의 depth 인덱스 추가
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'posts' AND indexname = 'idx_posts_depth') THEN
        CREATE INDEX idx_posts_depth ON posts(depth);
        RAISE NOTICE 'Created index idx_posts_depth on posts table';
    ELSE
        RAISE NOTICE 'Index idx_posts_depth already exists on posts table';
    END IF;

    -- posts 테이블의 parent_id 인덱스 추가
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'posts' AND indexname = 'idx_posts_parent_id') THEN
        CREATE INDEX idx_posts_parent_id ON posts(parent_id);
        RAISE NOTICE 'Created index idx_posts_parent_id on posts table';
    ELSE
        RAISE NOTICE 'Index idx_posts_parent_id already exists on posts table';
    END IF;
END $$;

-- 4. 트리거 함수 추가 (reply count 업데이트)
CREATE OR REPLACE FUNCTION update_post_reply_count() 
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- 새 게시글이 답글이면 부모 게시글의 reply_count 증가
        IF NEW.parent_id IS NOT NULL THEN
            UPDATE posts 
            SET reply_count = reply_count + 1 
            WHERE id = NEW.parent_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- 삭제된 게시글이 답글이면 부모 게시글의 reply_count 감소
        IF OLD.parent_id IS NOT NULL THEN
            UPDATE posts 
            SET reply_count = GREATEST(reply_count - 1, 0) 
            WHERE id = OLD.parent_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. 트리거 추가
DO $$
BEGIN
    -- reply count 업데이트 트리거 추가
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_post_reply_count_trigger') THEN
        CREATE TRIGGER update_post_reply_count_trigger
        AFTER INSERT OR DELETE ON posts
        FOR EACH ROW
        EXECUTE FUNCTION update_post_reply_count();
        RAISE NOTICE 'Created update_post_reply_count_trigger';
    ELSE
        RAISE NOTICE 'update_post_reply_count_trigger already exists';
    END IF;
END $$;

-- 6. 기존 reply_count 값 업데이트
UPDATE posts 
SET reply_count = (
    SELECT COUNT(*) 
    FROM posts p2 
    WHERE p2.parent_id = posts.id
);

RAISE NOTICE 'Schema synchronization completed successfully!'; 