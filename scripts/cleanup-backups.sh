#!/bin/bash

# 백업 파일 정리 스크립트

echo "🧹 백업 파일 정리 시작..."

# API 백업 정리 (7일 이상)
if [ -d "/opt/mincenter/backups/api" ]; then
    find "/opt/mincenter/backups/api" -name "*.backup.*" -mtime +7 -delete
    echo "✅ API 백업 파일 정리 완료"
fi

# Docker 백업 정리 (3일 이상)
find /tmp -name "docker_backup_*" -type d -mtime +3 -exec rm -rf {} \; 2>/dev/null || true
echo "✅ Docker 백업 파일 정리 완료"

# 서버 백업 정리 (7일 이상)
find /tmp -name "server_backup_*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true
echo "✅ 서버 백업 파일 정리 완료"

# SSL 백업 정리 (30일 이상)
if [ -d "/etc/ssl/certs/backup" ]; then
    find "/etc/ssl/certs/backup" -name "backup-*" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true
    echo "✅ SSL 백업 파일 정리 완료"
fi

# Nginx 백업 정리 (30일 이상)
if [ -d "/etc/nginx/backup" ]; then
    find "/etc/nginx/backup" -name "backup_*" -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true
    echo "✅ Nginx 백업 파일 정리 완료"
fi

echo "🎉 백업 파일 정리 완료!" 