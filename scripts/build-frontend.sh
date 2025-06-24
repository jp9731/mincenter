#!/bin/bash

# 메모리 최적화된 프론트엔드 빌드 스크립트

set -e

echo "🧠 메모리 최적화 빌드 시작..."

# 메모리 제한 설정
export NODE_OPTIONS="--max-old-space-size=2048"

# Docker 시스템 정리
echo "🧹 Docker 캐시 정리..."
docker system prune -f

# Site 빌드
echo "🏗️ Site 빌드 중..."
cd frontends/site
docker build --no-cache --memory=2g --memory-swap=2g -t site-builder .
cd ../..

# Admin 빌드
echo "🏗️ Admin 빌드 중..."
cd frontends/admin
docker build --no-cache --memory=2g --memory-swap=2g -t admin-builder .
cd ../..

echo "✅ 빌드 완료!" 