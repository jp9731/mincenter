#!/bin/bash

# 서버의 Docker Compose 설정 수정 스크립트
# 작업 폴더: /home/admin/projects/mincenter

set -e

echo "🔧 서버 Docker Compose 설정 수정 중..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 Docker Compose 파일 수정
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "📝 현재 docker-compose.yml 백업..."
  cp docker-compose.yml docker-compose.yml.backup
  
  echo "🐳 새로운 docker-compose.yml 생성..."
  cat > docker-compose.yml << 'COMPOSE_EOF'
services:
  postgres:
    image: postgres:17
    container_name: mincenter-postgres
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - mincenter_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 30s
      timeout: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: mincenter-redis
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - "${REDIS_PORT}:6379"
    volumes:
      - redis_data:/data
    networks:
      - mincenter_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5

  api:
    build: 
      context: .
      dockerfile: backends/api/Dockerfile
    container_name: mincenter-api
    ports:
      - "${API_PORT}:18080"
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
      - API_PORT=18080
      - RUST_LOG=${RUST_LOG}
      - CORS_ORIGIN=${CORS_ORIGIN}
      - JWT_SECRET=${JWT_SECRET}
      - REFRESH_SECRET=${REFRESH_SECRET}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - mincenter_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  mincenter_network:
    driver: bridge
COMPOSE_EOF

  # docker-compose.override.yml 제거 (충돌 방지)
  if [ -f "docker-compose.override.yml" ]; then
    echo "🗑️ docker-compose.override.yml 제거..."
    rm docker-compose.override.yml
  fi
  
  echo "✅ Docker Compose 설정 수정 완료"
  
  # PostgreSQL과 Redis 시작
  echo "🚀 PostgreSQL과 Redis 시작..."
  docker compose up -d postgres redis
  
  # 컨테이너 시작 대기
  echo "⏳ 서비스 시작 대기 중..."
  sleep 30
  
  # 상태 확인
  echo "📊 컨테이너 상태 확인..."
  docker compose ps
EOF

echo "✅ Docker Compose 수정 완료!"


