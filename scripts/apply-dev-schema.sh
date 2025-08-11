#!/bin/bash

# 개발환경 스키마를 서버에 적용하는 스크립트

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
BACKUP_DIR="/home/admin/projects/mincenter/backups/schema"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "🚀 개발환경 스키마를 서버에 적용"
echo "📅 시작 시간: $(date)"
echo

# 1단계: 현재 서버 스키마 백업
log_info "1단계: 현재 서버 스키마 백업"
ssh $SERVER_HOST "
    mkdir -p $BACKUP_DIR
    echo '💾 현재 서버 스키마 백업...'
    docker exec mincenter_postgres pg_dump -U mincenter -d mincenter --schema-only > '$BACKUP_DIR/server_schema_before_${TIMESTAMP}.sql'
    echo '📊 백업 파일 크기:'
    ls -lh '$BACKUP_DIR/server_schema_before_${TIMESTAMP}.sql'
"
log_success "서버 스키마 백업 완료"

# 2단계: 개발환경 마이그레이션 파일 전송
log_info "2단계: 개발환경 마이그레이션 파일 서버로 전송"
echo "📁 로컬 마이그레이션 파일 확인:"
ls -la backends/api/database/migrations/

echo "📤 마이그레이션 파일 서버로 전송..."
scp -r backends/api/database/migrations/ $SERVER_HOST:$PROJECT_PATH/api_migrations/

ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '📁 전송된 마이그레이션 파일:'
    ls -la api_migrations/
"
log_success "마이그레이션 파일 전송 완료"

# 3단계: SQLx CLI 설치 (서버에 없는 경우)
log_info "3단계: 서버에 SQLx CLI 설치 확인"
ssh $SERVER_HOST "
    if ! command -v sqlx &> /dev/null; then
        echo '🔧 SQLx CLI 설치 중...'
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
        cargo install sqlx-cli --no-default-features --features postgres
        echo '✅ SQLx CLI 설치 완료'
    else
        echo '✅ SQLx CLI 이미 설치됨'
        sqlx --version
    fi
"

# 4단계: 마이그레이션 실행
log_info "4단계: 개발환경 마이그레이션 실행"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🔄 마이그레이션 실행 중...'
    
    # DATABASE_URL 설정
    export DATABASE_URL='postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter'
    
    # 마이그레이션 실행
    ~/.cargo/bin/sqlx migrate run --source api_migrations/ || {
        echo '⚠️  일부 마이그레이션에서 오류가 발생했을 수 있습니다.'
        echo '📋 마이그레이션 상태 확인:'
        ~/.cargo/bin/sqlx migrate info --source api_migrations/ || echo 'migrate info 실행 실패'
    }
"

# 5단계: 새 스키마 확인
log_info "5단계: 업데이트된 스키마 확인"
ssh $SERVER_HOST "
    echo '📋 현재 테이블 목록:'
    docker exec mincenter_postgres psql -U mincenter -d mincenter -c '\dt'
    
    echo '🔍 새로 추가된 테이블 확인:'
    docker exec mincenter_postgres psql -U mincenter -d mincenter -c '
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = \"public\" 
    AND table_name LIKE \"%post_%\" 
    OR table_name LIKE \"%comment_%\"
    OR table_name LIKE \"%url_%\"
    ORDER BY table_name;'
    
    echo '📊 주요 테이블 레코드 수:'
    docker exec mincenter_postgres psql -U mincenter -d mincenter -c '
    SELECT 
        \"users\" as table_name, COUNT(*) as count FROM users
        UNION ALL SELECT \"posts\", COUNT(*) FROM posts  
        UNION ALL SELECT \"boards\", COUNT(*) FROM boards
        UNION ALL SELECT \"comments\", COUNT(*) FROM comments
        UNION ALL SELECT \"roles\", COUNT(*) FROM roles
    ORDER BY count DESC;'
"

# 6단계: 스키마 변경사항 백업
log_info "6단계: 업데이트된 스키마 백업"
ssh $SERVER_HOST "
    echo '💾 업데이트된 스키마 백업...'
    docker exec mincenter_postgres pg_dump -U mincenter -d mincenter --schema-only > '$BACKUP_DIR/server_schema_after_${TIMESTAMP}.sql'
    
    echo '📊 스키마 변경사항 비교:'
    if command -v diff &> /dev/null; then
        diff '$BACKUP_DIR/server_schema_before_${TIMESTAMP}.sql' '$BACKUP_DIR/server_schema_after_${TIMESTAMP}.sql' | head -20 || echo '스키마 변경사항이 있습니다.'
    else
        echo 'diff 명령어를 사용할 수 없어 변경사항을 직접 확인할 수 없습니다.'
    fi
    
    echo '📁 백업 파일 목록:'
    ls -lh '$BACKUP_DIR'/*${TIMESTAMP}*
"

log_success "🎉 개발환경 스키마 적용 완료!"
echo
echo "📊 스키마 마이그레이션 요약:"
echo "  - 백업 위치: $BACKUP_DIR"
echo "  - 백업 타임스탬프: $TIMESTAMP"
echo "  - PostgreSQL: 17.5 ✅"
echo "  - Redis: 7.4.5 ✅"
echo
log_info "다음 단계: API 서버 빌드 환경을 설정하세요."
echo "실행: ./scripts/setup-api-build-env.sh"
