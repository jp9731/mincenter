#!/bin/bash

# 마이그레이션 적용 스크립트
# database/migrations/ 폴더의 모든 마이그레이션을 순서대로 적용

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
    echo "사용법: $0 [local|remote|both]"
    echo ""
    echo "옵션:"
    echo "  local   - 로컬 데이터베이스에만 적용"
    echo "  remote  - 서버 데이터베이스에만 적용"
    echo "  both    - 로컬과 서버 모두에 적용"
    echo ""
    echo "예시:"
    echo "  $0 local    # 로컬 DB에 마이그레이션 적용"
    echo "  $0 remote   # 서버 DB에 마이그레이션 적용"
    echo "  $0 both     # 로컬과 서버 모두에 적용"
}

# 로컬 마이그레이션 적용
apply_local_migrations() {
    log_info "로컬 데이터베이스에 마이그레이션 적용 중..."
    
    # 마이그레이션 파일들을 순서대로 정렬
    for migration_file in database/migrations/*.sql; do
        if [ -f "$migration_file" ]; then
            log_info "적용 중: $(basename "$migration_file")"
            
            # 로컬 PostgreSQL에 적용
            psql -h localhost -p 15432 -U mincenter -d mincenter -f "$migration_file"
            
            log_success "완료: $(basename "$migration_file")"
        fi
    done
    
    log_success "로컬 마이그레이션 완료!"
}

# 서버 마이그레이션 적용
apply_remote_migrations() {
    log_info "서버 데이터베이스에 마이그레이션 적용 중..."
    
    # 백업
    log_info "서버 데이터베이스 백업 중..."
    ssh_cmd "mkdir -p $REMOTE_DIR/backups"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$REMOTE_DIR/backups/mincenter_backup_${TIMESTAMP}.sql"
    ssh_cmd "docker exec mincenter-postgres pg_dump -U mincenter -d mincenter > '$BACKUP_FILE'"
    ssh_cmd "gzip '$BACKUP_FILE'"
    log_success "백업 완료: ${BACKUP_FILE}.gz"
    
    # 마이그레이션 파일들 전송
    log_info "마이그레이션 파일 전송 중..."
    ssh_cmd "mkdir -p $REMOTE_DIR/database/migrations"
    scp_cmd "database/migrations/*.sql" "$REMOTE_DIR/database/migrations/"
    
    # 마이그레이션 파일들을 순서대로 적용
    for migration_file in database/migrations/*.sql; do
        if [ -f "$migration_file" ]; then
            filename=$(basename "$migration_file")
            log_info "적용 중: $filename"
            
            # 서버 PostgreSQL에 적용
            ssh_cmd "docker exec -i mincenter-postgres psql -U mincenter -d mincenter < $REMOTE_DIR/database/migrations/$filename"
            
            log_success "완료: $filename"
        fi
    done
    
    # API 재시작
    log_info "API 재시작 중..."
    ssh_cmd "cd $REMOTE_DIR && docker compose restart api"
    
    # 헬스체크
    sleep 10
    ssh_cmd "curl -f http://localhost:18080/health || echo 'API 서비스 오류'"
    
    log_success "서버 마이그레이션 완료!"
}

# 메인 로직
main() {
    local target=${1:-"both"}
    
    log_info "=== 마이그레이션 적용 시작 ==="
    log_info "대상: $target"
    
    case $target in
        "local")
            apply_local_migrations
            ;;
        "remote")
            apply_remote_migrations
            ;;
        "both")
            apply_local_migrations
            apply_remote_migrations
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    
    log_success "=== 마이그레이션 적용 완료 ==="
}

# 스크립트 실행
main "$@" 