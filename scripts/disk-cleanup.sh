#!/bin/bash

# 디스크 공간 정리 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

log_info "디스크 공간 정리를 시작합니다..."

# 1. 현재 디스크 사용량 확인
log_info "현재 디스크 사용량:"
df -h /

# 2. Docker 시스템 정리
log_info "Docker 시스템 정리를 시작합니다..."

# 모든 컨테이너 중지
log_info "실행 중인 컨테이너 중지..."
docker stop $(docker ps -q) 2>/dev/null || true

# 모든 컨테이너 삭제
log_info "모든 컨테이너 삭제..."
docker rm $(docker ps -aq) 2>/dev/null || true

# 모든 이미지 삭제
log_info "모든 Docker 이미지 삭제..."
docker rmi $(docker images -q) 2>/dev/null || true

# 모든 볼륨 삭제
log_info "모든 Docker 볼륨 삭제..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

# 모든 네트워크 삭제 (기본 네트워크 제외)
log_info "사용자 정의 네트워크 삭제..."
docker network rm $(docker network ls --filter "type=custom" -q) 2>/dev/null || true

# Docker 시스템 전체 정리
log_info "Docker 시스템 전체 정리..."
docker system prune -a -f --volumes

# 3. 빌드 캐시 정리
log_info "Docker 빌드 캐시 정리..."
docker builder prune -a -f

# 4. 로그 파일 정리
log_info "Docker 로그 파일 정리..."
sudo find /var/lib/docker/containers/ -name "*.log" -delete 2>/dev/null || true

# 5. 임시 파일 정리
log_info "시스템 임시 파일 정리..."
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true

# 6. 패키지 캐시 정리 (CentOS/RHEL)
log_info "패키지 캐시 정리..."
sudo yum clean all 2>/dev/null || true
sudo dnf clean all 2>/dev/null || true

# 7. 정리 후 디스크 사용량 확인
log_info "정리 후 디스크 사용량:"
df -h /

# 8. 사용 가능한 공간 계산
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

log_info "사용 가능한 공간: ${AVAILABLE_SPACE_GB}GB"

if [ $AVAILABLE_SPACE_GB -lt 5 ]; then
    log_warn "여전히 디스크 공간이 부족합니다. 추가 정리가 필요합니다."
    log_info "다음 명령어로 추가 정리를 수행할 수 있습니다:"
    echo "  - sudo journalctl --vacuum-time=1d  # 로그 파일 정리"
    echo "  - sudo find /var/log -name '*.log' -delete  # 로그 파일 삭제"
    echo "  - sudo rm -rf /var/cache/yum  # YUM 캐시 삭제"
else
    log_info "디스크 공간이 충분히 확보되었습니다."
fi

log_info "디스크 공간 정리가 완료되었습니다!" 