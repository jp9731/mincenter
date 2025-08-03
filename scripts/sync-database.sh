#!/bin/bash

# 로컬 데이터베이스 동기화 스크립트
# 개발 컴퓨터의 데이터베이스 변경사항을 서버로 동기화

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
REMOTE_USER="admin"
REMOTE_HOST="49.247.4.194"
REMOTE_PORT="22"
SSH_KEY="~/.ssh/firsthous_server_rsa"
REMOTE_DIR="/home/admin/projects/mincenter"

# SSH 명령어 헬퍼
ssh_cmd() {
    ssh -o BatchMode=yes -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST "$1"
}

scp_cmd() {
    scp -o BatchMode=yes -P $REMOTE_PORT "$1" $REMOTE_USER@$REMOTE_HOST:"$2"
}

# 사용법
usage() {
    echo "사용법: $0 [schema|data|full|backup]"
    echo ""
    echo "옵션:"
    echo "  schema  - 스키마만 동기화"
    echo "  data    - 데이터만 동기화"
    echo "  full    - 스키마 + 데이터 전체 동기화"
    echo "  backup  - 서버 DB 백업만 실행"
    echo ""
    echo "예시:"
    echo "  $0 schema    # 스키마 변경사항만 동기화"
    echo "  $0 data      # 개발 데이터를 서버로 동기화"
    echo "  $0 full      # 전체 동기화"
    echo "  $0 backup    # 서버 DB 백업"
}

# 서버 DB 백업
backup_database() {
    log_info "서버 데이터베이스 백업 중..."
    
    ssh_cmd "mkdir -p $REMOTE_DIR/backups"
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$REMOTE_DIR/backups/mincenter_backup_${TIMESTAMP}.sql"
    
    ssh_cmd "docker exec mincenter-postgres pg_dump -U mincenter -d mincenter > '$BACKUP_FILE'"
    ssh_cmd "gzip '$BACKUP_FILE'"
    
    log_success "백업 완료: ${BACKUP_FILE}.gz"
    
    # 오래된 백업 정리 (7일 이상)
    ssh_cmd "find $REMOTE_DIR/backups -name '*.sql.gz' -mtime +7 -delete"
}

# 스키마 동기화
sync_schema() {
    log_info "스키마 동기화 중..."
    
    # 스키마 파일 전송
    scp_cmd "database/sync_server_schema.sql" "$REMOTE_DIR/database/"
    
    # 스키마 적용
    ssh_cmd "docker exec -i mincenter-postgres psql -U mincenter -d mincenter < $REMOTE_DIR/database/sync_server_schema.sql"
    
    log_success "스키마 동기화 완료!"
}

# 데이터 동기화
sync_data() {
    log_info "데이터 동기화 중..."
    
    # 데이터 파일들 전송
    scp_cmd "database/seed.sql" "$REMOTE_DIR/database/"
    scp_cmd "database_data_dump.sql" "$REMOTE_DIR/database/"
    
    # 데이터 적용
    ssh_cmd "docker exec -i mincenter-postgres psql -U mincenter -d mincenter < $REMOTE_DIR/database/seed.sql"
    
    log_success "데이터 동기화 완료!"
}

# 전체 동기화
sync_full() {
    log_info "전체 데이터베이스 동기화 중..."
    
    # 백업
    backup_database
    
    # 스키마 동기화
    sync_schema
    
    # 데이터 동기화
    sync_data
    
    # API 재시작
    log_info "API 재시작 중..."
    ssh_cmd "cd $REMOTE_DIR && docker compose restart api"
    
    # 헬스체크
    sleep 10
    ssh_cmd "curl -f http://localhost:18080/health || echo 'API 서비스 오류'"
    
    log_success "전체 동기화 완료!"
}

# 데이터베이스 검증
verify_database() {
    log_info "데이터베이스 검증 중..."
    
    # 테이블 목록 확인
    echo "테이블 목록:"
    ssh_cmd "docker exec mincenter-postgres psql -U mincenter -d mincenter -c '\dt'"
    
    # 레코드 수 확인
    echo "주요 테이블 레코드 수:"
    ssh_cmd "docker exec mincenter-postgres psql -U mincenter -d mincenter -c \"SELECT 'users' as table_name, COUNT(*) as count FROM users UNION ALL SELECT 'posts', COUNT(*) FROM posts UNION ALL SELECT 'files', COUNT(*) FROM files;\""
}

# 메인 로직
main() {
    local action=${1:-"help"}
    
    log_info "=== 데이터베이스 동기화 시작 ==="
    
    case $action in
        "schema")
            backup_database
            sync_schema
            verify_database
            ;;
        "data")
            backup_database
            sync_data
            verify_database
            ;;
        "full")
            sync_full
            verify_database
            ;;
        "backup")
            backup_database
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
    
    log_success "=== 데이터베이스 동기화 완료 ==="
}

# 스크립트 실행
main "$@" 