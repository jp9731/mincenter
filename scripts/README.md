# Scripts Directory

이 디렉토리는 프로젝트 관리 및 배포를 위한 유틸리티 스크립트들을 포함합니다.

## 📁 현재 스크립트 목록

### 🦀 **SQLx 마이그레이션 (새로운 시스템)**
- **`sqlx-migrate.sh`** - SQLx 마이그레이션 관리 스크립트
  - 새로운 마이그레이션 생성, 로컬/서버 적용, 상태 확인, 롤백 등

### 🔄 **기존 마이그레이션 (하위 호환성)**
- **`apply-migrations.sh`** - 기존 마이그레이션 파일들을 로컬/서버에 적용
- **`generate-migration.sh`** - 새로운 기존 마이그레이션 파일 생성

### 🗄️ **데이터베이스 관리**
- **`sync-database.sh`** - 로컬과 서버 간 데이터베이스 동기화
- **`backup-database.sh`** - 데이터베이스 백업 생성
- **`cleanup-backups.sh`** - 오래된 백업 파일 정리
- **`seed-database.sh`** - 데이터베이스에 초기 데이터 삽입

### 🔐 **환경 설정 관리**
- **`backup-env.sh`** - 보안 강화된 .env 파일 관리 (GitHub Secrets 기반)
- **`unified-env.sh`** - 통합 .env 파일 관리 (심볼릭 링크 기반)
- **`env-loader.sh`** - 환경별 .env 파일 로더 (local/production)

### 🐳 **Docker Compose 관리**
- **`docker-compose-manager.sh`** - Docker Compose 서비스 관리

### ⚙️ **서버 설정**
- **`setup-new-server-env.sh`** - 새로운 서버 환경 초기 설정

## 🚀 사용법

### SQLx 마이그레이션 (권장)
```bash
# 새로운 마이그레이션 생성
./scripts/sqlx-migrate.sh add "마이그레이션_설명"

# 로컬에 마이그레이션 적용
./scripts/sqlx-migrate.sh run

# 서버에 마이그레이션 적용
./scripts/sqlx-migrate.sh server-run

# 마이그레이션 상태 확인
./scripts/sqlx-migrate.sh info
./scripts/sqlx-migrate.sh server-info
```

### 기존 마이그레이션 (하위 호환성)
```bash
# 새로운 마이그레이션 생성
./scripts/generate-migration.sh 001 "마이그레이션_설명"

# 마이그레이션 적용
./scripts/apply-migrations.sh local    # 로컬만
./scripts/apply-migrations.sh remote   # 서버만
./scripts/apply-migrations.sh both     # 둘 다
```

### 데이터베이스 관리
```bash
# 데이터베이스 동기화
./scripts/sync-database.sh

# 백업 생성
./scripts/backup-database.sh

# 백업 정리
./scripts/cleanup-backups.sh

# 초기 데이터 삽입
./scripts/seed-database.sh
```

