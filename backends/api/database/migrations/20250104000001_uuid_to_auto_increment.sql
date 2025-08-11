-- UUID를 자동 증가 숫자 ID로 변경하는 마이그레이션
-- 이 마이그레이션은 주요 테이블들의 UUID를 SERIAL ID로 변경합니다

-- 먼저 외래키 제약조건들을 모두 제거합니다
ALTER TABLE comments DROP CONSTRAINT IF EXISTS comments_post_id_fkey;
ALTER TABLE comments DROP CONSTRAINT IF EXISTS comments_user_id_fkey;
ALTER TABLE comments DROP CONSTRAINT IF EXISTS comments_parent_id_fkey;

ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_board_id_fkey;
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_category_id_fkey;
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_user_id_fkey;
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_deleted_by_fkey;
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_last_edited_by_fkey;
ALTER TABLE posts DROP CONSTRAINT IF EXISTS posts_moderated_by_fkey;

ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_board_id_fkey;

ALTER TABLE drafts DROP CONSTRAINT IF EXISTS drafts_board_id_fkey;
ALTER TABLE drafts DROP CONSTRAINT IF EXISTS drafts_category_id_fkey;
ALTER TABLE drafts DROP CONSTRAINT IF EXISTS drafts_user_id_fkey;

ALTER TABLE likes DROP CONSTRAINT IF EXISTS likes_user_id_fkey;

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;

ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_reporter_id_fkey;
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_resolved_by_fkey;

ALTER TABLE file_entities DROP CONSTRAINT IF EXISTS file_entities_file_id_fkey;
ALTER TABLE files DROP CONSTRAINT IF EXISTS files_user_id_fkey;

ALTER TABLE image_sizes DROP CONSTRAINT IF EXISTS image_sizes_file_id_fkey;

ALTER TABLE calendar_events DROP CONSTRAINT IF EXISTS calendar_events_user_id_fkey;

ALTER TABLE point_transactions DROP CONSTRAINT IF EXISTS point_transactions_user_id_fkey;

ALTER TABLE menus DROP CONSTRAINT IF EXISTS menus_parent_id_fkey;

ALTER TABLE refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_user_id_fkey;

ALTER TABLE user_social_accounts DROP CONSTRAINT IF EXISTS user_social_accounts_user_id_fkey;

ALTER TABLE pages DROP CONSTRAINT IF EXISTS pages_created_by_fkey;
ALTER TABLE pages DROP CONSTRAINT IF EXISTS pages_updated_by_fkey;

ALTER TABLE token_blacklist DROP CONSTRAINT IF EXISTS token_blacklist_user_id_fkey;

ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS role_permissions_role_id_fkey;
ALTER TABLE role_permissions DROP CONSTRAINT IF EXISTS role_permissions_permission_id_fkey;

ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_role_id_fkey;

-- 1. users 테이블 변경 (가장 중요한 기준 테이블)
-- 임시 컬럼 추가
ALTER TABLE users ADD COLUMN new_id SERIAL;

-- 2. boards 테이블 변경
ALTER TABLE boards ADD COLUMN new_id SERIAL;

-- 3. categories 테이블 변경
ALTER TABLE categories ADD COLUMN new_id SERIAL;
ALTER TABLE categories ADD COLUMN new_board_id INTEGER;

-- 4. posts 테이블 변경
ALTER TABLE posts ADD COLUMN new_id SERIAL;
ALTER TABLE posts ADD COLUMN new_board_id INTEGER;
ALTER TABLE posts ADD COLUMN new_category_id INTEGER;
ALTER TABLE posts ADD COLUMN new_user_id INTEGER;
ALTER TABLE posts ADD COLUMN new_deleted_by INTEGER;
ALTER TABLE posts ADD COLUMN new_last_edited_by INTEGER;
ALTER TABLE posts ADD COLUMN new_moderated_by INTEGER;

-- 5. comments 테이블 변경
ALTER TABLE comments ADD COLUMN new_id SERIAL;
ALTER TABLE comments ADD COLUMN new_post_id INTEGER;
ALTER TABLE comments ADD COLUMN new_user_id INTEGER;
ALTER TABLE comments ADD COLUMN new_parent_id INTEGER;

