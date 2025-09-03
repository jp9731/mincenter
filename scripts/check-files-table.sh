#!/bin/bash

# files 테이블 구조 확인

set -e

echo "🔍 files 테이블 구조 확인..."

SERVER_HOST="admin@mincenter.kr"

echo "🏠 개발컴 files 테이블:"
docker exec mincenter_postgres psql -U mincenter -d mincenter -c "\d files" | grep mime_type

echo ""
echo "🌐 서버 files 테이블:"
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d files" | grep mime_type
EOF
















