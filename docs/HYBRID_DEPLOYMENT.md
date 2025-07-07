# MinSchool 하이브리드 배포 가이드

## 개요

MinSchool은 하이브리드 배포 방식을 사용합니다:
- **Frontend (Site/Admin)**: Docker Node.js 20에서 빌드 후 정적 파일로 서빙
- **PostgreSQL**: Docker 컨테이너로 실행
- **Redis**: Docker 컨테이너로 실행
- **API**: 서버에서 직접 빌드 및 systemd 서비스로 실행 (Docker로 감싸지 않음, 포트 18080)
- **Nginx**: Docker 컨테이너로 실행 (정적 파일 서빙 + API 프록시)

### 서브도메인 구성
- **메인 사이트**: `http://mincenter.kr`, `http://www.mincenter.kr` (정적 파일)
- **관리자 페이지**: `http://admin.mincenter.kr` (정적 파일)
- **API 서버**: `http://api.mincenter.kr` (systemd로 관리, 18080 포트)

이 방식의 장점:
- Node.js 버전 충돌 문제 해결 (Docker Node.js 20 사용)
- 서브도메인으로 명확한 서비스 분리
- Frontend는 정적 파일로 빠른 서빙
- API는 최적화된 바이너리로 빠른 실행 (Docker 미사용)
- 개발 환경과 프로덕션 환경의 일관성

## 사전 요구사항

### 1. Docker 설치
```bash
# CentOS 7
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
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

### 3. Frontend 빌드 (Docker Node.js 20)
```bash
# Site 빌드
docker run --rm -v "$(pwd)/frontends/site:/app" -w /app node:20-alpine sh -c "
  npm ci
  npm run build
"

# Admin 빌드
docker run --rm -v "$(pwd)/frontends/admin:/app" -w /app node:20-alpine sh -c "
  npm ci
  npm run build
"
```

### 4. Docker Compose로 DB/Redis/Nginx 실행
```bash
docker-compose -f docker-compose.hybrid.yml up -d --build
```

## 배포 자동화 (GitHub Actions)

### 1. GitHub Secrets 설정
- `DEPLOY_SSH_KEY`: 서버 SSH 개인키
- `DEPLOY_HOST`: 서버 IP 주소
- `DEPLOY_USER`: 서버 사용자명
- `DEPLOY_PATH`: 배포 경로

### 2. 배포 프로세스
1. **Frontend 빌드**: Docker Node.js 20 컨테이너에서 빌드
2. **API 빌드**: 서버에서 직접 빌드 및 systemd 서비스 등록
3. **Docker 서비스**: PostgreSQL, Redis, Nginx 컨테이너 시작

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

### Frontend (정적 파일)
```bash
# 빌드 (Docker Node.js 20)
docker run --rm -v "$(pwd)/frontends/site:/app" -w /app node:20-alpine sh -c "npm ci && npm run build"
docker run --rm -v "$(pwd)/frontends/admin:/app" -w /app node:20-alpine sh -c "npm ci && npm run build"

# 정적 파일 위치
# Site: ./frontends/site/static/
# Admin: ./frontends/admin/static/
```

### DB/Redis/Nginx (Docker)
```bash
docker-compose -f docker-compose.hybrid.yml up -d --build
docker-compose -f docker-compose.hybrid.yml logs -f
```

## 포트 구성

| 서비스 | 포트 | 도메인 | 실행 방식 |
|--------|------|--------|-----------|
| API | 18080 | api.mincenter.kr | 바이너리 (systemd) |
| Site | 80 | mincenter.kr, www.mincenter.kr | 정적 파일 (Nginx) |
| Admin | 80 | admin.mincenter.kr | 정적 파일 (Nginx) |
| PostgreSQL | 15432 | - | Docker |
| Redis | 16379 | - | Docker |
| Nginx | 80/443 | 모든 서브도메인 | Docker |

## 환경변수

### API (systemd 서비스)
```bash
DATABASE_URL=postgresql://postgres:password@localhost:15432/mincenter
REDIS_URL=redis://:default_password@localhost:16379
JWT_SECRET=your_jwt_secret_here
API_PORT=18080
RUST_LOG=info
CORS_ORIGIN=*
```

### Frontend 빌드 시
```bash
NODE_ENV=production
API_URL=http://api.mincenter.kr
```

## 문제 해결

### 1. Frontend 빌드 실패
```bash
# Node.js 버전 확인
docker run --rm node:20-alpine node --version

# 의존성 문제 해결
docker run --rm -v "$(pwd)/frontends/site:/app" -w /app node:20-alpine sh -c "
  rm -rf node_modules package-lock.json
  npm ci
  npm run build
"
```

### 2. API 서버 연결 실패
```bash
# API 서버 상태 확인
sudo systemctl status minshool-api

# 포트 확인
netstat -tlnp | grep 18080

# 로그 확인
sudo journalctl -u minshool-api -f
```

### 3. 정적 파일 서빙 문제
```bash
# 빌드된 파일 확인
ls -la frontends/site/static/
ls -la frontends/admin/static/

# Nginx 로그 확인
docker-compose -f docker-compose.hybrid.yml logs nginx
```

## 기타 참고사항
- API 서버는 반드시 18080 포트로 리스닝해야 하며, nginx에서 `api.mincenter.kr`로 프록시됩니다.
- Frontend는 빌드 후 정적 파일로 서빙되므로 Node.js 서버가 필요하지 않습니다.
- API 환경변수는 systemd 서비스 파일에서 관리됩니다. 