#!/bin/bash

# OpenSSL 자체 서명 SSL 인증서 생성 스크립트
# MinCenter 서브도메인용

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수 정의
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 설정
DOMAIN="mincenter.kr"
SSL_DIR="/etc/nginx/ssl"
CERT_FILE="$SSL_DIR/mincenter.crt"
KEY_FILE="$SSL_DIR/mincenter.key"
CONFIG_FILE="$SSL_DIR/openssl.conf"

print_info "MinCenter SSL 인증서 생성 시작"
print_info "도메인: $DOMAIN"
print_info "인증서 위치: $CERT_FILE"
print_info "키 위치: $KEY_FILE"

# SSL 디렉토리 생성
if [ ! -d "$SSL_DIR" ]; then
    print_info "SSL 디렉토리 생성: $SSL_DIR"
    sudo mkdir -p "$SSL_DIR"
    sudo chmod 700 "$SSL_DIR"
else
    print_info "SSL 디렉토리 이미 존재: $SSL_DIR"
fi

# 기존 인증서 백업
if [ -f "$CERT_FILE" ] || [ -f "$KEY_FILE" ]; then
    print_warning "기존 인증서 파일이 발견되었습니다."
    BACKUP_DIR="$SSL_DIR/backup-$(date +%Y%m%d-%H%M%S)"
    sudo mkdir -p "$BACKUP_DIR"
    
    if [ -f "$CERT_FILE" ]; then
        sudo cp "$CERT_FILE" "$BACKUP_DIR/"
        print_info "기존 인증서 백업: $BACKUP_DIR/$(basename $CERT_FILE)"
    fi
    
    if [ -f "$KEY_FILE" ]; then
        sudo cp "$KEY_FILE" "$BACKUP_DIR/"
        print_info "기존 키 백업: $BACKUP_DIR/$(basename $KEY_FILE)"
    fi
fi

# OpenSSL 설정 파일 생성
print_info "OpenSSL 설정 파일 생성"
cat > /tmp/openssl.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = KR
ST = Seoul
L = Seoul
O = MinCenter
OU = IT Department
CN = $DOMAIN
emailAddress = admin@$DOMAIN

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = www.$DOMAIN
DNS.3 = admin.$DOMAIN
DNS.4 = api.$DOMAIN
DNS.5 = pm2.$DOMAIN
DNS.6 = localhost
IP.1 = 127.0.0.1
EOF

# 설정 파일을 SSL 디렉토리로 복사
sudo cp /tmp/openssl.conf "$CONFIG_FILE"
sudo chmod 600 "$CONFIG_FILE"
rm /tmp/openssl.conf

print_info "OpenSSL 설정 파일 생성 완료: $CONFIG_FILE"

# 개인키 생성
print_info "개인키 생성 중..."
sudo openssl genrsa -out "$KEY_FILE" 2048
sudo chmod 600 "$KEY_FILE"
print_info "개인키 생성 완료: $KEY_FILE"

# 인증서 서명 요청(CSR) 생성
print_info "인증서 서명 요청(CSR) 생성 중..."
sudo openssl req -new -key "$KEY_FILE" -out /tmp/mincenter.csr -config "$CONFIG_FILE"
print_info "CSR 생성 완료"

# 자체 서명 인증서 생성
print_info "자체 서명 인증서 생성 중..."
sudo openssl x509 -req -in /tmp/mincenter.csr -signkey "$KEY_FILE" -out "$CERT_FILE" -days 365 -extensions v3_req -extfile "$CONFIG_FILE"
sudo chmod 644 "$CERT_FILE"
print_info "자체 서명 인증서 생성 완료: $CERT_FILE"

# 임시 파일 정리
rm /tmp/mincenter.csr

# 인증서 정보 확인
print_info "생성된 인증서 정보:"
sudo openssl x509 -in "$CERT_FILE" -text -noout | grep -E "(Subject:|DNS:|IP Address:|Not Before:|Not After:)"

# 권한 설정
print_info "파일 권한 설정"
sudo chown root:root "$CERT_FILE" "$KEY_FILE" "$CONFIG_FILE"
sudo chmod 644 "$CERT_FILE"
sudo chmod 600 "$KEY_FILE"
sudo chmod 600 "$CONFIG_FILE"

# Nginx 설정 테스트
print_info "Nginx 설정 테스트"
if sudo nginx -t; then
    print_info "Nginx 설정이 유효합니다."
    print_warning "Nginx를 재시작하려면 다음 명령어를 실행하세요:"
    echo "sudo systemctl restart nginx"
else
    print_error "Nginx 설정에 오류가 있습니다."
    exit 1
fi

print_info "SSL 인증서 생성 완료!"
print_info "인증서 파일: $CERT_FILE"
print_info "개인키 파일: $KEY_FILE"
print_info "설정 파일: $CONFIG_FILE"

print_warning "주의사항:"
echo "1. 이 인증서는 자체 서명된 인증서입니다."
echo "2. 브라우저에서 보안 경고가 표시될 수 있습니다."
echo "3. 프로덕션 환경에서는 Let's Encrypt나 상용 인증서를 사용하세요."
echo "4. 인증서는 365일 후 만료됩니다."

print_info "인증서 만료일 확인:"
sudo openssl x509 -in "$CERT_FILE" -noout -dates 