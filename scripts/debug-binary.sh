#!/bin/bash

# 디버깅을 위한 스크립트
echo "=== mincenter-api 실행 환경 디버깅 ==="

# 1. 현재 디렉토리 확인
echo "Current directory: $(pwd)"

# 2. 바이너리 파일 확인
echo "Binary file check:"
ls -la target/release/mincenter-api

# 3. 환경 변수 확인
echo "Environment variables:"
echo "DATABASE_URL: $DATABASE_URL"
echo "REDIS_URL: $REDIS_URL"
echo "JWT_SECRET: $JWT_SECRET"
echo "REFRESH_SECRET: $REFRESH_SECRET"
echo "API_PORT: $API_PORT"
echo "RUST_LOG: $RUST_LOG"
echo "CORS_ORIGIN: $CORS_ORIGIN"

# 4. 설정 파일 확인
echo "Config files:"
ls -la .env* 2>/dev/null || echo "No .env files found"

# 5. 데이터베이스 연결 테스트
echo "Testing database connection..."
if command -v psql &> /dev/null; then
    psql "$DATABASE_URL" -c "SELECT 1;" 2>/dev/null && echo "✅ Database connection OK" || echo "❌ Database connection failed"
else
    echo "psql not available for testing"
fi

# 6. Redis 연결 테스트
echo "Testing Redis connection..."
if command -v redis-cli &> /dev/null; then
    redis-cli -u "$REDIS_URL" ping 2>/dev/null && echo "✅ Redis connection OK" || echo "❌ Redis connection failed"
else
    echo "redis-cli not available for testing"
fi

# 7. 바이너리 직접 실행 테스트 (포그라운드)
echo "Testing binary execution..."
echo "Running: ./target/release/mincenter-api"
echo "Press Ctrl+C to stop after a few seconds..."

# 환경 변수 설정
export DATABASE_URL=${DATABASE_URL:-"postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"}
export REDIS_URL=${REDIS_URL:-"redis://:tnekwoddl@localhost:16379"}
export JWT_SECRET=${JWT_SECRET:-"your-jwt-secret-here"}
export REFRESH_SECRET=${REFRESH_SECRET:-"your-refresh-secret-here"}
export API_PORT=${API_PORT:-18080}
export RUST_LOG=${RUST_LOG:-"debug"}
export CORS_ORIGIN=${CORS_ORIGIN:-"*"}

# 실행
timeout 10s ./target/release/mincenter-api 2>&1 | head -20