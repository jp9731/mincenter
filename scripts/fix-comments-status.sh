#!/bin/bash

# comments.status 필드 타입 수정 스크립트

set -e

echo "🔧 comments.status 필드 타입 수정 중..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 comments.status 수정
ssh $SERVER_HOST << 'EOF'
  echo "📊 현재 comments.status 상태 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d comments" | grep status
  
  echo ""
  echo "🔧 comments.status 기본값 제거 후 타입 변경..."
  
  # 기본값 제거
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE comments ALTER COLUMN status DROP DEFAULT;
  "
  
  # 타입 변경
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE comments ALTER COLUMN status TYPE post_status USING status::post_status;
  "
  
  # 기본값 다시 설정
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE comments ALTER COLUMN status SET DEFAULT 'active'::post_status;
  "
  
  echo ""
  echo "✅ comments.status 수정 완료! 결과 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d comments" | grep status
  
EOF
















