#!/bin/bash

# 스키마 생성 후 API 재빌드 및 실행 스크립트

set -e

echo "🔨 스키마 생성 후 API 재빌드 및 실행..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 API 재빌드 및 실행
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter/backends/api
  
  echo "📝 환경변수 설정..."
  export DATABASE_URL="postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"
  export REDIS_URL="redis://:tnekwoddl@localhost:16379"
  export API_PORT=18080
  export RUST_LOG=info
  export CORS_ORIGIN="https://mincenter.kr,https://admin.mincenter.kr"
  export JWT_SECRET="y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8="
  export REFRESH_SECRET="ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ="
  
  echo "🛑 기존 API 프로세스 종료..."
  pkill -f "mincenter-api" 2>/dev/null || true
  pkill -f "cargo run" 2>/dev/null || true
  pkill -9 -f "18080" 2>/dev/null || true
  fuser -k 18080/tcp 2>/dev/null || true
  
  echo "🧹 빌드 캐시 정리..."
  cargo clean
  
  echo "🔨 API 빌드 중..."
  if cargo build --release --bin mincenter-api; then
    echo "✅ API 빌드 성공!"
    
    echo "🚀 API 서버 실행..."
    nohup ./target/release/mincenter-api > /tmp/api.log 2>&1 &
    
    echo "⏳ API 서버 시작 대기 중..."
    sleep 15
    
    echo "📊 프로세스 상태 확인..."
    ps aux | grep mincenter-api | grep -v grep || echo "API 프로세스가 실행되지 않음"
    
    echo "🌐 포트 사용 확인..."
    ss -tlnp | grep :18080 || echo "18080 포트가 사용되지 않음"
    
    echo "🏥 API 서버 헬스체크..."
    for i in {1..10}; do
      if curl -f http://localhost:18080/api/health 2>/dev/null; then
        echo "✅ API 서버가 정상적으로 실행 중입니다!"
        break
      else
        echo "⏳ API 서버 시작 대기 중... ($i/10)"
        sleep 5
      fi
    done
    
  else
    echo "❌ API 빌드 실패"
  fi
  
  echo ""
  echo "📋 API 서버 로그 (마지막 30줄):"
  tail -30 /tmp/api.log 2>/dev/null || echo "로그 파일 없음"
  
  echo ""
  echo "🌐 최종 서비스 상태:"
  echo "- PostgreSQL: $(docker exec mincenter-postgres psql -U mincenter -d mincenter -c 'SELECT version()' 2>/dev/null | grep PostgreSQL || echo '❌ 실패')"
  echo "- Redis: $(docker exec mincenter-redis redis-cli ping 2>/dev/null || echo '❌ 실패')"
  echo "- API Health: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/api/health || echo '❌ 실패')"
  echo "- Nginx Proxy Manager: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:81 || echo '❌ 실패')"
  echo "- Portainer: $(curl -s -o /dev/null -w '%{http_code}' http://localhost:9000 || echo '❌ 실패')"
EOF

echo "🎉 API 재빌드 및 실행 완료!"
















