-- posts 테이블의 content 컬럼 수정
-- 실행일: 2025-01-08

-- NULL인 content를 기본값으로 설정
UPDATE public.posts 
SET content = '' 
WHERE content IS NULL;

-- 컬럼을 NOT NULL로 설정
ALTER TABLE public.posts 
ALTER COLUMN content SET NOT NULL;

-- 기본값 설정
ALTER TABLE public.posts 
ALTER COLUMN content SET DEFAULT ''; 