-- 6. files 테이블 변경
ALTER TABLE files ADD COLUMN new_id SERIAL;
ALTER TABLE files ADD COLUMN new_user_id INTEGER;

-- 7. 다른 테이블들도 동일하게 처리
ALTER TABLE drafts ADD COLUMN new_id SERIAL;
ALTER TABLE drafts ADD COLUMN new_user_id INTEGER;
ALTER TABLE drafts ADD COLUMN new_board_id INTEGER;
ALTER TABLE drafts ADD COLUMN new_category_id INTEGER;

ALTER TABLE likes ADD COLUMN new_id SERIAL;
ALTER TABLE likes ADD COLUMN new_user_id INTEGER;

ALTER TABLE notifications ADD COLUMN new_id SERIAL;
ALTER TABLE notifications ADD COLUMN new_user_id INTEGER;

ALTER TABLE reports ADD COLUMN new_id SERIAL;
ALTER TABLE reports ADD COLUMN new_reporter_id INTEGER;
ALTER TABLE reports ADD COLUMN new_resolved_by INTEGER;

ALTER TABLE file_entities ADD COLUMN new_id SERIAL;
ALTER TABLE file_entities ADD COLUMN new_file_id INTEGER;

ALTER TABLE image_sizes ADD COLUMN new_id SERIAL;
ALTER TABLE image_sizes ADD COLUMN new_file_id INTEGER;

ALTER TABLE calendar_events ADD COLUMN new_id SERIAL;
ALTER TABLE calendar_events ADD COLUMN new_user_id INTEGER;

ALTER TABLE point_transactions ADD COLUMN new_id SERIAL;
ALTER TABLE point_transactions ADD COLUMN new_user_id INTEGER;

ALTER TABLE menus ADD COLUMN new_id SERIAL;
ALTER TABLE menus ADD COLUMN new_parent_id INTEGER;

ALTER TABLE refresh_tokens ADD COLUMN new_id SERIAL;
ALTER TABLE refresh_tokens ADD COLUMN new_user_id INTEGER;

ALTER TABLE user_social_accounts ADD COLUMN new_id SERIAL;
ALTER TABLE user_social_accounts ADD COLUMN new_user_id INTEGER;

ALTER TABLE pages ADD COLUMN new_id SERIAL;
ALTER TABLE pages ADD COLUMN new_created_by INTEGER;
ALTER TABLE pages ADD COLUMN new_updated_by INTEGER;

ALTER TABLE token_blacklist ADD COLUMN new_id SERIAL;
ALTER TABLE token_blacklist ADD COLUMN new_user_id INTEGER;

ALTER TABLE roles ADD COLUMN new_id SERIAL;
ALTER TABLE permissions ADD COLUMN new_id SERIAL;

ALTER TABLE role_permissions ADD COLUMN new_id SERIAL;
ALTER TABLE role_permissions ADD COLUMN new_role_id INTEGER;
ALTER TABLE role_permissions ADD COLUMN new_permission_id INTEGER;

ALTER TABLE user_roles ADD COLUMN new_id SERIAL;
ALTER TABLE user_roles ADD COLUMN new_user_id INTEGER;
ALTER TABLE user_roles ADD COLUMN new_role_id INTEGER;

ALTER TABLE faqs ADD COLUMN new_id SERIAL;
ALTER TABLE galleries ADD COLUMN new_id SERIAL;
ALTER TABLE hero_sections ADD COLUMN new_id SERIAL;
ALTER TABLE organization_info ADD COLUMN new_id SERIAL;
ALTER TABLE site_info ADD COLUMN new_id SERIAL;
ALTER TABLE site_settings ADD COLUMN new_id SERIAL;
ALTER TABLE sns_links ADD COLUMN new_id SERIAL;

-- 이제 관계 데이터를 새로운 ID로 매핑
-- categories의 board_id 매핑
UPDATE categories SET new_board_id = (
    SELECT boards.new_id FROM boards WHERE boards.id = categories.board_id
);

