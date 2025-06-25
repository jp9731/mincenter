-- 한국어 텍스트 검색 설정
-- PostgreSQL에서 한국어 전문 검색을 위한 설정

-- 한국어 텍스트 검색 설정이 없으면 생성
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_ts_config WHERE cfgname = 'korean') THEN
        -- 한국어 텍스트 검색 설정 생성 (simple 설정을 기반으로)
        CREATE TEXT SEARCH CONFIGURATION korean (COPY = simple);
        
        -- 한국어 특화 설정 (기본적으로는 simple과 동일하지만 확장 가능)
        -- 필요시 한국어 형태소 분석기나 사전을 추가할 수 있음
    END IF;
END $$;

-- 한국어 텍스트 검색 설정 확인
SELECT cfgname, cfgparser FROM pg_ts_config WHERE cfgname = 'korean'; 