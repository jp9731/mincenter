#!/bin/bash

# 루트 .env 파일을 API 디렉토리에 심볼릭 링크로 연결하는 스크립트

set -e

echo "🔗 .env 파일 심볼릭 링크 생성..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 심볼릭 링크 생성
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter
  
  echo "🔍 현재 .env 파일 상태 확인..."
  echo "루트 디렉토리:"
  ls -la .env* 2>/dev/null || echo "루트에 .env 파일 없음"
  
  echo "API 디렉토리:"
  ls -la backends/api/.env* 2>/dev/null || echo "API에 .env 파일 없음"
  
  echo "📝 루트 디렉토리에 .env 파일 생성..."
  cat > .env << 'ENVEOF'
# 데이터베이스 설정
DATABASE_URL=postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter

# Redis 설정
REDIS_URL=redis://:tnekwoddl@localhost:16379

# API 서버 설정
API_PORT=18080
RUST_LOG=info

# CORS 설정
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr

# JWT 설정
JWT_SECRET=y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=
REFRESH_SECRET=ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=

# 토큰 만료 시간 (일 단위)
ACCESS_TOKEN_EXPIRY=1
REFRESH_TOKEN_EXPIRY=30

# 파일 업로드 설정
MAX_FILE_SIZE=10485760
UPLOAD_DIR=./uploads

# 로그 레벨
LOG_LEVEL=info
ENVEOF

  echo "🔧 파일 권한 설정..."
  chmod 600 .env
  
  echo "🗑️ 기존 API .env 파일 제거 (있다면)..."
  rm -f backends/api/.env
  
  echo "🔗 심볼릭 링크 생성..."
  cd backends/api
  ln -sf ../../.env .env
  
  echo "✅ 심볼릭 링크 생성 완료!"
  
  echo "🔍 결과 확인:"
  echo "루트 .env 파일:"
  ls -la ../../.env
  
  echo "API .env 심볼릭 링크:"
  ls -la .env
  
  echo "심볼릭 링크 대상 확인:"
  readlink .env
  
  echo "📋 연결된 .env 파일 내용 확인 (민감한 정보 제외):"
  cat .env | grep -v "SECRET\|PASSWORD" | grep -E "^[A-Z]" | head -5
  
  echo "✅ 심볼릭 링크 설정 완료!"
EOF

echo "🎉 .env 파일 심볼릭 링크 생성 완료!"
















