-- 게시글 이동 이력 테이블
CREATE TABLE post_move_history (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    original_board_id INTEGER NOT NULL,
    original_category_id INTEGER,
    moved_board_id INTEGER NOT NULL,
    moved_category_id INTEGER,
    move_reason TEXT,
    moved_by INTEGER NOT NULL,
    moved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    move_location VARCHAR(20) NOT NULL CHECK (move_location IN ('site', 'admin')),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (original_board_id) REFERENCES boards(id),
    FOREIGN KEY (original_category_id) REFERENCES categories(id),
    FOREIGN KEY (moved_board_id) REFERENCES boards(id),
    FOREIGN KEY (moved_category_id) REFERENCES categories(id),
    FOREIGN KEY (moved_by) REFERENCES users(id)
);

-- 게시글 숨김 이력 테이블
CREATE TABLE post_hide_history (
    id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL,
    hide_reason TEXT,
    hide_category VARCHAR(50) NOT NULL CHECK (hide_category IN ('광고', '음란물', '욕설비방', '기타 정책위반', 'inappropriate', 'spam', 'duplicate', 'violation', 'other', 'quick_hide')),
    hide_tags TEXT[],
    hidden_by INTEGER NOT NULL,
    hidden_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    hide_location VARCHAR(20) NOT NULL CHECK (hide_location IN ('site', 'admin')),
    is_hidden BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (hidden_by) REFERENCES users(id)
);

-- 인덱스 생성
CREATE INDEX idx_post_move_history_post_id ON post_move_history(post_id);
CREATE INDEX idx_post_move_history_moved_at ON post_move_history(moved_at);
CREATE INDEX idx_post_hide_history_post_id ON post_hide_history(post_id);
CREATE INDEX idx_post_hide_history_hidden_at ON post_hide_history(hidden_at);
CREATE INDEX idx_post_hide_history_is_hidden ON post_hide_history(is_hidden);
