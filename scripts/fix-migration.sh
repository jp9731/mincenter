#!/bin/bash

# 마이그레이션 오류 해결 스크립트 (납품 시 비활성화)
# PostgreSQL에서 마이그레이션 실행 시 발생하는 오류들을 해결

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

# 환경 변수 로드 (안전한 방식)
load_env() {
    log_info "환경 변수 로드 중..."
    
    if [ -f ".env" ]; then
        log_info ".env 파일에서 환경 변수 로드"
        # 안전한 환경 변수 로드
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                var_name=$(echo "$line" | cut -d'=' -f1)
                var_value=$(echo "$line" | cut -d'=' -f2-)
                
                if [[ "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    export "$var_name=$var_value"
                fi
            fi
        done < .env
    elif [ -f "backends/api/.env" ]; then
        log_info "backends/api/.env 파일에서 환경 변수 로드"
        # 안전한 환경 변수 로드
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^[[:space:]]*# ]] && [[ -n "$line" ]]; then
                var_name=$(echo "$line" | cut -d'=' -f1)
                var_value=$(echo "$line" | cut -d'=' -f2-)
                
                if [[ "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    export "$var_name=$var_value"
                fi
            fi
        done < backends/api/.env
    else
        log_warning "환경 변수 파일을 찾을 수 없습니다. 기본값 사용"
        # 기본값 설정
        export DATABASE_URL="postgresql://postgres:password@localhost:5432/mincenter"
    fi
    
    log_success "환경 변수 로드 완료"
}

# 데이터베이스 연결 테스트
test_db_connection() {
    log_info "데이터베이스 연결 테스트 중..."
    
    if command -v psql &> /dev/null; then
        if psql "$DATABASE_URL" -c "SELECT 1;" &> /dev/null; then
            log_success "데이터베이스 연결 성공"
            return 0
        else
            log_error "데이터베이스 연결 실패"
            return 1
        fi
    else
        log_warning "psql 명령어를 찾을 수 없습니다. Docker 컨테이너를 통해 연결을 시도합니다."
        return 0
    fi
}

# 기존 타입 및 객체 정리
cleanup_existing_objects() {
    log_info "기존 타입 및 객체 정리 중..."
    
    # Docker를 통한 실행
    if docker ps | grep -q postgres; then
        log_info "Docker 컨테이너를 통해 정리 실행"
        
        # 기존 타입들 삭제 (안전하게)
        docker exec -i $(docker ps -q --filter "name=postgres") psql "$DATABASE_URL" << 'EOF'
-- 기존 타입들 삭제 (존재하는 경우에만)
DO $$ 
BEGIN
    -- user_role 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        DROP TYPE user_role CASCADE;
    END IF;
    
    -- user_status 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status') THEN
        DROP TYPE user_status CASCADE;
    END IF;
    
    -- post_status 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'post_status') THEN
        DROP TYPE post_status CASCADE;
    END IF;
    
    -- file_type 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_type') THEN
        DROP TYPE file_type CASCADE;
    END IF;
    
    -- file_status 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_status') THEN
        DROP TYPE file_status CASCADE;
    END IF;
    
    -- processing_status 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'processing_status') THEN
        DROP TYPE processing_status CASCADE;
    END IF;
    
    -- entity_type 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entity_type') THEN
        DROP TYPE entity_type CASCADE;
    END IF;
    
    -- file_purpose 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'file_purpose') THEN
        DROP TYPE file_purpose CASCADE;
    END IF;
    
    -- notification_type 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        DROP TYPE notification_type CASCADE;
    END IF;
    
    -- menu_type 타입 삭제
    IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'menu_type') THEN
        DROP TYPE menu_type CASCADE;
    END IF;
    
    RAISE NOTICE '기존 타입들 정리 완료';
END $$;
EOF
        
        log_success "기존 타입 및 객체 정리 완료"
    else
        log_warning "PostgreSQL Docker 컨테이너를 찾을 수 없습니다. 수동으로 정리해주세요."
    fi
}

