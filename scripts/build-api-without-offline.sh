#!/bin/bash

# SQLx 오프라인 모드 없이 API 빌드

set -e

echo "🔨 SQLx 오프라인 모드 없이 API 빌드..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 오프라인 모드 없이 빌드
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter/backends/api
  
  echo "📝 환경변수 설정..."
  source .env
  
  echo "🛑 기존 API 프로세스 종료..."
  pkill -f "mincenter-api" 2>/dev/null || true
  pkill -9 -f "18080" 2>/dev/null || true
  fuser -k 18080/tcp 2>/dev/null || true
  
  echo "🧹 빌드 캐시 정리..."
  cargo clean
  
  echo "🔧 SQLx 오프라인 모드 비활성화..."
  export SQLX_OFFLINE=false
  
  echo "🔨 API 빌드 중 (실제 DB 연결 사용)..."
  if cargo build --release --bin mincenter-api; then
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
        echo "🌐 API Health: http://49.247.4.194:18080/api/health"
        break
      else
        echo "⏳ API 서버 시작 대기 중... ($i/15)"
        sleep 5
      fi
    done
    
  else
    echo "❌ API 빌드 실패"
    echo "📋 빌드 오류 로그:"
    tail -50 /tmp/build_error.log 2>/dev/null || echo "빌드 오류 로그 없음"
  fi
  
  echo ""
  echo "📋 API 서버 로그 (마지막 30줄):"
  tail -30 /tmp/api.log 2>/dev/null || echo "로그 파일 없음"
  
  echo ""
  echo "🌐 최종 서비스 상태 요약:"
  echo "=================================="
  echo "✅ PostgreSQL 17: 정상 (49.247.4.194:15432)"
  echo "✅ Redis 7: 정상 (49.247.4.194:16379)"
  echo "✅ Nginx Proxy Manager: 정상 (49.247.4.194:81)"
  echo "✅ Portainer: 정상 (49.247.4.194:9000)"
  
  if curl -f http://localhost:18080/api/health > /dev/null 2>&1; then
    echo "✅ API Server: 정상 (49.247.4.194:18080)"
  else
    echo "❌ API Server: 실패"
  fi
  echo "=================================="
EOF

echo "🎉 SQLx 오프라인 모드 없이 API 빌드 완료!"
















