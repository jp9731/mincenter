#!/bin/bash

# CentOS 7 Certbot 설치 및 Let's Encrypt 인증서 발급 스크립트
# 사용법: ./setup-certbot.sh

set -e

echo "🚀 CentOS 7 Certbot 설치 및 Let's Encrypt 인증서 발급을 시작합니다..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. EPEL 저장소 설치
log_info "EPEL 저장소를 설치합니다..."
if ! yum list installed | grep -q epel-release; then
    yum install -y epel-release
    log_success "EPEL 저장소 설치 완료"
else
    log_info "EPEL 저장소가 이미 설치되어 있습니다."
fi

# 2. Certbot 설치
log_info "Certbot을 설치합니다..."
if ! yum list installed | grep -q certbot; then
    yum install -y certbot python2-certbot-nginx
    log_success "Certbot 설치 완료"
else
    log_info "Certbot이 이미 설치되어 있습니다."
fi

# 3. 웹루트 디렉토리 생성
log_info "Certbot 웹루트 디렉토리를 생성합니다..."
mkdir -p /var/www/certbot
chown nginx:nginx /var/www/certbot
chmod 755 /var/www/certbot
log_success "웹루트 디렉토리 생성 완료"

# 4. nginx 설정 파일 복사
log_info "nginx 설정 파일을 복사합니다..."
if [ -f "nginx/minshool-subdomain.conf" ]; then
    cp nginx/minshool-subdomain.conf /etc/nginx/conf.d/
    log_success "nginx 설정 파일 복사 완료"
else
    log_error "nginx 설정 파일을 찾을 수 없습니다: nginx/minshool-subdomain.conf"
    exit 1
fi

# 5. nginx 설정 테스트
log_info "nginx 설정을 테스트합니다..."
if nginx -t; then
    log_success "nginx 설정 테스트 통과"
else
    log_error "nginx 설정 테스트 실패"
    exit 1
fi

# 6. nginx 재시작
log_info "nginx를 재시작합니다..."
systemctl restart nginx
log_success "nginx 재시작 완료"

# 7. 방화벽 설정 (80, 443 포트 허용)
log_info "방화벽을 설정합니다..."
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
    log_success "방화벽 설정 완료"
else
    log_warning "firewall-cmd를 찾을 수 없습니다. 수동으로 80, 443 포트를 열어주세요."
fi

# 8. 도메인 확인
echo ""
log_info "인증서를 발급할 도메인을 확인합니다..."
echo "다음 도메인에 대해 인증서를 발급합니다:"
echo "  - mincenter.kr"
echo "  - www.mincenter.kr"
echo "  - admin.mincenter.kr"
echo "  - api.mincenter.kr"
echo "  - pm2.mincenter.kr"
echo ""

# 9. 인증서 발급
log_info "Let's Encrypt 인증서를 발급합니다..."
echo "인증서 발급을 시작하시겠습니까? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    # 각 도메인별로 인증서 발급
    domains=("mincenter.kr" "www.mincenter.kr" "admin.mincenter.kr" "api.mincenter.kr" "pm2.mincenter.kr")
    
    for domain in "${domains[@]}"; do
        log_info "$domain 도메인에 대한 인증서를 발급합니다..."
        
        # certbot으로 인증서 발급
        certbot certonly \
            --webroot \
            --webroot-path=/var/www/certbot \
            --email admin@mincenter.kr \
            --agree-tos \
            --no-eff-email \
            --domains "$domain" \
            --non-interactive
        
        if [ $? -eq 0 ]; then
            log_success "$domain 인증서 발급 완료"
        else
            log_error "$domain 인증서 발급 실패"
        fi
    done
else
    log_info "인증서 발급을 건너뜁니다."
fi

# 10. 인증서 자동 갱신 설정
log_info "인증서 자동 갱신을 설정합니다..."
if [ ! -f /etc/cron.d/certbot-renew ]; then
    cat > /etc/cron.d/certbot-renew << EOF
# Certbot 자동 갱신 (매일 오전 2시)
0 2 * * * root /usr/bin/certbot renew --quiet --post-hook "systemctl reload nginx"
EOF
    log_success "자동 갱신 cron 작업 설정 완료"
else
    log_info "자동 갱신 cron 작업이 이미 설정되어 있습니다."
fi

# 11. HTTPS 설정 활성화 가이드
echo ""
log_success "Certbot 설치 및 인증서 발급이 완료되었습니다!"
echo ""
echo "📋 다음 단계:"
echo "1. 인증서 발급이 완료되면 nginx 설정에서 HTTPS 서버 블록의 주석을 해제하세요"
echo "2. nginx 설정을 다시 로드하세요: systemctl reload nginx"
echo "3. 브라우저에서 https://mincenter.kr 로 접속하여 SSL이 정상 작동하는지 확인하세요"
echo ""
echo "🔧 유용한 명령어:"
echo "  - 인증서 상태 확인: certbot certificates"
echo "  - 수동 갱신: certbot renew"
echo "  - nginx 설정 테스트: nginx -t"
echo "  - nginx 재시작: systemctl restart nginx"
echo ""

# 12. 인증서 상태 확인
if command -v certbot &> /dev/null; then
    log_info "발급된 인증서 목록:"
    certbot certificates
fi

log_success "설정이 완료되었습니다! 🎉" 