#!/bin/bash

# API 서비스 관리 스크립트
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
    echo -e "${BLUE}[API SERVICE]${NC} $1"
}

# API 프로세스 찾기
find_api_process() {
    pgrep -f "mincenter-api" || echo ""
}

# API 상태 확인
check_api_status() {
    log_header "=== API 상태 확인 ==="
    
    API_PID=$(find_api_process)
    
    if [ -n "$API_PID" ]; then
        log_info "API 프로세스: ✅ 실행 중 (PID: $API_PID)"
        
        # API 헬스체크
        API_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/api/health || echo '000')
        if [ "$API_STATUS" = "200" ]; then
            log_info "API 헬스체크: ✅ 정상 ($API_STATUS)"
        else
            log_warn "API 헬스체크: ⚠️ 비정상 ($API_STATUS)"
        fi
        
        # 프로세스 정보
        ps -p $API_PID -o pid,ppid,cmd,etime
    else
        log_error "API 프로세스: ❌ 실행되지 않음"
        return 1
    fi
}

# API 시작
start_api() {
    log_header "=== API 시작 ==="
    
    # 이미 실행 중인지 확인
    if [ -n "$(find_api_process)" ]; then
        log_warn "API가 이미 실행 중입니다."
        return 0
    fi
    
    # API 디렉토리로 이동
    cd backends/api
    
    # 환경변수 설정
    export DATABASE_URL="postgresql://${POSTGRES_USER:-postgres}:${POSTGRES_PASSWORD:-password}@localhost:15432/${POSTGRES_DB:-mincenter}"
    export REDIS_URL="redis://:${REDIS_PASSWORD:-tnekwoddl}@localhost:6379"
    export JWT_SECRET="${JWT_SECRET:-default_jwt_secret}"
    export RUST_LOG="${RUST_LOG_LEVEL:-info}"
    
    # 빌드 확인
    if [ ! -f "target/release/mincenter-api" ]; then
        log_info "API 바이너리가 없습니다. 빌드를 시작합니다..."
        cargo build --release || {
            log_error "API 빌드 실패"
            return 1
        }
    fi
    
    # API 시작
    log_info "API 프로세스 시작 중..."
    nohup ./target/release/mincenter-api > api.log 2>&1 &
    API_PID=$!
    
    # 시작 확인
    sleep 3
    if kill -0 $API_PID 2>/dev/null; then
        log_info "✅ API 시작 완료 (PID: $API_PID)"
    else
        log_error "❌ API 시작 실패"
        return 1
    fi
    
    # 원래 디렉토리로 복귀
    cd ../..
}

# API 중지
stop_api() {
    log_header "=== API 중지 ==="
    
    API_PID=$(find_api_process)
    
    if [ -n "$API_PID" ]; then
        log_info "API 프로세스 중지 중... (PID: $API_PID)"
        kill $API_PID
        
        # 중지 확인
        sleep 2
        if kill -0 $API_PID 2>/dev/null; then
            log_warn "프로세스가 종료되지 않았습니다. 강제 종료합니다..."
            kill -9 $API_PID
        fi
        
        log_info "✅ API 중지 완료"
    else
        log_warn "실행 중인 API 프로세스가 없습니다."
    fi
}

# API 재시작
restart_api() {
    log_header "=== API 재시작 ==="
    
    stop_api
    sleep 2
    start_api
}

# API 로그 확인
show_logs() {
    log_header "=== API 로그 ==="
    
    if [ -f "backends/api/api.log" ]; then
        tail -f backends/api/api.log
    else
        log_error "API 로그 파일을 찾을 수 없습니다."
    fi
}

# 메인 실행
main() {
    case "${1:-status}" in
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
            check_api_status
            ;;
        logs)
            show_logs
            ;;
        *)
            echo "사용법: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "명령어:"
            echo "  start   - API 시작"
            echo "  stop    - API 중지"
            echo "  restart - API 재시작"
            echo "  status  - API 상태 확인"
            echo "  logs    - API 로그 확인"
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 