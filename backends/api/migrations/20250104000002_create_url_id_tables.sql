-- URL ID 매핑 테이블들 생성
-- 각 주요 테이블마다 UUID <-> URL ID 매핑을 위한 테이블

-- 게시글 URL ID 매핑 테이블
CREATE TABLE posts_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT posts_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES posts(id) ON DELETE CASCADE
);

-- 댓글 URL ID 매핑 테이블
CREATE TABLE comments_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT comments_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES comments(id) ON DELETE CASCADE
);

-- 사용자 URL ID 매핑 테이블
CREATE TABLE users_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT users_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES users(id) ON DELETE CASCADE
);

-- 게시판 URL ID 매핑 테이블
CREATE TABLE boards_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT boards_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES boards(id) ON DELETE CASCADE
);

-- 카테고리 URL ID 매핑 테이블
CREATE TABLE categories_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT categories_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES categories(id) ON DELETE CASCADE
);

-- 페이지 URL ID 매핑 테이블
CREATE TABLE pages_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT pages_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES pages(id) ON DELETE CASCADE
);

-- 파일 URL ID 매핑 테이블
CREATE TABLE files_url_ids (
    id SERIAL PRIMARY KEY,
    uuid UUID NOT NULL UNIQUE,
    sequence_num INTEGER NOT NULL UNIQUE,
    hash VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT files_url_ids_uuid_fkey FOREIGN KEY (uuid) REFERENCES files(id) ON DELETE CASCADE
);

-- 인덱스 생성 (성능 최적화)
CREATE INDEX idx_posts_url_ids_sequence_hash ON posts_url_ids(sequence_num, hash);
CREATE INDEX idx_posts_url_ids_uuid ON posts_url_ids(uuid);

CREATE INDEX idx_comments_url_ids_sequence_hash ON comments_url_ids(sequence_num, hash);
CREATE INDEX idx_comments_url_ids_uuid ON comments_url_ids(uuid);

CREATE INDEX idx_users_url_ids_sequence_hash ON users_url_ids(sequence_num, hash);
CREATE INDEX idx_users_url_ids_uuid ON users_url_ids(uuid);

CREATE INDEX idx_boards_url_ids_sequence_hash ON boards_url_ids(sequence_num, hash);
CREATE INDEX idx_boards_url_ids_uuid ON boards_url_ids(uuid);

CREATE INDEX idx_categories_url_ids_sequence_hash ON categories_url_ids(sequence_num, hash);
CREATE INDEX idx_categories_url_ids_uuid ON categories_url_ids(uuid);

CREATE INDEX idx_pages_url_ids_sequence_hash ON pages_url_ids(sequence_num, hash);
CREATE INDEX idx_pages_url_ids_uuid ON pages_url_ids(uuid);

CREATE INDEX idx_files_url_ids_sequence_hash ON files_url_ids(sequence_num, hash);
CREATE INDEX idx_files_url_ids_uuid ON files_url_ids(uuid);

-- 기존 데이터를 위한 URL ID 생성 함수
CREATE OR REPLACE FUNCTION generate_url_ids_for_existing_data() RETURNS VOID AS $$
DECLARE
    rec RECORD;
    hash_val VARCHAR(10);
    seq_num INTEGER;
BEGIN
    -- 게시글용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM posts WHERE NOT is_deleted ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO posts_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    -- 댓글용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM comments ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO comments_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    -- 사용자용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM users ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO users_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    -- 게시판용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM boards ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO boards_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    -- 카테고리용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM categories ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO categories_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    -- 페이지용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM pages ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO pages_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    -- 파일용 URL ID 생성
    seq_num := 1;
    FOR rec IN SELECT id FROM files ORDER BY created_at LOOP
        hash_val := substring(encode(sha256(rec.id::text::bytea), 'base64'), 1, 6);
        INSERT INTO files_url_ids (uuid, sequence_num, hash) 
        VALUES (rec.id, seq_num, hash_val);
        seq_num := seq_num + 1;
    END LOOP;
    
    RAISE NOTICE 'URL ID 생성 완료';
END;
$$ LANGUAGE plpgsql;

-- 기존 데이터에 대한 URL ID 생성 실행
SELECT generate_url_ids_for_existing_data();

-- 함수 삭제 (일회성이므로)
DROP FUNCTION generate_url_ids_for_existing_data();
