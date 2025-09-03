#!/bin/bash

# Docker 컨테이너 상태 확인

set -e

echo "🔍 Docker 컨테이너 상태 확인..."

SERVER_HOST="admin@mincenter.kr"

ssh $SERVER_HOST << 'EOF'
  echo "📊 실행 중인 모든 컨테이너:"
  docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
  
  echo ""
  echo "🌐 Docker 네트워크 상세 정보:"
  docker network inspect proxy-network | grep -A 10 -B 2 "Containers"
  
EOF
















