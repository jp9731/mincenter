-- users 테이블 id 컬럼에 기본값 설정
ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 확인
\d users;