-- posts의 외래키 매핑
UPDATE posts SET 
    new_board_id = (SELECT boards.new_id FROM boards WHERE boards.id = posts.board_id),
    new_category_id = (SELECT categories.new_id FROM categories WHERE categories.id = posts.category_id),
    new_user_id = (SELECT users.new_id FROM users WHERE users.id = posts.user_id),
    new_deleted_by = (SELECT users.new_id FROM users WHERE users.id = posts.deleted_by),
    new_last_edited_by = (SELECT users.new_id FROM users WHERE users.id = posts.last_edited_by),
    new_moderated_by = (SELECT users.new_id FROM users WHERE users.id = posts.moderated_by);

-- comments의 외래키 매핑
UPDATE comments SET 
    new_post_id = (SELECT posts.new_id FROM posts WHERE posts.id = comments.post_id),
    new_user_id = (SELECT users.new_id FROM users WHERE users.id = comments.user_id);

-- comments의 parent_id 매핑 (자기 참조)
UPDATE comments SET new_parent_id = (
    SELECT c2.new_id FROM comments c2 WHERE c2.id = comments.parent_id
);

-- files의 외래키 매핑
UPDATE files SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = files.user_id
);

-- 다른 테이블들도 동일하게 매핑
UPDATE drafts SET 
    new_user_id = (SELECT users.new_id FROM users WHERE users.id = drafts.user_id),
    new_board_id = (SELECT boards.new_id FROM boards WHERE boards.id = drafts.board_id),
    new_category_id = (SELECT categories.new_id FROM categories WHERE categories.id = drafts.category_id);

UPDATE likes SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = likes.user_id
);

UPDATE notifications SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = notifications.user_id
);

UPDATE reports SET 
    new_reporter_id = (SELECT users.new_id FROM users WHERE users.id = reports.reporter_id),
    new_resolved_by = (SELECT users.new_id FROM users WHERE users.id = reports.resolved_by);

UPDATE file_entities SET new_file_id = (
    SELECT files.new_id FROM files WHERE files.id = file_entities.file_id
);

UPDATE image_sizes SET new_file_id = (
    SELECT files.new_id FROM files WHERE files.id = image_sizes.file_id
);

UPDATE calendar_events SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = calendar_events.user_id
);

UPDATE point_transactions SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = point_transactions.user_id
);

UPDATE menus SET new_parent_id = (
    SELECT m2.new_id FROM menus m2 WHERE m2.id = menus.parent_id
);

UPDATE refresh_tokens SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = refresh_tokens.user_id
);

UPDATE user_social_accounts SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = user_social_accounts.user_id
);

UPDATE pages SET 
    new_created_by = (SELECT users.new_id FROM users WHERE users.id = pages.created_by),
    new_updated_by = (SELECT users.new_id FROM users WHERE users.id = pages.updated_by);

UPDATE token_blacklist SET new_user_id = (
    SELECT users.new_id FROM users WHERE users.id = token_blacklist.user_id
);

UPDATE role_permissions SET 
    new_role_id = (SELECT roles.new_id FROM roles WHERE roles.id = role_permissions.role_id),
    new_permission_id = (SELECT permissions.new_id FROM permissions WHERE permissions.id = role_permissions.permission_id);

UPDATE user_roles SET 
    new_user_id = (SELECT users.new_id FROM users WHERE users.id = user_roles.user_id),
    new_role_id = (SELECT roles.new_id FROM roles WHERE roles.id = user_roles.role_id);

-- 이제 기존 컬럼들을 삭제하고 새 컬럼으로 교체

-- users 테이블
ALTER TABLE users DROP COLUMN id CASCADE;
ALTER TABLE users RENAME COLUMN new_id TO id;
ALTER TABLE users ADD PRIMARY KEY (id);

-- boards 테이블
ALTER TABLE boards DROP COLUMN id CASCADE;
ALTER TABLE boards RENAME COLUMN new_id TO id;
ALTER TABLE boards ADD PRIMARY KEY (id);

