#!/bin/bash

# 새로운 서버 환경 구축 스크립트
# 작업 폴더: /home/admin/projects/mincenter (반드시 유지)

set -e

echo "🚀 새로운 서버 환경 구축 시작..."

# 서버 정보
SERVER_HOST="admin@mincenter.kr"
PROJECT_DIR="/home/admin/projects/mincenter"

# 1. 서버 정리 및 기본 설정
echo "📁 서버 디렉토리 정리 및 생성..."
ssh $SERVER_HOST << 'EOF'
  # 기존 Docker 컨테이너 및 볼륨 정리
  docker compose down --volumes --remove-orphans 2>/dev/null || true
  docker system prune -af

  # 프로젝트 디렉토리 생성 (반드시 이 경로 유지)
  mkdir -p /home/admin/projects
  cd /home/admin/projects
  
  # 기존 mincenter 디렉토리 완전 삭제
  sudo rm -rf mincenter 2>/dev/null || rm -rf mincenter 2>/dev/null || true
  
  # Git 저장소 새로 클론
  git clone https://github.com/jp9731/mincenter.git
  cd mincenter
  
  # 파일 소유권 설정
  sudo chown -R admin:admin . || chown -R admin:admin . || true
  
  echo "✅ 프로젝트 디렉토리 준비 완료: $(pwd)"
EOF

echo "✅ 1단계 완료: 서버 디렉토리 설정"

# 2. Docker Compose 파일 업데이트
echo "🐳 Docker Compose 설정 업데이트..."
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  # 환경변수 파일 생성
  cat > .env << 'ENV_EOF'
POSTGRES_DB=mincenter
POSTGRES_USER=mincenter
POSTGRES_PASSWORD=!@swjp0209^^
POSTGRES_PORT=15432
REDIS_PASSWORD=tnekwoddl
REDIS_PORT=16379
API_PORT=18080
RUST_LOG=info
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr
JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
REFRESH_SECRET=ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=
ENV_EOF

  echo "✅ 환경변수 파일 생성 완료"
EOF

# 3. 데이터베이스 덤프 파일 서버로 전송
echo "📤 데이터베이스 덤프 파일 서버로 전송..."
scp mincenter_complete_dump.sql $SERVER_HOST:/home/admin/projects/mincenter/

echo "✅ 2단계 완료: 설정 파일 및 데이터 전송"

# 4. PostgreSQL과 Redis 컨테이너 시작
echo "🗄️ PostgreSQL과 Redis 컨테이너 시작..."
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  # PostgreSQL과 Redis만 먼저 시작
  docker compose up -d postgres redis
  
  # 컨테이너 시작 대기
  echo "⏳ 데이터베이스 시작 대기 중..."
  sleep 30
  
  # 컨테이너 상태 확인
  docker compose ps
EOF

echo "✅ 3단계 완료: 데이터베이스 서비스 시작"

# 5. 데이터베이스 복원
echo "📥 데이터베이스 복원 중..."
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  # 덤프 파일 복원
  docker exec -i $(docker compose ps -q postgres) psql -U mincenter -d mincenter < mincenter_complete_dump.sql
  
  echo "✅ 데이터베이스 복원 완료"
EOF

echo "✅ 4단계 완료: 데이터베이스 복원"

# 6. API 서버 Docker 설정
echo "🏗️ API 서버 Docker 설정..."
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  # API용 Dockerfile 생성
  cat > backends/api/Dockerfile << 'DOCKERFILE_EOF'
FROM rust:1.75 as builder

WORKDIR /app
COPY . .
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

  echo "✅ API Dockerfile 생성 완료"
EOF

echo "✅ 5단계 완료: API Docker 설정"

echo "🎉 새로운 서버 환경 구축 완료!"
echo "📍 작업 디렉토리: /home/admin/projects/mincenter"
echo ""
echo "다음 단계:"
echo "1. API 서버 빌드 및 실행: docker compose up -d api"
echo "2. 헬스체크: curl http://localhost:18080/api/health"
echo "3. 로그 확인: docker compose logs api"


