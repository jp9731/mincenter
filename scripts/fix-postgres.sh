#!/bin/bash

# PostgreSQL 설정 오류 해결 스크립트
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
    echo -e "${BLUE}[FIX]${NC} $1"
}

# PostgreSQL 컨테이너 중지
stop_postgres() {
    log_header "=== PostgreSQL 컨테이너 중지 ==="
    
    log_info "PostgreSQL 컨테이너 중지 중..."
    docker-compose -f docker-compose.prod.yml stop postgres
    
    log_info "PostgreSQL 컨테이너 삭제 중..."
    docker-compose -f docker-compose.prod.yml rm -f postgres
    
    log_info "PostgreSQL 컨테이너가 중지되었습니다."
}

# PostgreSQL 설정 파일 확인
check_postgres_config() {
    log_header "=== PostgreSQL 설정 파일 확인 ==="
    
    if [ -f "./database/postgresql.conf" ]; then
        log_info "postgresql.conf 파일이 존재합니다."
        log_info "파일 크기: $(ls -lh ./database/postgresql.conf | awk '{print $5}')"
        
        echo ""
        log_info "설정 파일 내용 확인 (처음 10줄):"
        head -10 ./database/postgresql.conf
    else
        log_error "postgresql.conf 파일이 없습니다!"
        create_postgres_config
    fi
}

# PostgreSQL 설정 파일 생성
create_postgres_config() {
    log_header "=== PostgreSQL 설정 파일 생성 ==="
    
    log_info "database 디렉토리 생성 중..."
    mkdir -p ./database
    
    log_info "PostgreSQL 13 호환 설정 파일 생성 중..."
    cat > ./database/postgresql.conf << 'EOF'
# PostgreSQL 기본 설정 (CentOS 7 + PostgreSQL 13 호환)

# 연결 설정
listen_addresses = '*'
port = 5432
max_connections = 100

# 메모리 설정
shared_buffers = 128MB
effective_cache_size = 512MB
work_mem = 4MB
maintenance_work_mem = 64MB

# 로그 설정
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# WAL 설정
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

# 체크포인트 설정
checkpoint_completion_target = 0.9
checkpoint_timeout = 5min

# 자동 vacuum 설정 (PostgreSQL 13 호환)
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.2
autovacuum_analyze_scale_factor = 0.1

# 한국어 설정
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'

# 기타 설정
datestyle = 'iso, dmy'
timezone = 'Asia/Seoul'

# 성능 최적화
random_page_cost = 1.1
effective_io_concurrency = 200
EOF
    
    log_info "postgresql.conf 파일이 생성되었습니다."
}

# PostgreSQL 컨테이너 시작
start_postgres() {
    log_header "=== PostgreSQL 컨테이너 시작 ==="
    
    log_info "PostgreSQL 컨테이너 시작 중..."
    docker-compose -f docker-compose.prod.yml up -d postgres
    
    log_info "PostgreSQL 시작 대기 중..."
    sleep 15
    
    log_info "PostgreSQL 컨테이너 상태 확인:"
    docker-compose -f docker-compose.prod.yml ps postgres
}

# PostgreSQL 연결 테스트
test_postgres_connection() {
    log_header "=== PostgreSQL 연결 테스트 ==="
    
    log_info "PostgreSQL 연결 테스트 중..."
    
    # 환경 변수 로드
    if [ -f ".env" ]; then
        source .env
    fi
    
    # 연결 테스트
    if docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U ${POSTGRES_USER:-postgres}; then
        log_info "PostgreSQL 연결 성공!"
        
        echo ""
        log_info "PostgreSQL 버전 확인:"
        docker-compose -f docker-compose.prod.yml exec postgres psql -U ${POSTGRES_USER:-postgres} -c "SELECT version();"
        
        echo ""
        log_info "데이터베이스 목록:"
        docker-compose -f docker-compose.prod.yml exec postgres psql -U ${POSTGRES_USER:-postgres} -c "\l"
    else
        log_error "PostgreSQL 연결 실패!"
        log_info "PostgreSQL 로그 확인:"
        docker-compose -f docker-compose.prod.yml logs postgres --tail=20
    fi
}

# PostgreSQL 로그 확인
check_postgres_logs() {
    log_header "=== PostgreSQL 로그 확인 ==="
    
    log_info "PostgreSQL 컨테이너 로그 (최근 20줄):"
    docker-compose -f docker-compose.prod.yml logs postgres --tail=20
}

# 메인 실행
main() {
    log_info "PostgreSQL 설정 오류 해결을 시작합니다..."
    
    # PostgreSQL 컨테이너 중지
    stop_postgres
    
    # PostgreSQL 설정 파일 확인 및 생성
    check_postgres_config
    
    # PostgreSQL 컨테이너 시작
    start_postgres
    
    # 잠시 대기
    sleep 5
    
    # PostgreSQL 로그 확인
    check_postgres_logs
    
    # PostgreSQL 연결 테스트
    test_postgres_connection
    
    log_info "PostgreSQL 설정 오류 해결이 완료되었습니다!"
}

# 스크립트 실행
main 