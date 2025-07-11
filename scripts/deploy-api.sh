#!/bin/bash

# API 배포 스크립트 (서버에서 실행)
echo "=== API 배포 시작 ==="

# 1. 저장소 업데이트
echo "📥 Pulling latest changes..."
git pull origin main || {
    echo "❌ Git pull failed"
    exit 1
}

# 2. API 디렉토리로 이동
cd backends/api || {
    echo "❌ Failed to change to API directory"
    exit 1
}

# 3. 빌드
echo "🔨 Building API..."
cargo build --release --bin mincenter-api || {
    echo "❌ Build failed"
    exit 1
}

# 4. 기존 프로세스 종료
echo "🛑 Stopping existing API..."
pkill -f mincenter-api || true
sleep 3

# 5. 새 프로세스 시작
echo "🚀 Starting new API..."
cd ../..
./scripts/start-api.sh

echo "✅ API 배포 완료!"