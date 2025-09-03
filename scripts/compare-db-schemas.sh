#!/bin/bash

# 서버와 개발컴 데이터베이스 스키마 비교 스크립트

set -e

echo "📊 서버와 개발컴 DB 스키마 비교..."

SERVER_HOST="admin@mincenter.kr"

# 먼저 개발컴 스키마 정보 수집
echo "🔍 개발컴 DB 스키마 정보 수집 중..."
psql postgresql://mincenter:!@swjp0209^^@localhost:5432/mincenter -c "\d+" > /tmp/local_schema.txt 2>/dev/null || echo "개발컴 DB 연결 실패"

# 주요 테이블들의 구조 확인 (개발컴)
echo "📋 개발컴 주요 테이블 구조:"
for table in users posts comments boards categories files; do
    echo "=== $table 테이블 (개발컴) ==="
    psql postgresql://mincenter:!@swjp0209^^@localhost:5432/mincenter -c "\d $table" 2>/dev/null || echo "$table 테이블 없음"
    echo ""
done > /tmp/local_tables.txt

# 서버 스키마 정보 수집
echo "🔍 서버 DB 스키마 정보 수집 중..."
ssh $SERVER_HOST << 'EOF'
  echo "📋 서버 주요 테이블 구조:"
  for table in users posts comments boards categories files; do
    echo "=== $table 테이블 (서버) ==="
    docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d $table" 2>/dev/null || echo "$table 테이블 없음"
    echo ""
  done
EOF > /tmp/server_tables.txt

echo "📊 스키마 비교 결과:"
echo "==================="
cat /tmp/local_tables.txt
echo ""
echo "서버 테이블 구조:"
echo "=================="
cat /tmp/server_tables.txt

echo ""
echo "🔍 특정 필드의 nullable 속성 비교..."

# posts 테이블의 주요 필드들 비교
echo "📋 posts 테이블 상세 비교:"
echo "개발컴 posts 테이블:"
psql postgresql://mincenter:!@swjp0209^^@localhost:5432/mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'posts' ORDER BY ordinal_position;" 2>/dev/null || echo "개발컴 posts 테이블 정보 없음"

echo ""
echo "서버 posts 테이블:"
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'posts' ORDER BY ordinal_position;"
EOF

echo ""
echo "📋 comments 테이블 상세 비교:"
echo "개발컴 comments 테이블:"
psql postgresql://mincenter:!@swjp0209^^@localhost:5432/mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'comments' ORDER BY ordinal_position;" 2>/dev/null || echo "개발컴 comments 테이블 정보 없음"

echo ""
echo "서버 comments 테이블:"
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'comments' ORDER BY ordinal_position;"
EOF
















