#!/bin/bash

# API 배포 스크립트 (사용자 레벨 systemd 사용 - sudo 불필요)
# 사용법: ./scripts/deploy-api.sh

set -e

# 배포 실패 시 임시 파일 정리 함수
cleanup_on_error() {
    echo "❌ 배포 중 오류가 발생했습니다. 임시 파일을 정리합니다..."
    
    # 로컬 임시 파일 정리
    if [ -f "api-deploy.tar.gz" ]; then
        rm -f api-deploy.tar.gz
        echo "✅ 로컬의 api-deploy.tar.gz 파일 삭제 완료"
    fi
    
    # 서버 임시 파일 정리 (가능한 경우)
    if ssh "$SERVER_HOST" "test -f /tmp/api-deploy.tar.gz" 2>/dev/null; then
        ssh "$SERVER_HOST" "rm -f /tmp/api-deploy.tar.gz"
        echo "✅ 서버의 /tmp/api-deploy.tar.gz 파일 삭제 완료"
    fi
    
    echo "🧹 임시 파일 정리 완료"
    exit 1
}

# 오류 발생 시 정리 함수 실행
trap cleanup_on_error ERR

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

# target, Cargo.lock, static/uploads 제외하고 압축
tar -czf ../../api-deploy.tar.gz \
    --exclude='./target' \
    --exclude='./Cargo.lock' \
    --exclude='./static/uploads' \
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

# 기존 백업 파일 정리 (최근 3개만 유지)
echo "기존 백업 파일 정리 중..."
ls -t api.backup.*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true

# 기존 API 폴더 백업 (있는 경우, static/uploads 제외)
if [ -d "api" ]; then
    echo "기존 API 폴더 백업 중 (static/uploads 제외)..."
    
    # 업로드 폴더만 별도 백업 (용량 절약을 위해)
    if [ -d "api/static/uploads" ]; then
        echo "업로드 폴더만 별도 백업 중..."
        cp -r api/static/uploads /tmp/uploads_backup
    fi
    
    # static/uploads 제외하고 백업
    tar -czf "api.backup.$(date +%Y%m%d_%H%M%S).tar.gz" \
        --exclude='api/static/uploads' \
        api/
    
    # 기존 폴더 삭제
    rm -rf api
fi

# 새 API 폴더 생성
echo "새 API 폴더 생성 중..."
mkdir -p api

# 압축 해제
echo "파일 압축 해제 중..."
cd api
tar -xzf /tmp/api-deploy.tar.gz

    # 업로드 폴더 복원 (백업이 있는 경우)
    if [ -d "/tmp/uploads_backup" ]; then
        echo "업로드 폴더 복원 중..."
        mkdir -p static
        cp -r /tmp/uploads_backup static/uploads
        rm -rf /tmp/uploads_backup
        echo "업로드 폴더 복원 완료"
    fi

# 백업 폴더에서 업로드 폴더 복원 (더 안전한 방법)
# 압축된 백업 파일에서 복원 (static/uploads는 별도 백업됨)
LATEST_BACKUP_TAR=$(ls -t /home/admin/projects/mincenter/api.backup.*.tar.gz 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP_TAR" ]; then
    echo "백업 파일에서 업로드 폴더 복원 중..."
    mkdir -p static
    # 압축 파일에서 static/uploads만 추출
    tar -xzf "$LATEST_BACKUP_TAR" --wildcards "api/static/uploads/*" --strip-components=3 -C static/ 2>/dev/null || true
    echo "백업 파일에서 업로드 폴더 복원 완료"
fi

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

# 기존 Docker 컨테이너 중지 (있는 경우)
echo "기존 Docker 컨테이너 중지 중..."
docker stop mincenter-api || true

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

# 환경 변수 파일 로드 (실제 파일 경로 사용)
EnvironmentFile=/home/admin/projects/mincenter/.env

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
echo "🧹 서버 임시 파일 정리 중..."
rm -f /tmp/api-deploy.tar.gz
echo "✅ 서버의 /tmp/api-deploy.tar.gz 파일 삭제 완료"

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
if [ -f "api-deploy.tar.gz" ]; then
    rm -f api-deploy.tar.gz
    echo "✅ 로컬의 api-deploy.tar.gz 파일 삭제 완료"
else
    echo "ℹ️  로컬에 api-deploy.tar.gz 파일이 없습니다"
fi

echo "🎉 API 배포가 완료되었습니다!"
echo ""
echo "📋 배포 완료 요약:"
echo "  ✅ 서버 배포: 완료"
echo "  ✅ 서비스 시작: 완료"
echo "  ✅ 임시 파일 정리: 완료"
echo ""
echo "🔧 서버 관리 명령어:"
echo "  ssh $SERVER_HOST 'systemctl --user status mincenter-api'"
echo "  ssh $SERVER_HOST 'systemctl --user logs mincenter-api -f'"
echo "  ssh $SERVER_HOST 'systemctl --user restart mincenter-api'"
