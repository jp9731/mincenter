-- posts 테이블 id 컬럼에 기본값 설정
ALTER TABLE posts ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 확인
\d posts;