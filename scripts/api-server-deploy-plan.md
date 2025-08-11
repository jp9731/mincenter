# API 서버 빌드 배포 계획

## 🎯 문제 상황
- **개발환경**: Mac M2 (ARM64) 
- **운영환경**: Ubuntu AMD64
- **문제**: 바이너리 호환성 불일치

## 💡 해결 방안: 서버에서 빌드

### 방법 1: 직접 서버 빌드 (권장)
```bash
# 서버에 Rust 설치 및 빌드 환경 구성
ssh admin@49.247.4.194

# Rust 설치 (서버에서 실행)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 프로젝트 디렉토리로 이동
cd /home/admin/projects/mincenter

# 최신 코드 가져오기
git pull origin main

# API 빌드 (릴리즈 모드)
cd backends/api
cargo build --release

# 바이너리 실행 권한 설정
chmod +x target/release/mincenter-api

# 서비스 재시작 (Docker 없이 직접 실행)
./target/release/mincenter-api
```

### 방법 2: Docker 멀티스테이지 빌드
```dockerfile
# backends/api/Dockerfile 수정
FROM rust:1.75 as builder

WORKDIR /app
COPY . .
RUN cargo build --release

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/mincenter-api /usr/local/bin/
EXPOSE 18080
CMD ["mincenter-api"]
```

### 방법 3: GitHub Actions 서버 배포 (자동화)
```yaml
# .github/workflows/deploy-api.yml
name: Deploy API to Server

on:
  push:
    branches: [ main ]
    paths: [ 'backends/api/**' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to server
        uses: appleboy/ssh-action@v1.0.0
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_SSH_KEY }}
          script: |
            cd /home/admin/projects/mincenter
            git pull origin main
            cd backends/api
            cargo build --release
            sudo systemctl restart mincenter-api
```

## 🔧 서버 환경 설정

### Rust 및 의존성 설치
```bash
# 서버에서 실행
ssh admin@49.247.4.194

# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 빌드 도구 설치
sudo apt install -y build-essential pkg-config libssl-dev

# Rust 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# SQLx CLI 설치 (마이그레이션용)
cargo install sqlx-cli --no-default-features --features postgres
```

### 시스템 서비스 설정
```bash
# systemd 서비스 파일 생성
sudo tee /etc/systemd/system/mincenter-api.service > /dev/null <<EOF
[Unit]
Description=MinCenter API Server
After=network.target postgresql.service

[Service]
Type=simple
User=admin
WorkingDirectory=/home/admin/projects/mincenter/backends/api
ExecStart=/home/admin/projects/mincenter/backends/api/target/release/mincenter-api
Restart=always
RestartSec=10

Environment=DATABASE_URL=postgresql://mincenter:password@localhost:15432/mincenter
Environment=REDIS_URL=redis://:password@localhost:6379
Environment=JWT_SECRET=your-jwt-secret
Environment=REFRESH_SECRET=your-refresh-secret
Environment=API_PORT=18080
Environment=RUST_LOG=info

[Install]
WantedBy=multi-user.target
EOF

# 서비스 활성화
sudo systemctl daemon-reload
sudo systemctl enable mincenter-api
```

## 🚀 배포 스크립트

### 자동 배포 스크립트 생성
```bash
#!/bin/bash
# scripts/deploy-api-to-server.sh

set -e

echo "🚀 API 서버 배포 시작..."

# 서버 정보
SERVER_HOST="admin@49.247.4.194"
PROJECT_PATH="/home/admin/projects/mincenter"

# 1. 코드 업데이트
echo "📥 최신 코드 가져오기..."
ssh $SERVER_HOST "cd $PROJECT_PATH && git pull origin main"

# 2. 빌드
echo "🔨 API 빌드 중..."
ssh $SERVER_HOST "cd $PROJECT_PATH/backends/api && cargo build --release"

# 3. 마이그레이션 실행
echo "🗄️ 데이터베이스 마이그레이션..."
ssh $SERVER_HOST "cd $PROJECT_PATH/backends/api && sqlx migrate run"

# 4. 서비스 재시작
echo "🔄 API 서비스 재시작..."
ssh $SERVER_HOST "sudo systemctl restart mincenter-api"

# 5. 헬스체크
echo "🏥 헬스체크..."
sleep 5
ssh $SERVER_HOST "curl -f http://localhost:18080/health" || {
    echo "❌ 헬스체크 실패"
    exit 1
}

echo "✅ API 배포 완료!"
```

## 📋 배포 순서

### 1단계: PostgreSQL 업그레이드 (우선)
1. 데이터베이스 백업
2. PostgreSQL 13 → 17 업그레이드
3. 데이터 복구 및 검증

### 2단계: 서버 환경 준비
1. Rust 설치
2. 빌드 도구 설치  
3. 시스템 서비스 설정

### 3단계: API 배포
1. 코드 업데이트
2. 서버에서 빌드
3. 마이그레이션 실행
4. 서비스 시작

### 4단계: 검증
1. API 헬스체크
2. 기능 테스트
3. 로그 확인

## ⚠️ 주의사항
- 빌드 시간이 오래 걸릴 수 있음 (첫 빌드 시 10-20분)
- 서버 메모리 부족 시 swap 설정 필요
- 방화벽에서 18080 포트 열어야 함
