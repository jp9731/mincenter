#!/bin/bash

# 마이그레이션 오류 해결 스크립트
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
    echo -e "${BLUE}[FIX MIGRATION]${NC} $1"
}

# 환경 변수 로드
load_env_variables() {
    log_info "환경 변수를 로드합니다..."
    
    if [ -f ".env" ]; then
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                var_name=$(echo "$line" | cut -d'=' -f1)
                var_value=$(echo "$line" | cut -d'=' -f2-)
                
                if [[ "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    export "$var_name=$var_value"
                fi
            fi
        done < .env
    fi
}

# DATABASE_URL 설정
setup_database_url() {
    if [ -z "$DATABASE_URL" ]; then
        if [ -n "$POSTGRES_USER" ] && [ -n "$POSTGRES_PASSWORD" ] && [ -n "$POSTGRES_DB" ]; then
            DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
            export DATABASE_URL
        fi
    fi
}

# 현재 데이터베이스 상태 확인
check_database_state() {
    log_header "=== 데이터베이스 상태 확인 ==="
    
    log_info "현재 데이터베이스 상태를 확인합니다..."
    
    cd backends/api
    
    # 마이그레이션 상태 확인
    log_info "마이그레이션 상태:"
    sqlx migrate info || true
    
    # 데이터베이스에 직접 접속하여 상태 확인
    log_info "데이터베이스 객체 확인:"
    
    # user_role 타입 확인
    if sqlx database execute "SELECT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'user_role');" 2>/dev/null; then
        log_warn "user_role 타입이 이미 존재합니다."
    fi
    
    # 테이블 목록 확인
    log_info "현재 테이블 목록:"
    sqlx database execute "SELECT tablename FROM pg_tables WHERE schemaname = 'public';" 2>/dev/null || true
    
    cd ../..
}

# 마이그레이션 초기화
reset_migration() {
    log_header "=== 마이그레이션 초기화 ==="
    
    log_warn "⚠️  주의: 이 작업은 모든 마이그레이션 기록을 초기화합니다!"
    log_warn "데이터베이스 스키마는 유지되지만 마이그레이션 상태가 리셋됩니다."
    
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "마이그레이션 초기화가 취소되었습니다."
        return
    fi
    
    cd backends/api
    
    log_info "마이그레이션 테이블 삭제 중..."
    sqlx database execute "DROP TABLE IF EXISTS _sqlx_migrations;" 2>/dev/null || true
    
    log_info "마이그레이션 테이블 재생성 중..."
    sqlx migrate info
    
    cd ../..
}

# 조건부 마이그레이션 실행
conditional_migration() {
    log_header "=== 조건부 마이그레이션 실행 ==="
    
    cd backends/api
    
    log_info "마이그레이션을 다시 실행합니다..."
    
    # 각 마이그레이션 파일을 개별적으로 실행
    for migration_file in migrations/*.sql; do
        if [ -f "$migration_file" ]; then
            migration_name=$(basename "$migration_file" .sql)
            log_info "마이그레이션 실행: $migration_name"
            
            # 마이그레이션 내용 확인
            log_info "마이그레이션 내용:"
            head -5 "$migration_file"
            
            # 조건부 실행
            if sqlx migrate run --source .; then
                log_info "✅ $migration_name 성공!"
            else
                log_warn "⚠️ $migration_name 실패 (이미 적용됨)"
            fi
        fi
    done
    
    cd ../..
}

# 수동 마이그레이션 적용
manual_migration() {
    log_header "=== 수동 마이그레이션 적용 ==="
    
    log_warn "⚠️  주의: 이 작업은 데이터베이스를 직접 수정합니다!"
    
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "수동 마이그레이션이 취소되었습니다."
        return
    fi
    
    cd backends/api
    
    log_info "수동으로 마이그레이션을 적용합니다..."
    
    # 마이그레이션 테이블 생성 (없는 경우)
    sqlx database execute "
        CREATE TABLE IF NOT EXISTS _sqlx_migrations (
            version bigint PRIMARY KEY,
            description text NOT NULL,
            installed_on timestamp with time zone NOT NULL DEFAULT now(),
            success boolean NOT NULL
        );
    " 2>/dev/null || true
    
    # 각 마이그레이션을 수동으로 적용
    for migration_file in migrations/*.sql; do
        if [ -f "$migration_file" ]; then
            migration_name=$(basename "$migration_file" .sql)
            version=$(echo "$migration_name" | cut -d'_' -f1)
            description=$(echo "$migration_name" | cut -d'_' -f2-)
            
            log_info "수동 마이그레이션: $migration_name"
            
            # 이미 적용되었는지 확인
            if sqlx database execute "SELECT 1 FROM _sqlx_migrations WHERE version = $version;" 2>/dev/null | grep -q "1"; then
                log_info "이미 적용됨: $migration_name"
            else
                # 마이그레이션 실행
                if sqlx database execute "$(cat $migration_file)"; then
                    # 성공 기록
                    sqlx database execute "INSERT INTO _sqlx_migrations (version, description, success) VALUES ($version, '$description', true);"
                    log_info "✅ $migration_name 수동 적용 성공!"
                else
                    log_error "❌ $migration_name 수동 적용 실패!"
                fi
            fi
        fi
    done
    
    cd ../..
}

# 마이그레이션 상태 확인
verify_migration() {
    log_header "=== 마이그레이션 상태 확인 ==="
    
    cd backends/api
    
    log_info "최종 마이그레이션 상태:"
    sqlx migrate info
    
    log_info "데이터베이스 테이블 확인:"
    sqlx database execute "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" 2>/dev/null || true
    
    cd ../..
}

# 메인 실행
main() {
    log_info "마이그레이션 오류 해결을 시작합니다..."
    
    # 환경 변수 로드
    load_env_variables
    setup_database_url
    
    # 현재 상태 확인
    check_database_state
    
    # 사용자 선택
    echo ""
    log_warn "해결 방법을 선택하세요:"
    echo "1. 마이그레이션 초기화 (권장)"
    echo "2. 조건부 마이그레이션 실행"
    echo "3. 수동 마이그레이션 적용"
    echo "4. 취소"
    
    read -p "선택 (1-4): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            reset_migration
            conditional_migration
            ;;
        2)
            conditional_migration
            ;;
        3)
            manual_migration
            ;;
        4)
            log_info "작업이 취소되었습니다."
            exit 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
    
    # 마이그레이션 상태 확인
    verify_migration
    
    log_info "마이그레이션 오류 해결이 완료되었습니다!"
}

# 스크립트 실행
main 