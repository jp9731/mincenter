#!/bin/bash

# 환경별 .env 파일 로더 스크립트

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
ENV_LOCAL="$ROOT_DIR/.env.local"
ENV_PRODUCTION="$ROOT_DIR/.env.production"

# 사용법
usage() {
    echo "사용법: $0 [command] [environment]"
    echo ""
    echo "명령어:"
    echo "  load <env>     - 특정 환경의 .env 파일을 .env로 로드"
    echo "  switch <env>   - 환경 전환 (local/production)"
    echo "  status         - 현재 환경 상태 확인"
    echo "  diff <env1> <env2> - 두 환경 간 설정 차이 비교"
    echo "  validate <env> - 특정 환경 설정 유효성 검사"
    echo ""
    echo "환경:"
    echo "  local       - 로컬 개발 환경 (.env.local)"
    echo "  production  - 프로덕션 환경 (.env.production)"
    echo ""
    echo "예시:"
    echo "  $0 load local"
    echo "  $0 switch production"
    echo "  $0 status"
    echo "  $0 diff local production"
}

# 환경별 .env 파일 로드
load_env() {
    local env=$1
    
    case $env in
        "local")
            if [ -f "$ENV_LOCAL" ]; then
                cp "$ENV_LOCAL" "$ENV_FILE"
                log_success "로컬 환경 설정을 .env에 로드했습니다."
                log_info "API_URL: http://localhost:18080"
                log_info "NODE_ENV: development"
            else
                log_error ".env.local 파일이 존재하지 않습니다."
                return 1
            fi
            ;;
        "production")
            if [ -f "$ENV_PRODUCTION" ]; then
                cp "$ENV_PRODUCTION" "$ENV_FILE"
                log_success "프로덕션 환경 설정을 .env에 로드했습니다."
                log_info "API_URL: http://mincenter-api:8080"
                log_info "NODE_ENV: production"
            else
                log_error ".env.production 파일이 존재하지 않습니다."
                return 1
            fi
            ;;
        *)
            log_error "지원하지 않는 환경입니다: $env"
            log_info "지원 환경: local, production"
            return 1
            ;;
    esac
    
    # 심볼릭 링크 업데이트
    update_symlinks
}

# 환경 전환
switch_env() {
    local env=$1
    
    log_info "환경을 $env로 전환 중..."
    
    # 현재 환경 백업
    if [ -f "$ENV_FILE" ]; then
        cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 새 환경 로드
    load_env "$env"
    
    log_success "환경 전환 완료!"
}

# 현재 환경 상태 확인
check_status() {
    log_info "현재 환경 상태 확인 중..."
    
    echo ""
    echo "📁 환경별 .env 파일:"
    for env_file in "$ENV_FILE" "$ENV_LOCAL" "$ENV_PRODUCTION"; do
        if [ -f "$env_file" ]; then
            size=$(stat -f%z "$env_file")
            modified=$(stat -f%Sm "$env_file")
            echo "  ✅ $(basename "$env_file"): ${size} bytes, 수정: $modified"
        else
            echo "  ❌ $(basename "$env_file"): 파일 없음"
        fi
    done
    
    echo ""
    echo "🔍 현재 .env 설정:"
    if [ -f "$ENV_FILE" ]; then
        echo "  NODE_ENV: $(grep '^NODE_ENV=' "$ENV_FILE" | cut -d'=' -f2)"
        echo "  API_URL: $(grep '^API_URL=' "$ENV_FILE" | cut -d'=' -f2)"
        echo "  DOMAIN: $(grep '^DOMAIN=' "$ENV_FILE" | cut -d'=' -f2)"
    else
        log_error "현재 .env 파일이 없습니다."
    fi
    
    echo ""
    echo "🔗 심볼릭 링크 상태:"
    for project in "frontends/site" "frontends/admin" "backends/api"; do
        project_env="$ROOT_DIR/$project/.env"
        if [ -L "$project_env" ]; then
            link_target=$(readlink "$project_env")
            echo "  ✅ $project/.env -> $link_target"
        else
            echo "  ❌ $project/.env (심볼릭 링크 아님)"
        fi
    done
}

