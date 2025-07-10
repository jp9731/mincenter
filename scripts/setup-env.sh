#!/bin/bash

# Docker 환경변수 설정 스크립트

echo "🔧 Docker 환경변수 설정 시작..."

# 프로젝트 루트 디렉토리
PROJECT_ROOT=$(pwd)

# Site 프론트엔드 환경변수 설정
if [ ! -f "frontends/site/.env" ]; then
    cat > frontends/site/.env << EOF
# Site 프론트엔드 환경변수
VITE_API_URL=\${VITE_API_URL:-http://localhost:18080}
VITE_GOOGLE_CLIENT_ID=\${VITE_GOOGLE_CLIENT_ID:-}
VITE_KAKAO_CLIENT_ID=\${VITE_KAKAO_CLIENT_ID:-}
EOF
    echo "✅ Site .env 파일 생성 완료"
else
    echo "ℹ️ Site .env 파일이 이미 존재합니다"
fi

# Admin 프론트엔드 환경변수 설정
if [ ! -f "frontends/admin/.env" ]; then
    cat > frontends/admin/.env << EOF
# Admin 프론트엔드 환경변수
VITE_API_URL=\${VITE_API_URL:-http://localhost:18080}
EOF
    echo "✅ Admin .env 파일 생성 완료"
else
    echo "ℹ️ Admin .env 파일이 이미 존재합니다"
fi

# Docker Compose 환경변수 파일 생성
if [ ! -f ".env" ]; then
    cat > .env << EOF
# Docker Compose 환경변수
APP_NAME=mincenter
POSTGRES_DB=mincenter
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_secure_password
JWT_SECRET=your_jwt_secret_key
API_PORT=18080
REDIS_PASSWORD=your_redis_password
REDIS_PORT=16379
CORS_ORIGIN=*
RUST_LOG_LEVEL=info
NODE_ENV=production
VITE_API_URL=http://localhost:18080
PUBLIC_API_URL=http://localhost:18080
SESSION_SECRET=your_session_secret
ADMIN_SESSION_SECRET=your_admin_session_secret
ADMIN_EMAIL=admin@mincenter.kr
EOF
    echo "✅ Docker Compose .env 파일 생성 완료"
    echo "⚠️  보안을 위해 .env 파일의 비밀번호를 변경해주세요!"
else
    echo "ℹ️ Docker Compose .env 파일이 이미 존재합니다"
fi

echo "🎉 환경변수 설정 완료!"
echo ""
echo "📝 다음 단계:"
echo "1. .env 파일의 비밀번호를 변경하세요"
echo "2. docker-compose -f docker-compose.prod.yml up -d 로 실행하세요" 