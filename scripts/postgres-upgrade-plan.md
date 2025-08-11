# PostgreSQL 13 → 17 업그레이드 계획

## 🎯 목표
- 서버 PostgreSQL 13 → 17 업그레이드
- 개발환경과 운영환경 버전 통일
- 안전한 데이터 마이그레이션

## 📋 업그레이드 단계

### 1단계: 현재 상태 확인 및 백업
```bash
# 서버 접속
ssh admin@49.247.4.194

# 현재 PostgreSQL 버전 확인
docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT version();"

# 전체 데이터베이스 백업
mkdir -p /home/admin/projects/mincenter/backups/upgrade
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
docker exec mincenter-postgres pg_dumpall -U mincenter > "/home/admin/projects/mincenter/backups/upgrade/full_backup_${TIMESTAMP}.sql"

# 스키마만 백업
docker exec mincenter-postgres pg_dump -U mincenter -d mincenter --schema-only > "/home/admin/projects/mincenter/backups/upgrade/schema_${TIMESTAMP}.sql"

# 데이터만 백업
docker exec mincenter-postgres pg_dump -U mincenter -d mincenter --data-only > "/home/admin/projects/mincenter/backups/upgrade/data_${TIMESTAMP}.sql"
```

### 2단계: Docker Compose 설정 업데이트
```bash
# 현재 서비스 중지
cd /home/admin/projects/mincenter
docker-compose down

# PostgreSQL 이미지를 17로 변경
# docker-compose.yml에서 postgres:13 → postgres:17 변경
```

### 3단계: 데이터 볼륨 처리
```bash
# 기존 PostgreSQL 13 볼륨 백업
docker volume create postgres_data_backup
docker run --rm -v mincenter_postgres_data:/from -v postgres_data_backup:/to alpine ash -c "cd /from && cp -av . /to"

# 기존 볼륨 제거 (PostgreSQL 17과 호환 안됨)
docker volume rm mincenter_postgres_data
```

### 4단계: PostgreSQL 17 시작 및 데이터 복구
```bash
# PostgreSQL 17 컨테이너 시작 (새 볼륨으로)
docker-compose up -d postgres

# 로그 확인
docker-compose logs -f postgres

# 데이터 복구
docker exec -i mincenter-postgres psql -U mincenter -d mincenter < "/home/admin/projects/mincenter/backups/upgrade/full_backup_${TIMESTAMP}.sql"
```

### 5단계: 검증
```bash
# 버전 확인
docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT version();"

# 테이블 목록 확인
docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt"

# 데이터 건수 확인
docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples
FROM pg_stat_user_tables
ORDER BY schemaname, tablename;
"
```

## ⚠️ 롤백 계획
문제 발생 시:
1. 컨테이너 중지: `docker-compose down`
2. 볼륨 복구: `docker volume rm mincenter_postgres_data && docker volume create mincenter_postgres_data`
3. 백업 볼륨에서 복구: `docker run --rm -v postgres_data_backup:/from -v mincenter_postgres_data:/to alpine ash -c "cd /from && cp -av . /to"`
4. PostgreSQL 13으로 되돌리기: docker-compose.yml 수정 후 재시작

## 📝 체크리스트
- [ ] 현재 상태 확인
- [ ] 전체 백업 완료
- [ ] Docker Compose 설정 업데이트
- [ ] 볼륨 백업 및 제거
- [ ] PostgreSQL 17 시작
- [ ] 데이터 복구
- [ ] 버전 및 데이터 검증
- [ ] API 연결 테스트
