#!/bin/bash

# mincenter-api 시작 스크립트
echo "=== Starting mincenter-api ==="

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

# 3. 환경 변수 설정
export DATABASE_URL=${DATABASE_URL:-"postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"}
export REDIS_URL=${REDIS_URL:-"redis://:tnekwoddl@localhost:16379"}
export JWT_SECRET=${JWT_SECRET:-"your-jwt-secret-here"}
export REFRESH_SECRET=${REFRESH_SECRET:-"your-refresh-secret-here"}
export API_PORT=${API_PORT:-18080}
export RUST_LOG=${RUST_LOG:-"info"}
export CORS_ORIGIN=${CORS_ORIGIN:-"*"}

# 4. 환경 변수 확인
echo "Environment variables:"
echo "DATABASE_URL: $DATABASE_URL"
echo "REDIS_URL: $REDIS_URL"
echo "JWT_SECRET: ${JWT_SECRET:0:10}..."
echo "API_PORT: $API_PORT"
echo "RUST_LOG: $RUST_LOG"

# 5. 바이너리 파일 확인
if [ ! -f "target/release/mincenter-api" ]; then
    echo "❌ Binary not found. Building..."
    cargo build --release --bin mincenter-api || {
        echo "❌ Build failed"
        exit 1
    }
fi

echo "✅ Binary found: target/release/mincenter-api"

# 6. 연결 테스트
echo "Testing connections..."

# PostgreSQL 연결 테스트
if command -v psql &> /dev/null; then
    if psql "$DATABASE_URL" -c "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ Database connection OK"
    else
        echo "❌ Database connection failed"
        exit 1
    fi
fi

# Redis 연결 테스트
if command -v redis-cli &> /dev/null; then
    if redis-cli -u "$REDIS_URL" ping >/dev/null 2>&1; then
        echo "✅ Redis connection OK"
    else
        echo "❌ Redis connection failed"
        exit 1
    fi
fi

# 7. 시작 방식 선택
if [ "$1" = "foreground" ] || [ "$1" = "fg" ]; then
    echo "🚀 Starting in foreground mode..."
    exec ./target/release/mincenter-api
else
    echo "🚀 Starting in background mode..."
    
    # 로그 디렉토리 생성
    mkdir -p logs
    
    # 백그라운드에서 실행
    nohup ./target/release/mincenter-api > logs/api.log 2>&1 &
    
    # PID 저장
    echo $! > api.pid
    
    echo "Process started with PID: $!"
    echo "Log file: logs/api.log"
    echo "PID file: api.pid"
    
    # 시작 확인
    sleep 3
    
    if ps -p $! > /dev/null; then
        echo "✅ Process is running"
        
        # 로그 일부 출력
        echo "Recent logs:"
        tail -10 logs/api.log
        
        # 건강 상태 확인
        sleep 2
        if curl -s "http://localhost:$API_PORT/api/health" >/dev/null 2>&1; then
            echo "✅ API health check passed"
        else
            echo "⚠️ API health check failed (may need more time)"
        fi
    else
        echo "❌ Process failed to start"
        echo "Check logs:"
        cat logs/api.log
        exit 1
    fi
fi