#!/bin/bash

# 프론트엔드 배포 스크립트
# 로컬에서 빌드한 프론트엔드를 서버에 배포

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
SITE_BUILD_DIR="frontends/site/build"
ADMIN_BUILD_DIR="frontends/admin/build"
REMOTE_WEB_DIR="/var/www/html"
REMOTE_SITE_DIR="${REMOTE_WEB_DIR}/site"
REMOTE_ADMIN_DIR="${REMOTE_WEB_DIR}/admin"

# 환경변수 확인
if [ -z "$REMOTE_HOST" ] || [ "$REMOTE_HOST" = "your-server-ip" ]; then
    log_error "REMOTE_HOST 환경변수를 설정해주세요."
    log_info "사용법: REMOTE_HOST=your-server-ip ./scripts/deploy-frontend.sh"
    exit 1
fi

# 로컬 빌드 확인
if [ ! -d "$SITE_BUILD_DIR" ]; then
    log_error "사이트 빌드 디렉토리를 찾을 수 없습니다: $SITE_BUILD_DIR"
    log_info "먼저 'cd frontends/site && npm run build'를 실행해주세요."
    exit 1
fi

if [ ! -d "$ADMIN_BUILD_DIR" ]; then
    log_error "관리자 빌드 디렉토리를 찾을 수 없습니다: $ADMIN_BUILD_DIR"
    log_info "먼저 'cd frontends/admin && npm run build'를 실행해주세요."
    exit 1
fi

log_info "=== 프론트엔드 배포 시작 ==="
log_info "서버: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}"
log_info "배포 경로: ${REMOTE_WEB_DIR}"

# 1. 서버 연결 테스트
log_info "서버 연결 테스트 중..."
if ! ssh -p "$REMOTE_PORT" -o ConnectTimeout=10 "$REMOTE_USER@$REMOTE_HOST" "echo '연결 성공'" > /dev/null 2>&1; then
    log_error "서버에 연결할 수 없습니다."
    exit 1
fi

# 2. 원격 디렉토리 생성
log_info "원격 디렉토리 생성 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_SITE_DIR $REMOTE_ADMIN_DIR"

# 3. 기존 파일 백업 (선택적)
log_info "기존 파일 백업 중..."
BACKUP_DIR="/tmp/frontend_backup_$(date +%Y%m%d_%H%M%S)"
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $BACKUP_DIR && cp -r $REMOTE_SITE_DIR $BACKUP_DIR/ 2>/dev/null || true && cp -r $REMOTE_ADMIN_DIR $BACKUP_DIR/ 2>/dev/null || true"

# 4. 사이트 파일 업로드
log_info "사이트 파일 업로드 중..."
rsync -avz -e "ssh -p $REMOTE_PORT" --delete "$SITE_BUILD_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_SITE_DIR/"

# 5. 관리자 파일 업로드
log_info "관리자 파일 업로드 중..."
rsync -avz -e "ssh -p $REMOTE_PORT" --delete "$ADMIN_BUILD_DIR/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_ADMIN_DIR/"

# 6. 권한 설정
log_info "권한 설정 중..."
ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "chown -R nginx:nginx $REMOTE_WEB_DIR && chmod -R 755 $REMOTE_WEB_DIR"

# 7. Nginx 설정 확인 및 재시작
log_info "Nginx 설정 확인 중..."
if ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "nginx -t"; then
    log_info "Nginx 재시작 중..."
    ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "systemctl reload nginx"
else
    log_error "Nginx 설정에 오류가 있습니다."
    exit 1
fi

# 8. 배포 확인
log_info "배포 확인 중..."
SITE_STATUS=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost/site/ || echo '000'")
ADMIN_STATUS=$(ssh -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "curl -s -o /dev/null -w '%{http_code}' http://localhost/admin/ || echo '000'")

if [ "$SITE_STATUS" = "200" ] && [ "$ADMIN_STATUS" = "200" ]; then
    log_success "프론트엔드 배포가 성공적으로 완료되었습니다!"
    log_info "사이트: http://$REMOTE_HOST/site/ (상태: $SITE_STATUS)"
    log_info "관리자: http://$REMOTE_HOST/admin/ (상태: $ADMIN_STATUS)"
else
    log_warning "배포는 완료되었지만 일부 페이지에 접근할 수 없습니다."
    log_info "사이트 상태: $SITE_STATUS"
    log_info "관리자 상태: $ADMIN_STATUS"
    log_info "Nginx 로그 확인: ssh $REMOTE_USER@$REMOTE_HOST 'tail -f /var/log/nginx/error.log'"
fi

log_success "=== 프론트엔드 배포 완료 ==="
log_info "백업 위치: $BACKUP_DIR"
log_info "배포된 파일:"
log_info "  사이트: $REMOTE_SITE_DIR"
log_info "  관리자: $REMOTE_ADMIN_DIR" 