#!/bin/bash

# PostgreSQL 데이터를 Docker volume에서 호스트 파일 시스템으로 마이그레이션하는 스크립트

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

log_header() {
    echo -e "${BLUE}[MIGRATION]${NC} $1"
}

log_header "=== PostgreSQL 데이터 마이그레이션 시작 ==="

# 환경 변수 로드
if [ -f ".env" ]; then
    source .env
    log_info "환경 변수 로드 완료"
else
    log_warn ".env 파일이 없습니다. 기본값을 사용합니다."
    POSTGRES_DB=${POSTGRES_DB:-mincenter}
    POSTGRES_USER=${POSTGRES_USER:-postgres}
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
fi

# 데이터 디렉토리 생성
log_info "데이터 디렉토리 생성 중..."
mkdir -p database/data

# 기존 컨테이너 확인
if docker ps | grep -q mincenter_postgres; then
    log_info "기존 PostgreSQL 컨테이너가 실행 중입니다."
    
    # 데이터 백업
    log_info "기존 데이터 백업 중..."
    BACKUP_FILE="database/backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if docker exec mincenter_postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"; then
        log_info "데이터 백업 완료: $BACKUP_FILE"
    else
        log_error "데이터 백업 실패!"
        exit 1
    fi
    
    # 기존 컨테이너 중지
    log_info "기존 컨테이너 중지 중..."
    docker stop mincenter_postgres
    docker rm mincenter_postgres
else
    log_info "기존 PostgreSQL 컨테이너가 실행되지 않고 있습니다."
fi

# 기존 volume 확인 및 데이터 복사
if docker volume ls | grep -q postgres_data; then
    log_info "기존 volume에서 데이터 복사 중..."
    
    # 임시 컨테이너로 volume 데이터 복사
    docker run --rm -v postgres_data:/source -v "$(pwd)/database/data:/dest" alpine sh -c "
        cp -r /source/* /dest/ 2>/dev/null || true
        chown -R 999:999 /dest
    "
    
    log_info "Volume 데이터 복사 완료"
else
    log_info "기존 volume이 없습니다. 새로 시작합니다."
fi

# 새로운 컨테이너 시작
log_info "새로운 PostgreSQL 컨테이너 시작 중..."
docker-compose -f docker-compose.prod.yml up -d postgres

# 컨테이너 시작 대기
log_info "컨테이너 시작 대기 중..."
sleep 10

# 헬스체크
log_info "PostgreSQL 헬스체크 중..."
if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" > /dev/null 2>&1; then
    log_info "PostgreSQL 연결 성공!"
else
    log_error "PostgreSQL 연결 실패!"
    exit 1
fi

# 백업 파일이 있으면 복원
if [ -f "$BACKUP_FILE" ]; then
    log_info "백업 데이터 복원 중..."
    if docker-compose -f docker-compose.prod.yml exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$BACKUP_FILE"; then
        log_info "데이터 복원 완료!"
    else
        log_warn "데이터 복원 실패. 백업 파일을 수동으로 확인하세요: $BACKUP_FILE"
    fi
fi

# 기존 volume 정리 (선택사항)
read -p "기존 Docker volume을 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "기존 volume 삭제 중..."
    docker volume rm postgres_data 2>/dev/null || log_warn "Volume이 이미 삭제되었거나 존재하지 않습니다."
fi

log_header "=== PostgreSQL 데이터 마이그레이션 완료 ==="
log_info "이제 docker-compose down을 해도 데이터가 보존됩니다!"
log_info "데이터 위치: ./database/data/" 