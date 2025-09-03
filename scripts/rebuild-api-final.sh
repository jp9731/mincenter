#!/bin/bash

# 스키마 수정 완료 후 API 최종 빌드 및 실행

set -e

echo "🚀 스키마 수정 완료 후 API 최종 빌드 및 실행..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 API 최종 빌드 및 실행
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter/backends/api
  
  echo "📝 환경변수 로드..."
  source .env
  
  echo "🛑 기존 API 프로세스 완전 종료..."
  pkill -f "mincenter-api" 2>/dev/null || true
  pkill -f "cargo run" 2>/dev/null || true
  pkill -9 -f "18080" 2>/dev/null || true
  fuser -k 18080/tcp 2>/dev/null || true
  
  echo "🧹 빌드 캐시 완전 정리..."
  cargo clean
  rm -f sqlx-data.json .sqlx-data.json
  
  echo "🔧 SQLx 오프라인 모드 비활성화..."
  export SQLX_OFFLINE=false
  
  echo "🔨 API 빌드 중..."
  echo "데이터베이스 연결: $DATABASE_URL"
  
  if timeout 600 cargo build --release --bin mincenter-api; then
    echo "✅ API 빌드 성공!"
    
    echo "🚀 API 서버 백그라운드 실행..."
    nohup ./target/release/mincenter-api > /tmp/api.log 2>&1 &
    
    echo "⏳ API 서버 시작 대기 중..."
    sleep 15
    
    echo "📊 프로세스 상태 확인..."
    ps aux | grep mincenter-api | grep -v grep || echo "❌ API 프로세스 없음"
    
    echo "🌐 포트 18080 상태 확인..."
    ss -tlnp | grep :18080 || echo "❌ 포트 18080 바인딩 안됨"
    
    echo "🔍 API 헬스 체크..."
    sleep 5
    if curl -f http://localhost:18080/api/health 2>/dev/null; then
      echo ""
      echo "✅ API 서버 정상 실행 중!"
    else
      echo ""
      echo "❌ API 서버 헬스 체크 실패"
      echo "로그 확인:"
      tail -20 /tmp/api.log
    fi
    
  else
    echo "❌ API 빌드 실패"
    echo "빌드 로그를 확인하세요."
  fi
  
EOF
















