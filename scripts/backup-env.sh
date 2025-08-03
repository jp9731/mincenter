#!/bin/bash

# .env 파일 백업 및 복구 스크립트

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
SERVER_HOST="49.247.4.194"
SERVER_USER="admin"
SSH_KEY="~/.ssh/mincenter_deploy"
REMOTE_DIR="/home/admin/projects/mincenter"
BACKUP_DIR="/home/admin/projects/mincenter/backups"

# 사용법
usage() {
    echo "사용법: $0 [command]"
    echo ""
    echo "명령어:"
    echo "  backup    - 서버의 .env 파일을 백업"
    echo "  restore   - 백업된 .env 파일을 서버에 복구"
    echo "  check     - 서버의 .env 파일 상태 확인"
    echo "  sync      - 로컬 .env를 서버에 동기화"
    echo ""
    echo "예시:"
    echo "  $0 backup"
    echo "  $0 restore"
    echo "  $0 check"
}

# 서버에 .env 파일 백업
backup_env() {
    log_info "서버의 .env 파일을 백업 중..."
    
    # 백업 디렉토리 생성
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "mkdir -p $BACKUP_DIR"
    
    # 타임스탬프
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/.env_backup_${TIMESTAMP}"
    
    # .env 파일 백업
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "cp $REMOTE_DIR/.env $BACKUP_FILE"
    
    # 압축
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "gzip $BACKUP_FILE"
    
    log_success "백업 완료: ${BACKUP_FILE}.gz"
    
    # 오래된 백업 정리 (30일 이상)
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "find $BACKUP_DIR -name '.env_backup_*.gz' -mtime +30 -delete"
    
    # 백업 목록 표시
    log_info "현재 백업 목록:"
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "ls -la $BACKUP_DIR/.env_backup_*.gz 2>/dev/null || echo '백업 파일이 없습니다.'"
}

# 백업된 .env 파일 복구
restore_env() {
    log_info "백업된 .env 파일을 복구 중..."
    
    # 최신 백업 파일 찾기
    LATEST_BACKUP=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "ls -t $BACKUP_DIR/.env_backup_*.gz 2>/dev/null | head -1")
    
    if [ -z "$LATEST_BACKUP" ]; then
        log_error "백업 파일을 찾을 수 없습니다."
        exit 1
    fi
    
    log_info "복구할 백업 파일: $LATEST_BACKUP"
    
    # 백업 파일 압축 해제 및 복구
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "gunzip -c $LATEST_BACKUP > $REMOTE_DIR/.env"
    
    # 권한 설정
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "chmod 644 $REMOTE_DIR/.env"
    
    log_success "복구 완료!"
    
    # 복구된 파일 확인
    log_info "복구된 .env 파일 내용:"
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "head -10 $REMOTE_DIR/.env"
}

# 서버의 .env 파일 상태 확인
check_env() {
    log_info "서버의 .env 파일 상태 확인 중..."
    
    # .env 파일 존재 여부
    if ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "test -f $REMOTE_DIR/.env"; then
        log_success ".env 파일이 존재합니다."
        
        # 파일 크기
        FILE_SIZE=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%s $REMOTE_DIR/.env")
        log_info "파일 크기: ${FILE_SIZE} bytes"
        
        # 수정 시간
        MOD_TIME=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%y $REMOTE_DIR/.env")
        log_info "수정 시간: $MOD_TIME"
        
        # 주요 설정 확인
        log_info "주요 설정 확인:"
        ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "grep -E '^(APP_NAME|DOMAIN|POSTGRES_DB|API_PORT|JWT_SECRET)=' $REMOTE_DIR/.env"
        
    else
        log_error ".env 파일이 존재하지 않습니다!"
        
        # 백업 파일 확인
        log_info "백업 파일 확인:"
        ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "ls -la $BACKUP_DIR/.env_backup_*.gz 2>/dev/null || echo '백업 파일이 없습니다.'"
    fi
}

# 로컬 .env를 서버에 동기화
sync_env() {
    log_info "로컬 .env 파일을 서버에 동기화 중..."
    
    # 로컬 .env 파일 확인
    if [ ! -f ".env" ]; then
        log_error "로컬 .env 파일이 존재하지 않습니다."
        exit 1
    fi
    
    # 기존 .env 백업
    backup_env
    
    # 로컬 .env 파일을 서버에 전송
    scp -i $SSH_KEY .env $SERVER_USER@$SERVER_HOST:$REMOTE_DIR/
    
    # 권한 설정
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "chmod 644 $REMOTE_DIR/.env"
    
    log_success "동기화 완료!"
    
    # 동기화된 파일 확인
    log_info "동기화된 .env 파일 내용:"
    ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "head -10 $REMOTE_DIR/.env"
}

# 메인 로직
main() {
    local command=${1:-"help"}
    
    case $command in
        "backup")
            backup_env
            ;;
        "restore")
            restore_env
            ;;
        "check")
            check_env
            ;;
        "sync")
            sync_env
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 