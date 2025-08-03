#!/bin/bash

# Docker Compose 관리 스크립트

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
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
COMPOSE_OVERRIDE="$ROOT_DIR/docker-compose.override.yml"

# 사용법
usage() {
    echo "사용법: $0 [command] [options]"
    echo ""
    echo "명령어:"
    echo "  status         - Docker Compose 상태 확인"
    echo "  start          - 서비스 시작"
    echo "  stop           - 서비스 중지"
    echo "  restart        - 서비스 재시작"
    echo "  build          - 이미지 빌드"
    echo "  logs <service> - 서비스 로그 확인"
    echo "  clean          - 사용하지 않는 리소스 정리"
    echo "  backup         - 현재 설정 백업"
    echo "  validate       - Docker Compose 파일 유효성 검사"
    echo ""
    echo "환경:"
    echo "  local          - 로컬 개발 환경 (override.yml 사용)"
    echo "  production     - 프로덕션 환경 (override.yml 무시)"
    echo ""
    echo "예시:"
    echo "  $0 status"
    echo "  $0 start local"
    echo "  $0 logs api"
    echo "  $0 clean"
}

# Docker Compose 상태 확인
check_status() {
    log_info "Docker Compose 상태 확인 중..."
    
    if [ -f "$COMPOSE_FILE" ]; then
        log_success "✅ docker-compose.yml 존재"
        echo "  크기: $(stat -f%z "$COMPOSE_FILE") bytes"
    else
        log_error "❌ docker-compose.yml 없음"
        return 1
    fi
    
    if [ -f "$COMPOSE_OVERRIDE" ]; then
        log_success "✅ docker-compose.override.yml 존재"
        echo "  크기: $(stat -f%z "$COMPOSE_OVERRIDE") bytes"
    else
        log_warning "⚠️  docker-compose.override.yml 없음"
    fi
    
    echo ""
    echo "🐳 컨테이너 상태:"
    cd "$ROOT_DIR"
    docker compose ps
    
    echo ""
    echo "📊 리소스 사용량:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
}

# 서비스 시작
start_services() {
    local env=${1:-"local"}
    
    log_info "Docker Compose 서비스 시작 중... (환경: $env)"
    
    cd "$ROOT_DIR"
    
    case $env in
        "local")
            # 로컬 개발 환경 (override.yml 자동 적용)
            docker compose up -d
            ;;
        "production")
            # 프로덕션 환경 (override.yml 무시)
            docker compose -f docker-compose.yml up -d
            ;;
        *)
            log_error "지원하지 않는 환경: $env"
            return 1
            ;;
    esac
    
    log_success "서비스 시작 완료!"
    
    # 상태 확인
    sleep 5
    docker compose ps
}

# 서비스 중지
stop_services() {
    log_info "Docker Compose 서비스 중지 중..."
    
    cd "$ROOT_DIR"
    docker compose down
    
    log_success "서비스 중지 완료!"
}

# 서비스 재시작
restart_services() {
    local env=${1:-"local"}
    
    log_info "Docker Compose 서비스 재시작 중... (환경: $env)"
    
    stop_services
    start_services "$env"
}

# 이미지 빌드
build_images() {
    local env=${1:-"local"}
    
    log_info "Docker 이미지 빌드 중... (환경: $env)"
    
    cd "$ROOT_DIR"
    
    case $env in
        "local")
            docker compose build --no-cache
            ;;
        "production")
            docker compose -f docker-compose.yml build --no-cache
            ;;
        *)
            log_error "지원하지 않는 환경: $env"
            return 1
            ;;
    esac
    
    log_success "이미지 빌드 완료!"
}

# 서비스 로그 확인
show_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        log_error "서비스명을 지정해주세요."
        log_info "사용 가능한 서비스: postgres, redis, api, site, admin"
        return 1
    fi
    
    log_info "$service 서비스 로그 확인 중..."
    
    cd "$ROOT_DIR"
    docker compose logs -f "$service"
}

# 사용하지 않는 리소스 정리
clean_resources() {
    log_warning "사용하지 않는 Docker 리소스 정리 중..."
    
    # 중지된 컨테이너 삭제
    docker container prune -f
    
    # 사용하지 않는 이미지 삭제
    docker image prune -f
    
    # 사용하지 않는 볼륨 삭제
    docker volume prune -f
    
    # 사용하지 않는 네트워크 삭제
    docker network prune -f
    
    log_success "리소스 정리 완료!"
}

# 현재 설정 백업
backup_config() {
    log_info "Docker Compose 설정 백업 중..."
    
    local backup_dir="$ROOT_DIR/docker-compose-backup"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    mkdir -p "$backup_dir"
    
    # 현재 설정 백업
    cp "$COMPOSE_FILE" "$backup_dir/docker-compose.yml.backup_$timestamp"
    
    if [ -f "$COMPOSE_OVERRIDE" ]; then
        cp "$COMPOSE_OVERRIDE" "$backup_dir/docker-compose.override.yml.backup_$timestamp"
    fi
    
    log_success "백업 완료: $backup_dir"
    
    # 오래된 백업 정리 (30일 이상)
    find "$backup_dir" -name "*.backup_*" -mtime +30 -delete 2>/dev/null || true
}

# Docker Compose 파일 유효성 검사
validate_config() {
    log_info "Docker Compose 파일 유효성 검사 중..."
    
    cd "$ROOT_DIR"
    
    # 기본 파일 검사
    if docker compose config > /dev/null 2>&1; then
        log_success "✅ docker-compose.yml 유효"
    else
        log_error "❌ docker-compose.yml 오류"
        docker compose config
        return 1
    fi
    
    # override 파일 검사
    if [ -f "$COMPOSE_OVERRIDE" ]; then
        if docker compose -f docker-compose.yml -f docker-compose.override.yml config > /dev/null 2>&1; then
            log_success "✅ docker-compose.override.yml 유효"
        else
            log_error "❌ docker-compose.override.yml 오류"
            docker compose -f docker-compose.yml -f docker-compose.override.yml config
            return 1
        fi
    fi
    
    log_success "모든 Docker Compose 파일이 유효합니다!"
}

# 메인 로직
main() {
    local command=${1:-"help"}
    local option=${2:-""}
    
    case $command in
        "status")
            check_status
            ;;
        "start")
            start_services "$option"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services "$option"
            ;;
        "build")
            build_images "$option"
            ;;
        "logs")
            show_logs "$option"
            ;;
        "clean")
            clean_resources
            ;;
        "backup")
            backup_config
            ;;
        "validate")
            validate_config
            ;;
        "help"|*)
            usage
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 