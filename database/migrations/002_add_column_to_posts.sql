-- 마이그레이션: 002_add_column_to_posts.sql
-- 설명: posts 테이블에 새로운 컬럼 추가
-- 날짜: 2025-08-03

-- 새로운 컬럼 추가
ALTER TABLE posts ADD COLUMN IF NOT EXISTS priority INTEGER DEFAULT 0;

-- 기존 데이터 업데이트 (필요시)
UPDATE posts SET priority = 1 WHERE is_pinned = true;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_posts_priority ON posts(priority);

-- 댓글 추가
COMMENT ON COLUMN posts.priority IS '게시글 우선순위 (높을수록 우선)'; 