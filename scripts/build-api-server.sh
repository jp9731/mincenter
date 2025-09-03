#!/bin/bash

# API 서버 빌드 및 실행 스크립트
# 작업 폴더: /home/admin/projects/mincenter

set -e

echo "🏗️ API 서버 빌드 및 실행 중..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 API 빌드 및 실행
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "🐳 API Dockerfile 생성..."
  cat > backends/api/Dockerfile << 'DOCKERFILE_EOF'
FROM rust:1.75 as builder

WORKDIR /app

# 의존성 파일들만 먼저 복사 (캐싱 최적화)
COPY backends/api/Cargo.toml backends/api/Cargo.lock ./
COPY backends/api/src ./src

# 의존성 빌드 (캐싱)
RUN cargo build --release --bin mincenter-api

FROM debian:bookworm-slim

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 빌드된 바이너리 복사
COPY --from=builder /app/target/release/mincenter-api /app/mincenter-api

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

  echo "✅ API Dockerfile 생성 완료"
  
  echo "🔨 API Docker 이미지 빌드 중..."
  docker build -t mincenter-api:latest -f backends/api/Dockerfile .
  
  echo "✅ API 이미지 빌드 완료"
  
  echo "🚀 API 서버 시작..."
  docker compose up -d api
  
  echo "⏳ API 서버 시작 대기 중..."
  sleep 30
  
  echo "📊 컨테이너 상태 확인..."
  docker compose ps
  
  echo ""
  echo "🏥 API 서버 헬스체크..."
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

echo "🎉 API 서버 빌드 및 실행 완료!"


