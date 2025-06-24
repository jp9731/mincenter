# CentOS 7 배포 가이드

이 가이드는 CentOS 7 환경에서 MinSchool 애플리케이션을 배포하는 방법을 설명합니다.

## 📋 사전 요구사항

### 시스템 요구사항
- CentOS 7 (최소 2GB RAM, 20GB 디스크)
- 루트 권한 또는 sudo 권한
- 인터넷 연결

### 필수 소프트웨어
- Docker 1.13 이상
- Docker Compose 1.18 이상
- Git
- Node.js 18+ (PM2 사용 시)

## 🚀 1단계: 시스템 업데이트

```bash
# 시스템 업데이트
sudo yum update -y

# EPEL 저장소 활성화
sudo yum install -y epel-release

# 개발 도구 설치
sudo yum groupinstall -y "Development Tools"
```

## 🐳 2단계: Docker 설치

### Docker CE 설치
```bash
# 이전 Docker 제거
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Docker 저장소 추가
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Docker CE 설치
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Docker 서비스 시작 및 자동 시작 설정
sudo systemctl start docker
sudo systemctl enable docker

# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
```

### Docker Compose 설치
```bash
# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 심볼릭 링크 생성
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

## 📁 3단계: 프로젝트 클론

```bash
# 프로젝트 디렉토리 생성
sudo mkdir -p /var/www
cd /var/www

# 프로젝트 클론
sudo git clone https://github.com/your-username/your-repo.git minshool
cd minshool

# 권한 설정
sudo chown -R $USER:$USER /var/www/minshool
```

## ⚙️ 4단계: 환경 변수 설정

```bash
# 환경 변수 파일 복사
cp env.example .env

# 환경 변수 편집
nano .env
```

### 주요 환경 변수 설정
```bash
# Application Configuration
APP_NAME=mincenter
NODE_ENV=production
DOMAIN=mincenter.kr

# Database Configuration
POSTGRES_DB=mincenter
POSTGRES_USER=mincenter
POSTGRES_PASSWORD=!@swjp0209^^
POSTGRES_PORT=15432

# API Configuration
API_PORT=18080
API_URL=http://localhost:18080
PUBLIC_API_URL=https://api.mincenter.kr
JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
RUST_LOG_LEVEL=info
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr

# Site Configuration
SITE_PORT=13000
SESSION_SECRET=generate_32_character_random_string

# Admin Configuration
ADMIN_PORT=13001
ADMIN_SESSION_SECRET=mByehQKM5tYxlsAFTFpWiKBpsrBiSFwoLTblYKCu+Hs=
ADMIN_EMAIL=admin@mincenter.kr

# Redis Configuration
REDIS_PORT=6379
REDIS_PASSWORD=change_this_redis_password

# Nginx Configuration
HTTP_PORT=80
HTTPS_PORT=443

# SSL Configuration
SSL_EMAIL=ssl@mincenter.kr

# Backup Configuration
BACKUP_SCHEDULE=0 2 * * *
BACKUP_RETENTION_DAYS=7

# Monitoring Configuration
MONITORING_ENABLED=true
LOG_LEVEL=info
```

## 🔧 5단계: 방화벽 설정

```bash
# 방화벽 서비스 시작
sudo systemctl start firewalld
sudo systemctl enable firewalld

# 필요한 포트 열기
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=18080/tcp  # API
sudo firewall-cmd --permanent --add-port=13000/tcp  # Site
sudo firewall-cmd --permanent --add-port=13001/tcp  # Admin
sudo firewall-cmd --permanent --add-port=15432/tcp  # PostgreSQL
sudo firewall-cmd --permanent --add-port=6379/tcp   # Redis
sudo firewall-cmd --permanent --add-port=22000/tcp  # SSH (GitHub Actions)

# 방화벽 규칙 적용
sudo firewall-cmd --reload

# 방화벽 상태 확인
sudo firewall-cmd --list-all
```

## 🚀 6단계: Docker Compose 배포

### 자동 배포 스크립트 사용
```bash
# 배포 스크립트 실행 권한 부여
chmod +x scripts/deploy.sh

# 배포 실행
./scripts/deploy.sh
```

### 수동 배포
```bash
# 기존 컨테이너 중지
docker-compose -f docker-compose.prod.yml down

