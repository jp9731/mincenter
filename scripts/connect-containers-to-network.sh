#!/bin/bash

# PostgreSQL과 Redis 컨테이너를 proxy-network에 연결

set -e

echo "🌐 PostgreSQL과 Redis 컨테이너를 proxy-network에 연결..."

SERVER_HOST="admin@mincenter.kr"

ssh $SERVER_HOST << 'EOF'
  echo "🔗 mincenter-postgres를 proxy-network에 연결..."
  docker network connect proxy-network mincenter-postgres || echo "이미 연결됨 또는 연결 실패"
  
  echo "🔗 mincenter-redis를 proxy-network에 연결..."
  docker network connect proxy-network mincenter-redis || echo "이미 연결됨 또는 연결 실패"
  
  echo ""
  echo "📊 네트워크 연결 상태 확인..."
  docker network inspect proxy-network | grep -A 20 "Containers"
  
EOF
















