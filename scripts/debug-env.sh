#!/bin/bash

# 환경변수 디버그 스크립트

echo "🔍 환경변수 디버그 시작..."

# 현재 환경변수 확인
echo "=== 현재 환경변수 ==="
echo "VITE_API_URL: ${VITE_API_URL:-'NOT SET'}"
echo "NODE_ENV: ${NODE_ENV:-'NOT SET'}"

# .env 파일 확인
echo ""
echo "=== .env 파일 확인 ==="
if [ -f "frontends/site/.env" ]; then
    echo "Site .env 파일 존재:"
    cat frontends/site/.env
else
    echo "❌ Site .env 파일이 없습니다"
fi

if [ -f "frontends/admin/.env" ]; then
    echo ""
    echo "Admin .env 파일 존재:"
    cat frontends/admin/.env
else
    echo "❌ Admin .env 파일이 없습니다"
fi

# Docker 빌드 시 환경변수 확인
echo ""
echo "=== Docker 빌드 환경변수 확인 ==="
echo "빌드 시 전달할 환경변수:"
echo "VITE_API_URL=${VITE_API_URL:-https://api.mincenter.kr}"

# 빌드 테스트
echo ""
echo "=== 빌드 테스트 ==="
cd frontends/site

# 환경변수 파일 생성 테스트
echo "VITE_API_URL=${VITE_API_URL:-https://api.mincenter.kr}" > .env.test
echo "생성된 .env.test 파일:"
cat .env.test

# 빌드 시 환경변수 확인
echo ""
echo "빌드 시 환경변수 확인:"
VITE_API_URL=${VITE_API_URL:-https://api.mincenter.kr} npm run build

echo "🎉 디버그 완료!" 