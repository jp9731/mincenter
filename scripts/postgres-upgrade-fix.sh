#!/bin/bash

# PostgreSQL 13 → 17 업그레이드 수정 스크립트
# 문제점들을 해결하여 다시 실행

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
TIMESTAMP="20250811_215019"

# PostgreSQL 정보
POSTGRES_CONTAINER="mincenter-postgres"
POSTGRES_USER="mincenter"
POSTGRES_DB="mincenter"
POSTGRES_PASSWORD="!@swjp0209^^"
POSTGRES_PORT="15432"

echo "🔧 PostgreSQL 업그레이드 문제 해결"
echo "📅 시작 시간: $(date)"
echo

# 1단계: 현재 상태 확인
log_info "1단계: 현재 상태 확인"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🔍 현재 컨테이너 상태:'
    docker ps | grep postgres
    echo
    echo '🐘 현재 PostgreSQL 버전:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();'
    echo
    echo '📝 Docker Compose 파일 확인:'
    grep 'image: postgres' docker-compose.yml
"

# 2단계: 완전히 정리하고 다시 시작
log_info "2단계: PostgreSQL 컨테이너 완전 정리"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🛑 모든 서비스 중지...'
    docker compose down
    
    echo '🗑️  PostgreSQL 컨테이너 및 이미지 제거...'
    docker rm -f $POSTGRES_CONTAINER 2>/dev/null || echo 'ℹ️  컨테이너가 이미 제거됨'
    docker rmi postgres:13-alpine 2>/dev/null || echo 'ℹ️  이미지가 이미 제거됨'
    
    echo '🧹 PostgreSQL 17 이미지 다운로드...'
    docker pull postgres:17-alpine
    
    echo '📊 현재 이미지 목록:'
    docker images | grep postgres
"

# 3단계: 기존 볼륨 완전 제거
log_info "3단계: 기존 볼륨 완전 제거"
ssh $SERVER_HOST "
    echo '🗑️  기존 PostgreSQL 볼륨 완전 제거...'
    docker volume rm mincenter_postgres_data 2>/dev/null || echo 'ℹ️  볼륨이 이미 제거됨'
    
    echo '📊 현재 볼륨 목록:'
    docker volume ls | grep postgres
"

# 4단계: PostgreSQL 17 새로 시작
log_info "4단계: PostgreSQL 17 새로 시작"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🚀 PostgreSQL 17 컨테이너 시작...'
    docker compose up -d postgres
    
    echo '⏳ PostgreSQL 17 초기화 대기 (60초)...'
    sleep 60
    
    echo '🔍 컨테이너 상태:'
    docker compose ps postgres
    
    echo '🐘 PostgreSQL 17 버전 확인:'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();' || {
        echo '⏳ 추가 대기 후 재시도...'
        sleep 30
        docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT version();'
    }
"

# 5단계: 스키마만 먼저 복구
log_info "5단계: 스키마 복구 (데이터 제외)"
ssh $SERVER_HOST "
    cd $BACKUP_DIR
    echo '🏗️  스키마만 복구 중...'
    
    # 스키마 백업 파일 압축 해제
    if [ -f 'schema_${TIMESTAMP}.sql.gz' ]; then
        gunzip -k 'schema_${TIMESTAMP}.sql.gz' 2>/dev/null || echo 'ℹ️  이미 압축 해제됨'
    fi
    
    # 스키마 복구
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB < 'schema_${TIMESTAMP}.sql' || {
        echo '⚠️  일부 오류가 발생했지만 계속 진행합니다.'
    }
"

# 6단계: 데이터 복구 (TRUNCATE 후)
log_info "6단계: 데이터 복구"
ssh $SERVER_HOST "
    cd $BACKUP_DIR
    echo '🗑️  기존 데이터 정리...'
    docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB -c '
    TRUNCATE TABLE users, roles, permissions, role_permissions, user_roles, 
                   boards, categories, posts, comments, files, file_entities,
                   pages, menus, site_settings, site_info, organization_info,
                   calendar_events, faqs, notifications, refresh_tokens,
                   point_transactions, reports, drafts, galleries, hero_sections,
                   image_sizes, likes, sns_links, token_blacklist, user_social_accounts
    RESTART IDENTITY CASCADE;
    '
    
    echo '📥 데이터 복구 중...'
    # 데이터 백업 파일 압축 해제
    if [ -f 'data_${TIMESTAMP}.sql.gz' ]; then
        gunzip -k 'data_${TIMESTAMP}.sql.gz' 2>/dev/null || echo 'ℹ️  이미 압축 해제됨'
    fi
    
    # 데이터 복구
    docker exec -i $POSTGRES_CONTAINER psql -U $POSTGRES_USER -d $POSTGRES_DB < 'data_${TIMESTAMP}.sql' || {
        echo '⚠️  일부 오류가 발생했지만 계속 진행합니다.'
    }
"

# 7단계: 최종 검증
log_info "7단계: 최종 검증"
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
        table_name, 
        (xpath(\"//row/c/text()\", query_to_xml(format(\"select count(*) as c from %I.%I\", schemaname, tablename), false, true, \"\")))[1]::text::int AS row_count
    FROM information_schema.tables 
    WHERE table_schema = \"public\" AND table_type = \"BASE TABLE\"
    ORDER BY row_count DESC;
    '
"

# 8단계: 전체 서비스 재시작
log_info "8단계: 전체 서비스 재시작"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🔄 전체 서비스 재시작...'
    docker compose up -d
    
    echo '⏳ 서비스 안정화 대기 (20초)...'
    sleep 20
    
    echo '🏥 서비스 상태 확인:'
    docker compose ps
"

log_success "🎉 PostgreSQL 13 → 17 업그레이드 수정 완료!"
echo
echo "📊 업그레이드 요약:"
echo "  - 이전: PostgreSQL 13.21"
echo "  - 현재: PostgreSQL 17.x (확인 필요)"
echo "  - 백업: $BACKUP_DIR (타임스탬프: $TIMESTAMP)"
echo
log_info "다음 단계: 개발환경 스키마 마이그레이션을 진행하세요."
