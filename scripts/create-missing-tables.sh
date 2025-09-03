#!/bin/bash

# 서버에 누락된 테이블들 생성

set -e

echo "🔧 서버에 누락된 테이블들 생성..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 누락된 테이블 생성
ssh $SERVER_HOST << 'EOF'
  echo "📊 현재 서버 테이블 상태 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt" | grep -E "(post_hide_history|comment_hide_history)"
  
  echo ""
  echo "🔧 누락된 테이블 생성 시작..."
  
  echo "1️⃣ post_hide_history 테이블 생성 (있으면 건너뛰기)..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    CREATE TABLE IF NOT EXISTS post_hide_history (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
        hidden_by UUID NOT NULL REFERENCES users(id),
        hide_reason TEXT,
        category TEXT,
        is_hidden BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        unhidden_at TIMESTAMP WITH TIME ZONE
    );
  " || echo "⚠️ post_hide_history 생성 실패"
  
  echo "2️⃣ comment_hide_history 테이블 생성 (있으면 건너뛰기)..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    CREATE TABLE IF NOT EXISTS comment_hide_history (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        comment_id UUID NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
        hidden_by UUID NOT NULL REFERENCES users(id),
        hide_reason TEXT,
        category TEXT,
        is_hidden BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        unhidden_at TIMESTAMP WITH TIME ZONE
    );
  " || echo "⚠️ comment_hide_history 생성 실패"
  
  echo "3️⃣ 인덱스 생성..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "
    CREATE INDEX IF NOT EXISTS idx_post_hide_history_post_id ON post_hide_history(post_id);
    CREATE INDEX IF NOT EXISTS idx_post_hide_history_is_hidden ON post_hide_history(is_hidden);
    CREATE INDEX IF NOT EXISTS idx_comment_hide_history_comment_id ON comment_hide_history(comment_id);
    CREATE INDEX IF NOT EXISTS idx_comment_hide_history_is_hidden ON comment_hide_history(is_hidden);
  " || echo "⚠️ 인덱스 생성 실패"
  
  echo ""
  echo "✅ 테이블 생성 완료! 확인..."
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\dt" | grep -E "(hide_history|url_ids)"
  
EOF
















