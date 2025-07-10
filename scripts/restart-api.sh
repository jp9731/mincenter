#!/bin/bash

# API 서버 재시작 스크립트

API_DIR="/opt/mincenter/backends/api"
PID_FILE="$API_DIR/api.pid"

echo "🔄 API 서버 재시작 시작..."

# 기존 프로세스 종료
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "기존 프로세스 종료 중... (PID: $PID)"
        kill "$PID"
        sleep 3
        # 강제 종료
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID"
            echo "강제 종료 완료"
        fi
    fi
    rm -f "$PID_FILE"
fi

# 환경변수 설정
export DATABASE_URL=postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter
export REDIS_URL=redis://:tnekwoddl@localhost:16379
export JWT_SECRET=your_jwt_secret_key
export API_PORT=18080
export RUST_LOG=info
export CORS_ALLOWED_ORIGINS=https://mincenter.kr,https://www.mincenter.kr,http://localhost:5173,http://localhost:3000

# API 디렉토리로 이동
cd "$API_DIR"

# Rust 빌드
echo "Rust 빌드 중..."
cargo build --release --bin mincenter-api

# 백그라운드에서 실행
echo "API 서버 시작 중..."
nohup ./target/release/mincenter-api > api.log 2>&1 &
echo $! > api.pid

# 시작 대기
sleep 5

# 상태 확인
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "✅ API 서버 재시작 완료 (PID: $PID)"
    else
        echo "❌ API 서버 시작 실패"
        exit 1
    fi
else
    echo "❌ PID 파일이 생성되지 않음"
    exit 1
fi 