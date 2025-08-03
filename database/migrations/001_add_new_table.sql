-- 마이그레이션: 001_add_new_table.sql
-- 설명: 새로운 테이블 추가
-- 날짜: 2025-08-03

-- 새로운 테이블 생성
CREATE TABLE IF NOT EXISTS new_feature (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_new_feature_name ON new_feature(name);

-- 댓글 추가
COMMENT ON TABLE new_feature IS '새로운 기능 테이블';
COMMENT ON COLUMN new_feature.name IS '기능 이름';
COMMENT ON COLUMN new_feature.description IS '기능 설명'; 