-- categories 테이블
ALTER TABLE categories DROP COLUMN id CASCADE;
ALTER TABLE categories RENAME COLUMN new_id TO id;
ALTER TABLE categories DROP COLUMN board_id;
ALTER TABLE categories RENAME COLUMN new_board_id TO board_id;
ALTER TABLE categories ADD PRIMARY KEY (id);

-- posts 테이블
ALTER TABLE posts DROP COLUMN id CASCADE;
ALTER TABLE posts RENAME COLUMN new_id TO id;
ALTER TABLE posts DROP COLUMN board_id;
ALTER TABLE posts RENAME COLUMN new_board_id TO board_id;
ALTER TABLE posts DROP COLUMN category_id;
ALTER TABLE posts RENAME COLUMN new_category_id TO category_id;
ALTER TABLE posts DROP COLUMN user_id;
ALTER TABLE posts RENAME COLUMN new_user_id TO user_id;
ALTER TABLE posts DROP COLUMN deleted_by;
ALTER TABLE posts RENAME COLUMN new_deleted_by TO deleted_by;
ALTER TABLE posts DROP COLUMN last_edited_by;
ALTER TABLE posts RENAME COLUMN new_last_edited_by TO last_edited_by;
ALTER TABLE posts DROP COLUMN moderated_by;
ALTER TABLE posts RENAME COLUMN new_moderated_by TO moderated_by;
ALTER TABLE posts ADD PRIMARY KEY (id);

-- comments 테이블
ALTER TABLE comments DROP COLUMN id CASCADE;
ALTER TABLE comments RENAME COLUMN new_id TO id;
ALTER TABLE comments DROP COLUMN post_id;
ALTER TABLE comments RENAME COLUMN new_post_id TO post_id;
ALTER TABLE comments DROP COLUMN user_id;
ALTER TABLE comments RENAME COLUMN new_user_id TO user_id;
ALTER TABLE comments DROP COLUMN parent_id;
ALTER TABLE comments RENAME COLUMN new_parent_id TO parent_id;
ALTER TABLE comments ADD PRIMARY KEY (id);

-- files 테이블
ALTER TABLE files DROP COLUMN id CASCADE;
ALTER TABLE files RENAME COLUMN new_id TO id;
ALTER TABLE files DROP COLUMN user_id;
ALTER TABLE files RENAME COLUMN new_user_id TO user_id;
ALTER TABLE files ADD PRIMARY KEY (id);

-- 나머지 테이블들도 동일하게 처리
ALTER TABLE drafts DROP COLUMN id CASCADE;
ALTER TABLE drafts RENAME COLUMN new_id TO id;
ALTER TABLE drafts DROP COLUMN user_id;
ALTER TABLE drafts RENAME COLUMN new_user_id TO user_id;
ALTER TABLE drafts DROP COLUMN board_id;
ALTER TABLE drafts RENAME COLUMN new_board_id TO board_id;
ALTER TABLE drafts DROP COLUMN category_id;
ALTER TABLE drafts RENAME COLUMN new_category_id TO category_id;
ALTER TABLE drafts ADD PRIMARY KEY (id);

ALTER TABLE likes DROP COLUMN id CASCADE;
ALTER TABLE likes RENAME COLUMN new_id TO id;
ALTER TABLE likes DROP COLUMN user_id;
ALTER TABLE likes RENAME COLUMN new_user_id TO user_id;
ALTER TABLE likes ADD PRIMARY KEY (id);

ALTER TABLE notifications DROP COLUMN id CASCADE;
ALTER TABLE notifications RENAME COLUMN new_id TO id;
ALTER TABLE notifications DROP COLUMN user_id;
ALTER TABLE notifications RENAME COLUMN new_user_id TO user_id;
ALTER TABLE notifications ADD PRIMARY KEY (id);

ALTER TABLE reports DROP COLUMN id CASCADE;
ALTER TABLE reports RENAME COLUMN new_id TO id;
ALTER TABLE reports DROP COLUMN reporter_id;
ALTER TABLE reports RENAME COLUMN new_reporter_id TO reporter_id;
ALTER TABLE reports DROP COLUMN resolved_by;
ALTER TABLE reports RENAME COLUMN new_resolved_by TO resolved_by;
ALTER TABLE reports ADD PRIMARY KEY (id);

