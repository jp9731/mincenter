#!/bin/bash

# API 서버 상태 확인 스크립트 (systemd 기반)

set -e

echo "📊 MinCenter API 서버 상태 확인 중..."

# 서버 정보
SERVER_HOST="mincenter-auto"

# 서버에서 서비스 상태 확인
echo "서버에서 API 서비스 상태 확인 중..."
ssh "$SERVER_HOST" << 'EOF'
set -e

echo "=== systemd 서비스 상태 ==="
systemctl --user status mincenter-api --no-pager

echo ""
echo "=== 최근 로그 (마지막 20줄) ==="
journalctl --user -u mincenter-api -n 20 --no-pager

echo ""
echo "=== 서비스 활성화 상태 ==="
systemctl --user is-enabled mincenter-api || echo "서비스가 활성화되지 않았습니다."

echo ""
echo "=== 프로세스 정보 ==="
ps aux | grep mincenter-api | grep -v grep || echo "실행 중인 프로세스가 없습니다."

echo ""
echo "=== 포트 사용 상태 ==="
netstat -tlnp | grep :18080 || echo "포트 18080이 사용되지 않고 있습니다."

echo ""
echo "=== HTTP 상태 확인 ==="
if curl -f http://localhost:18080/health > /dev/null 2>&1; then
    echo "✅ API 서버가 HTTP 요청에 응답합니다."
    echo "🔗 Health Check: http://localhost:18080/health"
else
    echo "❌ API 서버가 HTTP 요청에 응답하지 않습니다."
fi
EOF

echo "🎉 상태 확인 완료!"
