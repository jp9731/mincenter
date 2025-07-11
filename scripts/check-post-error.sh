#!/bin/bash

# 글쓰기 에러 체크 스크립트
echo "=== 글쓰기 에러 체크 ==="

# 1. 현재 실행 중인 API 프로세스 확인
echo "1. API 프로세스 확인..."
ps aux | grep mincenter-api | grep -v grep

# 2. 로그에서 글쓰기 관련 에러 확인
echo "2. 최근 글쓰기 에러 로그..."
if [ -f "logs/api.log" ]; then
    echo "--- 최근 500 에러 ---"
    tail -50 logs/api.log | grep -E "(ERROR|error|fail|500|📝|❌)"
else
    echo "--- api.log 파일 없음, 다른 로그 확인 ---"
    tail -50 api.log | grep -E "(ERROR|error|fail|500|📝|❌)" || echo "에러 로그 없음"
fi

# 3. 데이터베이스 연결 확인
echo "3. 데이터베이스 연결 확인..."
if command -v psql &> /dev/null; then
    echo "--- 게시판 테이블 확인 ---"
    psql "postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter" -c "SELECT id, name, slug FROM boards WHERE slug = 'notice';" 2>/dev/null || echo "DB 연결 실패"
else
    echo "psql 명령어 없음"
fi

# 4. API 테스트
echo "4. API 테스트..."
echo "--- Health Check ---"
curl -s -w "HTTP %{http_code}\n" http://localhost:18080/api/health

echo "--- 게시판 조회 ---"
curl -s -w "HTTP %{http_code}\n" http://localhost:18080/api/community/boards/notice

echo "=== 체크 완료 ==="