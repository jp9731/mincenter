# CentOS 7 배포 가이드

이 문서는 CentOS 7 환경에서 애플리케이션을 배포하는 방법을 설명합니다.

## 📋 시스템 요구사항

### 최소 요구사항
- **OS**: CentOS 7.0 이상
- **CPU**: 2코어 이상
- **RAM**: 4GB 이상
- **디스크**: 20GB 이상의 여유 공간
- **네트워크**: 인터넷 연결

### 권장사항
- **CPU**: 4코어 이상
- **RAM**: 8GB 이상
- **디스크**: 50GB 이상의 여유 공간

## 🚀 설치 및 배포 과정

### 1단계: 시스템 환경 설정

```bash
# CentOS 7 환경 설정 스크립트 실행
sudo ./scripts/centos7-setup.sh
```

이 스크립트는 다음 작업을 수행합니다:
- 시스템 업데이트
- Docker 및 Docker Compose 설치
- 방화벽 설정
- SELinux 설정
- 시스템 리소스 최적화

### 2단계: 환경 변수 설정

```bash
# 환경 변수 파일 복사
cp env.example .env

# 환경 변수 편집
nano .env
```

필수 환경 변수:
```bash
# 애플리케이션 설정
APP_NAME=minshool
NODE_ENV=production

# 데이터베이스 설정
POSTGRES_DB=minshool_db
POSTGRES_USER=minshool_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_PORT=5432

# API 설정
API_PORT=8080
JWT_SECRET=your_jwt_secret_key
RUST_LOG_LEVEL=info
CORS_ORIGIN=https://your-domain.com

# 프론트엔드 설정
SITE_PORT=3000
ADMIN_PORT=3001
API_URL=http://localhost:8080
PUBLIC_API_URL=https://your-domain.com/api

# 세션 설정
SESSION_SECRET=your_session_secret
ADMIN_SESSION_SECRET=your_admin_session_secret
ADMIN_EMAIL=admin@your-domain.com

# Redis 설정
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# Nginx 설정
HTTP_PORT=80
HTTPS_PORT=443
DOMAIN=your-domain.com
```

### 3단계: SSL 인증서 준비

```bash
# SSL 인증서 디렉토리 생성
sudo mkdir -p nginx/ssl

# 자체 서명 인증서 생성 (개발용)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=MinSchool/CN=your-domain.com"

# 실제 인증서 사용 시 (Let's Encrypt 등)
# sudo cp /path/to/your/cert.pem nginx/ssl/
# sudo cp /path/to/your/key.pem nginx/ssl/
```

### 4단계: 애플리케이션 배포

```bash
# 배포 스크립트 실행
./scripts/deploy.sh
```

## 🔧 CentOS 7 특별 고려사항

### SELinux 설정

SELinux가 활성화된 경우 Docker 컨테이너 실행에 문제가 발생할 수 있습니다.

```bash
# SELinux 상태 확인
getenforce

# 임시 비활성화
sudo setenforce 0

# 영구 비활성화 (재부팅 후 적용)
sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

### 방화벽 설정

CentOS 7의 기본 방화벽(firewalld)에서 필요한 포트를 열어야 합니다.

```bash
# 방화벽 상태 확인
sudo firewall-cmd --state

# 필요한 포트 열기
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=3001/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp

# 방화벽 재시작
sudo firewall-cmd --reload
```

### 시스템 리소스 최적화

```bash
# 파일 디스크립터 제한 확인
ulimit -n

# 커널 파라미터 확인
sysctl vm.max_map_count
```

## 🐛 문제 해결

### 일반적인 문제들

#### 1. Docker 권한 문제
```bash
# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 재로그인 후 확인
docker ps
```

#### 2. 포트 충돌
```bash
# 사용 중인 포트 확인
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# 충돌하는 서비스 중지
sudo systemctl stop httpd  # Apache가 실행 중인 경우
```

#### 3. 디스크 공간 부족
```bash
# 디스크 사용량 확인
df -h

# Docker 정리
docker system prune -a
```

#### 4. 메모리 부족
```bash
# 메모리 사용량 확인
free -h

# 스왑 공간 추가 (필요시)
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 로그 확인

```bash
# 컨테이너 로그 확인
docker-compose -f docker-compose.prod.yml logs api
docker-compose -f docker-compose.prod.yml logs site
docker-compose -f docker-compose.prod.yml logs admin

# 실시간 로그 모니터링
docker-compose -f docker-compose.prod.yml logs -f
```

## 📊 모니터링

### 서비스 상태 확인

```bash
# 모든 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 헬스체크
curl http://localhost:8080/health
curl http://localhost:3000
curl http://localhost:3001
```

### 성능 모니터링

```bash
# 시스템 리소스 모니터링
htop
iotop
nethogs

# Docker 리소스 사용량
docker stats
```

## 🔄 업데이트 및 유지보수

### 애플리케이션 업데이트

```bash
# 최신 코드 가져오기
git pull origin main

# 재배포
./scripts/deploy.sh
```

### 백업

```bash
# 데이터베이스 백업
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup_$(date +%Y%m%d_%H%M%S).sql

# 볼륨 백업
docker run --rm -v minshool_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:

1. 시스템 로그: `sudo journalctl -f`
2. Docker 로그: `docker-compose -f docker-compose.prod.yml logs`
3. Nginx 로그: `sudo tail -f /var/log/nginx/error.log`

## 📝 참고사항

- CentOS 7은 2024년 6월 30일에 EOL(End of Life)이 예정되어 있습니다.
- 프로덕션 환경에서는 CentOS 8 또는 Rocky Linux 8/9 사용을 권장합니다.
- 이 설정은 개발 및 테스트 환경에 최적화되어 있습니다. 