# 마이그레이션 초기화
reset_migrations() {
    log_info "마이그레이션 초기화 중..."
    
    if [ -d "backends/api" ]; then
        cd backends/api
        
        # 마이그레이션 초기화
        if command -v sqlx &> /dev/null; then
            log_info "sqlx migrate reset 실행"
            sqlx migrate reset --database-url "$DATABASE_URL" --yes
        else
            log_warning "sqlx 명령어를 찾을 수 없습니다. Docker를 통해 실행합니다."
            
            # Docker를 통한 마이그레이션 초기화
            docker run --rm \
                -v "$(pwd)/migrations:/migrations" \
                -e DATABASE_URL="$DATABASE_URL" \
                --network host \
                ghcr.io/launchbadge/sqlx-cli:latest \
                migrate reset --database-url "$DATABASE_URL" --yes
        fi
        
        cd ../..
        log_success "마이그레이션 초기화 완료"
    else
        log_error "backends/api 디렉토리를 찾을 수 없습니다."
        exit 1
    fi
}

# 마이그레이션 실행
run_migrations() {
    log_info "마이그레이션 실행 중..."
    
    if [ -d "backends/api" ]; then
        cd backends/api
        
        # 마이그레이션 실행
        if command -v sqlx &> /dev/null; then
            log_info "sqlx migrate run 실행"
            sqlx migrate run --database-url "$DATABASE_URL"
        else
            log_warning "sqlx 명령어를 찾을 수 없습니다. Docker를 통해 실행합니다."
            
            # Docker를 통한 마이그레이션 실행
            docker run --rm \
                -v "$(pwd)/migrations:/migrations" \
                -e DATABASE_URL="$DATABASE_URL" \
                --network host \
                ghcr.io/launchbadge/sqlx-cli:latest \
                migrate run --database-url "$DATABASE_URL"
        fi
        
        cd ../..
        log_success "마이그레이션 실행 완료"
    else
        log_error "backends/api 디렉토리를 찾을 수 없습니다."
        exit 1
    fi
}

# 조건부 마이그레이션 실행 (안전한 방식)
run_safe_migrations() {
    log_info "안전한 마이그레이션 실행 중..."
    
    if [ -d "backends/api" ]; then
        cd backends/api
        
        # 각 마이그레이션 파일을 개별적으로 실행
        for migration_file in migrations/*.sql; do
            if [ -f "$migration_file" ]; then
                log_info "마이그레이션 파일 실행: $(basename "$migration_file")"
                
                # Docker를 통한 개별 마이그레이션 실행
                if docker ps | grep -q postgres; then
                    docker exec -i $(docker ps -q --filter "name=postgres") psql "$DATABASE_URL" < "$migration_file"
                    log_success "$(basename "$migration_file") 실행 완료"
                else
                    log_error "PostgreSQL Docker 컨테이너를 찾을 수 없습니다."
                    exit 1
                fi
            fi
        done
        
        cd ../..
        log_success "안전한 마이그레이션 실행 완료"
    else
        log_error "backends/api 디렉토리를 찾을 수 없습니다."
        exit 1
    fi
}

# 마이그레이션 상태 확인
check_migration_status() {
    log_info "마이그레이션 상태 확인 중..."
    
    if [ -d "backends/api" ]; then
        cd backends/api
        
        # 마이그레이션 상태 확인
        if command -v sqlx &> /dev/null; then
            log_info "sqlx migrate info 실행"
            sqlx migrate info --database-url "$DATABASE_URL"
        else
            log_warning "sqlx 명령어를 찾을 수 없습니다. Docker를 통해 확인합니다."
            
            # Docker를 통한 마이그레이션 상태 확인
            docker run --rm \
                -v "$(pwd)/migrations:/migrations" \
                -e DATABASE_URL="$DATABASE_URL" \
                --network host \
                ghcr.io/launchbadge/sqlx-cli:latest \
                migrate info --database-url "$DATABASE_URL"
        fi
        
        cd ../..
    else
        log_error "backends/api 디렉토리를 찾을 수 없습니다."
        exit 1
    fi
}

# 메인 실행 함수
main() {
    log_info "=== 마이그레이션 오류 해결 스크립트 (비활성화) ==="
    
    log_warning "⚠️  이 스크립트는 납품을 위해 비활성화되었습니다."
    log_info "데이터베이스 스키마 변경사항은 수동으로 적용하세요."
    log_info "필요한 경우 직접 DB에 접속하여 변경사항을 적용하시기 바랍니다."
    
    log_success "=== 마이그레이션 스크립트 종료 ==="
    log_info "납품 시 수동으로 DB 스키마를 관리하세요."
}

# 스크립트 실행
main "$@" 