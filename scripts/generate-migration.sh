#!/bin/bash

# 마이그레이션 파일 자동 생성 스크립트

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

# 사용법
usage() {
    echo "사용법: $0 <마이그레이션_번호> <설명>"
    echo ""
    echo "예시:"
    echo "  $0 001 '새로운 테이블 추가'"
    echo "  $0 002 'posts 테이블에 컬럼 추가'"
    echo "  $0 003 '인덱스 추가'"
    echo ""
    echo "결과: database/migrations/001_새로운_테이블_추가.sql"
}

# 마이그레이션 파일 생성
generate_migration() {
    local number=$1
    local description=$2
    local filename="database/migrations/${number}_${description// /_}.sql"
    
    # 디렉토리 생성
    mkdir -p database/migrations
    
    # 마이그레이션 파일 생성
    cat > "$filename" << EOF
-- 마이그레이션: ${number}_${description// /_}.sql
-- 설명: ${description}
-- 날짜: $(date +"%Y-%m-%d")
-- 작성자: $(whoami)

-- TODO: 여기에 SQL 명령어를 작성하세요
-- 예시:
-- CREATE TABLE IF NOT EXISTS new_table (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name VARCHAR(255) NOT NULL,
--     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- ALTER TABLE existing_table ADD COLUMN IF NOT EXISTS new_column VARCHAR(255);

-- CREATE INDEX IF NOT EXISTS idx_table_column ON table_name(column_name);

-- UPDATE table_name SET column_name = 'default_value' WHERE column_name IS NULL;

-- COMMENT ON TABLE table_name IS '테이블 설명';
-- COMMENT ON COLUMN table_name.column_name IS '컬럼 설명';

EOF
    
    log_success "마이그레이션 파일 생성됨: $filename"
    log_info "이제 $filename 파일을 편집하여 SQL 명령어를 작성하세요."
}

# 메인 로직
main() {
    if [ $# -lt 2 ]; then
        usage
        exit 1
    fi
    
    local number=$1
    shift
    local description="$*"
    
    log_info "마이그레이션 파일 생성 중..."
    log_info "번호: $number"
    log_info "설명: $description"
    
    generate_migration "$number" "$description"
}

# 스크립트 실행
main "$@" 