#!/bin/bash

# PostgreSQL 13 → 17 업그레이드 및 백업 스크립트
# 사용법: ./scripts/server-backup-and-upgrade.sh

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
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# PostgreSQL 정보
POSTGRES_CONTAINER="mincenter-postgres"
POSTGRES_USER="mincenter"
POSTGRES_DB="mincenter"
POSTGRES_PASSWORD="!@swjp0209^^"
POSTGRES_PORT="15432"

echo "🚀 PostgreSQL 13 → 17 업그레이드 프로세스 시작"
echo "📅 시작 시간: $(date)"
echo "🖥️  서버: $SERVER_HOST"
echo "📁 프로젝트 경로: $PROJECT_PATH"
echo "💾 백업 디렉토리: $BACKUP_DIR"
echo

# 1단계: 현재 상태 확인
log_info "1단계: 현재 PostgreSQL 상태 확인"
ssh $SERVER_HOST "
    echo '📊 현재 Docker 컨테이너 상태:'
    docker ps | grep postgres || echo '❌ PostgreSQL 컨테이너가 실행 중이지 않습니다.'
    echo
    echo '🐘 PostgreSQL 버전 확인:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();' 2>/dev/null || echo '❌ PostgreSQL 연결 실패'
    echo
    echo '📊 데이터베이스 목록:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -c '\l' 2>/dev/null || echo '❌ 데이터베이스 목록 조회 실패'
    echo
    echo '🔌 포트 확인:'
    docker port $POSTGRES_CONTAINER || echo '❌ 포트 정보 조회 실패'
"

# 2단계: 백업 디렉토리 생성
log_info "2단계: 백업 디렉토리 생성"
ssh $SERVER_HOST "mkdir -p $BACKUP_DIR"
log_success "백업 디렉토리 생성 완료: $BACKUP_DIR"

# 3단계: 전체 백업
log_info "3단계: 전체 데이터베이스 백업 (pg_dumpall)"
ssh $SERVER_HOST "
    echo '💾 전체 백업 시작...'
    docker exec $POSTGRES_CONTAINER pg_dumpall -U $POSTGRES_USER > '$BACKUP_DIR/full_backup_${TIMESTAMP}.sql'
    echo '📊 백업 파일 크기:'
    ls -lh '$BACKUP_DIR/full_backup_${TIMESTAMP}.sql'
    echo '🗜️  백업 파일 압축...'
    gzip '$BACKUP_DIR/full_backup_${TIMESTAMP}.sql'
    ls -lh '$BACKUP_DIR/full_backup_${TIMESTAMP}.sql.gz'
"
log_success "전체 백업 완료: full_backup_${TIMESTAMP}.sql.gz"

# 4단계: 스키마 백업
log_info "4단계: 스키마 백업"
ssh $SERVER_HOST "
    echo '🏗️  스키마 백업 시작...'
    docker exec $POSTGRES_CONTAINER pg_dump -U $POSTGRES_USER -d $POSTGRES_DB --schema-only > '$BACKUP_DIR/schema_${TIMESTAMP}.sql'
    echo '📊 스키마 백업 파일 크기:'
    ls -lh '$BACKUP_DIR/schema_${TIMESTAMP}.sql'
    gzip '$BACKUP_DIR/schema_${TIMESTAMP}.sql'
"
log_success "스키마 백업 완료: schema_${TIMESTAMP}.sql.gz"

# 5단계: 데이터 백업
log_info "5단계: 데이터 백업"
ssh $SERVER_HOST "
    echo '📊 데이터 백업 시작...'
    docker exec $POSTGRES_CONTAINER pg_dump -U $POSTGRES_USER -d $POSTGRES_DB --data-only > '$BACKUP_DIR/data_${TIMESTAMP}.sql'
    echo '📊 데이터 백업 파일 크기:'
    ls -lh '$BACKUP_DIR/data_${TIMESTAMP}.sql'
    gzip '$BACKUP_DIR/data_${TIMESTAMP}.sql'
"
log_success "데이터 백업 완료: data_${TIMESTAMP}.sql.gz"

# 6단계: 테이블 정보 백업
log_info "6단계: 테이블 정보 및 통계 백업"
ssh $SERVER_HOST "
    echo '📋 테이블 목록 및 통계 저장...'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c '
    SELECT 
        schemaname,
        tablename,
        n_tup_ins as inserts,
        n_tup_upd as updates,
        n_tup_del as deletes,
        n_live_tup as live_tuples
    FROM pg_stat_user_tables
    ORDER BY schemaname, tablename;
    ' > '$BACKUP_DIR/table_stats_${TIMESTAMP}.txt'
    
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c '\dt' > '$BACKUP_DIR/table_list_${TIMESTAMP}.txt'
"
log_success "테이블 정보 백업 완료"

# 7단계: 백업 검증
log_info "7단계: 백업 파일 검증"
ssh $SERVER_HOST "
    echo '🔍 백업 파일 목록:'
    ls -lh '$BACKUP_DIR'/*${TIMESTAMP}*
    echo
    echo '💾 총 백업 크기:'
    du -sh '$BACKUP_DIR'
"

# 8단계: Docker Compose 파일 백업
log_info "8단계: Docker Compose 설정 백업"
ssh $SERVER_HOST "
    echo '📋 현재 Docker Compose 설정 백업...'
    cp '$PROJECT_PATH/docker-compose.yml' '$BACKUP_DIR/docker-compose_backup_${TIMESTAMP}.yml'
    cp '$PROJECT_PATH/.env' '$BACKUP_DIR/env_backup_${TIMESTAMP}' 2>/dev/null || echo 'ℹ️  .env 파일 없음'
"
log_success "Docker Compose 설정 백업 완료"

log_success "🎉 모든 백업이 완료되었습니다!"
echo
echo "📁 백업 파일 위치: $BACKUP_DIR"
echo "📅 백업 타임스탬프: $TIMESTAMP"
echo
log_warning "다음 단계: PostgreSQL 17 업그레이드를 진행하시겠습니까?"
echo "계속하려면 ./scripts/postgres-upgrade.sh를 실행하세요."
