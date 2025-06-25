#!/bin/bash

# 디스크 사용량 분석 스크립트
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
    echo -e "${BLUE}[ANALYSIS]${NC} $1"
}

log_info "디스크 사용량 분석을 시작합니다..."

# 1. 전체 디스크 사용량
log_header "=== 전체 디스크 사용량 ==="
df -h

echo ""

# 2. 디렉토리별 사용량 (상위 10개)
log_header "=== 디렉토리별 사용량 (상위 10개) ==="
sudo du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10

echo ""

# 3. 큰 파일 찾기 (100MB 이상)
log_header "=== 큰 파일 찾기 (100MB 이상) ==="
sudo find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10

echo ""

# 4. 로그 파일 크기
log_header "=== 로그 파일 크기 ==="
sudo du -sh /var/log/* 2>/dev/null | sort -hr | head -5

echo ""

# 5. Docker 관련 사용량
log_header "=== Docker 사용량 ==="
if command -v docker &> /dev/null; then
    echo "Docker 시스템 사용량:"
    docker system df
    
    echo ""
    echo "Docker 이미지 크기 (상위 5개):"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -6
    
    echo ""
    echo "Docker 컨테이너 크기:"
    docker ps -s --format "table {{.Names}}\t{{.Size}}"
else
    echo "Docker가 설치되지 않았습니다."
fi

echo ""

# 6. 패키지 캐시 크기
log_header "=== 패키지 캐시 크기 ==="
if [ -d "/var/cache/yum" ]; then
    echo "YUM 캐시 크기:"
    sudo du -sh /var/cache/yum
fi

if [ -d "/var/cache/dnf" ]; then
    echo "DNF 캐시 크기:"
    sudo du -sh /var/cache/dnf
fi

echo ""

# 7. 임시 파일 크기
log_header "=== 임시 파일 크기 ==="
sudo du -sh /tmp /var/tmp 2>/dev/null

echo ""

# 8. 홈 디렉토리 사용량
log_header "=== 홈 디렉토리 사용량 ==="
sudo du -sh /home/* 2>/dev/null | sort -hr | head -5

echo ""

# 9. 오래된 파일 찾기 (30일 이상)
log_header "=== 오래된 파일 찾기 (30일 이상, 상위 10개) ==="
sudo find /tmp /var/tmp -type f -mtime +30 -exec ls -lh {} \; 2>/dev/null | head -10

echo ""

# 10. 권장 정리 항목
log_header "=== 권장 정리 항목 ==="
echo "1. 로그 파일 정리: sudo journalctl --vacuum-time=7d"
echo "2. 패키지 캐시 정리: sudo yum clean all"
echo "3. 임시 파일 정리: sudo rm -rf /tmp/* /var/tmp/*"
echo "4. Docker 정리: docker system prune -a -f"
echo "5. 오래된 로그 파일: sudo find /var/log -name '*.log' -mtime +30 -delete"

log_info "디스크 사용량 분석이 완료되었습니다!" 