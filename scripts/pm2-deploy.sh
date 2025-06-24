#!/bin/bash

# PM2 배포 스크립트 (CentOS 7 호환)
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

# 환경 변수 확인
if [ ! -f .env ]; then
    log_error "환경 변수 파일(.env)이 없습니다."
    log_info "env.example을 복사하여 .env 파일을 생성하고 설정하세요."
    exit 1
fi

# 환경 변수 로드
source .env

log_info "PM2 배포를 시작합니다..."

# 1. PM2 설치 확인
if ! command -v pm2 &> /dev/null; then
    log_error "PM2가 설치되지 않았습니다."
    log_info "npm install -g pm2를 실행하여 PM2를 설치하세요."
    exit 1
fi

# 2. 기존 프로세스 중지
log_info "기존 PM2 프로세스를 중지합니다..."
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# 3. 의존성 설치
log_info "프론트엔드 의존성을 설치합니다..."

# Site 의존성 설치
if [ -d "frontends/site" ]; then
    log_info "Site 의존성을 설치합니다..."
    cd frontends/site
    npm ci --production
    cd ../..
fi

# Admin 의존성 설치
if [ -d "frontends/admin" ]; then
    log_info "Admin 의존성을 설치합니다..."
    cd frontends/admin
    npm ci --production
    cd ../..
fi

# 4. 빌드
log_info "프론트엔드를 빌드합니다..."

# Site 빌드
if [ -d "frontends/site" ]; then
    log_info "Site를 빌드합니다..."
    cd frontends/site
    npm run build
    cd ../..
fi

# Admin 빌드
if [ -d "frontends/admin" ]; then
    log_info "Admin을 빌드합니다..."
    cd frontends/admin
    npm run build
    cd ../..
fi

# 5. PM2로 애플리케이션 시작
log_info "PM2로 애플리케이션을 시작합니다..."

# Site 시작 (포트 13000)
if [ -d "frontends/site" ]; then
    log_info "Site를 시작합니다 (포트: $SITE_PORT)..."
    cd frontends/site
    pm2 start npm --name "site" -- start
    cd ../..
fi

# Admin 시작 (포트 13001)
if [ -d "frontends/admin" ]; then
    log_info "Admin을 시작합니다 (포트: $ADMIN_PORT)..."
    cd frontends/admin
    pm2 start npm --name "admin" -- start
    cd ../..
fi

# 6. PM2 설정 저장
log_info "PM2 설정을 저장합니다..."
pm2 save

# 7. PM2 시작 스크립트 생성
log_info "PM2 시작 스크립트를 생성합니다..."
pm2 startup

# 8. 헬스체크 대기
log_info "서비스가 시작될 때까지 대기합니다..."
sleep 30

# 9. 헬스체크
log_info "헬스체크를 수행합니다..."

# Site 헬스체크 (포트 13000)
if curl -f http://localhost:13000 > /dev/null 2>&1; then
    log_info "Site: 정상"
else
    log_error "Site: 비정상"
    log_info "PM2 로그를 확인하세요: pm2 logs site"
    exit 1
fi

# Admin 헬스체크 (포트 13001)
if curl -f http://localhost:13001 > /dev/null 2>&1; then
    log_info "Admin: 정상"
else
    log_error "Admin: 비정상"
    log_info "PM2 로그를 확인하세요: pm2 logs admin"
    exit 1
fi

# 10. 배포 완료
log_info "PM2 배포가 완료되었습니다!"
log_info "서비스 상태:"
pm2 status

log_info "접속 URL:"
echo "  - 메인 사이트: http://localhost:13000"
echo "  - 관리자 페이지: http://localhost:13001"

log_info "PM2 명령어:"
echo "  - 상태 확인: pm2 status"
echo "  - 로그 확인: pm2 logs"
echo "  - 재시작: pm2 restart all"
echo "  - 중지: pm2 stop all"

log_info "CentOS 7에서 PM2 배포가 성공적으로 완료되었습니다!" 