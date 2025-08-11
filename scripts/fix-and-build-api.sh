#!/bin/bash

# API 빌드 문제 해결 및 배포 스크립트

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

echo "🔧 API 빌드 문제 해결 및 배포"
echo "📅 시작 시간: $(date)"
echo

# 1단계: 서버에서 기존 타겟 디렉토리 정리
log_info "1단계: 서버에서 기존 빌드 아티팩트 정리"
ssh $SERVER_HOST "
    cd $API_PATH
    echo '🧹 기존 빌드 아티팩트 정리...'
    rm -rf target/
    
    echo '🔄 Cargo 캐시 정리...'
    source ~/.cargo/env
    cargo clean
"
log_success "빌드 아티팩트 정리 완료"

# 2단계: 환경변수 재설정
log_info "2단계: 환경변수 재설정"
ssh $SERVER_HOST "
    cd $API_PATH
    echo '📝 환경변수 파일 재생성...'
    cat > .env << 'EOF'
DATABASE_URL=postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter
REDIS_URL=redis://:tnekwoddl@localhost:6379
JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
REFRESH_SECRET=ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=
API_PORT=18080
RUST_LOG=info
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr,http://localhost:3000
NODE_ENV=production
SQLX_OFFLINE=true
EOF
    echo '✅ 환경변수 파일 재생성 완료'
"
log_success "환경변수 재설정 완료"

# 3단계: 의존성 체크 모드로 빌드 시도
log_info "3단계: 의존성 체크 모드로 빌드 시도"
ssh $SERVER_HOST "
    cd $API_PATH
    echo '📦 의존성 체크 빌드...'
    source ~/.cargo/env
    export SQLX_OFFLINE=true
    export DATABASE_URL='postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter'
    
    # 의존성만 먼저 빌드
    echo '🔧 의존성 빌드 중...'
    cargo build --release --lib || {
        echo '❌ 라이브러리 빌드 실패, 디버그 모드로 시도...'
        cargo build --lib || {
            echo '❌ 디버그 빌드도 실패'
            exit 1
        }
    }
"

# 4단계: 바이너리 빌드 시도
log_info "4단계: 바이너리 빌드 시도"
ssh $SERVER_HOST "
    cd $API_PATH
    echo '🏗️  바이너리 빌드 시작...'
    source ~/.cargo/env
    export SQLX_OFFLINE=true
    export DATABASE_URL='postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter'
    
    # 바이너리 빌드
    cargo build --release --bin mincenter-api || {
        echo '❌ 릴리즈 빌드 실패, 디버그 모드로 시도...'
        cargo build --bin mincenter-api || {
            echo '❌ 바이너리 빌드 실패'
            exit 1
        }
        echo '⚠️  디버그 모드로 빌드됨'
        BINARY_PATH='target/debug/mincenter-api'
    }
    
    # 빌드 성공 확인
    if [ -f 'target/release/mincenter-api' ]; then
        echo '✅ 릴리즈 바이너리 빌드 성공'
        BINARY_PATH='target/release/mincenter-api'
    elif [ -f 'target/debug/mincenter-api' ]; then
        echo '✅ 디버그 바이너리 빌드 성공'
        BINARY_PATH='target/debug/mincenter-api'
    else
        echo '❌ 바이너리를 찾을 수 없음'
        exit 1
    fi
    
    echo \"🎯 사용할 바이너리: \$BINARY_PATH\"
    chmod +x \$BINARY_PATH
    ls -lh \$BINARY_PATH
"

# 5단계: systemd 서비스 설정 (동적 바이너리 경로)
log_info "5단계: systemd 서비스 설정"
ssh $SERVER_HOST "
    # 바이너리 경로 확인
    if [ -f '$API_PATH/target/release/mincenter-api' ]; then
        BINARY_PATH='$API_PATH/target/release/mincenter-api'
        echo '🎯 릴리즈 바이너리 사용'
    elif [ -f '$API_PATH/target/debug/mincenter-api' ]; then
        BINARY_PATH='$API_PATH/target/debug/mincenter-api'
        echo '🎯 디버그 바이너리 사용'
    else
        echo '❌ 바이너리를 찾을 수 없음'
        exit 1
    fi

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
ExecStart=\$BINARY_PATH
Restart=always
RestartSec=10
KillMode=mixed
TimeoutStopSec=5

# 환경변수
Environment=DATABASE_URL=postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter
Environment=REDIS_URL=redis://:tnekwoddl@localhost:6379
Environment=JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
Environment=REFRESH_SECRET=ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=
Environment=API_PORT=18080
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

# 6단계: 서비스 시작 및 상태 확인
log_info "6단계: 서비스 시작 및 상태 확인"
ssh $SERVER_HOST "
    echo '🛑 기존 서비스 중지...'
    sudo systemctl stop mincenter-api 2>/dev/null || echo 'ℹ️  기존 서비스가 실행 중이 아님'
    
    echo '🚀 새 API 서비스 시작...'
    sudo systemctl start mincenter-api
    
    echo '⏳ 서비스 안정화 대기 (15초)...'
    sleep 15
    
    echo '🏥 서비스 상태 확인:'
    sudo systemctl status mincenter-api --no-pager
    
    echo '🔍 포트 확인:'
    ss -tlnp | grep 18080 || echo '❌ 포트 18080에서 리스닝하지 않음'
    
    echo '📋 최근 로그:'
    sudo journalctl -u mincenter-api -n 30 --no-pager
"

# 7단계: 헬스체크
log_info "7단계: API 헬스체크"
ssh $SERVER_HOST "
    echo '🏥 API 헬스체크 테스트...'
    sleep 5
    
    # 기본 연결 테스트
    curl -f -m 10 http://localhost:18080/health 2>/dev/null && {
        echo '✅ 헬스체크 성공'
    } || {
        echo '❌ 헬스체크 실패 - 상세 로그:'
        sudo journalctl -u mincenter-api -n 20 --no-pager
        echo '🔍 프로세스 상태:'
        ps aux | grep mincenter-api | grep -v grep || echo 'API 프로세스 없음'
    }
"

log_success "🎉 API 서버 빌드 및 배포 스크립트 완료!"
echo
echo "📊 배포 정보:"
echo "  - API 포트: 18080"
echo "  - 서비스 이름: mincenter-api"
echo "  - 로그 확인: sudo journalctl -u mincenter-api -f"
echo "  - 서비스 재시작: sudo systemctl restart mincenter-api"
echo "  - 헬스체크: curl http://localhost:18080/health"
echo
