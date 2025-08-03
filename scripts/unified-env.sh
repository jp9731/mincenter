#!/bin/bash

# 통합 .env 파일 관리 스크립트

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
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
SITE_ENV="$ROOT_DIR/frontends/site/.env"
ADMIN_ENV="$ROOT_DIR/frontends/admin/.env"
API_ENV="$ROOT_DIR/backends/api/.env"

# 사용법
usage() {
    echo "사용법: $0 [command]"
    echo ""
    echo "명령어:"
    echo "  status    - .env 파일 상태 확인"
    echo "  setup     - 통합 .env 파일 설정"
    echo "  validate  - .env 파일 유효성 검사"
    echo "  backup    - 현재 .env 파일 백업"
    echo "  restore   - 백업에서 .env 파일 복구"
    echo ""
    echo "통합 .env 관리:"
    echo "  - 최상위 .env 파일 하나로 모든 설정 통합"
    echo "  - 각 프로젝트는 심볼릭 링크로 .env 참조"
    echo "  - 중복 제거 및 일관성 보장"
    echo ""
    echo "예시:"
    echo "  $0 status"
    echo "  $0 setup"
    echo "  $0 validate"
}

# .env 파일 상태 확인
check_status() {
    log_info ".env 파일 상태 확인 중..."
    
    echo ""
    echo "📁 .env 파일 위치:"
    echo "  최상위: $ENV_FILE"
    echo "  Site:   $SITE_ENV"
    echo "  Admin:  $ADMIN_ENV"
    echo "  API:    $API_ENV"
    echo ""
    
    # 최상위 .env 파일 확인
    if [ -f "$ENV_FILE" ]; then
        log_success "✅ 최상위 .env 파일 존재"
        echo "  크기: $(stat -f%z "$ENV_FILE") bytes"
        echo "  수정: $(stat -f%Sm "$ENV_FILE")"
    else
        log_error "❌ 최상위 .env 파일 없음"
    fi
    
    # 심볼릭 링크 확인
    echo ""
    echo "🔗 심볼릭 링크 상태:"
    
    for env_path in "$SITE_ENV" "$ADMIN_ENV" "$API_ENV"; do
        if [ -L "$env_path" ]; then
            link_target=$(readlink "$env_path")
            if [ "$link_target" = "../../.env" ]; then
                log_success "✅ $(basename $(dirname "$env_path"))/.env -> ../../.env"
            else
                log_warning "⚠️  $(basename $(dirname "$env_path"))/.env -> $link_target"
            fi
        else
            log_error "❌ $(basename $(dirname "$env_path"))/.env (심볼릭 링크 아님)"
        fi
    done
    
    # 설정 중복 확인
    echo ""
    echo "🔍 설정 중복 확인:"
    if [ -f "$ENV_FILE" ]; then
        duplicates=$(grep -E '^[A-Z_]+=' "$ENV_FILE" | cut -d'=' -f1 | sort | uniq -d)
        if [ -z "$duplicates" ]; then
            log_success "✅ 중복된 설정 없음"
        else
            log_warning "⚠️  중복된 설정 발견:"
            echo "$duplicates"
        fi
    fi
}

# 통합 .env 파일 설정
setup_unified_env() {
    log_info "통합 .env 파일 설정 중..."
    
    # 백업 생성
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "기존 .env 파일 백업 완료"
    fi
    
    # 기존 분산 .env 파일들 제거
    for env_path in "$SITE_ENV" "$ADMIN_ENV" "$API_ENV"; do
        if [ -f "$env_path" ] && [ ! -L "$env_path" ]; then
            rm "$env_path"
            log_info "제거: $env_path"
        fi
    done
    
    # 심볼릭 링크 생성
    cd "$ROOT_DIR/frontends/site" && ln -sf ../../.env .env
    cd "$ROOT_DIR/frontends/admin" && ln -sf ../../.env .env
    cd "$ROOT_DIR/backends/api" && ln -sf ../../.env .env
    
    log_success "통합 .env 파일 설정 완료!"
    
    # 상태 확인
    check_status
}

# .env 파일 유효성 검사
validate_env() {
    log_info ".env 파일 유효성 검사 중..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env 파일이 존재하지 않습니다."
        return 1
    fi
    
    # 필수 설정 확인
    required_vars=(
        "APP_NAME"
        "NODE_ENV"
        "DOMAIN"
        "POSTGRES_DB"
        "POSTGRES_USER"
        "POSTGRES_PASSWORD"
        "API_PORT"
        "JWT_SECRET"
        "REFRESH_SECRET"
        "SITE_PORT"
        "ADMIN_PORT"
        "REDIS_PASSWORD"
    )
    
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$ENV_FILE"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -eq 0 ]; then
        log_success "✅ 모든 필수 설정이 존재합니다."
    else
        log_error "❌ 누락된 필수 설정:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        return 1
    fi
    
    # 포트 충돌 확인
    echo ""
    echo "🔍 포트 설정 확인:"
    grep -E 'PORT=' "$ENV_FILE" | while read line; do
        echo "  $line"
    done
    
    # API URL 일관성 확인
    echo ""
    echo "🔍 API URL 일관성 확인:"
    api_urls=$(grep -E 'API_URL' "$ENV_FILE")
    echo "$api_urls"
}

# .env 파일 백업
backup_env() {
    log_info ".env 파일 백업 중..."
    
    if [ -f "$ENV_FILE" ]; then
        backup_file="$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$backup_file"
        log_success "백업 완료: $backup_file"
        
        # 오래된 백업 정리 (30일 이상)
        find "$ROOT_DIR" -name ".env.backup.*" -mtime +30 -delete 2>/dev/null || true
    else
        log_error ".env 파일이 존재하지 않습니다."
    fi
}

# 백업에서 .env 파일 복구
restore_env() {
    log_info "백업에서 .env 파일 복구 중..."
    
    # 최신 백업 파일 찾기
    latest_backup=$(find "$ROOT_DIR" -name ".env.backup.*" -type f | sort | tail -1)
    
    if [ -z "$latest_backup" ]; then
        log_error "백업 파일을 찾을 수 없습니다."
        return 1
    fi
    
    log_info "복구할 백업 파일: $latest_backup"
    
    # 백업에서 복구
    cp "$latest_backup" "$ENV_FILE"
    log_success "복구 완료!"
}

# 메인 로직
main() {
    local command=${1:-"help"}
    
    case $command in
        "status")
            check_status
            ;;
        "setup")
            setup_unified_env
            ;;
        "validate")
            validate_env
            ;;
        "backup")
            backup_env
            ;;
        "restore")
            restore_env
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 