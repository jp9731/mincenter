-- refresh_tokens 테이블 id 컬럼에 기본값 설정
ALTER TABLE refresh_tokens ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- is_revoked 컬럼 추가 (없는 경우)
ALTER TABLE refresh_tokens ADD COLUMN IF NOT EXISTS is_revoked boolean DEFAULT false;

-- 확인
\d refresh_tokens;