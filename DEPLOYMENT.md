# 배포 가이드

## 개요

이 프로젝트는 하이브리드 배포 방식을 사용합니다:

- **Frontend (Site/Admin)**: Cloudflare Pages 자동 배포
- **Backend (API)**: 원격 서버 배포 (systemd 기반)
- **Database (PostgreSQL/Redis)**: 서버에서 직접 실행

## Frontend 배포

### Site & Admin
- **배포 방식**: Cloudflare Pages 자동 배포
- **트리거**: Git push 시 자동 배포
- **설정**: 별도 설정 불필요 (Cloudflare Pages에서 자동 감지)

```bash
# 개발 서버 실행
cd frontends/site
npm run dev

cd frontends/admin  
npm run dev
```

## Backend 배포

### API 서버
- **배포 방식**: 원격 서버 배포 (systemd 기반)
- **서버**: `mincenter-auto` 호스트
- **데이터베이스**: 서버의 PostgreSQL/Redis 사용

#### 배포 스크립트 사용

```bash
# API 서버 배포 (전체 배포)
./scripts/deploy-api.sh

# 중요: static/uploads 폴더는 자동으로 보존됩니다
# - 업로드 파일들은 용량 절약을 위해 백업에서 제외됩니다
# - 기존 업로드 파일들이 임시 백업에서 자동으로 복원됩니다
# - 배포 시 업로드된 파일들이 삭제되지 않습니다

# API 서버 중지
./scripts/stop-api.sh

# API 서버 재시작
./scripts/restart-api.sh

# API 서버 상태 확인
./scripts/status-api.sh

# API 서버 로그 확인
./scripts/logs-api.sh [라인수]
```

#### 서버에서 직접 관리

```bash
# 서버 접속
ssh mincenter-auto

# 서비스 상태 확인
systemctl --user status mincenter-api

# 서비스 재시작
systemctl --user restart mincenter-api

# 실시간 로그 확인
journalctl --user -u mincenter-api -f

# 서비스 중지
systemctl --user stop mincenter-api
```

## 환경 설정

### 서버 환경 변수 (.env)
서버의 `/home/admin/projects/mincenter/api/.env` 파일에 설정:

```bash
# API 서버
API_PORT=18080
JWT_SECRET=your_jwt_secret
REFRESH_SECRET=your_refresh_secret
RUST_LOG_LEVEL=info
CORS_ORIGIN=https://yourdomain.com

# 데이터베이스 (서버의 PostgreSQL/Redis)
DATABASE_URL=postgresql://user:password@localhost:5432/database
REDIS_URL=redis://localhost:6379
```

### SSH 설정
`~/.ssh/config` 파일에 서버 정보 추가:

```
Host mincenter-auto
    HostName your-server-ip
    User admin
    Port 22
    IdentityFile ~/.ssh/your-private-key
```

## 서버 요구사항

- **Rust**: 최신 버전
- **PostgreSQL**: 17.x
- **Redis**: 7.x
- **메모리**: 최소 2GB
- **디스크**: 최소 10GB
- **SSH 접근**: 키 기반 인증

## 모니터링

### 로그 확인
```bash
# API 로그 확인 (로컬에서)
./scripts/logs-api.sh 100

# 실시간 로그 확인 (서버에서)
ssh mincenter-auto 'journalctl --user -u mincenter-api -f'
```

### 상태 확인
```bash
# API 상태 확인 (로컬에서)
./scripts/status-api.sh

# 직접 상태 확인 (서버에서)
ssh mincenter-auto 'systemctl --user status mincenter-api'
```

## 문제 해결

### API 서버가 시작되지 않는 경우
1. 서버 상태 확인: `./scripts/status-api.sh`
2. 로그 확인: `./scripts/logs-api.sh 50`
3. 서버 직접 확인: `ssh mincenter-auto 'systemctl --user status mincenter-api'`

### 포트 충돌 오류 (Address already in use)
1. 기존 Docker 컨테이너 확인: `ssh mincenter-auto 'docker ps | grep mincenter'`
2. Docker 컨테이너 중지: `ssh mincenter-auto 'docker stop mincenter-api'`
3. 포트 사용 확인: `ssh mincenter-auto 'netstat -tlnp | grep :18080'`
4. 서비스 재시작: `./scripts/restart-api.sh`

### 배포 실패 시
1. SSH 연결 확인: `ssh mincenter-auto 'echo "연결 성공"'`
2. 서버 디스크 공간 확인: `ssh mincenter-auto 'df -h'`
3. Rust 설치 확인: `ssh mincenter-auto 'rustc --version'`

### 데이터베이스 연결 오류
1. 서버에서 PostgreSQL 상태 확인: `ssh mincenter-auto 'systemctl status postgresql'`
2. 서버에서 Redis 상태 확인: `ssh mincenter-auto 'systemctl status redis'`
3. 환경 변수 확인: `ssh mincenter-auto 'cat /home/admin/projects/mincenter/api/.env'`

## 보안 고려사항

- 환경 변수 파일(.env)은 절대 Git에 커밋하지 마세요
- JWT 시크릿은 강력한 랜덤 문자열을 사용하세요
- SSH 키는 안전하게 보관하세요
- API 서버는 방화벽으로 보호하세요
- 정기적으로 보안 업데이트를 적용하세요
- 사용자 레벨 systemd 서비스로 권한 최소화
