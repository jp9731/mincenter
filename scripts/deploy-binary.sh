#!/bin/bash

# 바이너리 배포 스크립트
# 로컬에서 빌드한 바이너리를 서버에 배포

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 설정
APP_NAME="mincenter-api"
BINARY_NAME="mincenter-api"
LOCAL_BINARY_PATH="backends/api/target/release/${BINARY_NAME}"
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_HOST="${REMOTE_HOST:-your-server-ip}"
REMOTE_PORT="${REMOTE_PORT:-22}"
REMOTE_DIR="/opt/${APP_NAME}"
REMOTE_BINARY_PATH="${REMOTE_DIR}/${BINARY_NAME}"
SERVICE_NAME="${APP_NAME}"

# 환경변수 확인
if [ -z "$REMOTE_HOST" ] || [ "$REMOTE_HOST" = "your-server-ip" ]; then
    log_error "REMOTE_HOST 환경변수를 설정해주세요."
    log_info "사용법: REMOTE_HOST=your-server-ip ./scripts/deploy-binary.sh"
    exit 1
fi

# 로컬 바이너리 확인
if [ ! -f "$LOCAL_BINARY_PATH" ]; then
    log_error "로컬 바이너리를 찾을 수 없습니다: $LOCAL_BINARY_PATH"
    log_info "먼저 'cargo build --release'를 실행해주세요."
    exit 1
fi

log_info "=== 바이너리 배포 시작 ==="
log_info "서버: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}"
log_info "배포 경로: ${REMOTE_DIR}"

# 1. 서버 연결 테스트
log_info "서버 연결 테스트 중..."
if ! ssh -p "$REMOTE_PORT" -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" "echo '연결 성공'" > /dev/null 2>&1; then
    log_error "서버에 연결할 수 없습니다."
    exit 1
fi

# 2. 원격 디렉토리 생성
log_info "원격 디렉토리 생성 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

# 3. 기존 서비스 중지
log_info "기존 서비스 중지 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl stop $SERVICE_NAME || true"

# 4. 바이너리 업로드
log_info "바이너리 업로드 중..."
scp -P "$REMOTE_PORT" "$LOCAL_BINARY_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_BINARY_PATH"

# 5. 실행 권한 설정
log_info "실행 권한 설정 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "chmod +x $REMOTE_BINARY_PATH"

# 6. systemd 서비스 파일 생성
log_info "systemd 서비스 파일 생성 중..."
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

cat << EOF | ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "cat > $SERVICE_FILE"
[Unit]
Description=MinCenter API Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=$REMOTE_DIR
ExecStart=$REMOTE_BINARY_PATH
Restart=always
RestartSec=3
Environment=DATABASE_URL=postgresql://postgres:password@localhost:5432/mincenter
Environment=REDIS_URL=redis://:default_password@localhost:6379
Environment=JWT_SECRET=your_jwt_secret_here
Environment=API_PORT=18080
Environment=RUST_LOG=info
Environment=CORS_ORIGIN=*
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 7. systemd 재로드 및 서비스 활성화
log_info "systemd 재로드 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl daemon-reload"

log_info "서비스 활성화 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl enable $SERVICE_NAME"

# 8. 서비스 시작
log_info "서비스 시작 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl start $SERVICE_NAME"

# 9. 서비스 상태 확인
log_info "서비스 상태 확인 중..."
sleep 3
if ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl is-active --quiet $SERVICE_NAME"; then
    log_success "서비스가 성공적으로 시작되었습니다!"
    log_info "서비스 상태:"
    ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl status $SERVICE_NAME --no-pager -l"
else
    log_error "서비스 시작에 실패했습니다."
    log_info "로그 확인:"
    ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "journalctl -u $SERVICE_NAME -n 20 --no-pager"
    exit 1
fi

log_success "=== 바이너리 배포 완료 ==="
log_info "API 서버가 포트 18080에서 실행 중입니다."
log_info "서비스 관리 명령어:"
log_info "  상태 확인: systemctl status $SERVICE_NAME"
log_info "  로그 확인: journalctl -u $SERVICE_NAME -f"
log_info "  서비스 중지: systemctl stop $SERVICE_NAME"
log_info "  서비스 시작: systemctl start $SERVICE_NAME"
log_info "  서비스 재시작: systemctl restart $SERVICE_NAME" 