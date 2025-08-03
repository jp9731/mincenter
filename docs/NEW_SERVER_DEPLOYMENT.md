# 새로운 서버 배포 가이드 (49.247.4.194)

## 개요
이 문서는 MinCenter 프로젝트를 새로운 서버 `49.247.4.194`에 배포하는 방법을 설명합니다.

## 서버 정보
- **서버 IP**: 49.247.4.194
- **사용자**: admin
- **SSH 키**: ~/.ssh/firsthous_server_rsa
- **운영체제**: Ubuntu 24.04.2 LTS
- **웹서버**: Nginx Proxy Manager (Docker)

## 사전 요구사항

### 로컬 환경
- Rust (cargo)
- Node.js (npm)
- SSH 키 설정

### 서버 환경
- Docker
- Docker Compose
- Nginx Proxy Manager

## 배포 단계

### 1. 서버 환경 설정
```bash
# 서버 환경 설정 실행
./scripts/setup-new-server-env.sh
```

이 스크립트는 다음 작업을 수행합니다:
- Docker Compose 설치 확인
- 필요한 디렉토리 생성
- 환경 변수 파일 생성
- 백업 및 관리 스크립트 생성
- cron 작업 설정

### 2. 애플리케이션 배포
```bash
# 전체 애플리케이션 배포
./scripts/deploy-new-server.sh
```

이 스크립트는 다음 작업을 수행합니다:
- 백엔드 빌드 및 배포
- 프론트엔드 빌드 및 배포
- 데이터베이스 파일 배포
- Docker 컨테이너 시작

## 서비스 포트

| 서비스 | 포트 | 설명 |
|--------|------|------|
| API 서버 | 18080 | Rust Axum API |
| 사이트 | 13000 | 메인 웹사이트 |
| 관리자 | 13001 | 관리자 페이지 |
| PostgreSQL | 15432 | 데이터베이스 |
| Redis | 16379 | 캐시/세션 |

## Nginx Proxy Manager 설정

### 1. Proxy Hosts 설정

#### API 서버
- **Domain**: api.mincenter.kr
- **Scheme**: http
- **Forward Hostname/IP**: 49.247.4.194
- **Forward Port**: 18080
- **SSL**: Let's Encrypt 활성화

#### 메인 사이트
- **Domain**: mincenter.kr, www.mincenter.kr
- **Scheme**: http
- **Forward Hostname/IP**: 49.247.4.194
- **Forward Port**: 13000
- **SSL**: Let's Encrypt 활성화

#### 관리자 페이지
- **Domain**: admin.mincenter.kr
- **Scheme**: http
- **Forward Hostname/IP**: 49.247.4.194
- **Forward Port**: 13001
- **SSL**: Let's Encrypt 활성화

### 2. SSL 인증서 설정
각 도메인에 대해 Let's Encrypt SSL 인증서를 발급받아 설정합니다.

## 관리 명령어

### 서비스 관리
```bash
# 서비스 시작
ssh admin@49.247.4.194 '/opt/mincenter/manage.sh start'

# 서비스 중지
ssh admin@49.247.4.194 '/opt/mincenter/manage.sh stop'

# 서비스 재시작
ssh admin@49.247.4.194 '/opt/mincenter/manage.sh restart'

# 서비스 상태 확인
ssh admin@49.247.4.194 '/opt/mincenter/manage.sh status'

# 로그 확인
ssh admin@49.247.4.194 '/opt/mincenter/manage.sh logs'
```

### 백업
```bash
# 수동 백업
ssh admin@49.247.4.194 '/opt/mincenter/backup.sh'

# 자동 백업 (매일 새벽 2시)
# cron에 설정되어 있음
```

### 컨테이너 관리
```bash
# 컨테이너 상태 확인
ssh admin@49.247.4.194 'cd /opt/mincenter && docker-compose ps'

# 컨테이너 로그 확인
ssh admin@49.247.4.194 'cd /opt/mincenter && docker-compose logs -f'

# 컨테이너 재시작
ssh admin@49.247.4.194 'cd /opt/mincenter && docker-compose restart'
```

## 문제 해결

### 1. 서비스가 시작되지 않는 경우
```bash
# 로그 확인
ssh admin@49.247.4.194 'cd /opt/mincenter && docker-compose logs'

# 컨테이너 상태 확인
ssh admin@49.247.4.194 'cd /opt/mincenter && docker-compose ps'
```

### 2. 데이터베이스 연결 문제
```bash
# PostgreSQL 컨테이너 확인
ssh admin@49.247.4.194 'docker exec mincenter-postgres pg_isready -U mincenter'

# 데이터베이스 로그 확인
ssh admin@49.247.4.194 'docker logs mincenter-postgres'
```

### 3. 포트 충돌 문제
```bash
# 포트 사용 확인
ssh admin@49.247.4.194 'netstat -tlnp | grep -E "(18080|13000|13001)"'
```

## 모니터링

### 헬스체크 엔드포인트
- API: `http://49.247.4.194:18080/health`
- 사이트: `http://49.247.4.194:13000`
- 관리자: `http://49.247.4.194:13001`

### 로그 위치
- 컨테이너 로그: `docker-compose logs`
- 백업 로그: `/opt/mincenter/backups/`

## 보안 고려사항

1. **JWT_SECRET 변경**: 프로덕션 환경에서는 기본 JWT_SECRET을 변경하세요.
2. **방화벽 설정**: 필요한 포트만 열어두세요.
3. **정기 백업**: 자동 백업이 설정되어 있지만, 정기적으로 백업 상태를 확인하세요.
4. **SSL 인증서**: 모든 도메인에 SSL 인증서를 설정하세요.

## 업데이트 방법

### 전체 시스템 업데이트
```bash
# 1. 로컬에서 새 버전 빌드
cd backends/api && cargo build --release
cd frontends/site && npm run build
cd frontends/admin && npm run build

# 2. 배포 스크립트 실행
./scripts/deploy-new-server.sh
```

### 개별 서비스 업데이트
```bash
# API만 업데이트
./scripts/deploy-binary.sh

# 프론트엔드만 업데이트
./scripts/deploy-frontend.sh site
./scripts/deploy-frontend.sh admin
``` 