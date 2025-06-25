#!/bin/bash

# PostgreSQL 컨테이너 진단 스크립트
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
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 컨테이너 상태 확인
check_container_status() {
    log_header "=== 컨테이너 상태 확인 ==="
    
    log_info "모든 컨테이너 상태:"
    docker-compose -f docker-compose.prod.yml ps
    
    echo ""
    log_info "PostgreSQL 컨테이너 상세 정보:"
    docker-compose -f docker-compose.prod.yml ps postgres
    
    echo ""
    log_info "PostgreSQL 컨테이너 로그 (최근 50줄):"
    docker-compose -f docker-compose.prod.yml logs --tail=50 postgres
}

# PostgreSQL 설정 확인
check_postgres_config() {
    log_header "=== PostgreSQL 설정 확인 ==="
    
    log_info "postgresql.conf 파일 존재 확인:"
    if [ -f "./database/postgresql.conf" ]; then
        log_info "postgresql.conf 파일이 존재합니다."
        echo "파일 크기: $(ls -lh ./database/postgresql.conf | awk '{print $5}')"
    else
        log_error "postgresql.conf 파일이 없습니다!"
        log_info "기본 설정 파일을 생성합니다..."
        create_default_postgres_config
    fi
    
    echo ""
    log_info "환경 변수 확인:"
    echo "POSTGRES_DB: ${POSTGRES_DB:-mincenter}"
    echo "POSTGRES_USER: ${POSTGRES_USER:-postgres}"
    echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-password}"
}

# 기본 PostgreSQL 설정 파일 생성
create_default_postgres_config() {
    log_info "기본 PostgreSQL 설정 파일을 생성합니다..."
    
    mkdir -p ./database
    
    cat > ./database/postgresql.conf << 'EOF'
# PostgreSQL 기본 설정 (CentOS 7 호환)

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

# 자동 vacuum 설정
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min

# 한국어 설정
lc_messages = 'ko_KR.UTF-8'
lc_monetary = 'ko_KR.UTF-8'
lc_numeric = 'ko_KR.UTF-8'
lc_time = 'ko_KR.UTF-8'

# 기타 설정
datestyle = 'iso, dmy'
timezone = 'Asia/Seoul'
default_text_search_config = 'pg_catalog.korean'
EOF
    
    log_info "postgresql.conf 파일이 생성되었습니다."
}

# PostgreSQL 컨테이너 재시작
restart_postgres() {
    log_header "=== PostgreSQL 컨테이너 재시작 ==="
    
    log_info "PostgreSQL 컨테이너 중지..."
    docker-compose -f docker-compose.prod.yml stop postgres
    
    log_info "PostgreSQL 컨테이너 삭제..."
    docker-compose -f docker-compose.prod.yml rm -f postgres
    
    log_info "PostgreSQL 볼륨 확인..."
    docker volume ls | grep postgres
    
    log_info "PostgreSQL 컨테이너 시작..."
    docker-compose -f docker-compose.prod.yml up -d postgres
    
    log_info "PostgreSQL 시작 대기 중..."
    sleep 10
    
    log_info "PostgreSQL 컨테이너 상태 확인:"
    docker-compose -f docker-compose.prod.yml ps postgres
}

# PostgreSQL 연결 테스트
test_postgres_connection() {
    log_header "=== PostgreSQL 연결 테스트 ==="
    
    log_info "PostgreSQL 컨테이너 내부에서 연결 테스트..."
    docker-compose -f docker-compose.prod.yml exec postgres pg_isready -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-mincenter}
    
    if [ $? -eq 0 ]; then
        log_info "PostgreSQL 연결 성공!"
        
        echo ""
        log_info "데이터베이스 목록:"
        docker-compose -f docker-compose.prod.yml exec postgres psql -U ${POSTGRES_USER:-postgres} -c "\l"
        
        echo ""
        log_info "테이블 목록:"
        docker-compose -f docker-compose.prod.yml exec postgres psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-mincenter} -c "\dt"
    else
        log_error "PostgreSQL 연결 실패!"
    fi
}

# 포트 확인
check_ports() {
    log_header "=== 포트 확인 ==="
    
    log_info "5432 포트 사용 현황:"
    netstat -tulpn | grep :5432 || echo "5432 포트가 사용되지 않음"
    
    log_info "Docker 네트워크 확인:"
    docker network ls
    docker network inspect minc_int 2>/dev/null || echo "minc_int 네트워크가 없음"
}

# 메인 실행
main() {
    log_info "PostgreSQL 컨테이너 진단을 시작합니다..."
    
    # 환경 변수 로드
    if [ -f ".env" ]; then
        source .env
    fi
    
    # 컨테이너 상태 확인
    check_container_status
    
    # PostgreSQL 설정 확인
    check_postgres_config
    
    # 포트 확인
    check_ports
    
    # 사용자 선택
    echo ""
    log_warn "다음 중 선택하세요:"
    echo "1. PostgreSQL 컨테이너 재시작"
    echo "2. 연결 테스트"
    echo "3. 취소"
    
    read -p "선택 (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            restart_postgres
            test_postgres_connection
            ;;
        2)
            test_postgres_connection
            ;;
        3)
            log_info "진단이 취소되었습니다."
            exit 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
    
    log_info "PostgreSQL 진단이 완료되었습니다!"
}

# 스크립트 실행
main 