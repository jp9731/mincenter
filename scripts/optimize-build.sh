#!/bin/bash

# Docker 빌드 최적화 스크립트 (메모리 부족 문제 해결)

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
    echo -e "${BLUE}[OPTIMIZE]${NC} $1"
}

log_header "=== Docker 빌드 최적화 시작 ==="

# 1. Docker 시스템 정리
log_info "Docker 시스템 정리 중..."
docker system prune -f
docker builder prune -f

# 2. 메모리 상태 확인
log_info "시스템 메모리 상태 확인..."
free -h || true
df -h

# 3. Docker 빌드 최적화 환경 변수 설정
log_info "Docker 빌드 최적화 환경 변수 설정..."
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_PROGRESS=plain

# 4. 개별 서비스 빌드 (메모리 부족 방지)
log_info "개별 서비스 빌드 시작..."

# PostgreSQL 빌드 (이미지 기반이므로 빠름)
log_info "PostgreSQL 서비스 빌드..."
docker-compose -f docker-compose.prod.yml build postgres

# Site 빌드
log_info "Site 서비스 빌드..."
docker-compose -f docker-compose.prod.yml build site

# 빌드 후 메모리 정리
docker system prune -f

# Admin 빌드
log_info "Admin 서비스 빌드..."
docker-compose -f docker-compose.prod.yml build admin

# 5. 최종 정리
log_info "빌드 완료 후 정리..."
docker system prune -f

log_header "=== Docker 빌드 최적화 완료 ==="
log_info "모든 서비스가 성공적으로 빌드되었습니다!"

# 6. 빌드 결과 확인
log_info "빌드된 이미지 확인..."
docker images | grep mincenter || true 