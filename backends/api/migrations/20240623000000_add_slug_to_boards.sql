ALTER TABLE boards ADD COLUMN slug VARCHAR(100) NOT NULL DEFAULT '';

-- 기존 데이터에 slug 채우기 (name을 소문자, 한글/특수문자 -로 치환)
UPDATE boards SET slug = lower(regexp_replace(name, '[^a-zA-Z0-9]+', '-', 'g'));

-- slug NOT NULL, UNIQUE 제약
ALTER TABLE boards ALTER COLUMN slug DROP DEFAULT;
ALTER TABLE boards ADD CONSTRAINT boards_slug_unique UNIQUE (slug); 