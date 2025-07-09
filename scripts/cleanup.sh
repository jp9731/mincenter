#!/bin/bash

# Docker 정리 스크립트
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

# 환경 변수 로드
if [ -f .env ]; then
    source .env
fi

APP_NAME=${APP_NAME:-mincenter}

log_info "Docker 정리를 시작합니다..."

# 1. Docker Compose 컨테이너 중지
log_info "Docker Compose 컨테이너를 중지합니다..."
if [ -f "docker-compose.prod.yml" ]; then
    docker-compose -f docker-compose.prod.yml down --remove-orphans --timeout 30 || true
fi

if [ -f "docker-compose.yml" ]; then
    docker-compose down --remove-orphans --timeout 30 || true
fi

# 2. 관련 컨테이너 강제 종료
log_info "관련 컨테이너를 강제 종료합니다..."
docker ps -q --filter "name=${APP_NAME}_" | xargs -r docker kill || true
docker ps -aq --filter "name=${APP_NAME}_" | xargs -r docker rm -f || true

# 3. API 프로세스 종료
log_info "API 프로세스를 종료합니다..."
pkill -f mincenter-api || true
if [ -f "backends/api/api.pid" ]; then
    API_PID=$(cat backends/api/api.pid)
    kill $API_PID 2>/dev/null || true
    rm -f backends/api/api.pid
fi

# 4. 네트워크 정리
log_info "Docker 네트워크를 정리합니다..."
docker network prune -f || true

# 특정 네트워크 강제 삭제 시도
log_info "특정 네트워크를 강제 삭제합니다..."
docker network rm "${APP_NAME}_internal" 2>/dev/null || true

# 5. 사용하지 않는 리소스 정리
log_info "사용하지 않는 Docker 리소스를 정리합니다..."
docker system prune -f || true

# 6. 볼륨 정리 (선택사항)
read -p "볼륨도 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_warn "볼륨을 삭제합니다..."
    docker volume rm "${APP_NAME}_postgres_data" 2>/dev/null || true
    docker volume prune -f || true
fi

# 7. 이미지 정리 (선택사항)
read -p "사용하지 않는 이미지도 삭제하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_warn "사용하지 않는 이미지를 삭제합니다..."
    docker image prune -a -f || true
fi

log_info "Docker 정리가 완료되었습니다!"

# 8. 현재 상태 확인
log_info "현재 Docker 상태:"
echo "컨테이너:"
docker ps -a --filter "name=${APP_NAME}_" || true

echo "네트워크:"
docker network ls --filter "name=${APP_NAME}_" || true

echo "볼륨:"
docker volume ls --filter "name=${APP_NAME}_" || true 