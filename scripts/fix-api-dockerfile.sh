#!/bin/bash

# API Dockerfile 수정 스크립트
# 작업 폴더: /home/admin/projects/mincenter

set -e

echo "🔧 API Dockerfile 수정 중..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 Dockerfile 수정
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "🐳 간단한 API Dockerfile 생성..."
  cat > backends/api/Dockerfile << 'DOCKERFILE_EOF'
FROM rust:1.75 as builder

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

  echo "✅ API Dockerfile 수정 완료"
  
  # 기존 API 컨테이너 중지
  docker compose stop api 2>/dev/null || true
  docker compose rm -f api 2>/dev/null || true
  
  echo "🔨 API Docker 이미지 다시 빌드 중..."
  docker build -t mincenter-api:latest -f backends/api/Dockerfile .
  
  echo "🚀 API 서버 재시작..."
  docker compose up -d api
  
  echo "⏳ API 서버 시작 대기 중..."
  sleep 30
  
  echo "📊 최종 컨테이너 상태 확인..."
  docker compose ps
  
  echo ""
  echo "🏥 최종 API 서버 헬스체크..."
  curl -f http://localhost:18080/api/health && echo " ✅ API 서버 정상 작동!"
EOF

echo "🎉 API 서버 수정 및 재시작 완료!"


