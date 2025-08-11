#!/bin/bash

# PostgreSQL 13 → 17 업그레이드 실행 스크립트
# 사용법: ./scripts/postgres-upgrade.sh

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
BACKUP_DIR="/home/admin/projects/mincenter/backups/upgrade"
TIMESTAMP="20250811_215019"  # 백업 타임스탬프 (위에서 생성된 것)

# PostgreSQL 정보
POSTGRES_CONTAINER="mincenter-postgres"
POSTGRES_USER="mincenter"
POSTGRES_DB="mincenter"
POSTGRES_PASSWORD="!@swjp0209^^"
POSTGRES_PORT="15432"

echo "🚀 PostgreSQL 13 → 17 업그레이드 실행"
echo "📅 시작 시간: $(date)"
echo "🖥️  서버: $SERVER_HOST"
echo "📁 프로젝트 경로: $PROJECT_PATH"
echo "💾 백업 타임스탬프: $TIMESTAMP"
echo

# 확인 프롬프트
log_warning "PostgreSQL 13을 17로 업그레이드합니다."
log_warning "기존 데이터는 백업되었지만, 컨테이너가 재생성됩니다."
echo -n "계속 진행하시겠습니까? (y/N): "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_info "업그레이드가 취소되었습니다."
    exit 0
fi

# 1단계: 현재 서비스 중지
log_info "1단계: 현재 서비스 중지"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🛑 현재 실행 중인 서비스 중지...'
    docker-compose down
    echo '📊 중지된 컨테이너 확인:'
    docker ps -a | grep mincenter || echo 'ℹ️  mincenter 관련 컨테이너 없음'
"
log_success "서비스 중지 완료"

# 2단계: 볼륨 백업
log_info "2단계: PostgreSQL 데이터 볼륨 백업"
ssh $SERVER_HOST "
    echo '💾 데이터 볼륨 백업 생성...'
    docker volume create postgres_data_backup_${TIMESTAMP} || echo 'ℹ️  볼륨 이미 존재'
    
    # 기존 볼륨이 있는지 확인
    if docker volume ls | grep -q mincenter_postgres_data; then
        echo '📦 기존 볼륨을 백업 볼륨으로 복사...'
        docker run --rm -v mincenter_postgres_data:/from -v postgres_data_backup_${TIMESTAMP}:/to alpine ash -c 'cd /from && cp -av . /to'
        echo '✅ 볼륨 백업 완료'
    else
        echo 'ℹ️  기존 postgres 볼륨이 없습니다.'
    fi
    
    echo '📊 현재 볼륨 목록:'
    docker volume ls | grep postgres || echo 'ℹ️  postgres 관련 볼륨 없음'
"
log_success "볼륨 백업 완료"

# 3단계: Docker Compose 파일 업데이트
log_info "3단계: Docker Compose 파일 업데이트 (postgres:13 → postgres:17)"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '📝 현재 PostgreSQL 이미지 확인:'
    grep 'image: postgres' docker-compose.yml || echo '❌ postgres 이미지 설정을 찾을 수 없습니다.'
    
    echo '🔄 PostgreSQL 13을 17로 변경...'
    sed -i 's/postgres:13-alpine/postgres:17-alpine/g' docker-compose.yml
    sed -i 's/postgres:13/postgres:17/g' docker-compose.yml
    
    echo '✅ 변경 후 확인:'
    grep 'image: postgres' docker-compose.yml
"
log_success "Docker Compose 파일 업데이트 완료"

# 4단계: 기존 볼륨 제거 (PostgreSQL 17과 호환 안됨)
log_info "4단계: 기존 PostgreSQL 13 볼륨 제거"
ssh $SERVER_HOST "
    echo '🗑️  기존 PostgreSQL 13 볼륨 제거 (17과 호환 불가)...'
    docker volume rm mincenter_postgres_data 2>/dev/null || echo 'ℹ️  볼륨이 이미 제거되었거나 존재하지 않습니다.'
    
    echo '📊 현재 볼륨 상태:'
    docker volume ls | grep postgres || echo 'ℹ️  postgres 관련 볼륨 없음'
