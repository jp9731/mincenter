#!/bin/bash

# API 디버깅 전용 스크립트
echo "=== API 디버깅 모드 ==="

# 1. 현재 디렉토리 확인 및 변경
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="$(dirname "$SCRIPT_DIR")/backends/api"

echo "Script directory: $SCRIPT_DIR"
echo "API directory: $API_DIR"

# API 디렉토리로 이동
cd "$API_DIR" || {
    echo "❌ Failed to change to API directory: $API_DIR"
    exit 1
}

echo "Current directory: $(pwd)"

# 2. 기존 프로세스 종료
echo "Stopping existing processes..."
pkill -f mincenter-api || true
sleep 2

# 3. 상세 환경 변수 설정
export DATABASE_URL=${DATABASE_URL:-"postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"}
export REDIS_URL=${REDIS_URL:-"redis://:tnekwoddl@localhost:16379"}
export JWT_SECRET=${JWT_SECRET:-"your-jwt-secret-here"}
export REFRESH_SECRET=${REFRESH_SECRET:-"your-refresh-secret-here"}
export API_PORT=${API_PORT:-18080}
export RUST_LOG="trace,mincenter_api=trace,sqlx=debug,hyper=debug,tower_http=debug"
export CORS_ORIGIN=${CORS_ORIGIN:-"*"}
export RUST_BACKTRACE=1

# 4. 환경 변수 확인
echo "=== 환경 변수 ==="
echo "DATABASE_URL: $DATABASE_URL"
echo "REDIS_URL: $REDIS_URL"
echo "JWT_SECRET: ${JWT_SECRET:0:10}..."
echo "REFRESH_SECRET: ${REFRESH_SECRET:0:10}..."
echo "API_PORT: $API_PORT"
echo "RUST_LOG: $RUST_LOG"
echo "RUST_BACKTRACE: $RUST_BACKTRACE"

# 5. 바이너리 파일 확인
if [ ! -f "target/release/mincenter-api" ]; then
    echo "❌ Binary not found. Building..."
    cargo build --release --bin mincenter-api || {
        echo "❌ Build failed"
        exit 1
    }
fi

echo "✅ Binary found: target/release/mincenter-api"

# 6. 바이너리 정보 확인
echo "=== 바이너리 정보 ==="
ls -la target/release/mincenter-api
file target/release/mincenter-api
ldd target/release/mincenter-api 2>/dev/null || echo "Static binary or ldd not available"

# 7. 연결 테스트
echo "=== 연결 테스트 ==="

# PostgreSQL 연결 테스트
echo "Testing PostgreSQL connection..."
if command -v psql &> /dev/null; then
    if psql "$DATABASE_URL" -c "SELECT version();" 2>/dev/null; then
        echo "✅ PostgreSQL connection OK"
    else
        echo "❌ PostgreSQL connection failed"
        psql "$DATABASE_URL" -c "SELECT 1;" 2>&1 | head -5
    fi
else
    echo "⚠️ psql not available"
fi

# Redis 연결 테스트
echo "Testing Redis connection..."
if command -v redis-cli &> /dev/null; then
    if redis-cli -u "$REDIS_URL" ping 2>/dev/null; then
        echo "✅ Redis connection OK"
    else
        echo "❌ Redis connection failed"
        redis-cli -u "$REDIS_URL" ping 2>&1 | head -5
    fi
else
    echo "⚠️ redis-cli not available"
fi

# 8. 포트 확인
echo "=== 포트 확인 ==="
netstat -tlnp | grep :$API_PORT || echo "Port $API_PORT not in use"

# 9. 로그 디렉토리 생성
mkdir -p logs

# 10. 포그라운드 실행 (디버깅용)
echo "=== 포그라운드 실행 (Ctrl+C로 종료) ==="
echo "Starting API in foreground mode for debugging..."
echo "Log output will be shown in real-time"
echo "Press Ctrl+C to stop"
echo ""

# 실행
exec ./target/release/mincenter-api 2>&1 | tee logs/debug.log