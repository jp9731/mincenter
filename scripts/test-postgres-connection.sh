#!/bin/bash

# PostgreSQL 연결 테스트

set -e

echo "🔍 PostgreSQL 연결 테스트..."

# URL 인코딩된 연결 문자열로 테스트
CONNECTION_STRING="postgresql://mincenter:%21%40swjp0209%5E%5E@49.247.4.194:15432/mincenter"

echo "📡 서버 연결 가능 여부 확인..."
nc -z 49.247.4.194 15432 && echo "✅ 포트 15432 연결 가능" || echo "❌ 포트 15432 연결 불가"

echo ""
echo "🗄️ PostgreSQL 직접 연결 테스트..."
if command -v psql &> /dev/null; then
    echo "psql 클라이언트로 연결 테스트..."
    psql "$CONNECTION_STRING" -c "SELECT COUNT(*) as total_users FROM users;" 2>/dev/null || echo "❌ psql 연결 실패"
else
    echo "ℹ️ psql 클라이언트가 설치되어 있지 않습니다."
fi

echo ""
echo "🔧 서버에서 직접 사용자 수 확인..."
ssh admin@mincenter.kr << 'EOF'
    echo "PostgreSQL 컨테이너에서 직접 사용자 수 조회:"
    docker exec mincenter-postgres psql -U mincenter -d mincenter -c "SELECT COUNT(*) as total_users FROM users;"
EOF















