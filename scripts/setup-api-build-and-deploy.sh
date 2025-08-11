#!/bin/bash

# API 서버 빌드 환경 설정 및 배포 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 서버 정보
SERVER_HOST="admin@mincenter.kr"
PROJECT_PATH="/home/admin/projects/mincenter"
API_PATH="$PROJECT_PATH/backends/api"
API_PORT="18080"

echo "🚀 API 서버 빌드 환경 설정 및 배포"
echo "📅 시작 시간: $(date)"
echo "🔌 API 포트: $API_PORT"
echo

# 1단계: 서버에 API 소스 코드 전송
log_info "1단계: API 소스 코드 서버로 전송"
echo "📤 backends/api 디렉토리 전송 중..."
rsync -avz --delete --exclude 'target' backends/api/ $SERVER_HOST:$API_PATH/
log_success "API 소스 코드 전송 완료"

# 2단계: 서버에 빌드 의존성 설치
log_info "2단계: 서버 빌드 의존성 설치"
ssh $SERVER_HOST "
    echo '🔧 시스템 패키지 업데이트 및 빌드 도구 설치...'
    sudo apt update
    sudo apt install -y build-essential pkg-config libssl-dev curl
    
    echo '🦀 Rust 환경 확인...'
    source ~/.cargo/env
    rustc --version
    cargo --version
    
    echo '📋 SQLx CLI 확인...'
    ~/.cargo/bin/sqlx --version
"
log_success "빌드 의존성 설치 완료"

# 3단계: 환경변수 파일 생성
log_info "3단계: API 환경변수 설정"
ssh $SERVER_HOST "
    cd $API_PATH
    echo '📝 .env 파일 생성...'
    cat > .env << 'EOF'
DATABASE_URL=postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter
REDIS_URL=redis://:tnekwoddl@localhost:6379
JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
REFRESH_SECRET=ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=
API_PORT=$API_PORT
RUST_LOG=info
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr,http://localhost:3000
NODE_ENV=production
EOF
    echo '✅ .env 파일 생성 완료:'
    cat .env
"
log_success "환경변수 설정 완료"

# 4단계: 프로젝트 빌드
log_info "4단계: Rust 프로젝트 빌드"
ssh $SERVER_HOST "
    cd $API_PATH
    echo '🔨 Rust 프로젝트 빌드 시작...'
    source ~/.cargo/env
    
    # 의존성 확인
    echo '📦 Cargo.toml 확인:'
    head -10 Cargo.toml
    
    # 릴리즈 모드로 빌드
    echo '🏗️  릴리즈 빌드 실행...'
    cargo build --release
    
    echo '📊 빌드된 바이너리 확인:'
    ls -lh target/release/
    
    # 실행 권한 부여
    chmod +x target/release/mincenter-api
"
log_success "프로젝트 빌드 완료"

# 5단계: systemd 서비스 설정
log_info "5단계: systemd 서비스 설정"
ssh $SERVER_HOST "
    echo '📋 systemd 서비스 파일 생성...'
    sudo tee /etc/systemd/system/mincenter-api.service > /dev/null << EOF
[Unit]
Description=MinCenter API Server
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service

[Service]
Type=simple
User=admin
Group=admin
WorkingDirectory=$API_PATH
ExecStart=$API_PATH/target/release/mincenter-api
Restart=always
RestartSec=10
KillMode=mixed
TimeoutStopSec=5

# 환경변수
Environment=DATABASE_URL=postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter
Environment=REDIS_URL=redis://:tnekwoddl@localhost:6379
Environment=JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
Environment=REFRESH_SECRET=ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=
Environment=API_PORT=$API_PORT
Environment=RUST_LOG=info
Environment=CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr,http://localhost:3000

# 로그 설정
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mincenter-api

[Install]
WantedBy=multi-user.target
EOF

    echo '🔄 systemd 데몬 리로드...'
    sudo systemctl daemon-reload
    
    echo '✅ 서비스 활성화...'
    sudo systemctl enable mincenter-api
"
log_success "systemd 서비스 설정 완료"

# 6단계: 기존 API 컨테이너 중지 및 새 서비스 시작
log_info "6단계: 기존 컨테이너 중지 및 새 서비스 시작"
ssh $SERVER_HOST "
    echo '🛑 기존 API 컨테이너 중지...'
    docker stop mincenter-api 2>/dev/null || echo 'ℹ️  기존 API 컨테이너가 없습니다.'
    docker rm mincenter-api 2>/dev/null || echo 'ℹ️  기존 API 컨테이너가 없습니다.'
    
    echo '🚀 새 API 서비스 시작...'
    sudo systemctl start mincenter-api
    
    echo '⏳ 서비스 안정화 대기 (10초)...'
    sleep 10
"

# 7단계: 서비스 상태 확인
log_info "7단계: API 서비스 상태 확인"
ssh $SERVER_HOST "
    echo '🏥 서비스 상태:'
    sudo systemctl status mincenter-api --no-pager
    
    echo '🔍 포트 확인:'
    ss -tlnp | grep $API_PORT || echo '❌ 포트 $API_PORT 에서 리스닝하지 않음'
    
    echo '📋 최근 로그:'
    sudo journalctl -u mincenter-api -n 20 --no-pager
"

# 8단계: 헬스체크
log_info "8단계: API 헬스체크"
ssh $SERVER_HOST "
    echo '🏥 API 헬스체크 테스트...'
    sleep 5
    curl -f http://localhost:$API_PORT/health && echo '✅ 헬스체크 성공' || {
        echo '❌ 헬스체크 실패 - 로그 확인:'
        sudo journalctl -u mincenter-api -n 10 --no-pager
    }
"

# 9단계: 방화벽 설정 (필요시)
log_info "9단계: 방화벽 포트 열기"
ssh $SERVER_HOST "
    echo '🔥 방화벽에서 $API_PORT 포트 열기...'
    sudo ufw allow $API_PORT/tcp 2>/dev/null || echo 'ℹ️  ufw가 설치되지 않았거나 비활성화됨'
    
    echo '🔍 현재 열린 포트:'
    ss -tlnp | grep -E ':(80|443|$API_PORT|15432|6379)' || echo 'ℹ️  포트 정보 없음'
"

log_success "🎉 API 서버 빌드 환경 설정 및 배포 완료!"
echo
echo "📊 배포 요약:"
echo "  - API 포트: $API_PORT"
echo "  - 서비스 이름: mincenter-api"
echo "  - 실행 경로: $API_PATH/target/release/mincenter-api"
echo "  - 로그 확인: sudo journalctl -u mincenter-api -f"
echo "  - 서비스 재시작: sudo systemctl restart mincenter-api"
echo "  - 헬스체크: curl http://localhost:$API_PORT/health"
echo
log_info "API 서버가 성공적으로 배포되었습니다!"
