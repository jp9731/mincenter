-- refresh_tokens 테이블에 is_revoked 컬럼 추가
-- 실행일: 2025-01-08

-- 컬럼 추가
ALTER TABLE public.refresh_tokens 
ADD COLUMN is_revoked boolean DEFAULT false;

-- 기존 데이터에 대해 is_revoked를 false로 설정
UPDATE public.refresh_tokens 
SET is_revoked = false 
WHERE is_revoked IS NULL;

-- 컬럼을 NOT NULL로 설정
ALTER TABLE public.refresh_tokens 
ALTER COLUMN is_revoked SET NOT NULL;

-- 인덱스 추가 (선택사항)
CREATE INDEX idx_refresh_tokens_is_revoked ON public.refresh_tokens USING btree (is_revoked); 