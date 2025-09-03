#!/bin/bash

# 서버 DB 스키마를 개발컴과 동일하게 수정하는 스크립트

set -e

echo "🔧 서버 DB 스키마를 개발컴과 동일하게 수정 중..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 스키마 수정 실행
ssh $SERVER_HOST << 'EOF'
  echo "📊 현재 서버 스키마 상태 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d posts" | grep content
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d comments" | grep status
  
  echo ""
  echo "🔧 스키마 수정 시작..."
  
  echo "1️⃣ posts.content 필드를 NOT NULL로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    UPDATE posts SET content = '' WHERE content IS NULL;
    ALTER TABLE posts ALTER COLUMN content SET NOT NULL;
  " || echo "⚠️ posts.content 수정 실패"
  
  echo "2️⃣ posts.meta_title 길이를 255로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE posts ALTER COLUMN meta_title TYPE character varying(255);
  " || echo "⚠️ posts.meta_title 수정 실패"
  
  echo "3️⃣ posts.attached_files를 text[]로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE posts ALTER COLUMN attached_files TYPE text[] USING 
    CASE 
      WHEN attached_files IS NULL OR attached_files = '' THEN NULL
      ELSE string_to_array(attached_files, ',')
    END;
  " || echo "⚠️ posts.attached_files 수정 실패"
  
  echo "4️⃣ posts.thumbnail_urls를 jsonb로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE posts ALTER COLUMN thumbnail_urls TYPE jsonb USING 
    CASE 
      WHEN thumbnail_urls IS NULL OR thumbnail_urls = '' THEN NULL
      ELSE thumbnail_urls::jsonb
    END;
  " || echo "⚠️ posts.thumbnail_urls 수정 실패"
  
  echo "5️⃣ posts.id 기본값을 uuid_generate_v4()로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE posts ALTER COLUMN id SET DEFAULT uuid_generate_v4();
  " || echo "⚠️ posts.id 기본값 수정 실패"
  
  echo "6️⃣ comments.status를 post_status 타입으로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE comments ALTER COLUMN status TYPE post_status USING status::post_status;
  " || echo "⚠️ comments.status 수정 실패"
  
  echo "7️⃣ comments.id 기본값을 uuid_generate_v4()로 변경..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    ALTER TABLE comments ALTER COLUMN id SET DEFAULT uuid_generate_v4();
  " || echo "⚠️ comments.id 기본값 수정 실패"
  
  echo ""
  echo "✅ 스키마 수정 완료! 수정 결과 확인..."
  
  echo "📊 posts 테이블 수정 결과:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d posts" | grep -E "(content|meta_title|attached_files|thumbnail_urls|id)"
  
  echo ""
  echo "📊 comments 테이블 수정 결과:"
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d comments" | grep -E "(status|id)"
  
EOF
















