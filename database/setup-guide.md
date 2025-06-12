# 🐘 PostgreSQL Docker 자동 초기화 가이드

## 📁 디렉토리 구조

```
project/
├── docker-compose.yml
├── .env
├── database/
│   ├── init.sql           # 스키마 + 기본 데이터
│   ├── seed.sql           # 샘플 데이터
│   ├── postgresql.conf    # PostgreSQL 설정
│   └── setup-guide.md     # 이 파일
├── nginx/
│   └── nginx.conf
└── redis/
    └── redis.conf
```

## 🚀 자동 초기화 작동 방식

### PostgreSQL 컨테이너 초기화 순서

1. **컨테이너 시작** → PostgreSQL 서비스 시작
2. **초기화 스크립트 실행** → `/docker-entrypoint-initdb.d/` 폴더의 스크립트들을 **알파벳 순서**로 실행
3. **데이터베이스 준비 완료** → 애플리케이션 연결 가능

### 실행 순서

```
01-init.sql    → 스키마, 테이블, 인덱스, 기본 데이터 생성
02-seed.sql    → 샘플 데이터, 테스트 계정 생성
```

## ⚙️ 사용 방법

### 1. 최초 설치 (완전 초기화)

```bash
# 기존 데이터 완전 삭제 (주의!)
docker-compose down -v

# 새로 시작
docker-compose up -d postgres

# 로그 확인
docker-compose logs postgres
```

### 2. 개발 중 스키마 변경

```bash
# PostgreSQL만 재시작 (데이터 유지)
docker-compose restart postgres

# 완전 초기화가 필요한 경우
docker-compose down
docker volume rm $(docker volume ls -q | grep postgres)
docker-compose up -d postgres
```

### 3. 프로덕션 배포

```bash
# seed.sql 제외하고 배포
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 설정 파일들

### postgresql.conf 예시

```ini
# postgresql.conf
# 성능 최적화 설정

# 메모리 설정
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB

# 커넥션 설정
max_connections = 200
listen_addresses = '*'

# 로깅 설정
log_destination = 'stderr'
logging_collector = on
log_statement = 'mod'
log_min_duration_statement = 1000

# 한국어 설정
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
```

### Docker Compose 볼륨 설정

```yaml
postgres:
  volumes:
    # 데이터 영구 저장
    - postgres_data:/var/lib/postgresql/data
    # 초기화 스크립트 (읽기 전용)
    - ./database/init.sql:/docker-entrypoint-initdb.d/01-init.sql:ro
    - ./database/seed.sql:/docker-entrypoint-initdb.d/02-seed.sql:ro
    # 설정 파일 (읽기 전용)
    - ./database/postgresql.conf:/etc/postgresql/postgresql.conf:ro
```

## 🎯 초기화 확인 방법

### 1. 데이터베이스 접속 테스트

```bash
# 컨테이너 내부 접속
docker-compose exec postgres psql -U myapp_user -d myapp_db

# 테이블 확인
\dt

# 샘플 데이터 확인
SELECT count(*) FROM users;
SELECT count(*) FROM posts;
SELECT count(*) FROM boards;
```

### 2. 로그 확인

```bash
# 초기화 로그 확인
docker-compose logs postgres | grep -i "database system is ready"

# 에러 확인
docker-compose logs postgres | grep -i error
```

### 3. 헬스체크 확인

```bash
# 헬스체크 상태 확인
docker-compose ps postgres

# 직접 헬스체크 실행
docker-compose exec postgres pg_isready -U myapp_user -d myapp_db
```

## ❗ 주의사항

### 1. 초기화 스크립트 실행 조건

- **새로운 볼륨**일 때만 실행됨
- 기존 데이터가 있으면 스크립트 무시됨
- 스키마 변경 시 볼륨 삭제 후 재생성 필요

### 2. 파일 권한 문제

```bash
# SQL 파일 권한 확인
ls -la database/

# 권한 수정 (필요시)
chmod 644 database/*.sql
```

### 3. 한글 인코딩 문제

```bash
# 컨테이너 환경변수 확인
docker-compose exec postgres env | grep -i locale

# 인코딩 확인
docker-compose exec postgres psql -U myapp_user -d myapp_db -c "SHOW client_encoding;"
```

## 🐛 트러블슈팅

### 1. 스크립트가 실행되지 않을 때

```bash
# 1. 볼륨 완전 삭제
docker-compose down -v
docker volume prune

# 2. 파일 존재 확인
ls -la database/

# 3. 다시 시작
docker-compose up -d postgres
```

### 2. 권한 에러 발생시

```bash
# PostgreSQL 로그 확인
docker-compose logs postgres

# 파일 권한 확인 및 수정
sudo chown -R $USER:$USER database/
chmod 644 database/*.sql
```

### 3. 연결 실패시

```bash
# 포트 확인
docker-compose ps
netstat -tlnp | grep 5432

# 방화벽 확인
sudo ufw status

# 설정 파일 확인
docker-compose exec postgres cat /etc/postgresql/postgresql.conf | grep listen_addresses
```

## 📊 데이터베이스 상태 확인 쿼리

```sql
-- 테이블 목록 및 행 수
SELECT 
    schemaname,
    tablename,
    n_tup_ins as "Total Rows"
FROM pg_stat_user_tables
ORDER BY n_tup_ins DESC;

-- 인덱스 사용률 확인
SELECT 
    schemaname,
    tablename,
    idx_scan,
    seq_scan,
    CASE 
        WHEN seq_scan + idx_scan > 0 
        THEN 100.0 * idx_scan / (seq_scan + idx_scan) 
        ELSE 0 
    END AS index_usage_percentage
FROM pg_stat_user_tables
ORDER BY index_usage_percentage DESC;

-- 데이터베이스 크기 확인
SELECT 
    pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname)) AS size
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```

## 🔄 정기 유지보수

### 1. 정리 작업 실행

```sql
-- 만료된 임시저장 정리
SELECT cleanup_expired_drafts();

-- 고아 파일 정리
SELECT cleanup_orphaned_files();

-- 통계 정보 업데이트
ANALYZE;
```

### 2. 백업 스크립트

```bash
#!/bin/bash
# backup.sh

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="./backups"
DB_NAME="myapp_db"
DB_USER="myapp_user"

mkdir -p $BACKUP_DIR

docker-compose exec postgres pg_dump -U $DB_USER -d $DB_NAME > "$BACKUP_DIR/backup_$DATE.sql"

echo "백업 완료: $BACKUP_DIR/backup_$DATE.sql"
```

이렇게 설정하면 Docker 컨테이너 시작 시 자동으로 데이터베이스가 초기화되고, 개발/테스트에 필요한 모든 데이터가 준비됩니다! 🎉