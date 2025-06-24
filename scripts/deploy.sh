#!/bin/bash

# 배포 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 환경 변수 확인
if [ ! -f .env ]; then
    log_error "환경 변수 파일(.env)이 없습니다."
    log_info "env.example을 복사하여 .env 파일을 생성하고 설정하세요."
    exit 1
fi

# 환경 변수 로드
source .env

log_info "배포를 시작합니다..."

# 1. 기존 컨테이너 중지
log_info "기존 컨테이너를 중지합니다..."
docker-compose -f docker-compose.prod.yml down

# 2. 최신 이미지 가져오기
log_info "최신 이미지를 가져옵니다..."
docker-compose -f docker-compose.prod.yml pull

# 3. 새 이미지 빌드
log_info "새 이미지를 빌드합니다..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 4. 컨테이너 시작
log_info "컨테이너를 시작합니다..."
docker-compose -f docker-compose.prod.yml up -d

# 5. 헬스체크 대기
log_info "서비스가 시작될 때까지 대기합니다..."
sleep 30

# 6. 헬스체크
log_info "헬스체크를 수행합니다..."

# PostgreSQL 헬스체크
if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null 2>&1; then
    log_info "PostgreSQL: 정상"
else
    log_error "PostgreSQL: 비정상"
    exit 1
fi

# API 헬스체크
if curl -f http://localhost:$API_PORT/health > /dev/null 2>&1; then
    log_info "API: 정상"
else
    log_error "API: 비정상"
    exit 1
fi

# Site 헬스체크
if curl -f http://localhost:$SITE_PORT > /dev/null 2>&1; then
    log_info "Site: 정상"
else
    log_error "Site: 비정상"
    exit 1
fi

# Admin 헬스체크
if curl -f http://localhost:$ADMIN_PORT > /dev/null 2>&1; then
    log_info "Admin: 정상"
else
    log_error "Admin: 비정상"
    exit 1
fi

# 7. 불필요한 이미지 정리
log_info "불필요한 이미지를 정리합니다..."
docker image prune -f

# 8. 배포 완료
log_info "배포가 완료되었습니다!"
log_info "서비스 상태:"
docker-compose -f docker-compose.prod.yml ps

log_info "접속 URL:"
echo "  - 메인 사이트: http://localhost:$SITE_PORT"
echo "  - 관리자 페이지: http://localhost:$ADMIN_PORT"
echo "  - API: http://localhost:$API_PORT" 