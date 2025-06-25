#!/bin/bash

# 서버 종합 정리 스크립트
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
    echo -e "${BLUE}[CLEANUP]${NC} $1"
}

# 백업 함수
backup_important_files() {
    log_info "중요 파일 백업을 시작합니다..."
    
    BACKUP_DIR="/tmp/server_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    # 중요 설정 파일 백업
    if [ -f "/etc/hosts" ]; then
        cp /etc/hosts $BACKUP_DIR/
    fi
    
    if [ -f "/etc/resolv.conf" ]; then
        cp /etc/resolv.conf $BACKUP_DIR/
    fi
    
    log_info "백업 완료: $BACKUP_DIR"
}

# 정리 전 확인
confirm_cleanup() {
    log_warn "⚠️  주의: 이 스크립트는 시스템 파일을 삭제합니다!"
    log_warn "중요한 데이터가 있다면 먼저 백업하세요."
    
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "정리가 취소되었습니다."
        exit 0
    fi
}

log_info "서버 종합 정리를 시작합니다..."

# 정리 전 확인
confirm_cleanup

# 백업
backup_important_files

# 1. 시스템 로그 정리
log_header "=== 시스템 로그 정리 ==="
log_info "시스템 로그 정리 중..."
sudo journalctl --vacuum-time=7d
sudo journalctl --vacuum-size=100M

# 오래된 로그 파일 삭제
log_info "오래된 로그 파일 삭제 중..."
sudo find /var/log -name "*.log" -mtime +30 -delete 2>/dev/null || true
sudo find /var/log -name "*.gz" -mtime +30 -delete 2>/dev/null || true

# 2. 패키지 캐시 정리
log_header "=== 패키지 캐시 정리 ==="
log_info "YUM/DNF 캐시 정리 중..."
sudo yum clean all 2>/dev/null || true
sudo dnf clean all 2>/dev/null || true

# 3. 임시 파일 정리
log_header "=== 임시 파일 정리 ==="
log_info "임시 파일 정리 중..."
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true

# 오래된 임시 파일 삭제
log_info "오래된 임시 파일 삭제 중..."
sudo find /tmp -type f -mtime +7 -delete 2>/dev/null || true
sudo find /var/tmp -type f -mtime +7 -delete 2>/dev/null || true

# 4. Docker 정리
log_header "=== Docker 정리 ==="
if command -v docker &> /dev/null; then
    log_info "Docker 시스템 정리 중..."
    docker system prune -a -f --volumes 2>/dev/null || true
    docker builder prune -a -f 2>/dev/null || true
    
    # Docker 로그 파일 정리
    log_info "Docker 로그 파일 정리 중..."
    sudo find /var/lib/docker/containers/ -name "*.log" -delete 2>/dev/null || true
else
    log_info "Docker가 설치되지 않았습니다."
fi

# 5. 불필요한 패키지 제거
log_header "=== 불필요한 패키지 제거 ==="
log_info "사용하지 않는 패키지 제거 중..."
sudo yum autoremove -y 2>/dev/null || true
sudo dnf autoremove -y 2>/dev/null || true

# 6. 커널 정리
log_header "=== 커널 정리 ==="
log_info "오래된 커널 제거 중..."
if command -v dnf &> /dev/null; then
    sudo dnf remove $(dnf repoquery --installonly --latest-limit=-2 -q) -y 2>/dev/null || true
elif command -v yum &> /dev/null; then
    sudo package-cleanup --oldkernels --count=2 -y 2>/dev/null || true
fi

# 7. 캐시 디렉토리 정리
log_header "=== 캐시 디렉토리 정리 ==="
log_info "브라우저 캐시 정리 중..."
sudo rm -rf /home/*/.cache/* 2>/dev/null || true
sudo rm -rf /root/.cache/* 2>/dev/null || true

# 8. 오래된 백업 파일 정리
log_header "=== 백업 파일 정리 ==="
log_info "오래된 백업 파일 정리 중..."
sudo find /var/backups -type f -mtime +30 -delete 2>/dev/null || true
sudo find /backup -type f -mtime +30 -delete 2>/dev/null || true

# 9. 빈 디렉토리 정리
log_header "=== 빈 디렉토리 정리 ==="
log_info "빈 디렉토리 정리 중..."
sudo find /tmp -type d -empty -delete 2>/dev/null || true
sudo find /var/tmp -type d -empty -delete 2>/dev/null || true

# 10. 정리 후 디스크 사용량 확인
log_header "=== 정리 후 디스크 사용량 ==="
log_info "정리 후 디스크 사용량:"
df -h /

# 사용 가능한 공간 계산
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

log_info "정리 후 사용 가능한 공간: ${AVAILABLE_SPACE_GB}GB"

# 11. 정리 결과 요약
log_header "=== 정리 완료 ==="
log_info "서버 종합 정리가 완료되었습니다!"
log_info "정리된 항목:"
echo "  ✓ 시스템 로그 (7일 이전)"
echo "  ✓ 패키지 캐시"
echo "  ✓ 임시 파일"
echo "  ✓ Docker 리소스"
echo "  ✓ 불필요한 패키지"
echo "  ✓ 오래된 커널"
echo "  ✓ 브라우저 캐시"
echo "  ✓ 오래된 백업 파일"

log_info "백업 위치: $BACKUP_DIR"
log_warn "필요한 경우 백업 파일을 확인하고 삭제하세요." 