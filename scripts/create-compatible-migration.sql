-- UUID 호환 post management 테이블 생성
-- posts 테이블이 UUID를 사용하므로 모든 외래키도 UUID로 설정

-- 1. post_move_history 테이블 (UUID 버전)
CREATE TABLE IF NOT EXISTS post_move_history (
    id SERIAL PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    original_board_id UUID NOT NULL,
    original_category_id UUID,
    moved_board_id UUID NOT NULL,
    moved_category_id UUID,
    move_reason TEXT,
    moved_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    moved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    move_location VARCHAR(50) DEFAULT 'admin'
);

-- 2. post_hide_history 테이블 (UUID 버전)
CREATE TABLE IF NOT EXISTS post_hide_history (
    id SERIAL PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    hide_reason TEXT,
    hide_category VARCHAR(100),
    hidden_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hidden_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- 3. comment_hide_history 테이블 (UUID 버전)
CREATE TABLE IF NOT EXISTS comment_hide_history (
    id SERIAL PRIMARY KEY,
    comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    hide_reason TEXT,
    hide_category VARCHAR(100),
    hidden_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hidden_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE
);

-- 4. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_post_move_history_post_id ON post_move_history(post_id);
CREATE INDEX IF NOT EXISTS idx_post_move_history_moved_at ON post_move_history(moved_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_move_history_moved_by ON post_move_history(moved_by);

CREATE INDEX IF NOT EXISTS idx_post_hide_history_post_id ON post_hide_history(post_id);
CREATE INDEX IF NOT EXISTS idx_post_hide_history_hidden_at ON post_hide_history(hidden_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_hide_history_hidden_by ON post_hide_history(hidden_by);
CREATE INDEX IF NOT EXISTS idx_post_hide_history_active ON post_hide_history(is_active);

CREATE INDEX IF NOT EXISTS idx_comment_hide_history_comment_id ON comment_hide_history(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_hide_history_hidden_at ON comment_hide_history(hidden_at DESC);
CREATE INDEX IF NOT EXISTS idx_comment_hide_history_hidden_by ON comment_hide_history(hidden_by);
CREATE INDEX IF NOT EXISTS idx_comment_hide_history_active ON comment_hide_history(is_active);

-- 5. 코멘트 (테이블 생성 완료 확인)
SELECT 'post_move_history 테이블 생성 완료' as status;
SELECT 'post_hide_history 테이블 생성 완료' as status;
SELECT 'comment_hide_history 테이블 생성 완료' as status;
