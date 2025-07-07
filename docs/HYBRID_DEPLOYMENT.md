# MinSchool 하이브리드 배포 가이드

## 개요

MinSchool은 하이브리드 배포 방식을 사용합니다:
- **Frontend (Site/Admin)**: Docker 컨테이너로 실행 (Node.js 20)
- **PostgreSQL**: Docker 컨테이너로 실행
- **Redis**: Docker 컨테이너로 실행
- **API**: 서버에서 직접 빌드 및 systemd 서비스로 실행 (Docker로 감싸지 않음, 포트 18080)

### 서브도메인 구성
- **메인 사이트**: `http://mincenter.kr`, `http://www.mincenter.kr`
- **관리자 페이지**: `http://admin.mincenter.kr`
- **API 서버**: `http://api.mincenter.kr` (systemd로 관리, 18080 포트)

이 방식의 장점:
- Node.js 버전 충돌 문제 해결 (Node.js 20 사용)
- 서브도메인으로 명확한 서비스 분리
- 포트 바인딩으로 격리된 환경
- API는 최적화된 바이너리로 빠른 실행 (Docker 미사용)
- 개발 환경과 프로덕션 환경의 일관성

## 사전 요구사항

### 1. Docker 설치
```bash
# macOS
brew install docker docker-compose

# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose

# CentOS 7
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. API 서버 빌드 및 서비스 등록 (서버에서 직접)
```bash
# 서버에서 직접 실행
bash scripts/server-build-api.sh
```
- Rust, gcc, openssl-devel 등 의존성 자동 설치
- `/opt/minshool-api/minshool-api`로 바이너리 복사
- `/etc/systemd/system/minshool-api.service` 등록 및 자동 재시작
- 18080 포트로 리스닝

### 3. Docker Compose로 프론트엔드/DB/Redis/Nginx 실행
```bash
docker-compose -f docker-compose.hybrid.yml up -d --build
```
- **API 서비스는 Docker Compose에 포함되지 않음**

## 배포 자동화 (GitHub Actions)
- 서버에 코드 복사 후, `scripts/server-build-api.sh` 실행
- 이후 Docker Compose로 프론트엔드/DB/Redis/Nginx만 재시작

## 서비스 관리

### API (Rust)
```bash
# 빌드 및 서비스 등록/재시작
bash scripts/server-build-api.sh

# 서비스 상태 확인
sudo systemctl status minshool-api

# 로그 확인
sudo journalctl -u minshool-api -f

# 수동 재시작
sudo systemctl restart minshool-api
```

### 프론트엔드/DB/Redis/Nginx (Docker)
```bash
docker-compose -f docker-compose.hybrid.yml up -d --build
docker-compose -f docker-compose.hybrid.yml logs -f
```

## 기타 참고사항
- API 서버는 반드시 18080 포트로 리스닝해야 하며, nginx에서 `api.mincenter.kr`로 프록시됩니다.
- API 환경변수는 systemd 서비스 파일에서 관리됩니다.
- 서버에서 직접 빌드가 어려운 경우, CentOS 7 환경에서 빌드 후 바이너리만 복사해도 무방합니다.

## 포트 구성

| 서비스 | 포트 | 도메인 | 실행 방식 |
|--------|------|--------|-----------|
| API | 18080 | api.mincenter.kr | 바이너리 |
| Site | 13000 | mincenter.kr, www.mincenter.kr | Docker |
| Admin | 13001 | admin.mincenter.kr | Docker |
| PostgreSQL | 15432 | - | Docker |
| Redis | 16379 | - | Docker |
| Nginx | 80/443 | 모든 서브도메인 | Docker |

## 환경변수

### 필수 환경변수
```bash
APP_NAME=mincenter
POSTGRES_DB=mincenter
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password
REDIS_PASSWORD=default_password
API_URL=http://api.mincenter.kr
DOMAIN=mincenter.kr
```

### 선택적 환경변수
```bash
REDIS_PORT=16379
HTTP_PORT=80
HTTPS_PORT=443
JWT_SECRET=your_jwt_secret_here
RUST_LOG=info
CORS_ORIGIN=*
```

## 문제 해결

### 1. API 서버 연결 실패
```bash
# API 서버 상태 확인
sudo systemctl status minshool-api

# 로그 확인
sudo journalctl -u minshool-api -f

# 포트 확인
netstat -tlnp | grep 18080

