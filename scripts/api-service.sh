#!/bin/bash

# API 서비스 관리 스크립트
# start, stop, restart, status, logs 명령어 지원

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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# API 디렉토리
API_DIR="backends/api"
PID_FILE="$API_DIR/api.pid"
LOG_FILE="$API_DIR/api.log"
BINARY_FILE="$API_DIR/target/release/mincenter-api"

# 환경 변수 로드
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# API 프로세스 상태 확인
check_api_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0  # 실행 중
        else
            return 1  # PID 파일은 있지만 프로세스 없음
        fi
    else
        return 2  # PID 파일 없음
    fi
}

# API 서비스 시작
start_api() {
    log_info "API 서비스를 시작합니다..."
    
    if check_api_status; then
        log_warn "API 서비스가 이미 실행 중입니다."
        return 0
    fi
    
    # API 디렉토리로 이동
    cd "$API_DIR"
    
    # 바이너리 파일 확인
    if [ ! -f "$BINARY_FILE" ]; then
        log_info "API 바이너리가 없습니다. 빌드를 시작합니다..."
        cargo build --release
    fi
    
    # 환경 변수 확인
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL이 설정되지 않았습니다."
        exit 1
    fi
    
    # API 서버 시작
    log_info "API 서버를 시작합니다..."
    nohup ./target/release/mincenter-api > api.log 2>&1 &
    local pid=$!
    echo $pid > api.pid
    
    # 시작 확인
    sleep 3
    if ps -p "$pid" > /dev/null; then
        log_info "API 서비스가 성공적으로 시작되었습니다. (PID: $pid)"
    else
        log_error "API 서비스 시작에 실패했습니다."
        log_info "로그를 확인하세요: tail -f $LOG_FILE"
        exit 1
    fi
    
    cd ../..
}

# API 서비스 중지
stop_api() {
    log_info "API 서비스를 중지합니다..."
    
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null; then
            log_info "API 프로세스 (PID: $pid)를 종료합니다..."
            kill "$pid"
            
            # 종료 대기
            local count=0
            while ps -p "$pid" > /dev/null 2>&1 && [ $count -lt 10 ]; do
                sleep 1
                count=$((count + 1))
            done
            
            if ps -p "$pid" > /dev/null 2>&1; then
                log_warn "프로세스가 종료되지 않았습니다. 강제 종료합니다..."
                kill -9 "$pid"
            fi
            
            rm -f "$PID_FILE"
            log_info "API 서비스가 중지되었습니다."
        else
            log_warn "API 프로세스가 이미 종료되었습니다."
            rm -f "$PID_FILE"
        fi
    else
        log_warn "API 서비스가 실행 중이지 않습니다."
    fi
}

# API 서비스 재시작
restart_api() {
    log_info "API 서비스를 재시작합니다..."
    stop_api
    sleep 2
    start_api
}

# API 서비스 상태 확인
status_api() {
    log_info "API 서비스 상태를 확인합니다..."
    
    if check_api_status; then
        local pid=$(cat "$PID_FILE")
        log_info "API 서비스: 실행 중 (PID: $pid)"
        
        # 포트 확인
        if netstat -tlnp 2>/dev/null | grep -q ":18080 "; then
            log_info "포트 18080: 사용 중"
        else
            log_warn "포트 18080: 사용되지 않음"
        fi
        
        # 메모리 사용량
        local memory=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024 " MB"}')
        log_info "메모리 사용량: $memory"
        
        return 0
    else
        log_warn "API 서비스: 중지됨"
        return 1
    fi
}

# API 로그 확인
logs_api() {
    if [ -f "$LOG_FILE" ]; then
        if [ "$1" = "-f" ]; then
            log_info "API 로그를 실시간으로 확인합니다. (Ctrl+C로 종료)"
            tail -f "$LOG_FILE"
        else
            log_info "최근 API 로그:"
            tail -n 50 "$LOG_FILE"
        fi
    else
        log_warn "API 로그 파일이 없습니다."
    fi
}

# API 빌드
build_api() {
    log_info "API를 빌드합니다..."
    
    cd "$API_DIR"
    
    # 의존성 확인
    if ! command -v cargo &> /dev/null; then
        log_error "Rust가 설치되지 않았습니다."
        exit 1
    fi
    
    # 빌드 실행
    log_info "cargo build --release --bin mincenter-api 실행 중..."
    cargo build --release --bin mincenter-api
    
    if [ $? -eq 0 ]; then
        log_info "API 빌드가 완료되었습니다."
        log_info "바이너리 크기: $(du -h target/release/mincenter-api | cut -f1)"
    else
        log_error "API 빌드에 실패했습니다."
        exit 1
    fi
    
    cd ../..
}

# 사용법 출력
usage() {
    echo "API 서비스 관리 스크립트"
    echo ""
    echo "사용법: $0 {start|stop|restart|status|logs|build}"
    echo ""
    echo "명령어:"
    echo "  start   - API 서비스 시작"
    echo "  stop    - API 서비스 중지"
    echo "  restart - API 서비스 재시작"
    echo "  status  - API 서비스 상태 확인"
    echo "  logs    - API 로그 확인"
    echo "  logs -f - API 로그 실시간 확인"
    echo "  build   - API 빌드"
    echo ""
    echo "예시:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 logs -f"
}

# 메인 로직
case "$1" in
    start)
        start_api
        ;;
    stop)
        stop_api
        ;;
    restart)
        restart_api
        ;;
    status)
        status_api
        ;;
    logs)
        logs_api "$2"
        ;;
    build)
        build_api
        ;;
    *)
        usage
        exit 1
        ;;
esac

exit 0 