#!/bin/bash

# MinSchool 하이브리드 배포 스크립트
# Frontend, PostgreSQL, Redis는 Docker로 실행
# API는 로컬에서 빌드한 바이너리로 실행

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

# 환경변수 설정
export APP_NAME=mincenter
export POSTGRES_DB=mincenter
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=password
export REDIS_PASSWORD=default_password
export REDIS_PORT=16379
export API_URL=http://api.mincenter.kr
export DOMAIN=mincenter.kr
export HTTP_PORT=80
export HTTPS_PORT=443

# API 바이너리 경로
API_BINARY="build/centos7/minshool-api"

# 함수: API 바이너리 확인
check_api_binary() {
    if [ ! -f "$API_BINARY" ]; then
        log_error "API 바이너리가 없습니다: $API_BINARY"
        log_info "다음 명령어로 바이너리를 빌드하세요:"
        log_info "  ./scripts/build-centos7.sh"
        exit 1
    fi
    log_success "API 바이너리 확인됨: $API_BINARY"
}

# 함수: Docker 설치 확인
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker가 설치되지 않았습니다."
        log_info "Docker를 설치한 후 다시 시도하세요."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose가 설치되지 않았습니다."
        log_info "Docker Compose를 설치한 후 다시 시도하세요."
        exit 1
    fi
    
    log_success "Docker 및 Docker Compose 확인됨"
}

# 함수: 기존 서비스 정리
cleanup_services() {
    log_info "기존 서비스 정리 중..."
    
    # API 프로세스 종료
    pkill -f minshool-api || true
    sleep 2
    
    # Docker 서비스 정리
    docker-compose -f docker-compose.hybrid.yml down || true
    
    log_success "기존 서비스 정리 완료"
}

# 함수: API 서버 시작
start_api_server() {
    log_info "API 서버 시작 중..."
    
    # 바이너리 권한 설정
    chmod +x "$API_BINARY"
    
    # API 서버 백그라운드 실행
    nohup "$API_BINARY" > /tmp/minshool-api.log 2>&1 &
    API_PID=$!
    
    # PID 저장
    echo $API_PID > /tmp/minshool-api.pid
    
    # 서버 시작 대기
    sleep 5
    
    # 헬스체크
    if curl -f http://localhost:18080/health > /dev/null 2>&1; then
        log_success "API 서버 시작 완료 (PID: $API_PID)"
    else
        log_error "API 서버 시작 실패"
        cat /tmp/minshool-api.log
        exit 1
    fi
}

# 함수: Docker 서비스 시작
start_docker_services() {
    log_info "Docker 서비스 시작 중..."
    
    # Docker Compose로 서비스 시작
    docker-compose -f docker-compose.hybrid.yml up -d --build
    
    # 서비스 시작 대기
    sleep 10
    
    # 헬스체크
    log_info "서비스 헬스체크 중..."
    
    # PostgreSQL 헬스체크
    if docker exec ${APP_NAME}_postgres pg_isready -U postgres > /dev/null 2>&1; then
        log_success "PostgreSQL 시작 완료"
    else
        log_error "PostgreSQL 시작 실패"
        exit 1
    fi
    
    # Redis 헬스체크
    if docker exec ${APP_NAME}_redis redis-cli --raw incr ping > /dev/null 2>&1; then
        log_success "Redis 시작 완료"
    else
        log_error "Redis 시작 실패"
        exit 1
    fi
    
    # Site 헬스체크
    if curl -f http://localhost:13000/ > /dev/null 2>&1; then
        log_success "Site 서비스 시작 완료"
    else
        log_error "Site 서비스 시작 실패"
        exit 1
    fi
    
    # Admin 헬스체크
    if curl -f http://localhost:13001/ > /dev/null 2>&1; then
        log_success "Admin 서비스 시작 완료"
    else
        log_error "Admin 서비스 시작 실패"
        exit 1
    fi
    
    log_success "모든 Docker 서비스 시작 완료"
}

# 함수: 서비스 상태 확인
check_services() {
    log_info "서비스 상태 확인 중..."
    
    echo "=== API 서버 상태 ==="
    if [ -f /tmp/minshool-api.pid ]; then
        API_PID=$(cat /tmp/minshool-api.pid)
        if ps -p $API_PID > /dev/null; then
            log_success "API 서버 실행 중 (PID: $API_PID)"
        else
            log_error "API 서버가 실행되지 않음"
        fi
    else
        log_error "API 서버 PID 파일이 없음"
    fi
    
    echo "=== Docker 컨테이너 상태 ==="
    docker-compose -f docker-compose.hybrid.yml ps
    
    echo "=== 포트 사용 현황 ==="
    netstat -tlnp | grep -E ':(80|443|13000|13001|15432|16379|18080)' || true
}

# 함수: 서비스 중지
stop_services() {
    log_info "서비스 중지 중..."
    
    # API 서버 중지
    if [ -f /tmp/minshool-api.pid ]; then
        API_PID=$(cat /tmp/minshool-api.pid)
        kill $API_PID 2>/dev/null || true
        rm -f /tmp/minshool-api.pid
        log_success "API 서버 중지됨"
    fi
    
    # Docker 서비스 중지
    docker-compose -f docker-compose.hybrid.yml down
    log_success "Docker 서비스 중지됨"
}

# 메인 함수
main() {
    case "${1:-start}" in
        "start")
            log_info "MinSchool 하이브리드 배포 시작"
            check_api_binary
            check_docker
            cleanup_services
            start_api_server
            start_docker_services
            check_services
            log_success "배포 완료!"
            log_info "사이트: http://localhost"
            log_info "관리자: http://localhost/admin"
            log_info "API: http://localhost:18080"
            ;;
        "stop")
            log_info "서비스 중지"
            stop_services
            log_success "모든 서비스가 중지되었습니다."
            ;;
        "restart")
            log_info "서비스 재시작"
            stop_services
            sleep 2
            check_api_binary
            check_docker
            start_api_server
            start_docker_services
            check_services
            log_success "재시작 완료!"
            ;;
        "status")
            check_services
            ;;
        "logs")
            log_info "로그 확인"
            echo "=== API 서버 로그 ==="
            tail -f /tmp/minshool-api.log &
            echo "=== Docker 서비스 로그 ==="
            docker-compose -f docker-compose.hybrid.yml logs -f
            ;;
        *)
            echo "사용법: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "명령어:"
            echo "  start   - 서비스 시작 (기본값)"
            echo "  stop    - 서비스 중지"
            echo "  restart - 서비스 재시작"
            echo "  status  - 서비스 상태 확인"
            echo "  logs    - 로그 확인"
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 