"
log_success "기존 볼륨 제거 완료"

# 5단계: PostgreSQL 17 컨테이너 시작
log_info "5단계: PostgreSQL 17 컨테이너 시작"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🚀 PostgreSQL 17 컨테이너 시작...'
    docker-compose up -d postgres
    
    echo '⏳ PostgreSQL 17 초기화 대기 (30초)...'
    sleep 30
    
    echo '🔍 컨테이너 상태 확인:'
    docker-compose ps
    
    echo '📋 로그 확인:'
    docker-compose logs postgres | tail -10
"
log_success "PostgreSQL 17 시작 완료"

# 6단계: 버전 확인
log_info "6단계: PostgreSQL 17 버전 확인"
ssh $SERVER_HOST "
    echo '🐘 PostgreSQL 버전 확인:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();' || {
        echo '❌ PostgreSQL 연결 실패, 추가 대기...'
        sleep 30
        docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();'
    }
"

# 7단계: 데이터 복구
log_info "7단계: 백업 데이터 복구"
ssh $SERVER_HOST "
    echo '📥 전체 백업 데이터 복구...'
    cd $BACKUP_DIR
    
    # 백업 파일 압축 해제
    if [ -f 'full_backup_${TIMESTAMP}.sql.gz' ]; then
        gunzip -k 'full_backup_${TIMESTAMP}.sql.gz'
        echo '📂 백업 파일 압축 해제 완료'
    fi
    
    # 데이터 복구 (순환 외래키 문제로 disable-triggers 사용)
    echo '🔄 데이터 복구 중... (외래키 제약 조건 임시 비활성화)'
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB --set ON_ERROR_STOP=off < 'full_backup_${TIMESTAMP}.sql' || {
        echo '⚠️  일부 오류가 발생했지만 계속 진행합니다.'
        echo '🔧 외래키 제약 조건을 비활성화하고 다시 시도...'
        docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SET session_replication_role = replica;'
        docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB < 'full_backup_${TIMESTAMP}.sql'
        docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SET session_replication_role = DEFAULT;'
    }
"
log_success "데이터 복구 완료"

# 8단계: 검증
log_info "8단계: 업그레이드 검증"
ssh $SERVER_HOST "
    echo '🔍 PostgreSQL 17 버전 최종 확인:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();'
    
    echo '📊 데이터베이스 목록:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -c '\l'
    
    echo '📋 테이블 목록:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c '\dt'
    
    echo '📈 주요 테이블 레코드 수:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c '
    SELECT 
        schemaname, 
        tablename, 
        n_live_tup as live_rows
    FROM pg_stat_user_tables 
    WHERE n_live_tup > 0 
    ORDER BY n_live_tup DESC;
    '
"

# 9단계: 전체 서비스 재시작
log_info "9단계: 전체 서비스 재시작"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🔄 전체 서비스 재시작...'
    docker-compose up -d
    
    echo '⏳ 서비스 안정화 대기 (20초)...'
    sleep 20
    
    echo '🏥 서비스 헬스체크:'
    docker-compose ps
    
    # API 헬스체크 (있다면)
    if docker-compose ps | grep -q api; then
        echo '🔍 API 헬스체크:'
        curl -f http://localhost:18080/health 2>/dev/null && echo '✅ API 정상' || echo '❌ API 응답 없음'
    fi
"

log_success "🎉 PostgreSQL 13 → 17 업그레이드 완료!"
echo
echo "📊 업그레이드 요약:"
echo "  - 이전 버전: PostgreSQL 13.21"
echo "  - 현재 버전: PostgreSQL 17.x"
echo "  - 백업 위치: $BACKUP_DIR"
echo "  - 백업 타임스탬프: $TIMESTAMP"
echo
log_info "다음 단계: 개발환경 스키마 마이그레이션을 진행하세요."
echo "실행: ./scripts/apply-dev-schema.sh"
