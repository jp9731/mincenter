#!/bin/bash

# Nginx 설정 설치 스크립트 (CentOS 7)
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

# 서버 IP 확인
get_server_ip() {
    log_info "서버 IP를 확인합니다..."
    
    # 외부 IP 확인
    EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "unknown")
    log_info "외부 IP: $EXTERNAL_IP"
    
    # 내부 IP 확인
    INTERNAL_IP=$(hostname -I | awk '{print $1}')
    log_info "내부 IP: $INTERNAL_IP"
    
    # 사용자에게 IP 선택 요청
    echo
    log_info "사용할 IP 주소를 선택하세요:"
    echo "1) 외부 IP: $EXTERNAL_IP"
    echo "2) 내부 IP: $INTERNAL_IP"
    echo "3) 직접 입력"
    
    read -p "선택 (1-3): " choice
    
    case $choice in
        1)
            SERVER_IP=$EXTERNAL_IP
            ;;
        2)
            SERVER_IP=$INTERNAL_IP
            ;;
        3)
            read -p "IP 주소를 입력하세요: " SERVER_IP
            ;;
        *)
            log_error "잘못된 선택입니다."
            exit 1
            ;;
    esac
    
    log_info "선택된 IP: $SERVER_IP"
}

# Nginx 설치 확인
check_nginx() {
    if ! command -v nginx &> /dev/null; then
        log_error "Nginx가 설치되지 않았습니다."
        log_info "Nginx를 설치하세요: sudo yum install nginx"
        exit 1
    fi
    
    NGINX_VERSION=$(nginx -v 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    log_info "Nginx 버전: $NGINX_VERSION"
}

# SSL 인증서 설정
setup_ssl() {
    log_step "SSL 인증서를 설정합니다..."
    
    # SSL 디렉토리 생성
    sudo mkdir -p /etc/nginx/ssl
    
    # 기존 인증서 확인
    if [ -f /etc/nginx/ssl/cert.pem ] && [ -f /etc/nginx/ssl/key.pem ]; then
        log_warn "SSL 인증서가 이미 존재합니다."
        read -p "재생성하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            generate_ssl_cert
        fi
    else
        generate_ssl_cert
    fi
}

# SSL 인증서 생성
generate_ssl_cert() {
    log_info "자체 서명 SSL 인증서를 생성합니다..."
    
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/key.pem \
        -out /etc/nginx/ssl/cert.pem \
        -subj "/C=KR/ST=Seoul/L=Seoul/O=MinCenter/CN=mincenter.kr"
    
    # 권한 설정
    sudo chmod 600 /etc/nginx/ssl/key.pem
    sudo chmod 644 /etc/nginx/ssl/cert.pem
    
    log_info "SSL 인증서가 생성되었습니다."
}

# Nginx 설정 파일 생성
create_nginx_config() {
    log_step "Nginx 설정 파일을 생성합니다..."
    
    # 설정 파일 복사
    sudo cp nginx/minshool-production.conf /etc/nginx/conf.d/minshool.conf
    
    # IP 주소 치환
    sudo sed -i "s/127.0.0.1:8080/$SERVER_IP:8080/g" /etc/nginx/conf.d/minshool.conf
    sudo sed -i "s/127.0.0.1:3000/$SERVER_IP:3000/g" /etc/nginx/conf.d/minshool.conf
    sudo sed -i "s/127.0.0.1:3001/$SERVER_IP:3001/g" /etc/nginx/conf.d/minshool.conf
    
    log_info "Nginx 설정 파일이 생성되었습니다: /etc/nginx/conf.d/minshool.conf"
}

# 방화벽 설정
setup_firewall() {
    log_step "방화벽을 설정합니다..."
    
    # 필요한 포트 열기
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --permanent --add-port=3000/tcp
    sudo firewall-cmd --permanent --add-port=3001/tcp
    sudo firewall-cmd --permanent --add-port=9615/tcp
    
    # 방화벽 재시작
    sudo firewall-cmd --reload
    
    log_info "방화벽 설정이 완료되었습니다."
}

# Nginx 설정 테스트
test_nginx_config() {
    log_step "Nginx 설정을 테스트합니다..."
    
    if sudo nginx -t; then
        log_info "✅ Nginx 설정 테스트 성공!"
    else
        log_error "❌ Nginx 설정 테스트 실패"
        exit 1
    fi
}

# Nginx 재시작
restart_nginx() {
    log_step "Nginx를 재시작합니다..."
    
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    
    if sudo systemctl is-active --quiet nginx; then
        log_info "✅ Nginx가 성공적으로 시작되었습니다."
    else
        log_error "❌ Nginx 시작 실패"
        sudo systemctl status nginx
        exit 1
    fi
}

# 설정 확인
show_config() {
    log_step "설정을 확인합니다..."
    
    echo
    log_info "설정된 내용:"
    echo "  - 서버 IP: $SERVER_IP"
    echo "  - API 포트: 8080"
    echo "  - Site 포트: 3000"
    echo "  - Admin 포트: 3001"
    echo "  - PM2 웹 인터페이스: 9615"
    echo "  - 도메인: mincenter.kr"
    echo
    log_info "Nginx 설정 파일: /etc/nginx/conf.d/minshool.conf"
    log_info "SSL 인증서: /etc/nginx/ssl/"
    echo
    log_info "테스트 URL:"
    echo "  - HTTP: http://mincenter.kr (HTTPS로 리다이렉트)"
    echo "  - HTTPS: https://mincenter.kr"
    echo "  - 관리자: https://mincenter.kr/admin"
    echo "  - API: https://mincenter.kr/api"
    echo "  - PM2: https://mincenter.kr/pm2"
}

# 메인 실행
main() {
    log_step "Nginx 설정 설치를 시작합니다..."
    
    check_nginx
    get_server_ip
    setup_ssl
    create_nginx_config
    setup_firewall
    test_nginx_config
    restart_nginx
    show_config
    
    log_step "Nginx 설정 설치가 완료되었습니다!"
    
    log_info "다음 단계:"
    echo "  1. 애플리케이션을 시작하세요 (PM2 또는 Docker)"
    echo "  2. 브라우저에서 https://mincenter.kr 접속 테스트"
    echo "  3. 문제가 있으면 로그 확인: sudo tail -f /var/log/nginx/minshool_error.log"
}

# 스크립트 실행
main "$@" 