ALTER TABLE file_entities DROP COLUMN id CASCADE;
ALTER TABLE file_entities RENAME COLUMN new_id TO id;
ALTER TABLE file_entities DROP COLUMN file_id;
ALTER TABLE file_entities RENAME COLUMN new_file_id TO file_id;
ALTER TABLE file_entities ADD PRIMARY KEY (id);

ALTER TABLE image_sizes DROP COLUMN id CASCADE;
ALTER TABLE image_sizes RENAME COLUMN new_id TO id;
ALTER TABLE image_sizes DROP COLUMN file_id;
ALTER TABLE image_sizes RENAME COLUMN new_file_id TO file_id;
ALTER TABLE image_sizes ADD PRIMARY KEY (id);

ALTER TABLE calendar_events DROP COLUMN id CASCADE;
ALTER TABLE calendar_events RENAME COLUMN new_id TO id;
ALTER TABLE calendar_events DROP COLUMN user_id;
ALTER TABLE calendar_events RENAME COLUMN new_user_id TO user_id;
ALTER TABLE calendar_events ADD PRIMARY KEY (id);

ALTER TABLE point_transactions DROP COLUMN id CASCADE;
ALTER TABLE point_transactions RENAME COLUMN new_id TO id;
ALTER TABLE point_transactions DROP COLUMN user_id;
ALTER TABLE point_transactions RENAME COLUMN new_user_id TO user_id;
ALTER TABLE point_transactions ADD PRIMARY KEY (id);

ALTER TABLE menus DROP COLUMN id CASCADE;
ALTER TABLE menus RENAME COLUMN new_id TO id;
ALTER TABLE menus DROP COLUMN parent_id;
ALTER TABLE menus RENAME COLUMN new_parent_id TO parent_id;
ALTER TABLE menus ADD PRIMARY KEY (id);

ALTER TABLE refresh_tokens DROP COLUMN id CASCADE;
ALTER TABLE refresh_tokens RENAME COLUMN new_id TO id;
ALTER TABLE refresh_tokens DROP COLUMN user_id;
ALTER TABLE refresh_tokens RENAME COLUMN new_user_id TO user_id;
ALTER TABLE refresh_tokens ADD PRIMARY KEY (id);

ALTER TABLE user_social_accounts DROP COLUMN id CASCADE;
ALTER TABLE user_social_accounts RENAME COLUMN new_id TO id;
ALTER TABLE user_social_accounts DROP COLUMN user_id;
ALTER TABLE user_social_accounts RENAME COLUMN new_user_id TO user_id;
ALTER TABLE user_social_accounts ADD PRIMARY KEY (id);

ALTER TABLE pages DROP COLUMN id CASCADE;
ALTER TABLE pages RENAME COLUMN new_id TO id;
ALTER TABLE pages DROP COLUMN created_by;
ALTER TABLE pages RENAME COLUMN new_created_by TO created_by;
ALTER TABLE pages DROP COLUMN updated_by;
ALTER TABLE pages RENAME COLUMN new_updated_by TO updated_by;
ALTER TABLE pages ADD PRIMARY KEY (id);

ALTER TABLE token_blacklist DROP COLUMN id CASCADE;
ALTER TABLE token_blacklist RENAME COLUMN new_id TO id;
ALTER TABLE token_blacklist DROP COLUMN user_id;
ALTER TABLE token_blacklist RENAME COLUMN new_user_id TO user_id;
ALTER TABLE token_blacklist ADD PRIMARY KEY (id);

ALTER TABLE roles DROP COLUMN id CASCADE;
ALTER TABLE roles RENAME COLUMN new_id TO id;
ALTER TABLE roles ADD PRIMARY KEY (id);

ALTER TABLE permissions DROP COLUMN id CASCADE;
ALTER TABLE permissions RENAME COLUMN new_id TO id;
ALTER TABLE permissions ADD PRIMARY KEY (id);

