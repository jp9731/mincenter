#!/bin/bash

# 데이터베이스 시드 데이터 삽입 스크립트
# 데이터베이스 초기화 후 실행

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

# 환경 변수 로드
if [ -f ".env" ]; then
    log_info "환경 변수를 로드합니다..."
    export $(cat .env | grep -v '^#' | xargs)
else
    log_warning ".env 파일이 없습니다. 기본값을 사용합니다."
    export POSTGRES_DB=minshool_db
    export POSTGRES_USER=mincenter
    export POSTGRES_PASSWORD=mincenter123
    export POSTGRES_PORT=15432
fi

# 데이터베이스 연결 확인
log_info "데이터베이스 연결을 확인합니다..."

if ! docker-compose -f docker-compose.yml exec -T postgres pg_isready -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null 2>&1; then
    log_error "PostgreSQL에 연결할 수 없습니다."
    log_info "Docker Compose가 실행 중인지 확인하세요: docker-compose up -d"
    exit 1
fi

log_success "데이터베이스 연결 확인 완료"

# 시드 데이터 삽입
log_info "시드 데이터를 삽입합니다..."

if [ -f "database/seed.sql" ]; then
    docker-compose -f docker-compose.yml exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/seed.sql
    
    if [ $? -eq 0 ]; then
        log_success "시드 데이터 삽입 완료"
    else
        log_error "시드 데이터 삽입 실패"
        exit 1
    fi
else
    log_error "database/seed.sql 파일이 없습니다."
    exit 1
fi

# 데이터 확인
log_info "삽입된 데이터를 확인합니다..."

echo "=== 메뉴 데이터 ==="
docker-compose -f docker-compose.yml exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT id, name, menu_type, display_order, is_active FROM menus ORDER BY display_order;"

echo ""
echo "=== 게시판 데이터 ==="
docker-compose -f docker-compose.yml exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT id, name, slug, display_order FROM boards ORDER BY display_order;"

echo ""
echo "=== 페이지 데이터 ==="
docker-compose -f docker-compose.yml exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT id, title, slug, is_published FROM pages ORDER BY display_order;"

echo ""
echo "=== 관리자 계정 ==="
docker-compose -f docker-compose.yml exec -T postgres psql -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT email, name, role FROM users WHERE role = 'admin';"

log_success "데이터베이스 시드 데이터 삽입이 완료되었습니다!"
log_info "기본 관리자 계정: admin@mincenter.org / admin123" 