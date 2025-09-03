#!/bin/bash

# 기본 스키마 생성 스크립트

set -e

echo "🗄️ 기본 스키마 생성..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 기본 스키마 생성
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "🔧 UUID 확장 활성화..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
  
  echo "📊 기본 스키마 파일 실행..."
  
  # 기본 스키마 파일들을 순서대로 실행
  if [ -f "database/init.sql" ]; then
    echo "📊 database/init.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < database/init.sql || echo "⚠️ 일부 오류 발생"
  fi
  
  if [ -f "backends/api/database/init.sql" ]; then
    echo "📊 backends/api/database/init.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < backends/api/database/init.sql || echo "⚠️ 일부 오류 발생"
  fi
  
  echo "📊 시드 데이터 삽입..."
  if [ -f "database/seed.sql" ]; then
    echo "📊 database/seed.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < database/seed.sql || echo "⚠️ 일부 오류 발생"
  fi
  
  if [ -f "backends/api/database/seed.sql" ]; then
    echo "📊 backends/api/database/seed.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < backends/api/database/seed.sql || echo "⚠️ 일부 오류 발생"
  fi
  
  echo "📊 추가 마이그레이션 실행..."
  if [ -f "database/post_management_tables.sql" ]; then
    echo "📊 database/post_management_tables.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < database/post_management_tables.sql || echo "⚠️ 일부 오류 발생"
  fi
  
  if [ -f "backends/api/database/migrations/20250103000001_create_post_management_tables.sql" ]; then
    echo "📊 20250103000001_create_post_management_tables.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < backends/api/database/migrations/20250103000001_create_post_management_tables.sql || echo "⚠️ 일부 오류 발생"
  fi
  
  echo ""
  echo "📊 최종 테이블 상태:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt"
  
  echo ""
  echo "🔍 주요 테이블 존재 확인:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('users', 'posts', 'comments', 'boards', 'categories', 'files', 'menus', 'refresh_tokens')
    ORDER BY table_name;
  " || echo "테이블 조회 실패"
EOF

echo "🎉 기본 스키마 생성 완료!"
















