#!/bin/bash

# 보안 강화된 .env 파일 관리 스크립트 (GitHub Secrets 기반)

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

# 사용법
usage() {
    echo "사용법: $0 [command]"
    echo ""
    echo "명령어:"
    echo "  check     - 서버의 .env 파일 상태 확인"
    echo "  secure    - .env 파일 보안 강화 (권한 설정)"
    echo "  cleanup   - 불필요한 .env 백업 파일 정리"
    echo "  template  - .env 템플릿 생성 (GitHub Secrets용)"
    echo ""
    echo "보안 강화된 .env 관리:"
    echo "  - GitHub Secrets에서 민감 정보 관리"
    echo "  - 서버에는 최소 권한으로 .env 파일 생성"
    echo "  - 백업 파일 생성 금지 (보안상 위험)"
    echo ""
    echo "예시:"
    echo "  $0 check"
    echo "  $0 secure"
    echo "  $0 template"
}

# 서버의 .env 파일 상태 확인
check_env() {
    log_info "서버의 .env 파일 상태 확인 중..."
    
    # .env 파일 존재 여부
    if ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "test -f $REMOTE_DIR/.env"; then
        log_success ".env 파일이 존재합니다."
        
        # 파일 권한 확인
        PERMISSIONS=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%a $REMOTE_DIR/.env")
        log_info "파일 권한: $PERMISSIONS"
        
        if [ "$PERMISSIONS" = "600" ]; then
            log_success "✅ 보안 권한이 올바르게 설정되어 있습니다."
        else
            log_warning "⚠️  보안 권한이 올바르지 않습니다. (현재: $PERMISSIONS, 권장: 600)"
        fi
        
        # 파일 크기
        FILE_SIZE=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%s $REMOTE_DIR/.env")
        log_info "파일 크기: ${FILE_SIZE} bytes"
        
        # 수정 시간
        MOD_TIME=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%y $REMOTE_DIR/.env")
        log_info "수정 시간: $MOD_TIME"
        
        # 민감 정보 마스킹하여 주요 설정 확인
        log_info "주요 설정 확인 (민감 정보 마스킹):"
        ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "grep -E '^(APP_NAME|DOMAIN|POSTGRES_DB|API_PORT|NODE_ENV)=' $REMOTE_DIR/.env"
        ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "grep -E '^(JWT_SECRET|REFRESH_SECRET|SESSION_SECRET|POSTGRES_PASSWORD|REDIS_PASSWORD)=' $REMOTE_DIR/.env | sed 's/=.*/=***MASKED***/'"
        
    else
        log_error ".env 파일이 존재하지 않습니다!"
        log_info "GitHub Actions를 통해 .env 파일을 생성하거나, GitHub Secrets를 설정해주세요."
    fi
}

# .env 파일 보안 강화
secure_env() {
    log_info ".env 파일 보안 강화 중..."
    
    if ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "test -f $REMOTE_DIR/.env"; then
        # 권한을 600으로 설정 (소유자만 읽기/쓰기)
        ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "chmod 600 $REMOTE_DIR/.env"
        
        # 소유자 확인
        ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "chown $SERVER_USER:$SERVER_USER $REMOTE_DIR/.env"
        
        log_success "보안 강화 완료!"
        log_info "권한: 600 (소유자만 읽기/쓰기)"
        
        # 보안 상태 확인
        PERMISSIONS=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%a $REMOTE_DIR/.env")
        OWNER=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "stat -c%U $REMOTE_DIR/.env")
        
        log_info "현재 권한: $PERMISSIONS"
        log_info "현재 소유자: $OWNER"
        
    else
        log_error ".env 파일이 존재하지 않습니다."
        log_info "GitHub Actions를 통해 .env 파일을 생성해주세요."
    fi
}

# 불필요한 .env 백업 파일 정리
cleanup_env() {
    log_warning "불필요한 .env 백업 파일 정리 중..."
    
    # 백업 디렉토리 확인
    if ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "test -d $REMOTE_DIR/backups"; then
        # .env 관련 백업 파일 삭제
        BACKUP_COUNT=$(ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "find $REMOTE_DIR/backups -name '.env_backup_*' 2>/dev/null | wc -l")
        
        if [ "$BACKUP_COUNT" -gt 0 ]; then
            ssh -i $SSH_KEY $SERVER_USER@$SERVER_HOST "find $REMOTE_DIR/backups -name '.env_backup_*' -delete"
            log_success "$BACKUP_COUNT 개의 .env 백업 파일을 삭제했습니다."
        else
            log_info ".env 백업 파일이 없습니다."
        fi
    else
        log_info "백업 디렉토리가 없습니다."
    fi
}

# .env 템플릿 생성 (GitHub Secrets용)
generate_template() {
    log_info ".env 템플릿 생성 중..."
    
    cat > .env.template << 'EOF'
# Application Configuration
APP_NAME=mincenter
NODE_ENV=production
DOMAIN=mincenter.kr

# Database Configuration
POSTGRES_DB=mincenter
POSTGRES_USER=mincenter
POSTGRES_PASSWORD=YOUR_POSTGRES_PASSWORD_HERE
POSTGRES_PORT=15432

# API Configuration
API_PORT=18080
API_URL=http://mincenter-api:8080
PUBLIC_API_URL=https://api.mincenter.kr
JWT_SECRET=YOUR_JWT_SECRET_HERE
REFRESH_SECRET=YOUR_REFRESH_SECRET_HERE
RUST_LOG_LEVEL=info
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr

# Site Configuration
SITE_PORT=13000
SESSION_SECRET=YOUR_SESSION_SECRET_HERE

# Admin Configuration
ADMIN_PORT=13001
ADMIN_SESSION_SECRET=YOUR_ADMIN_SESSION_SECRET_HERE
ADMIN_EMAIL=admin@mincenter.kr

# Redis Configuration
REDIS_PORT=6379
REDIS_PASSWORD=YOUR_REDIS_PASSWORD_HERE

# Nginx Configuration
HTTP_PORT=80
HTTPS_PORT=443

# SSL Configuration
SSL_EMAIL=ssl@mincenter.kr

# Backup Configuration
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=7

# Monitoring Configuration
MONITORING_ENABLED=true
LOG_LEVEL=info
EOF

    log_success ".env.template 파일이 생성되었습니다."
    log_info "이 템플릿을 참고하여 GitHub Secrets를 설정하세요."
    log_info "실제 값은 GitHub Repository → Settings → Secrets and variables → Actions에서 설정"
}

# 메인 로직
main() {
    local command=${1:-"help"}
    
    case $command in
        "check")
            check_env
            ;;
        "secure")
            secure_env
            ;;
        "cleanup")
            cleanup_env
            ;;
        "template")
            generate_template
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 