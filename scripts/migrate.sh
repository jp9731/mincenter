#!/bin/bash

# 데이터베이스 마이그레이션 스크립트
# 기존 데이터를 보존하면서 스키마 변경사항만 적용

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}[MIGRATION]${NC} $1"
}

log_header "=== 데이터베이스 마이그레이션 시작 ==="

# 환경 변수 로드 (안전한 방법)
load_env_variables() {
    log_info "환경 변수를 로드합니다..."
    
    if [ -f ".env" ]; then
        # 안전한 환경 변수 로드
        while IFS= read -r line; do
            # 주석과 빈 줄 제외
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                # 변수명과 값 분리
                var_name=$(echo "$line" | cut -d'=' -f1)
                var_value=$(echo "$line" | cut -d'=' -f2-)
                
                # 유효한 변수명인지 확인
                if [[ "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    export "$var_name=$var_value"
                    log_info "환경 변수 로드: $var_name"
                fi
            fi
        done < .env
    else
        log_warn ".env 파일이 없습니다. 기본값을 사용합니다."
    fi
}

# 환경 변수 로드
load_env_variables

# DATABASE_URL 설정
setup_database_url() {
    log_info "데이터베이스 URL을 설정합니다..."
    
    if [ -z "$DATABASE_URL" ]; then
        # 환경 변수에서 DATABASE_URL 구성
        if [ -n "$POSTGRES_USER" ] && [ -n "$POSTGRES_PASSWORD" ] && [ -n "$POSTGRES_DB" ]; then
            DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
            export DATABASE_URL
            log_info "DATABASE_URL이 자동으로 설정되었습니다."
        else
            log_error "DATABASE_URL을 설정할 수 없습니다."
            log_info "필요한 환경 변수: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB"
            exit 1
        fi
    fi
    
    log_info "데이터베이스 URL: $DATABASE_URL"
}

# 데이터베이스 URL 설정
setup_database_url

# PostgreSQL 연결 확인
check_postgres_connection() {
    log_header "=== PostgreSQL 연결 확인 ==="
    
    log_info "PostgreSQL 연결을 확인합니다..."
    
    # Docker 컨테이너에서 PostgreSQL 연결 확인
    if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-mincenter} > /dev/null 2>&1; then
        log_info "PostgreSQL 연결 성공!"
    else
        log_error "PostgreSQL 연결 실패!"
        log_info "PostgreSQL 컨테이너 상태를 확인하세요."
        docker-compose -f docker-compose.prod.yml ps postgres
        exit 1
    fi
}

# PostgreSQL 연결 확인
check_postgres_connection

# API 디렉토리로 이동
log_info "API 디렉토리로 이동합니다..."
cd backends/api

# sqlx-cli 설치 확인
check_sqlx_installation() {
    log_header "=== sqlx-cli 설치 확인 ==="
    
    if ! command -v sqlx &> /dev/null; then
        log_warn "sqlx-cli가 설치되지 않았습니다. 설치를 시작합니다..."
        cargo install sqlx-cli --no-default-features --features postgres
        log_info "sqlx-cli 설치 완료!"
    else
        log_info "sqlx-cli가 이미 설치되어 있습니다."
    fi
}

# sqlx-cli 설치 확인
check_sqlx_installation

# 마이그레이션 상태 확인
log_header "=== 마이그레이션 상태 확인 ==="

log_info "현재 마이그레이션 상태 확인..."
if sqlx migrate info; then
    log_info "마이그레이션 정보 확인 성공!"
else
    log_error "마이그레이션 정보 확인 실패!"
    exit 1
fi

# 마이그레이션 실행
log_header "=== 마이그레이션 실행 ==="

log_info "마이그레이션 실행 중..."
if sqlx migrate run; then
    log_info "✅ 마이그레이션이 성공적으로 완료되었습니다."
else
    log_error "❌ 마이그레이션 실행 실패!"
    exit 1
fi

# 마이그레이션 후 상태 확인
log_header "=== 마이그레이션 후 상태 확인 ==="

log_info "최종 마이그레이션 상태:"
if sqlx migrate info; then
    log_info "마이그레이션 상태 확인 완료!"
else
    log_warn "마이그레이션 상태 확인 실패!"
fi

# 원래 디렉토리로 복귀
cd ../..

log_header "=== 데이터베이스 마이그레이션 완료 ==="
log_info "모든 마이그레이션이 성공적으로 완료되었습니다!" 