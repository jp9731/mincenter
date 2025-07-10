#!/bin/bash

# 데이터베이스 백업 스크립트

DB_NAME="mincenter"
DB_USER="mincenter"
BACKUP_DIR="/opt/mincenter/backups/database"
DATE=$(date +%Y%m%d_%H%M%S)

echo "🗄️ 데이터베이스 백업 시작..."

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# PostgreSQL 백업
if command -v pg_dump &> /dev/null; then
    pg_dump -h localhost -p 15432 -U "$DB_USER" "$DB_NAME" > "$BACKUP_DIR/postgres_backup_$DATE.sql"
    echo "✅ PostgreSQL 백업 완료: postgres_backup_$DATE.sql"
else
    echo "⚠️ pg_dump 명령어를 찾을 수 없습니다"
fi

# Redis 백업 (선택적)
if command -v redis-cli &> /dev/null; then
    redis-cli -h localhost -p 16379 -a tnekwoddl BGSAVE
    sleep 2
    cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_backup_$DATE.rdb" 2>/dev/null || echo "⚠️ Redis 백업 실패"
    echo "✅ Redis 백업 완료: redis_backup_$DATE.rdb"
else
    echo "⚠️ redis-cli 명령어를 찾을 수 없습니다"
fi

# 오래된 백업 파일 정리 (7일 이상)
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
find "$BACKUP_DIR" -name "*.rdb" -mtime +7 -delete

echo "🎉 데이터베이스 백업 완료: $BACKUP_DIR" 