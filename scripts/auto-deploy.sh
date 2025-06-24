#!/bin/bash

# 자동 배포 스크립트 (CentOS 7 호환)
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 환경 변수 확인
if [ ! -f .env ]; then
    log_error "환경 변수 파일(.env)이 없습니다."
    exit 1
fi

# 환경 변수 로드
source .env

# 배포 시작
log_step "자동 배포를 시작합니다..."

# 1. Git 상태 확인
log_info "Git 상태를 확인합니다..."
if [ -n "$(git status --porcelain)" ]; then
    log_warn "작업 디렉토리에 변경사항이 있습니다."
    git status --short
fi

# 2. 최신 코드 가져오기
log_info "최신 코드를 가져옵니다..."
git fetch origin
CURRENT_BRANCH=$(git branch --show-current)
REMOTE_COMMIT=$(git rev-parse origin/$CURRENT_BRANCH)
LOCAL_COMMIT=$(git rev-parse HEAD)

if [ "$REMOTE_COMMIT" = "$LOCAL_COMMIT" ]; then
    log_info "이미 최신 코드입니다."
else
    log_info "새로운 변경사항이 있습니다. 업데이트합니다..."
    git pull origin $CURRENT_BRANCH
fi

# 3. 기존 컨테이너 중지
log_info "기존 컨테이너를 중지합니다..."
docker-compose -f docker-compose.prod.yml down

# 4. 새 이미지 빌드
log_info "새 이미지를 빌드합니다..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 5. 컨테이너 시작
log_info "컨테이너를 시작합니다..."
docker-compose -f docker-compose.prod.yml up -d

# 6. 헬스체크 대기
log_info "서비스가 시작될 때까지 대기합니다..."
sleep 45

# 7. 헬스체크
log_info "헬스체크를 수행합니다..."

# PostgreSQL 헬스체크
if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null 2>&1; then
    log_info "✅ PostgreSQL: 정상"
else
    log_error "❌ PostgreSQL: 비정상"
    docker-compose -f docker-compose.prod.yml logs postgres
    exit 1
fi

# API 헬스체크
if curl -f http://localhost:$API_PORT/health > /dev/null 2>&1; then
    log_info "✅ API: 정상"
else
    log_error "❌ API: 비정상"
    docker-compose -f docker-compose.prod.yml logs api
    exit 1
fi

# Site 헬스체크
if curl -f http://localhost:$SITE_PORT > /dev/null 2>&1; then
    log_info "✅ Site: 정상"
else
    log_error "❌ Site: 비정상"
    docker-compose -f docker-compose.prod.yml logs site
    exit 1
fi

# Admin 헬스체크
if curl -f http://localhost:$ADMIN_PORT > /dev/null 2>&1; then
    log_info "✅ Admin: 정상"
else
    log_error "❌ Admin: 비정상"
    docker-compose -f docker-compose.prod.yml logs admin
    exit 1
fi

# 8. 불필요한 이미지 정리
log_info "불필요한 이미지를 정리합니다..."
docker image prune -f

# 9. 배포 완료
log_step "배포가 완료되었습니다!"
log_info "서비스 상태:"
docker-compose -f docker-compose.prod.yml ps

log_info "접속 URL:"
echo "  - 메인 사이트: http://localhost:$SITE_PORT"
echo "  - 관리자 페이지: http://localhost:$ADMIN_PORT"
echo "  - API: http://localhost:$API_PORT"

# 10. 배포 로그 저장
echo "$(date): 배포 완료 - 커밋: $(git rev-parse --short HEAD)" >> deploy.log

log_info "자동 배포가 성공적으로 완료되었습니다! 🎉" 