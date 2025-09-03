#!/bin/bash

# PostgreSQL 사용자 정보 확인

set -e

echo "🔍 Mincenter PostgreSQL 사용자 정보 확인..."

SERVER_HOST="admin@mincenter.kr"

echo "📊 사용자 정보 조회..."
ssh $SERVER_HOST << 'EOF'
  echo "🗄️ PostgreSQL 연결 및 사용자 정보 조회..."
  
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT 
      id, 
      email, 
      username, 
      role, 
      status, 
      created_at
    FROM users 
    ORDER BY created_at DESC 
    LIMIT 10;
  "
  
  echo ""
  echo "📈 총 사용자 수:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT COUNT(*) as total_users FROM users;
  "
  
  echo ""
  echo "👑 관리자 사용자:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT 
      id, 
      email, 
      username, 
      role 
    FROM users 
    WHERE role IN ('admin', 'super_admin')
    ORDER BY created_at;
  "
  
EOF















