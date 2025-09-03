#!/bin/bash

# 서버에 데이터베이스 복원 스크립트
# 작업 폴더: /home/admin/projects/mincenter

set -e

echo "📥 서버 데이터베이스 복원 중..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 데이터베이스 복원
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "⏳ PostgreSQL 컨테이너 준비 대기..."
  # PostgreSQL이 완전히 시작될 때까지 대기
  until docker exec mincenter-postgres pg_isready -U mincenter -d mincenter; do
    echo "PostgreSQL 시작 대기 중..."
    sleep 5
  done
  
  echo "🗄️ 데이터베이스 복원 시작..."
  # 덤프 파일 복원
  docker exec -i mincenter-postgres psql -U mincenter -d mincenter < mincenter_complete_dump.sql
  
  echo "✅ 데이터베이스 복원 완료!"
  
  # 데이터 확인
  echo "📊 데이터베이스 테이블 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt"
  
  echo ""
  echo "📊 사용자 수 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT COUNT(*) as user_count FROM users;"
  
  echo ""
  echo "📊 게시글 수 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT COUNT(*) as post_count FROM posts;"
EOF

echo "✅ 데이터베이스 복원 완료!"


