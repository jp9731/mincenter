#!/bin/bash

# API 서버 재시작 스크립트 (systemd 기반)

set -e

echo "🔄 MinCenter API 서버 재시작 중..."

# 서버 정보
SERVER_HOST="mincenter-auto"

# 서버에서 서비스 재시작
echo "서버에서 API 서비스 재시작 중..."
ssh "$SERVER_HOST" << 'EOF'
set -e

echo "API 서비스 재시작 중..."
systemctl --user restart mincenter-api

echo "서비스 상태 확인 중..."
sleep 3
systemctl --user status mincenter-api

echo "✅ API 서버가 재시작되었습니다."
EOF

echo "🎉 API 서버 재시작 완료!"
