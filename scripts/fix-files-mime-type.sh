#!/bin/bash

# files 테이블의 mime_type 필드를 NOT NULL로 수정

set -e

echo "🔧 files 테이블 mime_type 필드를 NOT NULL로 수정..."

SERVER_HOST="admin@mincenter.kr"

ssh $SERVER_HOST << 'EOF'
  echo "📊 현재 mime_type NULL 값 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    SELECT COUNT(*) as null_count FROM files WHERE mime_type IS NULL;
  "
  
  echo ""
  echo "🔧 NULL 값들을 기본값으로 업데이트..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    UPDATE files SET mime_type = 'application/octet-stream' WHERE mime_type IS NULL;
  "
  
  echo "📊 mime_type NOT NULL 제약 조건 추가..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE files ALTER COLUMN mime_type SET NOT NULL;
  "
  
  echo ""
  echo "✅ 수정 완료! 결과 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d files" | grep mime_type
  
EOF
















