#!/bin/bash

# .env 파일과 함께 API 빌드 및 실행 시도

set -e

echo "🔨 .env 파일과 함께 API 빌드 시도..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 .env 파일 확인 후 API 빌드
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter/backends/api
  
  echo "📝 .env 파일 확인..."
  if [ -f ".env" ]; then
    echo "✅ .env 파일 존재"
    echo "🔍 환경변수 로드 테스트..."
    source .env
    echo "DATABASE_URL이 설정됨: $(echo $DATABASE_URL | cut -c1-20)..."
  else
    echo "❌ .env 파일 없음"
    exit 1
  fi
  
  echo "🛑 기존 API 프로세스 종료..."
  pkill -f "mincenter-api" 2>/dev/null || true
  pkill -f "cargo run" 2>/dev/null || true
  pkill -9 -f "18080" 2>/dev/null || true
  fuser -k 18080/tcp 2>/dev/null || true
  
  echo "🧹 빌드 캐시 정리..."
  cargo clean
  
  echo "🔨 API 빌드 시도..."
  # 먼저 컴파일만 시도해보기
  if timeout 300 cargo check --bin mincenter-api; then
    echo "✅ 컴파일 체크 성공! 전체 빌드 진행..."
    
    if timeout 600 cargo build --release --bin mincenter-api; then
      echo "✅ API 빌드 성공!"
      
      echo "🚀 API 서버 실행..."
      nohup ./target/release/mincenter-api > /tmp/api.log 2>&1 &
      
      echo "⏳ API 서버 시작 대기 중..."
      sleep 20
      
      echo "📊 프로세스 상태 확인..."
      ps aux | grep mincenter-api | grep -v grep || echo "API 프로세스가 실행되지 않음"
      
      echo "🌐 포트 사용 확인..."
      ss -tlnp | grep :18080 || echo "18080 포트가 사용되지 않음"
      
      echo "🏥 API 서버 헬스체크..."
      for i in {1..15}; do
        if curl -f http://localhost:18080/api/health 2>/dev/null; then
          echo "✅ API 서버가 정상적으로 실행 중입니다!"
          echo "🌐 API 접근 URL: http://49.247.4.194:18080"
          break
        else
          echo "⏳ API 서버 시작 대기 중... ($i/15)"
          sleep 3
        fi
      done
      
    else
      echo "❌ API 빌드 실패"
    fi
  else
    echo "❌ 컴파일 체크 실패 - 타입 오류들이 여전히 존재"
    echo "📋 주요 오류들:"
    cargo check --bin mincenter-api 2>&1 | grep -E "error\[E[0-9]+\]" | head -10 || true
  fi
  
  echo ""
  echo "📋 API 서버 로그 (마지막 20줄):"
  tail -20 /tmp/api.log 2>/dev/null || echo "로그 파일 없음"
EOF

echo "🎉 .env 파일과 함께 API 빌드 시도 완료!"
















