#!/bin/bash

# API 서버의 CORS 설정 확인

set -e

echo "🔍 API 서버 CORS 설정 확인..."

SERVER_HOST="admin@mincenter.kr"

echo "🌐 API 서버 CORS 테스트..."
# 직접 CORS 헤더 확인
curl -H "Origin: https://admin.mincenter.kr" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://api.mincenter.kr/api/admin/login \
     -v 2>&1 | grep -i "access-control\|cors\|origin" || echo "CORS 헤더 없음"

echo ""
echo "📊 API 컨테이너 환경변수 확인..."
ssh $SERVER_HOST << 'EOF'
  echo "CORS_ORIGIN 환경변수:"
  docker exec mincenter-api env | grep CORS || echo "CORS 환경변수 없음"
  
  echo ""
  echo "API 컨테이너 로그에서 CORS 관련 내용:"
  docker logs mincenter-api 2>&1 | grep -i cors || echo "CORS 로그 없음"
EOF
















