# 배포 가이드

## 개요

이 프로젝트는 다음과 같은 구조로 배포됩니다:

- **PostgreSQL**: Docker 컨테이너로 실행
- **Redis**: Docker 컨테이너로 실행  
- **Site (Frontend)**: Docker 컨테이너로 실행
- **Admin (Frontend)**: Docker 컨테이너로 실행
- **API (Backend)**: 로컬 Rust 빌드로 실행

## 사전 요구사항

### 1. 시스템 요구사항
- CentOS 7 이상
- Docker 1.13 이상
- Docker Compose 1.18 이상
- Rust 1.70 이상

### 2. 소프트웨어 설치

#### Docker 설치
```bash
# Docker 설치
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

# Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER
```

#### Rust 설치
```bash
# Rust 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 환경 변수 설정
source ~/.cargo/env
echo 'source ~/.cargo/env' >> ~/.bashrc

# 설치 확인
rustc --version
cargo --version
```

## 배포 방법

### 1. 자동 배포 (GitHub Actions)

GitHub 저장소에 코드를 푸시하면 자동으로 배포됩니다.

**필요한 GitHub Secrets:**
- `DEPLOY_SSH_KEY`: 서버 SSH 개인키
- `DEPLOY_HOST`: 서버 IP 주소
- `DEPLOY_USER`: 서버 사용자명
- `DEPLOY_PATH`: 배포 경로 (예: /home/mincenter/www)

### 2. 수동 배포

#### 환경 변수 설정
```bash
# .env 파일 생성
cp .env.example .env

# 환경 변수 편집
vim .env
```

**필수 환경 변수:**
```bash
# 애플리케이션 설정
APP_NAME=mincenter
NODE_ENV=production

# 데이터베이스 설정
POSTGRES_DB=minshool_db
POSTGRES_USER=mincenter
POSTGRES_PASSWORD=your_password
POSTGRES_PORT=15432

# API 설정
API_PORT=18080
JWT_SECRET=your_jwt_secret_key
ACCESS_TOKEN_EXPIRY=60
REFRESH_TOKEN_EXPIRY=30

# 프론트엔드 설정
SITE_PORT=13000
ADMIN_PORT=13001
API_URL=http://localhost:18080
PUBLIC_API_URL=http://your-domain.com:18080

# Redis 설정
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# 세션 설정
SESSION_SECRET=your_session_secret
ADMIN_SESSION_SECRET=your_admin_session_secret
ADMIN_EMAIL=admin@example.com
```

#### 배포 실행
```bash
# 전체 배포
./scripts/deploy.sh

# 또는 단계별 실행
# 1. Docker 서비스 시작
docker-compose -f docker-compose.prod.yml up -d

# 2. 데이터베이스 마이그레이션
./scripts/migrate.sh

# 3. API 서비스 시작
./scripts/api-service.sh start
```

## 서비스 관리

### API 서비스 관리
```bash
# API 서비스 시작
./scripts/api-service.sh start

# API 서비스 중지
./scripts/api-service.sh stop

# API 서비스 재시작
./scripts/api-service.sh restart

# API 서비스 상태 확인
./scripts/api-service.sh status

# API 로그 확인
./scripts/api-service.sh logs

# API 로그 실시간 확인
./scripts/api-service.sh logs -f

# API 빌드
./scripts/api-service.sh build
```

### Docker 서비스 관리
```bash
# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 서비스 로그 확인
docker-compose -f docker-compose.prod.yml logs [service_name]

# 서비스 재시작
docker-compose -f docker-compose.prod.yml restart [service_name]

# 모든 서비스 중지
docker-compose -f docker-compose.prod.yml down

# 모든 서비스 시작
docker-compose -f docker-compose.prod.yml up -d
```

## 데이터베이스 관리

### 마이그레이션
```bash
# 마이그레이션 실행
./scripts/migrate.sh

# 또는 수동으로
cd backends/api
sqlx migrate run
```

### 마이그레이션 생성
```bash
cd backends/api

# 새 마이그레이션 생성
sqlx migrate add migration_name

# 마이그레이션 파일 편집
vim migrations/YYYYMMDDHHMMSS_migration_name.sql
```

### 마이그레이션 롤백
```bash
cd backends/api

# 마이그레이션 되돌리기
sqlx migrate revert
```

## 모니터링

### 서비스 상태 확인
```bash
# 전체 서비스 상태
./scripts/deploy.sh status

# 개별 서비스 상태
docker-compose -f docker-compose.prod.yml ps
./scripts/api-service.sh status
```

### 로그 확인
```bash
# API 로그
./scripts/api-service.sh logs -f

# Docker 서비스 로그
docker-compose -f docker-compose.prod.yml logs -f [service_name]
```

### 헬스체크
```bash
# API 헬스체크
curl http://localhost:18080/health

# 사이트 헬스체크
curl http://localhost:13000

# 관리자 페이지 헬스체크
curl http://localhost:13001
```

## 문제 해결

### API 서비스 문제
```bash
# API 프로세스 확인
ps aux | grep minshool-api

# API 로그 확인
tail -f backends/api/api.log

# API 재시작
./scripts/api-service.sh restart
```

### 데이터베이스 문제
```bash
# PostgreSQL 연결 확인
docker-compose -f docker-compose.prod.yml exec postgres pg_isready

# 데이터베이스 로그 확인
docker-compose -f docker-compose.prod.yml logs postgres
```

### 포트 충돌 문제
```bash
# 포트 사용 확인
netstat -tlnp | grep -E ':(13000|13001|18080|15432|6379)'

# 프로세스 종료
sudo kill -9 [PID]
```

## 백업 및 복구

### 데이터베이스 백업
```bash
# PostgreSQL 백업
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U mincenter minshool_db > backup.sql

# Redis 백업
docker-compose -f docker-compose.prod.yml exec redis redis-cli --rdb /data/dump.rdb
```

### 데이터베이스 복구
```bash
# PostgreSQL 복구
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U mincenter minshool_db < backup.sql
```

## 보안 고려사항

1. **환경 변수 보안**: `.env` 파일의 민감한 정보를 안전하게 관리
2. **포트 노출**: 필요한 포트만 외부에 노출
3. **방화벽 설정**: 필요한 포트만 열어두기
4. **정기 업데이트**: Docker 이미지와 Rust 버전 정기 업데이트

## 성능 최적화

1. **API 서비스**: `cargo build --release`로 최적화된 빌드 사용
2. **데이터베이스**: PostgreSQL 설정 최적화
3. **Redis**: 메모리 사용량 모니터링
4. **프론트엔드**: 정적 파일 압축 및 캐싱 