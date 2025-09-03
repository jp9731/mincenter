#!/bin/bash

# 수정된 코드를 서버로 동기화하고 API 재빌드

set -e

echo "🔄 수정된 코드를 서버로 동기화하고 API 재빌드..."

SERVER_HOST="admin@mincenter.kr"

echo "📤 수정된 CORS 파일을 서버로 전송..."
scp backends/api/src/middleware/cors.rs $SERVER_HOST:/home/admin/projects/mincenter/backends/api/src/middleware/

echo "🚀 서버에서 API 재빌드 및 재시작..."
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter/backends/api
  
  echo "🛑 기존 API 컨테이너 중지..."
  docker stop mincenter-api 2>/dev/null || true
  docker rm mincenter-api 2>/dev/null || true
  
  echo "🔨 API 재빌드..."
  export SQLX_OFFLINE=false
  export DATABASE_URL="postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"
  cargo build --release --bin mincenter-api
  
  echo "🚀 수정된 API를 Docker 컨테이너로 실행..."
  cd /home/admin/projects/mincenter
  
  docker run -d \
    --name mincenter-api \
    --restart unless-stopped \
    -p 18080:18080 \
    --network proxy-network \
    -v /home/admin/projects/mincenter:/app \
    -w /app/backends/api \
    -e DATABASE_URL="postgresql://mincenter:!@swjp0209^^@mincenter-postgres:5432/mincenter" \
    -e REDIS_URL="redis://:tnekwoddl@mincenter-redis:6379" \
    -e API_PORT=18080 \
    -e RUST_LOG=info \
    -e CORS_ORIGIN="https://mincenter.kr,https://admin.mincenter.kr,https://www.mincenter.kr" \
    -e JWT_SECRET="y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=" \
    -e REFRESH_SECRET="ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=" \
    -e ACCESS_TOKEN_EXPIRY=1 \
    -e REFRESH_TOKEN_EXPIRY=30 \
    -e MAX_FILE_SIZE=10485760 \
    -e UPLOAD_DIR=./uploads \
    -e LOG_LEVEL=info \
    ubuntu:22.04 \
    sh -c "
      echo '🚀 API 서버 실행...' &&
      cd /app/backends/api &&
      ./target/release/mincenter-api
    "
  
  echo "⏳ API 서버 시작 대기..."
  sleep 15
  
  echo "📊 환경변수 확인..."
  docker exec mincenter-api env | grep CORS_ORIGIN || echo "CORS_ORIGIN 환경변수 없음"
  
  echo ""
  echo "📊 CORS 테스트 (admin.mincenter.kr)..."
  curl -H "Origin: https://admin.mincenter.kr" \
       -H "Access-Control-Request-Method: POST" \
       -H "Access-Control-Request-Headers: Content-Type" \
       -X OPTIONS \
       http://localhost:18080/api/admin/login \
       -i 2>/dev/null | grep -i "access-control-allow-origin" || echo "❌ CORS 헤더 없음"
  
  echo ""
  echo "📝 최근 로그에서 CORS 확인..."
  docker logs --tail 3 mincenter-api | grep -i "admin.mincenter.kr" || echo "admin.mincenter.kr 관련 로그 없음"
  
EOF
















