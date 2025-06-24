#!/bin/bash

# PM2 배포 스크립트 (CentOS 7 호환)
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 환경 변수 확인
if [ ! -f .env ]; then
    log_error "환경 변수 파일(.env)이 없습니다."
    exit 1
fi

# 환경 변수 로드
source .env

# PM2 설치 확인
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        log_error "PM2가 설치되지 않았습니다."
        log_info "PM2를 설치하세요: npm install -g pm2"
        exit 1
    fi
    log_info "PM2 버전: $(pm2 --version)"
}

# 로그 디렉토리 생성
create_log_dirs() {
    log_info "로그 디렉토리를 생성합니다..."
    mkdir -p frontends/site/logs
    mkdir -p frontends/admin/logs
}

# 프론트엔드 빌드
build_frontends() {
    log_step "프론트엔드를 빌드합니다..."
    
    # Site 빌드
    log_info "Site 빌드 중..."
    cd frontends/site
    npm ci
    npm run build
    cd ../..
    
    # Admin 빌드
    log_info "Admin 빌드 중..."
    cd frontends/admin
    npm ci
    npm run build
    cd ../..
}

# PM2 프로세스 관리
manage_pm2() {
    log_step "PM2 프로세스를 관리합니다..."
    
    # 기존 프로세스 중지
    if pm2 list | grep -q "minshool"; then
        log_info "기존 PM2 프로세스를 중지합니다..."
        pm2 stop minshool-site minshool-admin 2>/dev/null || true
        pm2 delete minshool-site minshool-admin 2>/dev/null || true
    fi
    
    # 새 프로세스 시작
    log_info "새 PM2 프로세스를 시작합니다..."
    pm2 start ecosystem.config.js --env production
    
    # PM2 저장 및 시작 스크립트 생성
    pm2 save
    pm2 startup
}

# 헬스체크
health_check() {
    log_step "헬스체크를 수행합니다..."
    
    # 대기
    sleep 10
    
    # Site 헬스체크
    if curl -f http://localhost:3000 > /dev/null 2>&1; then
        log_info "✅ Site: 정상"
    else
        log_error "❌ Site: 비정상"
        pm2 logs minshool-site --lines 20
        exit 1
    fi
    
    # Admin 헬스체크
    if curl -f http://localhost:3001 > /dev/null 2>&1; then
        log_info "✅ Admin: 정상"
    else
        log_error "❌ Admin: 비정상"
        pm2 logs minshool-admin --lines 20
        exit 1
    fi
}

# 메인 실행
main() {
    log_step "PM2 배포를 시작합니다..."
    
    check_pm2
    create_log_dirs
    build_frontends
    manage_pm2
    health_check
    
    log_step "PM2 배포가 완료되었습니다!"
    log_info "PM2 상태:"
    pm2 list
    
    log_info "접속 URL:"
    echo "  - 메인 사이트: http://localhost:3000"
    echo "  - 관리자 페이지: http://localhost:3001"
    
    log_info "PM2 명령어:"
    echo "  - 상태 확인: pm2 list"
    echo "  - 로그 확인: pm2 logs"
    echo "  - 재시작: pm2 restart all"
    echo "  - 중지: pm2 stop all"
    echo "  - 삭제: pm2 delete all"
}

# 스크립트 실행
main "$@" 