#!/bin/bash

# API 서버 백업 스크립트
# 배포 전에 중요한 파일들을 백업

API_DIR="/opt/mincenter/backends/api"
BACKUP_DIR="/opt/mincenter/backups/api"
DATE=$(date +%Y%m%d_%H%M%S)

echo "🔧 API 서버 백업 시작..."

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 중요한 파일들 백업
if [ -f "$API_DIR/.env" ]; then
    cp "$API_DIR/.env" "$BACKUP_DIR/.env.backup.$DATE"
    echo "✅ .env 파일 백업 완료"
fi

if [ -d "$API_DIR/target" ]; then
    echo "✅ target 폴더 존재 확인"
fi

# 최근 백업 파일들 정리 (7일 이상 된 것 삭제)
find "$BACKUP_DIR" -name "*.backup.*" -mtime +7 -delete

echo "🎉 백업 완료: $BACKUP_DIR" 