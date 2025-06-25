#!/bin/bash

# 배포 스크립트 (CentOS 7 호환)
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

# CentOS 7 호환성 체크
check_centos_compatibility() {
    log_info "CentOS 7 호환성을 확인합니다..."
    
    # Docker 버전 체크
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_info "Docker 버전: $DOCKER_VERSION"
        
        # Docker 1.13 이상 필요
        if [[ "$(printf '%s\n' "1.13" "$DOCKER_VERSION" | sort -V | head -n1)" != "1.13" ]]; then
            log_error "Docker 1.13 이상이 필요합니다. 현재 버전: $DOCKER_VERSION"
            exit 1
        fi
    else
        log_error "Docker가 설치되지 않았습니다."
        exit 1
    fi
    
    # Docker Compose 버전 체크
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_info "Docker Compose 버전: $COMPOSE_VERSION"
        
        # Docker Compose 1.18 이상 필요
        if [[ "$(printf '%s\n' "1.18" "$COMPOSE_VERSION" | sort -V | head -n1)" != "1.18" ]]; then
            log_warn "Docker Compose 1.18 이상을 권장합니다. 현재 버전: $COMPOSE_VERSION"
        fi
    else
        log_error "Docker Compose가 설치되지 않았습니다."
        exit 1
    fi
    
    # Rust 설치 확인
    if command -v cargo &> /dev/null; then
        RUST_VERSION=$(cargo --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_info "Rust 버전: $RUST_VERSION"
    else
        log_error "Rust가 설치되지 않았습니다. API 서버를 빌드할 수 없습니다."
        exit 1
    fi
}

# 환경 변수 확인
if [ ! -f .env ]; then
    log_error "환경 변수 파일(.env)이 없습니다."
    log_info "env.example을 복사하여 .env 파일을 생성하고 설정하세요."
    exit 1
fi

# 환경 변수 로드
source .env

log_info "배포를 시작합니다..."

# 호환성 체크
check_centos_compatibility

# 디스크 공간 체크
check_disk_space() {
    log_info "디스크 공간을 확인합니다..."
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
    AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
    
    log_info "사용 가능한 공간: ${AVAILABLE_SPACE_GB}GB"
    
    if [ $AVAILABLE_SPACE_GB -lt 5 ]; then
        log_warn "디스크 공간이 부족합니다. 정리를 시작합니다..."
        if [ -f "scripts/disk-cleanup.sh" ]; then
            chmod +x scripts/disk-cleanup.sh
            ./scripts/disk-cleanup.sh
        else
            log_error "디스크 정리 스크립트가 없습니다. 수동으로 정리하세요."
            exit 1
        fi
        
        # 정리 후 다시 체크
        AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
        AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
        
        if [ $AVAILABLE_SPACE_GB -lt 3 ]; then
            log_error "디스크 공간이 여전히 부족합니다. 최소 3GB가 필요합니다."
            exit 1
        fi
    fi
}

# 디스크 공간 체크
check_disk_space

# 1. 기존 컨테이너 완전 중지 및 정리
log_info "기존 컨테이너를 완전히 중지하고 정리합니다..."

# Docker Compose로 실행 중인 컨테이너 중지
if [ -f "docker-compose.prod.yml" ]; then
    log_info "Docker Compose 컨테이너 중지..."
    docker-compose -f docker-compose.prod.yml down --remove-orphans --timeout 30 || true
    
    # 네트워크 정리 (강제로)
    log_info "Docker 네트워크 정리..."
    docker network prune -f || true
    
    # 관련된 모든 컨테이너 강제 종료
    log_info "관련 컨테이너 강제 종료..."
    docker ps -q --filter "name=${APP_NAME:-mincenter}_" | xargs -r docker kill || true
    docker ps -aq --filter "name=${APP_NAME:-mincenter}_" | xargs -r docker rm -f || true
fi

# 2. 새 이미지 빌드
log_info "새 이미지를 빌드합니다..."
docker-compose -f docker-compose.prod.yml build --no-cache

# 3. 컨테이너 시작
log_info "컨테이너를 시작합니다..."
docker-compose -f docker-compose.prod.yml up -d

# 4. 데이터베이스 마이그레이션 실행 (납품 시 수동 처리)
log_info "데이터베이스 마이그레이션은 수동으로 처리합니다..."
log_warn "납품 시에는 직접 DB에 접속하여 스키마 변경사항을 적용하세요."

# 5. 데이터베이스 헬스체크
log_info "데이터베이스 헬스체크를 수행합니다..."

# PostgreSQL 헬스체크
if docker-compose -f docker-compose.prod.yml exec -T postgres pg_isready -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null 2>&1; then
    log_info "PostgreSQL: 정상"
else
    log_error "PostgreSQL: 비정상"
    log_info "컨테이너 로그를 확인하세요: docker-compose -f docker-compose.prod.yml logs postgres"
    exit 1
fi

# API 헬스체크 (포트 18080)
if curl -f http://localhost:18080/health > /dev/null 2>&1; then
    log_info "API: 정상"
else
    log_error "API: 비정상"
    log_info "API 로그를 확인하세요: tail -f backends/api/api.log"
    exit 1
fi

# Site 헬스체크 (포트 13000)
if curl -f http://localhost:13000 > /dev/null 2>&1; then
    log_info "Site: 정상"
else
    log_error "Site: 비정상"
    log_info "컨테이너 로그를 확인하세요: docker-compose -f docker-compose.prod.yml logs site"
    exit 1
fi

# Admin 헬스체크 (포트 13001)
if curl -f http://localhost:13001 > /dev/null 2>&1; then
    log_info "Admin: 정상"
else
    log_error "Admin: 비정상"
    log_info "컨테이너 로그를 확인하세요: docker-compose -f docker-compose.prod.yml logs admin"
    exit 1
fi

# 6. 불필요한 이미지 정리
log_info "불필요한 이미지를 정리합니다..."
docker image prune -f

# 7. 배포 완료
log_info "배포가 완료되었습니다!"
log_info "서비스 상태:"
docker-compose -f docker-compose.prod.yml ps

log_info "CentOS 7에서 성공적으로 배포되었습니다!" 