ALTER TABLE role_permissions DROP COLUMN id CASCADE;
ALTER TABLE role_permissions RENAME COLUMN new_id TO id;
ALTER TABLE role_permissions DROP COLUMN role_id;
ALTER TABLE role_permissions RENAME COLUMN new_role_id TO role_id;
ALTER TABLE role_permissions DROP COLUMN permission_id;
ALTER TABLE role_permissions RENAME COLUMN new_permission_id TO permission_id;
ALTER TABLE role_permissions ADD PRIMARY KEY (id);

ALTER TABLE user_roles DROP COLUMN id CASCADE;
ALTER TABLE user_roles RENAME COLUMN new_id TO id;
ALTER TABLE user_roles DROP COLUMN user_id;
ALTER TABLE user_roles RENAME COLUMN new_user_id TO user_id;
ALTER TABLE user_roles DROP COLUMN role_id;
ALTER TABLE user_roles RENAME COLUMN new_role_id TO role_id;
ALTER TABLE user_roles ADD PRIMARY KEY (id);

ALTER TABLE faqs DROP COLUMN id CASCADE;
ALTER TABLE faqs RENAME COLUMN new_id TO id;
ALTER TABLE faqs ADD PRIMARY KEY (id);

ALTER TABLE galleries DROP COLUMN id CASCADE;
ALTER TABLE galleries RENAME COLUMN new_id TO id;
ALTER TABLE galleries ADD PRIMARY KEY (id);

ALTER TABLE hero_sections DROP COLUMN id CASCADE;
ALTER TABLE hero_sections RENAME COLUMN new_id TO id;
ALTER TABLE hero_sections ADD PRIMARY KEY (id);

ALTER TABLE organization_info DROP COLUMN id CASCADE;
ALTER TABLE organization_info RENAME COLUMN new_id TO id;
ALTER TABLE organization_info ADD PRIMARY KEY (id);

ALTER TABLE site_info DROP COLUMN id CASCADE;
ALTER TABLE site_info RENAME COLUMN new_id TO id;
ALTER TABLE site_info ADD PRIMARY KEY (id);

ALTER TABLE site_settings DROP COLUMN id CASCADE;
ALTER TABLE site_settings RENAME COLUMN new_id TO id;
ALTER TABLE site_settings ADD PRIMARY KEY (id);

ALTER TABLE sns_links DROP COLUMN id CASCADE;
ALTER TABLE sns_links RENAME COLUMN new_id TO id;
ALTER TABLE sns_links ADD PRIMARY KEY (id);

-- 외래키 제약조건 다시 추가
ALTER TABLE categories ADD CONSTRAINT categories_board_id_fkey 
    FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE;

ALTER TABLE posts ADD CONSTRAINT posts_board_id_fkey 
    FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE;
