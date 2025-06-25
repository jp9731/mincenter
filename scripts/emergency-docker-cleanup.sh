#!/bin/bash

# 긴급 Docker Device Mapper 정리 스크립트
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
    echo -e "${BLUE}[EMERGENCY CLEANUP]${NC} $1"
}

# 현재 상태 확인
check_current_status() {
    log_header "=== 현재 상태 확인 ==="
    
    log_info "현재 디스크 사용량:"
    df -h /
    
    echo ""
    log_info "Device Mapper 파일 크기:"
    ls -lh /var/lib/docker/devicemapper/devicemapper/data
    
    echo ""
    log_info "Docker 사용량:"
    docker system df
    
    echo ""
    log_info "실행 중인 컨테이너:"
    docker ps
}

# Docker 완전 정리
complete_docker_cleanup() {
    log_header "=== Docker 완전 정리 ==="
    
    log_info "1. 모든 컨테이너 중지..."
    docker stop $(docker ps -q) 2>/dev/null || true
    
    log_info "2. 모든 컨테이너 삭제..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    log_info "3. 모든 이미지 삭제..."
    docker rmi $(docker images -q) 2>/dev/null || true
    
    log_info "4. 모든 볼륨 삭제..."
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    
    log_info "5. 모든 네트워크 삭제..."
    docker network rm $(docker network ls --filter "type=custom" -q) 2>/dev/null || true
    
    log_info "6. Docker 시스템 전체 정리..."
    docker system prune -a -f --volumes
    
    log_info "7. Docker 빌드 캐시 정리..."
    docker builder prune -a -f
    
    log_info "8. Docker 로그 파일 정리..."
    sudo find /var/lib/docker/containers/ -name "*.log" -delete 2>/dev/null || true
}

# Device Mapper 파일 축소
shrink_devicemapper() {
    log_header "=== Device Mapper 파일 축소 ==="
    
    log_info "Docker 서비스 중지..."
    sudo systemctl stop docker
    
    log_info "Device Mapper 파일 크기 확인 (중지 후):"
    ls -lh /var/lib/docker/devicemapper/devicemapper/data
    
    log_info "Device Mapper 메타데이터 파일 확인:"
    ls -lh /var/lib/docker/devicemapper/devicemapper/metadata
    
    log_info "Docker 서비스 시작..."
    sudo systemctl start docker
    
    sleep 5
    
    log_info "Docker 서비스 상태 확인:"
    sudo systemctl status docker --no-pager -l
}

# 강제 정리 (위험)
force_cleanup() {
    log_header "=== 강제 정리 (위험) ==="
    
    log_warn "⚠️  주의: 이 작업은 모든 Docker 데이터를 완전히 삭제합니다!"
    log_warn "복구가 불가능합니다!"
    
    read -p "정말로 계속하시겠습니까? (yes를 입력하세요): " -r
    if [[ $REPLY != "yes" ]]; then
        log_info "강제 정리가 취소되었습니다."
        return
    fi
    
    log_info "Docker 서비스 중지..."
    sudo systemctl stop docker
    
    log_info "모든 Docker 데이터 삭제..."
    sudo rm -rf /var/lib/docker/*
    
    log_info "Docker 디렉토리 재생성..."
    sudo mkdir -p /var/lib/docker
    
    log_info "Docker 서비스 시작..."
    sudo systemctl start docker
    
    sleep 5
    
    log_info "Docker 서비스 상태 확인:"
    sudo systemctl status docker --no-pager -l
}

# 정리 후 확인
verify_cleanup() {
    log_header "=== 정리 결과 확인 ==="
    
    log_info "정리 후 디스크 사용량:"
    df -h /
    
    echo ""
    log_info "정리 후 Device Mapper 파일 크기:"
    if [ -f "/var/lib/docker/devicemapper/devicemapper/data" ]; then
        ls -lh /var/lib/docker/devicemapper/devicemapper/data
    else
        log_info "Device Mapper 파일이 삭제되었습니다."
    fi
    
    echo ""
    log_info "정리 후 Docker 사용량:"
    docker system df
    
    # 사용 가능한 공간 계산
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
    
    log_info "정리 후 사용 가능한 공간: ${AVAILABLE_SPACE_GB}GB"
}

# 메인 실행
main() {
    log_info "긴급 Docker Device Mapper 정리를 시작합니다..."
    
    # 현재 상태 확인
    check_current_status
    
    # 사용자 선택
    echo ""
    log_warn "정리 방법을 선택하세요:"
    echo "1. 일반 정리 (안전)"
    echo "2. 강제 정리 (위험, 모든 데이터 삭제)"
    echo "3. 취소"
    
    read -p "선택 (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            log_info "일반 정리를 시작합니다..."
            complete_docker_cleanup
            shrink_devicemapper
            ;;
        2)
            log_info "강제 정리를 시작합니다..."
            force_cleanup
            ;;
        3)
            log_info "정리가 취소되었습니다."
            exit 0
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
    
    # 정리 후 확인
    verify_cleanup
    
    log_info "긴급 Docker Device Mapper 정리가 완료되었습니다!"
}

# 스크립트 실행
main 