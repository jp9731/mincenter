#!/bin/bash

# SQLx 마이그레이션 관리 스크립트

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
API_DIR="backends/api"
MIGRATIONS_DIR="$API_DIR/database/migrations"

# 사용법
usage() {
    echo "사용법: $0 [command] [options]"
    echo ""
    echo "명령어:"
    echo "  add <name>           - 새로운 마이그레이션 파일 생성"
    echo "  run                  - 로컬 데이터베이스에 마이그레이션 적용"
    echo "  revert               - 마지막 마이그레이션 되돌리기"
    echo "  info                 - 마이그레이션 상태 확인"
    echo "  server-run           - 서버 데이터베이스에 마이그레이션 적용"
    echo "  server-revert        - 서버에서 마지막 마이그레이션 되돌리기"
    echo "  server-info          - 서버 마이그레이션 상태 확인"
    echo ""
    echo "예시:"
    echo "  $0 add 'add_new_table'"
    echo "  $0 run"
    echo "  $0 server-run"
    echo "  $0 info"
}

# 새로운 마이그레이션 생성
add_migration() {
    local name=$1
    
    if [ -z "$name" ]; then
        log_error "마이그레이션 이름을 지정해주세요."
        usage
        exit 1
    fi
    
    log_info "새로운 마이그레이션 생성 중: $name"
    
    cd "$API_DIR"
    sqlx migrate add --source database/migrations "$name"
    
    log_success "마이그레이션 파일이 생성되었습니다."
    log_info "이제 database/migrations/ 폴더에서 SQL을 작성하세요."
}

# 로컬 마이그레이션 실행
run_local_migrations() {
    log_info "로컬 데이터베이스에 마이그레이션 적용 중..."
    
    cd "$API_DIR"
    sqlx migrate run --source database/migrations --database-url "postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"
    
    log_success "로컬 마이그레이션 완료!"
}

# 로컬 마이그레이션 되돌리기
revert_local_migrations() {
    log_warning "마지막 마이그레이션을 되돌립니다..."
    
    cd "$API_DIR"
    sqlx migrate revert --source database/migrations --database-url "postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"
    
    log_success "마이그레이션 되돌리기 완료!"
}

# 로컬 마이그레이션 상태 확인
info_local_migrations() {
    log_info "로컬 마이그레이션 상태 확인 중..."
    
    cd "$API_DIR"
    sqlx migrate info --source database/migrations --database-url "postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"
}

# 서버 마이그레이션 실행
run_server_migrations() {
    log_info "서버 데이터베이스에 마이그레이션 적용 중..."
    
    # 백업
    log_info "서버 데이터베이스 백업 중..."
    ssh admin@49.247.4.194 "mkdir -p /home/admin/projects/mincenter/backups"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="/home/admin/projects/mincenter/backups/mincenter_backup_${TIMESTAMP}.sql"
    ssh admin@49.247.4.194 "docker exec mincenter-postgres pg_dump -U mincenter -d mincenter > '$BACKUP_FILE'"
    ssh admin@49.247.4.194 "gzip '$BACKUP_FILE'"
    log_success "백업 완료: ${BACKUP_FILE}.gz"
    
    # 마이그레이션 파일 전송
    log_info "마이그레이션 파일 전송 중..."
    scp -r "$MIGRATIONS_DIR" admin@49.247.4.194:/home/admin/projects/mincenter/api/database/
    
    # 서버에서 마이그레이션 실행
    log_info "서버에서 마이그레이션 실행 중..."
    ssh admin@49.247.4.194 "cd /home/admin/projects/mincenter/api && sqlx migrate run --source database/migrations --database-url 'postgresql://mincenter:!@swjp0209^^@postgres:5432/mincenter'"
    
    # API 재시작
    log_info "API 재시작 중..."
    ssh admin@49.247.4.194 "cd /home/admin/projects/mincenter && docker compose restart api"
    
    # 헬스체크
    sleep 10
    ssh admin@49.247.4.194 "curl -f http://localhost:18080/health || echo 'API 서비스 오류'"
    
    log_success "서버 마이그레이션 완료!"
}

# 서버 마이그레이션 되돌리기
revert_server_migrations() {
    log_warning "서버에서 마지막 마이그레이션을 되돌립니다..."
    
    # 백업
    log_info "서버 데이터베이스 백업 중..."
    ssh admin@49.247.4.194 "mkdir -p /home/admin/projects/mincenter/backups"
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="/home/admin/projects/mincenter/backups/mincenter_backup_${TIMESTAMP}.sql"
    ssh admin@49.247.4.194 "docker exec mincenter-postgres pg_dump -U mincenter -d mincenter > '$BACKUP_FILE'"
    ssh admin@49.247.4.194 "gzip '$BACKUP_FILE'"
    log_success "백업 완료: ${BACKUP_FILE}.gz"
    
    # 서버에서 마이그레이션 되돌리기
    ssh admin@49.247.4.194 "cd /home/admin/projects/mincenter/api && sqlx migrate revert --source database/migrations --database-url 'postgresql://mincenter:!@swjp0209^^@postgres:5432/mincenter'"
    
    # API 재시작
    log_info "API 재시작 중..."
    ssh admin@49.247.4.194 "cd /home/admin/projects/mincenter && docker compose restart api"
    
    log_success "서버 마이그레이션 되돌리기 완료!"
}

# 서버 마이그레이션 상태 확인
info_server_migrations() {
    log_info "서버 마이그레이션 상태 확인 중..."
    
    ssh admin@49.247.4.194 "cd /home/admin/projects/mincenter/api && sqlx migrate info --source database/migrations --database-url 'postgresql://mincenter:!@swjp0209^^@postgres:5432/mincenter'"
}

# 메인 로직
main() {
    local command=${1:-"help"}
    
    case $command in
        "add")
            add_migration "$2"
            ;;
        "run")
            run_local_migrations
            ;;
        "revert")
            revert_local_migrations
            ;;
        "info")
            info_local_migrations
            ;;
        "server-run")
            run_server_migrations
            ;;
        "server-revert")
            revert_server_migrations
            ;;
        "server-info")
            info_server_migrations
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 