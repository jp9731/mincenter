#!/bin/bash

# 정기 정리 cron 설정 스크립트
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
    echo -e "${BLUE}[CRON SETUP]${NC} $1"
}

log_info "정기 정리 cron 작업을 설정합니다..."

# 현재 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "프로젝트 디렉토리: $PROJECT_DIR"

# cron 작업 생성
create_cron_jobs() {
    log_header "=== cron 작업 생성 ==="
    
    # 기존 cron 작업 제거
    log_info "기존 cron 작업 제거 중..."
    crontab -l 2>/dev/null | grep -v "server-cleanup.sh" | crontab - || true
    
    # 새로운 cron 작업 추가
    log_info "새로운 cron 작업 추가 중..."
    
    # 매주 일요일 새벽 2시에 정리 실행
    (crontab -l 2>/dev/null; echo "0 2 * * 0 $PROJECT_DIR/scripts/server-cleanup.sh >> $PROJECT_DIR/logs/cleanup.log 2>&1") | crontab -
    
    # 매일 새벽 3시에 디스크 사용량 분석
    (crontab -l 2>/dev/null; echo "0 3 * * * $PROJECT_DIR/scripts/analyze-disk.sh >> $PROJECT_DIR/logs/disk-analysis.log 2>&1") | crontab -
    
    # 매일 새벽 4시에 Docker 정리
    (crontab -l 2>/dev/null; echo "0 4 * * * docker system prune -f >> $PROJECT_DIR/logs/docker-cleanup.log 2>&1") | crontab -
    
    log_info "cron 작업이 추가되었습니다."
}

# 로그 디렉토리 생성
create_log_directory() {
    log_header "=== 로그 디렉토리 생성 ==="
    
    LOG_DIR="$PROJECT_DIR/logs"
    mkdir -p "$LOG_DIR"
    
    log_info "로그 디렉토리 생성: $LOG_DIR"
}

# cron 작업 확인
verify_cron_jobs() {
    log_header "=== cron 작업 확인 ==="
    
    log_info "현재 설정된 cron 작업:"
    crontab -l
    
    echo ""
    log_info "cron 서비스 상태 확인:"
    sudo systemctl status crond --no-pager -l
}

# cron 서비스 시작
start_cron_service() {
    log_header "=== cron 서비스 시작 ==="
    
    log_info "cron 서비스 시작 중..."
    sudo systemctl start crond
    sudo systemctl enable crond
    
    log_info "cron 서비스가 시작되었습니다."
}

# 메인 실행
main() {
    log_info "정기 정리 cron 설정을 시작합니다..."
    
    # 로그 디렉토리 생성
    create_log_directory
    
    # cron 작업 생성
    create_cron_jobs
    
    # cron 서비스 시작
    start_cron_service
    
    # cron 작업 확인
    verify_cron_jobs
    
    log_info "정기 정리 cron 설정이 완료되었습니다!"
    log_info "설정된 작업:"
    echo "  ✓ 매주 일요일 새벽 2시: 서버 종합 정리"
    echo "  ✓ 매일 새벽 3시: 디스크 사용량 분석"
    echo "  ✓ 매일 새벽 4시: Docker 정리"
    echo ""
    log_info "로그 파일 위치: $PROJECT_DIR/logs/"
}

# 스크립트 실행
main 