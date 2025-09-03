#!/bin/bash

# API 서버 중지 스크립트 (systemd 기반)

set -e

echo "🛑 MinCenter API 서버 중지 중..."

# 서버 정보
SERVER_HOST="mincenter-auto"

# 서버에서 서비스 중지
echo "서버에서 API 서비스 중지 중..."
ssh "$SERVER_HOST" << 'EOF'
set -e

echo "API 서비스 중지 중..."
systemctl --user stop mincenter-api || echo "서비스가 이미 중지되어 있습니다."

echo "서비스 상태 확인 중..."
systemctl --user status mincenter-api || echo "서비스가 중지되었습니다."

echo "✅ API 서버가 중지되었습니다."
EOF

echo "🎉 API 서버 중지 완료!"