### 환경 설정 관리
```bash
# 보안 강화된 .env 관리
./scripts/backup-env.sh check
./scripts/backup-env.sh secure
./scripts/backup-env.sh cleanup
./scripts/backup-env.sh template

# 통합 .env 관리
./scripts/unified-env.sh status
./scripts/unified-env.sh validate
./scripts/unified-env.sh backup

# 환경별 .env 관리
./scripts/env-loader.sh status
./scripts/env-loader.sh switch local
./scripts/env-loader.sh switch production
./scripts/env-loader.sh diff local production

# Docker Compose 관리
./scripts/docker-compose-manager.sh status
./scripts/docker-compose-manager.sh start local
./scripts/docker-compose-manager.sh start production
./scripts/docker-compose-manager.sh logs api
./scripts/docker-compose-manager.sh clean

### 서버 설정
```bash
# 새 서버 환경 설정
./scripts/setup-new-server-env.sh
```

## 📋 마이그레이션 시스템 비교

### SQLx 마이그레이션 (권장)
- ✅ **타입 안전성**: 컴파일 타임에 SQL 검증
- ✅ **자동 추적**: 마이그레이션 상태 자동 관리
- ✅ **롤백 지원**: 안전한 되돌리기
- ✅ **IDE 지원**: Rust IDE에서 SQL 하이라이팅
- ✅ **자동화**: GitHub Actions와 완벽 통합

### 기존 마이그레이션 (하위 호환성)
- ✅ **호환성**: 기존 스크립트들과의 호환성
- ✅ **단순함**: 간단한 SQL 파일 기반
- ✅ **유연성**: 복잡한 마이그레이션 로직 가능

## 🔐 보안 강화된 .env 관리

### GitHub Secrets 기반 시스템
- ✅ **민감 정보 보호**: GitHub Secrets에서 안전하게 관리
- ✅ **최소 권한**: 서버의 .env 파일은 600 권한으로 제한
- ✅ **백업 금지**: 보안상 위험한 백업 파일 생성 금지
- ✅ **자동 생성**: GitHub Actions에서 동적으로 .env 파일 생성
- ✅ **마스킹**: 민감 정보는 로그에서 자동 마스킹

## 🌍 환경별 .env 관리

### 환경별 설정 분리
- ✅ **로컬 개발**: `.env.local` (localhost, development)
- ✅ **프로덕션**: `.env.production` (실제 도메인, production)
- ✅ **Docker Compose**: `docker-compose.override.yml` (로컬 개발용)
- ✅ **Rust API**: 환경별 기본값 자동 설정
- ✅ **SvelteKit**: `.env.local` 자동 인식

### 환경 전환 시스템
- ✅ **간편 전환**: `./scripts/env-loader.sh switch local/production`
- ✅ **상태 확인**: `./scripts/env-loader.sh status`
- ✅ **차이 비교**: `./scripts/env-loader.sh diff local production`
- ✅ **유효성 검사**: `./scripts/env-loader.sh validate local/production`

## 🐳 Docker Compose 관리

### 환경별 Docker Compose
- ✅ **로컬 개발**: `docker-compose.yml` + `docker-compose.override.yml`
- ✅ **프로덕션**: `docker-compose.yml`만 사용
- ✅ **자동 환경 감지**: `NODE_ENV` 기반 설정 적용
- ✅ **헬스체크**: 모든 서비스에 헬스체크 설정
- ✅ **기본값 제공**: 환경변수 없이도 동작

### Docker Compose 관리 도구
- ✅ **상태 확인**: `./scripts/docker-compose-manager.sh status`
- ✅ **환경별 시작**: `./scripts/docker-compose-manager.sh start local/production`
- ✅ **로그 확인**: `./scripts/docker-compose-manager.sh logs <service>`
- ✅ **리소스 정리**: `./scripts/docker-compose-manager.sh clean`
- ✅ **설정 백업**: `./scripts/docker-compose-manager.sh backup`
- ✅ **유효성 검사**: `./scripts/docker-compose-manager.sh validate`

## 🔄 배포 워크플로우

### 자동 배포 (GitHub Actions)
1. 코드 변경사항 커밋 및 푸시
2. GitHub Actions가 변경사항 감지
3. 해당 컴포넌트만 자동 배포
4. SQLx 마이그레이션 자동 적용

### 수동 배포
```bash
# 특정 컴포넌트만 배포
./scripts/sqlx-migrate.sh server-run  # DB만
# 또는 GitHub Actions의 manual-deploy.yml 사용
```

## 📝 참고사항

- 모든 스크립트는 실행 권한이 필요합니다: `chmod +x scripts/*.sh`
- 서버 관련 스크립트는 SSH 키 설정이 필요합니다
- 데이터베이스 스크립트는 PostgreSQL 클라이언트가 필요합니다
- SQLx 마이그레이션은 Rust 환경에서 실행됩니다

## 🗂️ 파일 구조

```
scripts/
├── sqlx-migrate.sh          # SQLx 마이그레이션 관리
├── apply-migrations.sh      # 기존 마이그레이션 적용
├── generate-migration.sh    # 기존 마이그레이션 생성
├── sync-database.sh         # DB 동기화
├── backup-database.sh       # DB 백업
├── cleanup-backups.sh       # 백업 정리
├── seed-database.sh         # 초기 데이터 삽입
├── backup-env.sh            # 보안 강화된 .env 관리
├── unified-env.sh           # 통합 .env 관리
├── env-loader.sh            # 환경별 .env 로더
├── docker-compose-manager.sh # Docker Compose 관리
├── setup-new-server-env.sh  # 서버 환경 설정
└── README.md               # 이 파일
``` 