-- posts 테이블에 댓글/대댓글 관련 필드 추가
ALTER TABLE posts ADD COLUMN IF NOT EXISTS depth INTEGER DEFAULT 0;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES posts(id);
ALTER TABLE posts ADD COLUMN IF NOT EXISTS reply_count INTEGER DEFAULT 0;

-- 기존 댓글들의 depth를 0으로 설정
UPDATE posts SET depth = 0 WHERE depth IS NULL;

-- 댓글 수를 계산하는 함수 생성
CREATE OR REPLACE FUNCTION update_post_reply_count()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS update_post_reply_count_trigger ON posts;
CREATE TRIGGER update_post_reply_count_trigger
    AFTER INSERT OR DELETE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION update_post_reply_count();

-- 기존 댓글들의 reply_count 업데이트
UPDATE posts p1 
SET reply_count = (
    SELECT COUNT(*) 
    FROM posts p2 
    WHERE p2.parent_id = p1.id
); 