# 환경 간 설정 차이 비교
diff_env() {
    local env1=$1
    local env2=$2
    
    local file1=""
    local file2=""
    
    case $env1 in
        "local") file1="$ENV_LOCAL" ;;
        "production") file1="$ENV_PRODUCTION" ;;
        *) log_error "지원하지 않는 환경: $env1"; return 1 ;;
    esac
    
    case $env2 in
        "local") file2="$ENV_LOCAL" ;;
        "production") file2="$ENV_PRODUCTION" ;;
        *) log_error "지원하지 않는 환경: $env2"; return 1 ;;
    esac
    
    if [ ! -f "$file1" ] || [ ! -f "$file2" ]; then
        log_error "비교할 파일이 존재하지 않습니다."
        return 1
    fi
    
    log_info "$env1 vs $env2 환경 설정 차이:"
    echo ""
    
    # 주요 설정 차이 비교
    echo "🔍 주요 설정 차이:"
    for var in "NODE_ENV" "API_URL" "DOMAIN" "CORS_ORIGIN" "LOG_LEVEL"; do
        val1=$(grep "^${var}=" "$file1" | cut -d'=' -f2- 2>/dev/null || echo "NOT_SET")
        val2=$(grep "^${var}=" "$file2" | cut -d'=' -f2- 2>/dev/null || echo "NOT_SET")
        
        if [ "$val1" != "$val2" ]; then
            echo "  $var:"
            echo "    $env1: $val1"
            echo "    $env2: $val2"
            echo ""
        fi
    done
}

# 환경 설정 유효성 검사
validate_env() {
    local env=$1
    
    local env_file=""
    case $env in
        "local") env_file="$ENV_LOCAL" ;;
        "production") env_file="$ENV_PRODUCTION" ;;
        *) log_error "지원하지 않는 환경: $env"; return 1 ;;
    esac
    
    if [ ! -f "$env_file" ]; then
        log_error "$env 환경 파일이 존재하지 않습니다: $env_file"
        return 1
    fi
    
    log_info "$env 환경 설정 유효성 검사 중..."
    
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
        if ! grep -q "^${var}=" "$env_file"; then
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
    
    # 환경별 특수 검사
    if [ "$env" = "local" ]; then
        # 로컬 환경 검사
        if grep -q "localhost" "$env_file"; then
            log_success "✅ 로컬 환경 설정 확인"
        else
            log_warning "⚠️  로컬 환경 설정이 아닐 수 있습니다."
        fi
    elif [ "$env" = "production" ]; then
        # 프로덕션 환경 검사
        if grep -q "production" "$env_file"; then
            log_success "✅ 프로덕션 환경 설정 확인"
        else
            log_warning "⚠️  프로덕션 환경 설정이 아닐 수 있습니다."
        fi
    fi
}

# 심볼릭 링크 업데이트
update_symlinks() {
    log_info "심볼릭 링크 업데이트 중..."
    
    cd "$ROOT_DIR/frontends/site" && ln -sf ../../.env .env
    cd "$ROOT_DIR/frontends/admin" && ln -sf ../../.env .env
    cd "$ROOT_DIR/backends/api" && ln -sf ../../.env .env
    
    log_success "심볼릭 링크 업데이트 완료!"
}

# 메인 로직
main() {
    local command=${1:-"help"}
    local env=${2:-""}
    local env2=${3:-""}
    
    case $command in
        "load")
            if [ -z "$env" ]; then
                log_error "환경을 지정해주세요."
                usage
                exit 1
            fi
            load_env "$env"
            ;;
        "switch")
            if [ -z "$env" ]; then
                log_error "환경을 지정해주세요."
                usage
                exit 1
            fi
            switch_env "$env"
            ;;
        "status")
            check_status
            ;;
        "diff")
            if [ -z "$env" ] || [ -z "$env2" ]; then
                log_error "비교할 두 환경을 지정해주세요."
                usage
                exit 1
            fi
            diff_env "$env" "$env2"
            ;;
        "validate")
            if [ -z "$env" ]; then
                log_error "검사할 환경을 지정해주세요."
                usage
                exit 1
            fi
            validate_env "$env"
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 