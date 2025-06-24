# Nginx SSL 인증서 설정 가이드

## 🚨 현재 문제
```
nginx: [emerg] cannot load certificate "/etc/nginx/ssl/cert.pem": BIO_new_file() failed
```

SSL 인증서 파일이 없어서 nginx가 시작되지 않고 있습니다.

## 🔧 해결 방법

### 1. 임시 SSL 인증서 생성 (개발/테스트용)

#### 자체 서명 인증서 생성
```bash
# SSL 디렉토리 생성
sudo mkdir -p /etc/nginx/ssl

# 개인키 생성
sudo openssl genrsa -out /etc/nginx/ssl/key.pem 2048

# 인증서 생성
sudo openssl req -new -x509 -key /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/cert.pem -days 365 -subj "/C=KR/ST=Seoul/L=Seoul/O=MinCenter/OU=IT/CN=mincenter.kr"

# 권한 설정
sudo chmod 600 /etc/nginx/ssl/key.pem
sudo chmod 644 /etc/nginx/ssl/cert.pem
sudo chown nginx:nginx /etc/nginx/ssl/*
```

### 2. Let's Encrypt 무료 SSL 인증서 (프로덕션용)

#### certbot 설치
```bash
# EPEL 저장소 활성화
sudo yum install -y epel-release

# certbot 설치
sudo yum install -y certbot python3-certbot-nginx
```

#### 도메인 인증서 발급
```bash
# nginx 설정 파일 백업
sudo cp /etc/nginx/conf.d/minshool-production.conf /etc/nginx/conf.d/minshool-production.conf.backup

# HTTP 전용 설정으로 임시 변경
sudo vi /etc/nginx/conf.d/minshool-production.conf
```

#### 임시 HTTP 설정:
```nginx
server {
    listen 80;
    server_name mincenter.kr www.mincenter.kr;
    
    location / {
        proxy_pass http://minshool_site;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /admin {
        proxy_pass http://minshool_admin;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api {
        proxy_pass http://minshool_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### nginx 재시작 및 인증서 발급
```bash
# nginx 재시작
sudo systemctl restart nginx
sudo systemctl status nginx

# SSL 인증서 발급
sudo certbot --nginx -d mincenter.kr -d www.mincenter.kr

# 자동 갱신 설정
sudo crontab -e
```

#### crontab에 추가:
```bash
0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. 수동 SSL 인증서 설정

#### 인증서 파일 업로드
```bash
# 로컬에서 서버로 인증서 파일 업로드
scp -P 22000 cert.pem mincenter@your_server_ip:/tmp/
scp -P 22000 key.pem mincenter@your_server_ip:/tmp/

# 서버에서 파일 이동
sudo mv /tmp/cert.pem /etc/nginx/ssl/
sudo mv /tmp/key.pem /etc/nginx/ssl/

# 권한 설정
sudo chmod 600 /etc/nginx/ssl/key.pem
sudo chmod 644 /etc/nginx/ssl/cert.pem
sudo chown nginx:nginx /etc/nginx/ssl/*
```

### 4. nginx 설정 검증 및 재시작

#### 설정 파일 검증
```bash
# nginx 설정 문법 검사
sudo nginx -t

# 설정 파일 테스트
sudo nginx -T | grep ssl
```

#### nginx 재시작
```bash
# nginx 재시작
sudo systemctl restart nginx
sudo systemctl status nginx

# 로그 확인
sudo tail -f /var/log/nginx/error.log
```

### 5. SSL 설정 최적화

#### 보안 강화 설정
```nginx
# SSL 설정 최적화
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;

# OCSP Stapling
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;

# HSTS 헤더
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

## 🔍 문제 해결

### 1. 인증서 파일 확인
```bash
# 인증서 파일 존재 확인
ls -la /etc/nginx/ssl/

# 인증서 내용 확인
sudo openssl x509 -in /etc/nginx/ssl/cert.pem -text -noout

# 개인키 확인
sudo openssl rsa -in /etc/nginx/ssl/key.pem -check
```

### 2. nginx 로그 확인
```bash
# 에러 로그 확인
sudo tail -f /var/log/nginx/error.log

# 액세스 로그 확인
sudo tail -f /var/log/nginx/access.log
```

### 3. 포트 확인
```bash
# 80, 443 포트 리스닝 확인
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 또는 ss 명령어 사용
sudo ss -tlnp | grep :80
sudo ss -tlnp | grep :443
```

## 🛡️ 보안 체크리스트

- [ ] SSL 인증서 파일 존재 확인
- [ ] 인증서 파일 권한 설정 (600/644)
- [ ] nginx 사용자 소유권 설정
- [ ] SSL 프로토콜 버전 설정 (TLS 1.2+)
- [ ] 안전한 암호화 스위트 설정
- [ ] HSTS 헤더 설정
- [ ] OCSP Stapling 설정
- [ ] 자동 인증서 갱신 설정

## 📊 SSL 상태 확인

### 온라인 도구
- [SSL Labs SSL Test](https://www.ssllabs.com/ssltest/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

### 명령어 도구
```bash
# SSL 연결 테스트
openssl s_client -connect mincenter.kr:443 -servername mincenter.kr

# 인증서 체인 확인
openssl s_client -connect mincenter.kr:443 -showcerts

# 암호화 스위트 확인
nmap --script ssl-enum-ciphers -p 443 mincenter.kr
```

## 🚨 응급 상황

### nginx 시작 실패 시
```bash
# 설정 파일 백업에서 복원
sudo cp /etc/nginx/conf.d/minshool-production.conf.backup /etc/nginx/conf.d/minshool-production.conf

# HTTP 전용으로 임시 설정
sudo vi /etc/nginx/conf.d/minshool-production.conf

# nginx 재시작
sudo systemctl restart nginx
```

### 인증서 만료 시
```bash
# Let's Encrypt 자동 갱신
sudo certbot renew

# 수동 갱신
sudo certbot renew --force-renewal
```

## 📝 참고 자료

- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [SSL Labs SSL Test](https://www.ssllabs.com/ssltest/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/) 