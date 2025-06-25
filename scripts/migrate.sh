#!/bin/bash

# 데이터베이스 마이그레이션 스크립트
# 기존 데이터를 보존하면서 스키마 변경사항만 적용

set -e

echo "=== 데이터베이스 마이그레이션 시작 ==="

# 환경 변수 로드
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 필수 환경 변수 확인
if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL이 설정되지 않았습니다."
    exit 1
fi

echo "데이터베이스 URL: $DATABASE_URL"

# API 디렉토리로 이동
cd backends/api

# sqlx-cli 설치 확인
if ! command -v sqlx &> /dev/null; then
    echo "sqlx-cli가 설치되지 않았습니다. 설치를 시작합니다..."
    cargo install sqlx-cli --no-default-features --features postgres
fi

# 마이그레이션 상태 확인
echo "현재 마이그레이션 상태 확인..."
sqlx migrate info

# 마이그레이션 실행
echo "마이그레이션 실행 중..."
sqlx migrate run

echo "✅ 마이그레이션이 성공적으로 완료되었습니다."

# 마이그레이션 후 상태 확인
echo "최종 마이그레이션 상태:"
sqlx migrate info

cd ../..

echo "=== 데이터베이스 마이그레이션 완료 ===" 