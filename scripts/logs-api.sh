#!/bin/bash

# API 서버 로그 확인 스크립트 (systemd 기반)

set -e

# 서버 정보
SERVER_HOST="mincenter-auto"

# 로그 라인 수 (기본값: 50)
LINES=${1:-50}

echo "📝 MinCenter API 서버 로그 확인 중... (최근 $LINES 줄)"

# 서버에서 로그 확인
ssh "$SERVER_HOST" << EOF
echo "=== API 서버 로그 (최근 $LINES 줄) ==="
journalctl --user -u mincenter-api -n $LINES --no-pager

echo ""
echo "=== 실시간 로그 모니터링 ==="
echo "실시간 로그를 보려면 다음 명령어를 사용하세요:"
echo "  journalctl --user -u mincenter-api -f"
EOF

echo "🎉 로그 확인 완료!"
