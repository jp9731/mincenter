-- 민들레센터 답글 및 대댓글 기능 추가 마이그레이션
-- 실행일: 2025-01-20

-- 1. posts 테이블에 답글 관련 컬럼 추가 (이미 존재할 수 있으므로 조건부 추가)
DO $$
BEGIN
    -- parent_id 컬럼 추가 (이미 존재하면 스킵)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'posts' AND column_name = 'parent_id') THEN
        ALTER TABLE posts ADD COLUMN parent_id uuid;
    END IF;
    
    -- depth 컬럼 추가 (이미 존재하면 스킵)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'posts' AND column_name = 'depth') THEN
        ALTER TABLE posts ADD COLUMN depth integer DEFAULT 0;
    END IF;
    
    -- reply_count 컬럼 추가 (이미 존재하면 스킵)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'posts' AND column_name = 'reply_count') THEN
        ALTER TABLE posts ADD COLUMN reply_count integer DEFAULT 0;
    END IF;
END $$;

-- 2. comments 테이블에 대댓글 관련 컬럼 추가 (이미 존재할 수 있으므로 조건부 추가)
DO $$
BEGIN
    -- depth 컬럼 추가 (이미 존재하면 스킵)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'comments' AND column_name = 'depth') THEN
        ALTER TABLE comments ADD COLUMN depth integer DEFAULT 0;
    END IF;
    
    -- is_deleted 컬럼 추가 (이미 존재하면 스킵)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'comments' AND column_name = 'is_deleted') THEN
        ALTER TABLE comments ADD COLUMN is_deleted boolean DEFAULT false;
    END IF;
END $$;

-- 3. 인덱스 생성 (이미 존재하면 스킵)
DO $$
BEGIN
    -- posts 테이블 parent_id 인덱스
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_posts_parent_id') THEN
        CREATE INDEX idx_posts_parent_id ON posts(parent_id);
    END IF;
    
    -- posts 테이블 depth 인덱스
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_posts_depth') THEN
        CREATE INDEX idx_posts_depth ON posts(depth);
    END IF;
    
    -- comments 테이블 depth 인덱스
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_comments_depth') THEN
        CREATE INDEX idx_comments_depth ON comments(depth);
    END IF;
    
    -- comments 테이블 is_deleted 인덱스
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_comments_is_deleted') THEN
        CREATE INDEX idx_comments_is_deleted ON comments(is_deleted);
    END IF;
END $$;

-- 4. 외래키 제약조건 추가 (이미 존재하면 스킵)
DO $$
BEGIN
    -- posts 테이블 parent_id 외래키
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE constraint_name = 'posts_parent_id_fkey' AND table_name = 'posts') THEN
        ALTER TABLE posts 
        ADD CONSTRAINT posts_parent_id_fkey 
        FOREIGN KEY (parent_id) REFERENCES posts(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 5. 기존 데이터 정리 (필요한 경우)
-- 기존 게시글들의 depth를 0으로 설정
UPDATE posts SET depth = 0 WHERE depth IS NULL;
UPDATE posts SET reply_count = 0 WHERE reply_count IS NULL;

-- 기존 댓글들의 depth를 적절히 설정
UPDATE comments SET depth = 0 WHERE parent_id IS NULL AND depth IS NULL;
UPDATE comments SET depth = 1 WHERE parent_id IS NOT NULL AND depth IS NULL;
UPDATE comments SET is_deleted = false WHERE is_deleted IS NULL;

-- 마이그레이션 완료
SELECT 'Migration completed successfully: Reply and nested comment functionality added' as result;