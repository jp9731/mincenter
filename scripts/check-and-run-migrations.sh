#!/bin/bash

# 마이그레이션 파일 확인 및 직접 실행 스크립트

set -e

echo "🔍 마이그레이션 파일 확인 및 실행..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 마이그레이션 파일 확인 및 실행
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "📂 현재 디렉토리 구조:"
  find . -name "*.sql" -type f | head -20
  
  echo ""
  echo "📊 데이터베이스 연결 테스트:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT version();" || echo "❌ 데이터베이스 연결 실패"
  
  echo ""
  echo "🗄️ 현재 테이블 상태:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt" || echo "테이블이 없음"
  
  echo ""
  echo "📁 마이그레이션 디렉토리 확인:"
  if [ -d "backends/api/database/migrations" ]; then
    echo "✅ backends/api/database/migrations 디렉토리 존재"
    ls -la backends/api/database/migrations/
  else
    echo "❌ backends/api/database/migrations 디렉토리 없음"
  fi
  
  echo ""
  echo "📁 루트 database 디렉토리 확인:"
  if [ -d "database" ]; then
    echo "✅ database 디렉토리 존재"
    ls -la database/
  else
    echo "❌ database 디렉토리 없음"
  fi
  
  echo ""
  echo "🚀 SQL 파일 직접 실행 시도..."
  
  # 기본 스키마 파일이 있다면 실행
  if [ -f "database/post_management_tables.sql" ]; then
    echo "📊 post_management_tables.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < database/post_management_tables.sql || echo "⚠️ 일부 오류 발생 (이미 존재하는 테이블일 수 있음)"
  fi
  
  # 마이그레이션 파일이 있다면 실행
  if [ -f "backends/api/database/migrations/20250103000001_create_post_management_tables.sql" ]; then
    echo "📊 20250103000001_create_post_management_tables.sql 실행 중..."
    docker exec -i mincenter-postgres psql -U mincenter -d mincenter < backends/api/database/migrations/20250103000001_create_post_management_tables.sql || echo "⚠️ 일부 오류 발생 (이미 존재하는 테이블일 수 있음)"
  fi
  
  # 덤프 파일이 있다면 실행 (주의: 이미 실행했을 수 있음)
  if [ -f "mincenter_server_dump.sql" ]; then
    echo "📊 mincenter_server_dump.sql 일부 테이블 생성 부분만 실행..."
    # 전체 덤프가 아닌 CREATE TABLE 부분만 추출해서 실행
    grep -A 50 "CREATE TABLE" mincenter_server_dump.sql | head -200 > /tmp/create_tables_only.sql || true
    if [ -s /tmp/create_tables_only.sql ]; then
      docker exec -i mincenter-postgres psql -U mincenter -d mincenter < /tmp/create_tables_only.sql || echo "⚠️ 일부 오류 발생"
    fi
  fi
  
  echo ""
  echo "📊 마이그레이션 후 테이블 상태:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt" || echo "여전히 테이블이 없음"
  
  echo ""
  echo "🔍 특정 테이블 존재 확인:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" || echo "테이블 조회 실패"
EOF

echo "🎉 마이그레이션 파일 확인 및 실행 완료!"
















