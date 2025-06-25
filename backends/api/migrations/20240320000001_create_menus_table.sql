-- Create menu_type enum (IF NOT EXISTS)
DO $$ BEGIN
    CREATE TYPE menu_type AS ENUM ('page', 'board', 'url');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create menus table (IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS menus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    menu_type menu_type NOT NULL,
    target_id UUID, -- 페이지 ID 또는 게시판 ID
    url TEXT, -- 외부 링크 URL
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    parent_id UUID REFERENCES menus(id) ON DELETE CASCADE, -- 2단 메뉴인 경우 1단 메뉴 ID
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for better performance (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_menus_parent_id ON menus(parent_id);
CREATE INDEX IF NOT EXISTS idx_menus_display_order ON menus(display_order);
CREATE INDEX IF NOT EXISTS idx_menus_is_active ON menus(is_active);

-- Create trigger to update updated_at (IF NOT EXISTS)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$ BEGIN
    CREATE TRIGGER update_menus_updated_at BEFORE UPDATE ON menus
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Insert sample menu data (IF NOT EXISTS)
INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '회사안내', '회사 소개 및 안내', 'page', NULL, '/about', 1, true, NULL
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '회사안내');

INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '봉사활동', '봉사 활동 관련', 'board', NULL, '/volunteer', 2, true, NULL
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '봉사활동');

INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '후원하기', '후원 관련 정보', 'page', NULL, '/donate', 3, true, NULL
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '후원하기');

INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '커뮤니티', '커뮤니티 게시판', 'board', NULL, '/community', 4, true, NULL
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '커뮤니티');

INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '공지사항', '공지사항 게시판', 'board', NULL, '/notice', 1, true, (SELECT id FROM menus WHERE name = '커뮤니티')
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '공지사항');

INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '자유게시판', '자유게시판', 'board', NULL, '/free', 2, true, (SELECT id FROM menus WHERE name = '커뮤니티')
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '자유게시판');

INSERT INTO menus (name, description, menu_type, target_id, url, display_order, is_active, parent_id) 
SELECT '질문과 답변', 'Q&A 게시판', 'board', NULL, '/qna', 3, true, (SELECT id FROM menus WHERE name = '커뮤니티')
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name = '질문과 답변'); 