ALTER TABLE posts ADD CONSTRAINT posts_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE posts ADD CONSTRAINT posts_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE posts ADD CONSTRAINT posts_deleted_by_fkey 
    FOREIGN KEY (deleted_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE posts ADD CONSTRAINT posts_last_edited_by_fkey 
    FOREIGN KEY (last_edited_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE posts ADD CONSTRAINT posts_moderated_by_fkey 
    FOREIGN KEY (moderated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE comments ADD CONSTRAINT comments_post_id_fkey 
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;
ALTER TABLE comments ADD CONSTRAINT comments_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE comments ADD CONSTRAINT comments_parent_id_fkey 
    FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE;

ALTER TABLE files ADD CONSTRAINT files_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE drafts ADD CONSTRAINT drafts_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE drafts ADD CONSTRAINT drafts_board_id_fkey 
    FOREIGN KEY (board_id) REFERENCES boards(id) ON DELETE CASCADE;
ALTER TABLE drafts ADD CONSTRAINT drafts_category_id_fkey 
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL;

ALTER TABLE likes ADD CONSTRAINT likes_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE reports ADD CONSTRAINT reports_reporter_id_fkey 
    FOREIGN KEY (reporter_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE reports ADD CONSTRAINT reports_resolved_by_fkey 
    FOREIGN KEY (resolved_by) REFERENCES users(id);

ALTER TABLE file_entities ADD CONSTRAINT file_entities_file_id_fkey 
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE;

ALTER TABLE image_sizes ADD CONSTRAINT image_sizes_file_id_fkey 
    FOREIGN KEY (file_id) REFERENCES files(id) ON DELETE CASCADE;

ALTER TABLE calendar_events ADD CONSTRAINT calendar_events_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE point_transactions ADD CONSTRAINT point_transactions_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE menus ADD CONSTRAINT menus_parent_id_fkey 
    FOREIGN KEY (parent_id) REFERENCES menus(id) ON DELETE CASCADE;

ALTER TABLE refresh_tokens ADD CONSTRAINT refresh_tokens_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_social_accounts ADD CONSTRAINT user_social_accounts_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE pages ADD CONSTRAINT pages_created_by_fkey 
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE pages ADD CONSTRAINT pages_updated_by_fkey 
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE token_blacklist ADD CONSTRAINT token_blacklist_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE role_permissions ADD CONSTRAINT role_permissions_role_id_fkey 
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;
ALTER TABLE role_permissions ADD CONSTRAINT role_permissions_permission_id_fkey 
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;

ALTER TABLE user_roles ADD CONSTRAINT user_roles_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_id_fkey 
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;

-- 필요한 인덱스들 다시 생성
CREATE INDEX IF NOT EXISTS idx_posts_board_id ON posts(board_id);
CREATE INDEX IF NOT EXISTS idx_posts_category_id ON posts(category_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_board_id ON categories(board_id);

-- entity_id도 정수 타입으로 변경해야 하는데, 이는 복잡하므로 별도로 처리
-- 우선 주요 테이블들만 변경 완료

-- 댓글 숨김 이력 테이블 생성 (게시글용은 이미 post_hide_history가 있음)
CREATE TABLE IF NOT EXISTS comment_hide_history (
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL,
    hide_reason TEXT,
    hide_category VARCHAR(50) NOT NULL CHECK (hide_category IN ('광고', '음란물', '욕설비방', '기타 정책위반', 'inappropriate', 'spam', 'duplicate', 'violation', 'other', 'quick_hide')),
    hide_tags TEXT[],
    hidden_by INTEGER NOT NULL,
    hidden_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    hide_location VARCHAR(20) NOT NULL DEFAULT 'admin' CHECK (hide_location IN ('site', 'admin')),
    is_hidden BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT comment_hide_history_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    CONSTRAINT comment_hide_history_hidden_by_fkey FOREIGN KEY (hidden_by) REFERENCES users(id) ON DELETE CASCADE
);

-- comments 테이블에 is_deleted 컬럼이 없다면 추가
ALTER TABLE comments ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE comments ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE comments ADD COLUMN IF NOT EXISTS deleted_by INTEGER;

-- comments 테이블에 삭제 관련 외래키 추가
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'comments_deleted_by_fkey'
    ) THEN
        ALTER TABLE comments ADD CONSTRAINT comments_deleted_by_fkey 
            FOREIGN KEY (deleted_by) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_comment_hide_history_comment_id ON comment_hide_history(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_hide_history_hidden_at ON comment_hide_history(hidden_at);
CREATE INDEX IF NOT EXISTS idx_comment_hide_history_is_hidden ON comment_hide_history(is_hidden);
CREATE INDEX IF NOT EXISTS idx_comments_is_deleted ON comments(is_deleted);

-- 함수들도 정수 타입에 맞게 수정
DROP FUNCTION IF EXISTS increment_page_view_count(uuid);
CREATE OR REPLACE FUNCTION increment_page_view_count(page_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pages 
    SET view_count = view_count + 1 
    WHERE id = page_id;
END;
$$;

DROP FUNCTION IF EXISTS restore_post(uuid, uuid);
CREATE OR REPLACE FUNCTION restore_post(post_id integer, restored_by_user_id integer) RETURNS void
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

DROP FUNCTION IF EXISTS soft_delete_post(uuid, uuid);
CREATE OR REPLACE FUNCTION soft_delete_post(post_id integer, deleted_by_user_id integer) RETURNS void
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
