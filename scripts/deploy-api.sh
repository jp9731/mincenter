#!/bin/bash

# API 배포 스크립트 (사용자 레벨 systemd 사용 - sudo 불필요)
# 사용법: ./scripts/deploy-api.sh

set -e

echo "🚀 MinCenter API 배포 시작..."

# 서버 정보
SERVER_HOST="mincenter-auto"
SERVER_PATH="/home/admin/projects/mincenter"
API_PATH="$SERVER_PATH/api"

# 로컬 API 경로 (절대 경로로 변경)
LOCAL_API_PATH="$(pwd)/backends/api"

# 1. 로컬에서 API 폴더 압축
echo "📦 API 폴더 압축 중..."
cd "$LOCAL_API_PATH"

# 현재 디렉토리 확인
echo "현재 작업 디렉토리: $(pwd)"
echo "압축할 파일들:"
ls -la

# target과 Cargo.lock 제외하고 압축
tar -czf ../../api-deploy.tar.gz \
    --exclude='./target' \
    --exclude='./Cargo.lock' \
    .

# 압축 파일 확인
echo "압축 파일 생성 완료:"
ls -la ../../api-deploy.tar.gz

# 2. 서버에 업로드
echo "📤 서버에 업로드 중..."
scp ../../api-deploy.tar.gz "$SERVER_HOST:/tmp/"

# 3. 서버에서 배포 실행 (sudo 없이)
echo "🔧 서버에서 빌드 및 배포 중..."
ssh "$SERVER_HOST" << 'EOF'
set -e

echo "서버에서 배포 작업 시작..."

# 작업 디렉토리로 이동
cd /home/admin/projects/mincenter

# 기존 API 폴더 백업 (있는 경우)
if [ -d "api" ]; then
    echo "기존 API 폴더 백업 중..."
    mv api "api.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 새 API 폴더 생성
echo "새 API 폴더 생성 중..."
mkdir -p api

# 압축 해제
echo "파일 압축 해제 중..."
cd api
tar -xzf /tmp/api-deploy.tar.gz

# Rust 환경 설정
echo "Rust 환경 설정 중..."
if ! command -v rustc &> /dev/null; then
    echo "Rust가 설치되어 있지 않습니다. 설치 중..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "Rust가 이미 설치되어 있습니다."
    source $HOME/.cargo/env
fi

# Rust 툴체인 업데이트
echo "Rust 툴체인 업데이트 중..."
rustup update

# 의존성 설치 및 빌드
echo "의존성 설치 및 빌드 중..."
cargo build --release

# 실행 파일 권한 설정
chmod +x target/release/mincenter-api

# 기존 서비스 중지 (있는 경우)
echo "기존 서비스 중지 중..."
systemctl --user stop mincenter-api || true

# 사용자 레벨 systemd 서비스 설정
echo "사용자 레벨 systemd 서비스 설정 중..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/mincenter-api.service << 'SERVICE_EOF'
[Unit]
Description=MinCenter API Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/admin/projects/mincenter/api
ExecStart=/home/admin/projects/mincenter/api/target/release/mincenter-api
Restart=always
RestartSec=10
Environment=RUST_LOG=info
Environment=RUST_BACKTRACE=1

# 환경 변수 파일 로드
EnvironmentFile=/home/admin/projects/mincenter/api/.env

[Install]
WantedBy=default.target
SERVICE_EOF

# 서비스 활성화 및 시작
echo "서비스 시작 중..."
systemctl --user daemon-reload
systemctl --user enable mincenter-api
systemctl --user start mincenter-api

# 서비스 상태 확인
sleep 3
echo "서비스 상태 확인 중..."
systemctl --user status mincenter-api

# 배포 성공 후 임시 파일 정리
echo "🧹 임시 파일 정리 중..."
rm -f /tmp/api-deploy.tar.gz

echo "✅ API 배포 완료!"
echo "참고: 사용자 레벨 systemd 서비스로 실행 중입니다."
echo "서비스 관리 명령어:"
echo "  systemctl --user status mincenter-api"
echo "  systemctl --user restart mincenter-api"
echo "  systemctl --user stop mincenter-api"
echo "  systemctl --user logs mincenter-api -f"
EOF

# 로컬 정리
echo "🧹 로컬 임시 파일 정리 중..."
rm -f api-deploy.tar.gz

echo "🎉 API 배포가 완료되었습니다!"
echo "서버에서 다음 명령어로 상태를 확인할 수 있습니다:"
echo "  ssh $SERVER_HOST 'systemctl --user status mincenter-api'"
echo "  ssh $SERVER_HOST 'systemctl --user logs mincenter-api -f'"
