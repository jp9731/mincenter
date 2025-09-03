#!/bin/bash

# API 컨테이너를 재시작하여 CORS 설정 적용

set -e

echo "🔄 API 컨테이너 재시작으로 CORS 설정 적용..."

SERVER_HOST="admin@mincenter.kr"

ssh $SERVER_HOST << 'EOF'
  echo "🛑 API 컨테이너 중지..."
  docker stop mincenter-api
  docker rm mincenter-api
  
  echo "🚀 CORS 설정이 적용된 API 컨테이너 재시작..."
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
  sleep 20
  
  echo "📊 CORS 테스트..."
  curl -H "Origin: https://admin.mincenter.kr" \
       -H "Access-Control-Request-Method: POST" \
       -H "Access-Control-Request-Headers: Content-Type" \
       -X OPTIONS \
       http://localhost:18080/api/admin/login \
       -v 2>&1 | grep -i "access-control-allow-origin" || echo "CORS 헤더 확인 필요"
  
  echo ""
  echo "📝 최근 로그 확인..."
  docker logs --tail 10 mincenter-api | grep -i cors || echo "CORS 로그 없음"
  
EOF
















