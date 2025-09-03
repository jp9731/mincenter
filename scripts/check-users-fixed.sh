#!/bin/bash

# PostgreSQL 사용자 정보 확인 (수정된 버전)

set -e

echo "🔍 Mincenter PostgreSQL 사용자 정보 확인..."

SERVER_HOST="admin@mincenter.kr"

echo "📊 사용자 정보 조회..."
ssh $SERVER_HOST << 'EOF'
  echo "🗄️ PostgreSQL 연결 및 사용자 테이블 스키마 확인..."
  
  echo "📋 users 테이블 컬럼 구조:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    \d users
  "
  
  echo ""
  echo "👥 사용자 정보 (상위 10명):"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT 
      id, 
      email, 
      name,
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
      name,
      role 
    FROM users 
    WHERE role IN ('admin', 'super_admin')
    ORDER BY created_at;
  "
  
  echo ""
  echo "📊 사용자 역할별 통계:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT 
      role, 
      COUNT(*) as count 
    FROM users 
    GROUP BY role 
    ORDER BY count DESC;
  "
  
EOF















