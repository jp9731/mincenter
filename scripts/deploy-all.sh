#!/bin/bash

# 전체 시스템 배포 스크립트
# 백엔드, 프론트엔드, 데이터베이스를 모두 배포

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
REMOTE_USER="${REMOTE_USER:-root}"
REMOTE_HOST="${REMOTE_HOST:-your-server-ip}"
REMOTE_PORT="${REMOTE_PORT:-22}"

# 환경변수 확인
if [ -z "$REMOTE_HOST" ] || [ "$REMOTE_HOST" = "your-server-ip" ]; then
    log_error "REMOTE_HOST 환경변수를 설정해주세요."
    log_info "사용법: REMOTE_HOST=your-server-ip ./scripts/deploy-all.sh"
    exit 1
fi

log_info "=== 전체 시스템 배포 시작 ==="
log_info "서버: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}"

# 1. 백엔드 빌드
log_info "1. 백엔드 빌드 중..."
cd backends/api
if ! cargo build --release; then
    log_error "백엔드 빌드에 실패했습니다."
    exit 1
fi
cd ../..

# 2. 프론트엔드 빌드
log_info "2. 사이트 프론트엔드 빌드 중..."
cd frontends/site
if ! npm run build; then
    log_error "사이트 프론트엔드 빌드에 실패했습니다."
    exit 1
fi
cd ../..

log_info "3. 관리자 프론트엔드 빌드 중..."
cd frontends/admin
if ! npm run build; then
    log_error "관리자 프론트엔드 빌드에 실패했습니다."
    exit 1
fi
cd ../..

# 3. 데이터베이스 파일 확인
log_info "4. 데이터베이스 파일 확인 중..."
if [ ! -f "database/init.sql" ]; then
    log_error "database/init.sql 파일을 찾을 수 없습니다."
    exit 1
fi

if [ ! -f "database/seed.sql" ]; then
    log_error "database/seed.sql 파일을 찾을 수 없습니다."
    exit 1
fi

# 4. 서버 연결 테스트
log_info "5. 서버 연결 테스트 중..."
if ! ssh -p "$REMOTE_PORT" -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" "echo '연결 성공'" > /dev/null 2>&1; then
    log_error "서버에 연결할 수 없습니다."
    exit 1
fi

# 5. 데이터베이스 배포
log_info "6. 데이터베이스 배포 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p /opt/database"
scp -P "$REMOTE_PORT" database/init.sql "$REMOTE_USER@$REMOTE_HOST:/opt/database/"
scp -P "$REMOTE_PORT" database/seed.sql "$REMOTE_USER@$REMOTE_HOST:/opt/database/"

# 6. 백엔드 배포
log_info "7. 백엔드 배포 중..."
./scripts/deploy-binary.sh

# 7. 프론트엔드 배포
log_info "8. 프론트엔드 배포 중..."
./scripts/deploy-frontend.sh

# 8. 최종 상태 확인
log_info "9. 최종 상태 확인 중..."
sleep 5

# API 서버 상태 확인
API_STATUS=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/health || echo '000'")

# 프론트엔드 상태 확인
SITE_STATUS=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost/site/ || echo '000'")
ADMIN_STATUS=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost/admin/ || echo '000'")

# 결과 출력
echo ""
log_success "=== 배포 완료 ==="
log_info "서비스 상태:"
log_info "  API 서버: http://$REMOTE_HOST:18080 (상태: $API_STATUS)"
log_info "  사이트: http://$REMOTE_HOST/site/ (상태: $SITE_STATUS)"
log_info "  관리자: http://$REMOTE_HOST/admin/ (상태: $ADMIN_STATUS)"

if [ "$API_STATUS" = "200" ] && [ "$SITE_STATUS" = "200" ] && [ "$ADMIN_STATUS" = "200" ]; then
    log_success "모든 서비스가 정상적으로 실행 중입니다!"
else
    log_warning "일부 서비스에 문제가 있을 수 있습니다."
    log_info "문제 해결:"
    log_info "  API 로그: ssh $REMOTE_USER@$REMOTE_HOST 'journalctl -u minshool-api -f'"
    log_info "  Nginx 로그: ssh $REMOTE_USER@$REMOTE_HOST 'tail -f /var/log/nginx/error.log'"
fi

echo ""
log_info "관리 명령어:"
log_info "  API 서비스: systemctl {start|stop|restart|status} minshool-api"
log_info "  Nginx: systemctl {start|stop|restart|reload} nginx"
log_info "  PostgreSQL: systemctl {start|stop|restart|status} postgresql"
log_info "  Redis: systemctl {start|stop|restart|status} redis" 