# 최신 이미지 가져오기
docker-compose -f docker-compose.prod.yml pull

# 새 이미지 빌드
docker-compose -f docker-compose.prod.yml build --no-cache

# 컨테이너 시작
docker-compose -f docker-compose.prod.yml up -d

# 상태 확인
docker-compose -f docker-compose.prod.yml ps
```

## 🌐 7단계: Nginx 설정

### Nginx 설치
```bash
# Nginx 설치
sudo yum install -y nginx

# Nginx 서비스 시작
sudo systemctl start nginx
sudo systemctl enable nginx
```

### Nginx 설정 파일 복사
```bash
# 설정 파일 복사
sudo cp nginx/minshool.conf /etc/nginx/conf.d/

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

### SSL 인증서 설정 (Let's Encrypt)
```bash
# Certbot 설치
sudo yum install -y certbot python3-certbot-nginx

# SSL 인증서 발급
sudo certbot --nginx -d mincenter.kr -d www.mincenter.kr

# 자동 갱신 설정
sudo crontab -e
# 다음 줄 추가: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 📊 8단계: 모니터링 설정

### PM2 설치 (선택사항)
```bash
# Node.js 설치
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# PM2 설치
sudo npm install -g pm2

# PM2 시작 스크립트 생성
pm2 startup
```

### 로그 모니터링
```bash
# Docker 로그 확인
docker-compose -f docker-compose.prod.yml logs -f

# Nginx 로그 확인
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

## 🔍 9단계: 헬스체크

```bash
# 서비스 상태 확인
curl -f http://localhost:13000 || echo "Site 비정상"
curl -f http://localhost:13001 || echo "Admin 비정상"
curl -f http://localhost:18080/health || echo "API 비정상"

# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps
```

## 🛠️ 10단계: 백업 설정

### 자동 백업 스크립트
```bash
# 백업 디렉토리 생성
sudo mkdir -p /var/backups/minshool

# 백업 스크립트 생성
sudo nano /usr/local/bin/backup-minshool.sh
```

```bash
#!/bin/bash
# 백업 스크립트 내용
BACKUP_DIR="/var/backups/minshool"
DATE=$(date +%Y%m%d_%H%M%S)

# PostgreSQL 백업
docker-compose -f /var/www/minshool/docker-compose.prod.yml exec -T postgres pg_dump -U mincenter mincenter > $BACKUP_DIR/db_$DATE.sql

# 파일 백업
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /var/www/minshool/static

# 7일 이상 된 백업 삭제
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

```bash
# 실행 권한 부여
sudo chmod +x /usr/local/bin/backup-minshool.sh

# Cron 작업 추가
sudo crontab -e
# 다음 줄 추가: 0 2 * * * /usr/local/bin/backup-minshool.sh
```

## 🔧 문제 해결

### 일반적인 문제들

#### 1. Docker 권한 문제
```bash
# Docker 그룹에 사용자 추가
sudo usermod -aG docker $USER
# 로그아웃 후 다시 로그인
```

#### 2. 포트 충돌
```bash
# 사용 중인 포트 확인
sudo netstat -tlnp | grep :13000
sudo netstat -tlnp | grep :13001
sudo netstat -tlnp | grep :18080
```

#### 3. 디스크 공간 부족
```bash
# 불필요한 Docker 이미지 정리
docker system prune -a

# 로그 파일 정리
sudo journalctl --vacuum-time=7d
```

#### 4. 메모리 부족
```bash
# 스왑 파일 생성
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:

1. **로그 확인**: `docker-compose -f docker-compose.prod.yml logs`
2. **서비스 상태**: `docker-compose -f docker-compose.prod.yml ps`
3. **시스템 리소스**: `htop`, `df -h`, `free -h`
4. **네트워크 연결**: `ping`, `curl`, `telnet`

## 🎉 배포 완료!

성공적으로 배포되면 다음 URL로 접속할 수 있습니다:

- **메인 사이트**: http://mincenter.kr (포트 13000)
- **관리자 페이지**: http://admin.mincenter.kr (포트 13001)
- **API**: https://api.mincenter.kr (포트 18080)

모든 서비스가 정상적으로 작동하는지 확인하고, 정기적인 모니터링과 백업을 수행하세요. 