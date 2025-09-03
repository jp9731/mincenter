#!/bin/bash

# 기존 프로세스 완전 정리 및 Docker 재시작 스크립트
# 작업 폴더: /home/admin/projects/mincenter

set -e

echo "🔥 기존 프로세스 완전 정리 및 Docker 재시작..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 기존 프로세스 정리 및 Docker 재시작
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "🛑 모든 관련 프로세스 강제 종료..."
  
  # 1. Docker 컨테이너 완전 정지 및 제거
  echo "🐳 Docker 컨테이너 완전 정리..."
  docker compose down --volumes --remove-orphans 2>/dev/null || true
  docker stop $(docker ps -aq) 2>/dev/null || true
  docker rm $(docker ps -aq) 2>/dev/null || true
  
  # 2. API 프로세스 강제 종료
  echo "⚡ API 프로세스 강제 종료..."
  pkill -f "mincenter-api" 2>/dev/null || true
  pkill -f "cargo run" 2>/dev/null || true
  pkill -f "target/release" 2>/dev/null || true
  pkill -9 -f "18080" 2>/dev/null || true
  
  # 3. PostgreSQL 프로세스 강제 종료
  echo "🗄️ PostgreSQL 프로세스 강제 종료..."
  pkill -f "postgres" 2>/dev/null || true
  pkill -9 -f "15432" 2>/dev/null || true
  pkill -9 -f "5432" 2>/dev/null || true
  
  # 4. Redis 프로세스 강제 종료  
  echo "🔴 Redis 프로세스 강제 종료..."
  pkill -f "redis-server" 2>/dev/null || true
  pkill -9 -f "16379" 2>/dev/null || true
  pkill -9 -f "6379" 2>/dev/null || true
  
  # 5. 포트 사용 프로세스 강제 종료
  echo "🔌 포트 사용 프로세스 정리..."
  fuser -k 18080/tcp 2>/dev/null || true
  fuser -k 15432/tcp 2>/dev/null || true  
  fuser -k 16379/tcp 2>/dev/null || true
  fuser -k 5432/tcp 2>/dev/null || true
  fuser -k 6379/tcp 2>/dev/null || true
  
  # 6. 잠시 대기 (프로세스 완전 종료 대기)
  echo "⏳ 프로세스 종료 대기 중..."
  sleep 5
  
  # 7. 포트 사용 상태 확인
  echo "📊 포트 사용 상태 확인..."
  echo "Port 18080 (API):"
  ss -tlnp | grep :18080 || echo "  - 사용 안함 ✅"
  echo "Port 15432 (PostgreSQL):"
  ss -tlnp | grep :15432 || echo "  - 사용 안함 ✅"
  echo "Port 16379 (Redis):"
  ss -tlnp | grep :16379 || echo "  - 사용 안함 ✅"
  
  echo "✅ 모든 기존 프로세스 정리 완료!"
  
  # 8. Docker 시스템 정리
  echo "🧹 Docker 시스템 정리..."
  docker system prune -af --volumes 2>/dev/null || true
  
  # 9. 새로운 Rust 버전으로 Dockerfile 수정
  echo "🦀 최신 Rust 버전으로 Dockerfile 업데이트..."
  cat > backends/api/Dockerfile << 'DOCKERFILE_EOF'
FROM rust:1.82 as builder

WORKDIR /app

# 전체 프로젝트 복사
COPY . .

# API 빌드
RUN cd backends/api && cargo build --release --bin mincenter-api

FROM debian:bookworm-slim

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 빌드된 바이너리 복사
COPY --from=builder /app/backends/api/target/release/mincenter-api /app/mincenter-api

# 실행 권한 부여
RUN chmod +x /app/mincenter-api

# 포트 노출
EXPOSE 18080

# 환경변수 설정
ENV API_PORT=18080
ENV RUST_LOG=info

# 헬스체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:18080/api/health || exit 1

# 실행 명령
CMD ["/app/mincenter-api"]
DOCKERFILE_EOF

  echo "✅ Dockerfile 업데이트 완료 (Rust 1.82)"
  
  # 10. PostgreSQL과 Redis부터 시작
  echo "🚀 PostgreSQL과 Redis 시작..."
  docker compose up -d postgres redis
  
  # 11. 서비스 시작 대기
  echo "⏳ 데이터베이스 서비스 시작 대기 중..."
  sleep 30
  
  # 12. PostgreSQL 연결 확인
  echo "🔍 PostgreSQL 연결 확인..."
  until docker exec $(docker compose ps -q postgres) pg_isready -U mincenter -d mincenter; do
    echo "PostgreSQL 시작 대기 중..."
    sleep 5
  done
  
  # 13. API Docker 이미지 빌드
  echo "🏗️ API Docker 이미지 빌드 중..."
  docker build -t mincenter-api:latest -f backends/api/Dockerfile .
  
  # 14. API 서비스 시작
  echo "🚀 API 서비스 시작..."
  docker compose up -d api
  
  # 15. API 시작 대기
  echo "⏳ API 서버 시작 대기 중..."
  sleep 30
  
  # 16. 최종 상태 확인
  echo "📊 최종 컨테이너 상태:"
  docker compose ps
  
  echo ""
  echo "🏥 API 서버 헬스체크:"
  for i in {1..10}; do
    if curl -f http://localhost:18080/api/health 2>/dev/null; then
      echo "✅ API 서버가 정상적으로 실행 중입니다!"
      break
    else
      echo "⏳ API 서버 시작 대기 중... ($i/10)"
      sleep 10
    fi
  done
  
  echo ""
  echo "📋 API 서버 로그 (마지막 20줄):"
  docker compose logs --tail=20 api
EOF

echo "🎉 서버 완전 재시작 완료!"


