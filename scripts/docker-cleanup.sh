#!/bin/bash

# Docker Device Mapper 정리 스크립트
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
    echo -e "${BLUE}[DOCKER CLEANUP]${NC} $1"
}

# Docker 사용량 확인
check_docker_usage() {
    log_header "=== Docker 사용량 확인 ==="
    
    if command -v docker &> /dev/null; then
        log_info "Docker 시스템 사용량:"
        docker system df
        
        echo ""
        log_info "Device Mapper 파일 크기:"
        if [ -f "/var/lib/docker/devicemapper/devicemapper/data" ]; then
            ls -lh /var/lib/docker/devicemapper/devicemapper/data
        fi
        
        echo ""
        log_info "Docker 이미지 목록:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
        
        echo ""
        log_info "Docker 컨테이너 목록:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    else
        log_error "Docker가 설치되지 않았습니다."
        exit 1
    fi
}

# Docker 정리
cleanup_docker() {
    log_header "=== Docker 정리 시작 ==="
    
    log_info "모든 컨테이너 중지 중..."
    docker stop $(docker ps -q) 2>/dev/null || true
    
    log_info "모든 컨테이너 삭제 중..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    log_info "사용하지 않는 이미지 삭제 중..."
    docker image prune -a -f
    
    log_info "사용하지 않는 볼륨 삭제 중..."
    docker volume prune -f
    
    log_info "사용하지 않는 네트워크 삭제 중..."
    docker network prune -f
    
    log_info "Docker 시스템 전체 정리 중..."
    docker system prune -a -f --volumes
    
    log_info "Docker 빌드 캐시 정리 중..."
    docker builder prune -a -f
    
    log_info "Docker 로그 파일 정리 중..."
    sudo find /var/lib/docker/containers/ -name "*.log" -delete 2>/dev/null || true
}

# Device Mapper 최적화
optimize_devicemapper() {
    log_header "=== Device Mapper 최적화 ==="
    
    log_info "Device Mapper 설정 확인 중..."
    
    # Docker 데몬 설정 확인
    if [ -f "/etc/docker/daemon.json" ]; then
        log_info "현재 Docker 데몬 설정:"
        cat /etc/docker/daemon.json
    else
        log_warn "Docker 데몬 설정 파일이 없습니다."
    fi
    
    log_info "Device Mapper 파일 크기 (정리 후):"
    if [ -f "/var/lib/docker/devicemapper/devicemapper/data" ]; then
        ls -lh /var/lib/docker/devicemapper/devicemapper/data
    fi
}

# Docker 서비스 재시작
restart_docker() {
    log_header "=== Docker 서비스 재시작 ==="
    
    log_info "Docker 서비스 재시작 중..."
    sudo systemctl restart docker
    
    log_info "Docker 서비스 상태 확인:"
    sudo systemctl status docker --no-pager -l
}

# 정리 후 확인
verify_cleanup() {
    log_header "=== 정리 결과 확인 ==="
    
    log_info "정리 후 Docker 사용량:"
    docker system df
    
    echo ""
    log_info "정리 후 디스크 사용량:"
    df -h /
    
    # 사용 가능한 공간 계산
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
    
    log_info "정리 후 사용 가능한 공간: ${AVAILABLE_SPACE_GB}GB"
}

# 메인 실행
main() {
    log_info "Docker Device Mapper 정리를 시작합니다..."
    
    # 정리 전 확인
    check_docker_usage
    
    # 사용자 확인
    log_warn "⚠️  주의: 이 작업은 모든 Docker 컨테이너와 이미지를 삭제합니다!"
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "정리가 취소되었습니다."
        exit 0
    fi
    
    # Docker 정리
    cleanup_docker
    
    # Device Mapper 최적화
    optimize_devicemapper
    
    # Docker 서비스 재시작
    restart_docker
    
    # 정리 후 확인
    verify_cleanup
    
    log_info "Docker Device Mapper 정리가 완료되었습니다!"
}

# 스크립트 실행
main 