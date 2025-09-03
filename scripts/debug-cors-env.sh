#!/bin/bash

# CORS 환경변수 디버깅

set -e

echo "🔍 CORS 환경변수 디버깅..."

SERVER_HOST="admin@mincenter.kr"

ssh $SERVER_HOST << 'EOF'
  echo "📊 현재 API 컨테이너의 환경변수:"
  docker exec mincenter-api env | grep -i cors || echo "CORS 환경변수 없음"
  
  echo ""
  echo "📊 모든 환경변수:"
  docker exec mincenter-api env | sort
  
  echo ""
  echo "📝 API 컨테이너에서 직접 환경변수 확인:"
  docker exec mincenter-api sh -c 'echo "CORS_ORIGIN = $CORS_ORIGIN"'
  
  echo ""
  echo "📊 Rust 프로그램 내에서 환경변수 디버깅 추가가 필요할 수 있음"
  
EOF
















