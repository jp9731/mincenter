#!/bin/bash

# MinSchool SSL 인증서 설정 스크립트
# certbot을 사용하여 Let's Encrypt SSL 인증서 생성

set -e

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

# 도메인 설정
DOMAINS=("mincenter.kr" "www.mincenter.kr" "admin.mincenter.kr" "api.mincenter.kr")
EMAIL="admin@mincenter.kr"

# 함수: certbot 설치 확인 및 설치
install_certbot() {
    log_info "certbot 설치 확인 중..."
    
    if ! command -v certbot &> /dev/null; then
        log_info "certbot 설치 중..."
        
        # CentOS 7
        if [ -f /etc/redhat-release ]; then
            sudo yum install -y epel-release
            sudo yum install -y certbot python2-certbot-nginx
        # Ubuntu/Debian
        elif [ -f /etc/debian_version ]; then
            sudo apt update
            sudo apt install -y certbot python3-certbot-nginx
        # macOS
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install certbot
        else
            log_error "지원되지 않는 운영체제입니다."
            exit 1
        fi
        
        log_success "certbot 설치 완료"
    else
        log_success "certbot이 이미 설치되어 있습니다."
    fi
}

# 함수: nginx 설정 백업
backup_nginx_config() {
    log_info "nginx 설정 백업 중..."
    
    BACKUP_DIR="/etc/nginx/backup_$(date +%Y%m%d_%H%M%S)"
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp /etc/nginx/nginx.conf "$BACKUP_DIR/"
    sudo cp -r /etc/nginx/conf.d/* "$BACKUP_DIR/" 2>/dev/null || true
    
    log_success "nginx 설정 백업 완료: $BACKUP_DIR"
}

# 함수: SSL 인증서 생성
generate_ssl_certificates() {
    log_info "SSL 인증서 생성 중..."
    
    # 각 도메인별로 인증서 생성
    for domain in "${DOMAINS[@]}"; do
        log_info "도메인 $domain에 대한 인증서 생성 중..."
        
        # certbot으로 인증서 생성 (nginx 플러그인 사용)
        sudo certbot --nginx \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            --domains "$domain" \
            --non-interactive
        
        log_success "도메인 $domain 인증서 생성 완료"
    done
}

# 함수: 와일드카드 인증서 생성 (대안)
generate_wildcard_certificate() {
    log_info "와일드카드 인증서 생성 중..."
    
    # DNS 챌린지를 위한 certbot 플러그인 설치
    if [ -f /etc/redhat-release ]; then
        sudo yum install -y python2-certbot-dns-cloudflare
    elif [ -f /etc/debian_version ]; then
        sudo apt install -y python3-certbot-dns-cloudflare
    fi
    
    # Cloudflare API 토큰이 필요한 경우
    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        log_warning "Cloudflare API 토큰이 설정되지 않았습니다."
        log_info "환경변수 CLOUDFLARE_API_TOKEN을 설정하거나 수동으로 인증서를 생성하세요."
        return 1
    fi
    
    # 와일드카드 인증서 생성
    sudo certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "*.mincenter.kr" \
        --non-interactive
    
    log_success "와일드카드 인증서 생성 완료"
}

# 함수: nginx SSL 설정 적용
apply_ssl_config() {
    log_info "nginx SSL 설정 적용 중..."
    
    # SSL 설정이 포함된 nginx 설정 파일 생성
    sudo tee /etc/nginx/conf.d/minshool-ssl.conf > /dev/null << 'EOF'
# MinSchool SSL 설정
# certbot이 자동으로 생성한 설정

# HTTP를 HTTPS로 리다이렉트
server {
    listen 80;
    server_name mincenter.kr www.mincenter.kr admin.mincenter.kr api.mincenter.kr;
    return 301 https://$server_name$request_uri;
}

# HTTPS 서버 설정은 certbot이 자동으로 생성
EOF
    
    # nginx 설정 테스트
    if sudo nginx -t; then
        log_success "nginx 설정 테스트 통과"
        
        # nginx 재시작
        sudo systemctl reload nginx
        log_success "nginx 재시작 완료"
    else
        log_error "nginx 설정 테스트 실패"
        exit 1
    fi
}

# 함수: 자동 갱신 설정
setup_auto_renewal() {
    log_info "자동 갱신 설정 중..."
    
    # crontab에 자동 갱신 작업 추가
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
    
    log_success "자동 갱신 설정 완료 (매일 오후 12시)"
}

# 함수: SSL 상태 확인
check_ssl_status() {
    log_info "SSL 인증서 상태 확인 중..."
    
    for domain in "${DOMAINS[@]}"; do
        log_info "도메인 $domain SSL 확인 중..."
        
        # 인증서 만료일 확인
        expiry_date=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
        
        if [ -n "$expiry_date" ]; then
            log_success "도메인 $domain: $expiry_date까지 유효"
        else
            log_error "도메인 $domain: SSL 인증서 확인 실패"
        fi
    done
}

# 메인 함수
main() {
    case "${1:-all}" in
        "install")
            log_info "certbot 설치만 실행"
            install_certbot
            ;;
        "certificates")
            log_info "SSL 인증서 생성만 실행"
            generate_ssl_certificates
            ;;
        "wildcard")
            log_info "와일드카드 인증서 생성만 실행"
            generate_wildcard_certificate
            ;;
        "apply")
            log_info "nginx SSL 설정 적용만 실행"
            apply_ssl_config
            ;;
        "renewal")
            log_info "자동 갱신 설정만 실행"
            setup_auto_renewal
            ;;
        "status")
            log_info "SSL 상태 확인만 실행"
            check_ssl_status
            ;;
        "all")
            log_info "전체 SSL 설정 프로세스 시작"
            install_certbot
            backup_nginx_config
            generate_ssl_certificates
            apply_ssl_config
            setup_auto_renewal
            check_ssl_status
            log_success "SSL 설정 완료!"
            ;;
        *)
            echo "사용법: $0 {install|certificates|wildcard|apply|renewal|status|all}"
            echo ""
            echo "명령어:"
            echo "  install     - certbot 설치"
            echo "  certificates - 개별 도메인 SSL 인증서 생성"
            echo "  wildcard    - 와일드카드 SSL 인증서 생성"
            echo "  apply       - nginx SSL 설정 적용"
            echo "  renewal     - 자동 갱신 설정"
            echo "  status      - SSL 상태 확인"
            echo "  all         - 전체 프로세스 실행 (기본값)"
            echo ""
            echo "환경변수:"
            echo "  CLOUDFLARE_API_TOKEN - Cloudflare API 토큰 (와일드카드 인증서용)"
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 