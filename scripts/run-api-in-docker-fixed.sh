#!/bin/bash

# API를 Docker 컨테이너로 실행하는 스크립트 (수정버전)

set -e

echo "🐳 API를 Docker 컨테이너로 실행..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 API Docker 컨테이너 실행
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "🛑 기존 API 프로세스 및 컨테이너 종료..."
  # 기존 바이너리 프로세스 종료
  pkill -f "mincenter-api" 2>/dev/null || true
  pkill -9 -f "18080" 2>/dev/null || true
  fuser -k 18080/tcp 2>/dev/null || true
  
  # 기존 Docker 컨테이너 종료 및 제거
  docker stop mincenter-api 2>/dev/null || true
  docker rm mincenter-api 2>/dev/null || true
  
  echo "🔍 Docker 네트워크 확인..."
  docker network ls | grep proxy-network || echo "proxy-network 네트워크 없음"
  
  echo "🐳 API Docker 컨테이너 실행..."
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
    -e CORS_ORIGIN="https://mincenter.kr,https://admin.mincenter.kr" \
    -e JWT_SECRET="y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=" \
    -e REFRESH_SECRET="ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=" \
    -e ACCESS_TOKEN_EXPIRY=1 \
    -e REFRESH_TOKEN_EXPIRY=30 \
    -e MAX_FILE_SIZE=10485760 \
    -e UPLOAD_DIR=./uploads \
    -e LOG_LEVEL=info \
    rust:1.75 \
    sh -c "
      echo '📦 Rust 환경 설정...' &&
      apt-get update -qq &&
      apt-get install -y -qq pkg-config libssl-dev &&
      echo '🔨 API 빌드...' &&
      cargo build --release --bin mincenter-api &&
      echo '🚀 API 서버 실행...' &&
      ./target/release/mincenter-api
    "
  
  echo "⏳ API 컨테이너 시작 대기 중..."
  sleep 30
  
  echo "📊 컨테이너 상태 확인..."
  docker ps | grep mincenter-api || echo "❌ API 컨테이너 없음"
  
  echo "🌐 포트 18080 상태 확인..."
  ss -tlnp | grep :18080 || echo "❌ 포트 18080 바인딩 안됨"
  
  echo "📝 API 컨테이너 로그 확인..."
  docker logs --tail 20 mincenter-api
  
  echo "🔍 API 헬스 체크..."
  sleep 10
  if curl -f http://localhost:18080/api/health 2>/dev/null; then
    echo ""
    echo "✅ API Docker 컨테이너 정상 실행 중!"
  else
    echo ""
    echo "❌ API 헬스 체크 실패"
    echo "상세 로그:"
    docker logs --tail 50 mincenter-api
  fi
  
EOF
















