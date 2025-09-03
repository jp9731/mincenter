#!/bin/bash

# 개발컴과 서버 데이터베이스 스키마 비교 스크립트

set -e

echo "📊 개발컴과 서버 DB 스키마 비교..."

SERVER_HOST="admin@mincenter.kr"

echo "🔍 개발컴 posts 테이블 구조 확인..."
docker exec mincenter_postgres psql -U mincenter -d mincenter -c "\d posts" > /tmp/local_posts.txt

echo "🔍 개발컴 comments 테이블 구조 확인..."
docker exec mincenter_postgres psql -U mincenter -d mincenter -c "\d comments" > /tmp/local_comments.txt

echo "🔍 개발컴 posts 테이블 nullable 정보 확인..."
docker exec mincenter_postgres psql -U mincenter -d mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'posts' ORDER BY ordinal_position;" > /tmp/local_posts_nullable.txt

echo "🔍 개발컴 comments 테이블 nullable 정보 확인..."
docker exec mincenter_postgres psql -U mincenter -d mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'comments' ORDER BY ordinal_position;" > /tmp/local_comments_nullable.txt

echo "🔍 서버 posts 테이블 구조 확인..."
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d posts"
EOF > /tmp/server_posts.txt

echo "🔍 서버 comments 테이블 구조 확인..."
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "\d comments"
EOF > /tmp/server_comments.txt

echo "🔍 서버 posts 테이블 nullable 정보 확인..."
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'posts' ORDER BY ordinal_position;"
EOF > /tmp/server_posts_nullable.txt

echo "🔍 서버 comments 테이블 nullable 정보 확인..."
ssh $SERVER_HOST << 'EOF'
  docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'comments' ORDER BY ordinal_position;"
EOF > /tmp/server_comments_nullable.txt

echo ""
echo "📋 ===== POSTS 테이블 비교 ====="
echo ""
echo "🏠 개발컴 posts 테이블:"
cat /tmp/local_posts.txt
echo ""
echo "🌐 서버 posts 테이블:"
cat /tmp/server_posts.txt

echo ""
echo "📋 ===== COMMENTS 테이블 비교 ====="
echo ""
echo "🏠 개발컴 comments 테이블:"
cat /tmp/local_comments.txt
echo ""
echo "🌐 서버 comments 테이블:"
cat /tmp/server_comments.txt

echo ""
echo "📊 ===== NULLABLE 속성 비교 ====="
echo ""
echo "🏠 개발컴 posts 테이블 nullable 정보:"
cat /tmp/local_posts_nullable.txt
echo ""
echo "🌐 서버 posts 테이블 nullable 정보:"
cat /tmp/server_posts_nullable.txt
echo ""
echo "🏠 개발컴 comments 테이블 nullable 정보:"
cat /tmp/local_comments_nullable.txt
echo ""
echo "🌐 서버 comments 테이블 nullable 정보:"
cat /tmp/server_comments_nullable.txt

echo ""
echo "🔍 ===== 차이점 분석 ====="
echo ""
echo "posts 테이블 nullable 차이점:"
diff /tmp/local_posts_nullable.txt /tmp/server_posts_nullable.txt || echo "posts 테이블에 차이점이 있습니다."
echo ""
echo "comments 테이블 nullable 차이점:"
diff /tmp/local_comments_nullable.txt /tmp/server_comments_nullable.txt || echo "comments 테이블에 차이점이 있습니다."
















