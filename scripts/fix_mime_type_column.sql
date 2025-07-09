-- files 테이블의 mime_type 컬럼 수정
-- 실행일: 2025-01-08

-- NULL인 mime_type을 기본값으로 설정
UPDATE public.files 
SET mime_type = 'application/octet-stream' 
WHERE mime_type IS NULL;

-- 컬럼을 NOT NULL로 설정
ALTER TABLE public.files 
ALTER COLUMN mime_type SET NOT NULL;

-- 기본값 설정
ALTER TABLE public.files 
ALTER COLUMN mime_type SET DEFAULT 'application/octet-stream'; 