# 서브도메인 연결 확인
curl -f http://api.mincenter.kr/health
```

### 2. 빌드 실패
```bash
# 의존성 확인
./scripts/build-centos7.sh check_dependencies

# Rust 버전 확인
rustc --version

# 타겟 확인
rustup target list --installed

# 클린 빌드
./scripts/build-centos7.sh clean
./scripts/build-centos7.sh build
```

### 3. Docker 서비스 문제
```bash
# 컨테이너 상태 확인
docker-compose -f docker-compose.hybrid.yml ps

# 로그 확인
docker-compose -f docker-compose.hybrid.yml logs

# 특정 서비스 로그
docker-compose -f docker-compose.hybrid.yml logs site
docker-compose -f docker-compose.hybrid.yml logs postgres
```

### 4. 서브도메인 연결 문제
```bash
# DNS 확인
nslookup mincenter.kr
nslookup admin.mincenter.kr
nslookup api.mincenter.kr

# HTTP 연결 확인
curl -I http://mincenter.kr
curl -I http://admin.mincenter.kr
curl -I http://api.mincenter.kr
```

### 5. SSL 인증서 문제
```bash
# SSL 상태 확인
./scripts/setup-ssl.sh status

# 인증서 수동 갱신
sudo certbot renew

# nginx 설정 테스트
sudo nginx -t

# nginx 재시작
sudo systemctl reload nginx
```

### 6. 데이터베이스 연결 문제
```bash
# PostgreSQL 컨테이너 접속
docker exec -it mincenter_postgres psql -U postgres -d mincenter

# Redis 컨테이너 접속
docker exec -it mincenter_redis redis-cli
```

### 7. 포트 충돌
```bash
# 포트 사용 현황 확인
netstat -tlnp | grep -E ':(80|443|13000|13001|15432|16379|18080)'

# 충돌하는 프로세스 종료
sudo lsof -ti:18080 | xargs kill -9
```

## 성능 최적화

### 1. API 서버 최적화
```bash
# systemd 리소스 제한 설정
sudo tee /etc/systemd/system/minshool-api.service > /dev/null << 'EOF'
[Unit]
Description=MinShool API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/minshool-api
ExecStart=/opt/minshool-api/minshool-api
Restart=always
RestartSec=3
Environment=DATABASE_URL=postgresql://postgres:password@localhost:15432/mincenter
Environment=REDIS_URL=redis://:default_password@localhost:16379
Environment=JWT_SECRET=your_jwt_secret_here
Environment=API_PORT=18080
Environment=RUST_LOG=info
Environment=CORS_ORIGIN=*
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
```

### 2. Docker 리소스 제한
```yaml
# docker-compose.hybrid.yml
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
```

## 모니터링

### 1. 시스템 모니터링
```bash
# 시스템 리소스 사용량
htop
iotop
nethogs

# Docker 리소스 사용량
docker stats
```

### 2. 로그 모니터링
```bash
# 실시간 로그 확인
tail -f /tmp/minshool-api.log
docker-compose -f docker-compose.hybrid.yml logs -f

# 서브도메인별 로그 확인
tail -f /var/log/nginx/minshool_site_access.log
tail -f /var/log/nginx/minshool_admin_access.log
tail -f /var/log/nginx/minshool_api_access.log

# SSL 로그 확인
tail -f /var/log/letsencrypt/letsencrypt.log

# 로그 로테이션 설정
sudo logrotate -f /etc/logrotate.d/minshool-api
```

## 백업 및 복구

### 1. 데이터베이스 백업
```bash
# PostgreSQL 백업
docker exec mincenter_postgres pg_dump -U postgres mincenter > backup_$(date +%Y%m%d_%H%M%S).sql

# Redis 백업
docker exec mincenter_redis redis-cli BGSAVE
docker cp mincenter_redis:/data/dump.rdb ./redis_backup_$(date +%Y%m%d_%H%M%S).rdb
```

### 2. 파일 백업
```bash
# 업로드된 파일 백업
tar -czf uploads_backup_$(date +%Y%m%d_%H%M%S).tar.gz backends/api/static/uploads/

# 설정 파일 백업
tar -czf config_backup_$(date +%Y%m%d_%H%M%S).tar.gz database/ nginx/

# SSL 인증서 백업
sudo tar -czf ssl_backup_$(date +%Y%m%d_%H%M%S).tar.gz /etc/letsencrypt/

# API 바이너리 백업
cp build/centos7/minshool-api backup_binary_$(date +%Y%m%d_%H%M%S)
``` 