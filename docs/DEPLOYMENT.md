# 배포 가이드

## 개요

이 프로젝트는 다음과 같은 구조로 배포됩니다:

- **PostgreSQL**: Docker 컨테이너로 실행
- **Redis**: Docker 컨테이너로 실행  
- **Site (Frontend)**: Docker 컨테이너로 실행
- **Admin (Frontend)**: Docker 컨테이너로 실행
- **API (Backend)**: 로컬 Rust 빌드로 실행 (배포 스크립트에서 제외)

> **⚠️ 중요**: API 서버는 배포 스크립트에서 자동으로 관리되지 않습니다. API는 별도로 빌드하고 실행해야 합니다.

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

#### Docker Compose 설치
```bash
# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 심볼릭 링크 생성
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
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

# 2. 데이터베이스 마이그레이션 (납품 시 수동 처리)
# ./scripts/migrate.sh  # 비활성화됨
echo "데이터베이스 스키마 변경사항은 수동으로 적용하세요."

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

### 데이터 저장 방식
이 프로젝트는 PostgreSQL 데이터를 호스트 파일 시스템에 직접 저장합니다:
- **데이터 위치**: `./database/data/`
- **장점**: `docker-compose down`을 해도 데이터가 보존됩니다
- **백업**: `./database/backup_*.sql` 파일로 자동 백업됩니다

### 데이터 마이그레이션 (Docker volume → 파일 시스템)
기존 Docker volume을 사용하던 경우 파일 시스템으로 마이그레이션:
```bash
# 마이그레이션 스크립트 실행
./scripts/migrate-db-to-filesystem.sh
```

### 마이그레이션 (납품 시 수동 처리)
```bash
# 마이그레이션 스크립트는 납품을 위해 비활성화되었습니다.
# ./scripts/migrate.sh  # 비활성화됨

# 데이터베이스 스키마 변경사항은 수동으로 적용하세요.
# 직접 DB에 접속하여 필요한 변경사항을 적용하시기 바랍니다.
```

### 마이그레이션 생성 (개발용)
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

### Docker 네트워크 삭제 오류

**오류 메시지:**
```
failed to remove network ***_internal: Error response from daemon: error while removing network: network ***_internal id *** has active endpoints
```

**해결 방법:**

#### 1. 정리 스크립트 사용 (권장)
```bash
# Docker 정리 스크립트 실행
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

#### 2. 수동 정리
```bash
# 모든 컨테이너 중지
docker-compose -f docker-compose.prod.yml down --remove-orphans

# 관련 컨테이너 강제 종료
docker ps -q --filter "name=mincenter_" | xargs -r docker kill
docker ps -aq --filter "name=mincenter_" | xargs -r docker rm -f

# 네트워크 정리
docker network prune -f

# 특정 네트워크 강제 삭제
docker network rm mincenter_internal 2>/dev/null || true
```

### API 서버 빌드 오류

**문제:** Docker 내부에서 Rust 빌드 실패

**해결 방법:**
```bash
# 로컬에서 Rust 빌드
cd backends/api
cargo build --release

# 빌드된 바이너리를 서버에 업로드
scp target/release/minshool-api user@server:/path/to/deployment/
```

### 데이터베이스 연결 오류

**문제:** PostgreSQL 컨테이너가 시작되지 않음

**해결 방법:**
```bash
# 컨테이너 로그 확인
docker-compose -f docker-compose.prod.yml logs postgres

# 데이터베이스 설정 확인
docker-compose -f docker-compose.prod.yml exec postgres psql -U postgres -d mincenter
```

## 서비스 관리

### API 서버 관리
```bash
# API 서버 시작
./scripts/api-service.sh start

# API 서버 중지
./scripts/api-service.sh stop

# API 서버 재시작
./scripts/api-service.sh restart

# API 서버 상태 확인
./scripts/api-service.sh status
```

### Docker 컨테이너 관리
```bash
# 컨테이너 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 컨테이너 로그 확인
docker-compose -f docker-compose.prod.yml logs [service_name]

# 컨테이너 재시작
docker-compose -f docker-compose.prod.yml restart [service_name]
```

### 데이터베이스 마이그레이션
```bash
# 마이그레이션 실행
./scripts/migrate.sh

# 마이그레이션 상태 확인
cd backends/api
cargo sqlx migrate info
```

## 모니터링

### 헬스체크
```bash
# PostgreSQL 헬스체크
curl -f http://localhost:5432

# API 헬스체크
curl -f http://localhost:18080/health

# Site 헬스체크
curl -f http://localhost:13000

# Admin 헬스체크
curl -f http://localhost:13001
```

### 로그 모니터링
```bash
# 실시간 로그 확인
docker-compose -f docker-compose.prod.yml logs -f

# API 로그 확인
tail -f backends/api/api.log
```

## 백업 및 복구

### 데이터베이스 백업
```bash
# PostgreSQL 백업
docker-compose -f docker-compose.prod.yml exec postgres pg_dump -U postgres mincenter > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 데이터베이스 복구
```bash
# PostgreSQL 복구
docker-compose -f docker-compose.prod.yml exec -T postgres psql -U postgres mincenter < backup_file.sql
```

## 보안 고려사항

### 방화벽 설정
```bash
# 필요한 포트만 열기
sudo firewall-cmd --permanent --add-port=13000/tcp  # Site
sudo firewall-cmd --permanent --add-port=13001/tcp  # Admin
sudo firewall-cmd --permanent --add-port=18080/tcp  # API
sudo firewall-cmd --reload
```

### SSL/TLS 설정
- Nginx를 사용하여 SSL 터미네이션 구성
- Let's Encrypt를 통한 무료 SSL 인증서 발급

## 성능 최적화

### Docker 리소스 제한
```yaml
# docker-compose.prod.yml에 추가
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### PostgreSQL 최적화
```bash
# postgresql.conf 설정 최적화
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB
```

## 트러블슈팅

### 일반적인 문제들

1. **포트 충돌**
   - `netstat -tulpn | grep :13000`로 포트 사용 확인
   - 다른 포트로 변경하거나 기존 서비스 중지

2. **권한 문제**
   - Docker 그룹에 사용자 추가 확인
   - 파일 권한 확인: `ls -la scripts/`

3. **메모리 부족**
   - `free -h`로 메모리 사용량 확인
   - 불필요한 컨테이너 정리

4. **디스크 공간 부족**
   - `df -h`로 디스크 사용량 확인
   - Docker 이미지 및 볼륨 정리

### 로그 분석
```bash
# 오류 로그 필터링
docker-compose -f docker-compose.prod.yml logs | grep -i error

# 최근 로그 확인
docker-compose -f docker-compose.prod.yml logs --tail=100
```

## 업데이트 및 유지보수

### 정기적인 업데이트
```bash
# 1. 코드 업데이트
git pull origin main

# 2. Docker 이미지 재빌드
docker-compose -f docker-compose.prod.yml build --no-cache

# 3. 서비스 재시작
./scripts/deploy.sh
```

### 백업 스케줄링
```bash
# crontab에 백업 작업 추가
0 2 * * * /path/to/backup_script.sh
```

이 가이드를 따라하면 CentOS 7 환경에서 안정적으로 MinCenter를 배포하고 운영할 수 있습니다. 