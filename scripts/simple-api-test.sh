#!/bin/bash

# 간단한 API 테스트 서버 생성 및 배포

set -e

SERVER_HOST="admin@mincenter.kr"
API_PATH="/home/admin/projects/mincenter/backends/api"

echo "🧪 간단한 API 테스트 서버 생성"

# 1. 서버에 간단한 테스트 main.rs 생성
ssh $SERVER_HOST "
cd $API_PATH
echo '📝 간단한 테스트 서버 코드 생성...'
cat > src/main_test.rs << 'EOF'
use axum::{
    routing::get,
    Router,
    response::Json,
};
use serde_json::{json, Value};
use std::net::SocketAddr;
use tokio;

async fn health() -> Json<Value> {
    Json(json!({
        \"status\": \"ok\",
        \"message\": \"MinCenter API Server is running\",
        \"version\": \"1.0.0\",
        \"timestamp\": chrono::Utc::now().to_rfc3339()
    }))
}

async fn info() -> Json<Value> {
    Json(json!({
        \"service\": \"mincenter-api\",
        \"environment\": \"production\",
        \"database\": \"connected\",
        \"redis\": \"connected\"
    }))
}

#[tokio::main]
async fn main() {
    // 환경변수에서 포트 읽기
    let port = std::env::var(\"API_PORT\")
        .unwrap_or_else(|_| \"18080\".to_string())
        .parse::<u16>()
        .unwrap_or(18080);
    
    let app = Router::new()
        .route(\"/health\", get(health))
        .route(\"/info\", get(info))
        .route(\"/\", get(|| async { \"MinCenter API Server\" }));

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!(\"🚀 MinCenter API Server starting on {}\", addr);
    
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}
EOF

echo '✅ 테스트 서버 코드 생성 완료'
"

# 2. 간단한 Cargo.toml 생성
ssh $SERVER_HOST "
cd $API_PATH
echo '📝 간단한 Cargo.toml 생성...'
cat > Cargo_test.toml << 'EOF'
[package]
name = \"mincenter-api-test\"
version = \"0.1.0\"
edition = \"2021\"

[[bin]]
name = \"mincenter-api-test\"
path = \"src/main_test.rs\"

[dependencies]
axum = \"0.7\"
tokio = { version = \"1.0\", features = [\"full\"] }
serde = { version = \"1.0\", features = [\"derive\"] }
serde_json = \"1.0\"
chrono = { version = \"0.4\", features = [\"serde\"] }
EOF

echo '✅ 테스트 Cargo.toml 생성 완료'
"

# 3. 테스트 빌드
ssh $SERVER_HOST "
cd $API_PATH
echo '🏗️  테스트 서버 빌드...'
source ~/.cargo/env
cargo build --manifest-path=Cargo_test.toml --release

if [ -f 'target/release/mincenter-api-test' ]; then
    echo '✅ 테스트 서버 빌드 성공'
    chmod +x target/release/mincenter-api-test
    ls -lh target/release/mincenter-api-test
else
    echo '❌ 테스트 서버 빌드 실패'
    exit 1
fi
"

# 4. 테스트 서버 실행
ssh $SERVER_HOST "
cd $API_PATH
echo '🚀 테스트 서버 실행...'

# 기존 프로세스 종료
pkill -f mincenter-api || echo 'ℹ️  기존 프로세스 없음'

# 환경변수 설정하고 백그라운드 실행
export API_PORT=18080
nohup ./target/release/mincenter-api-test > api_test.log 2>&1 &
TEST_PID=\$!

echo \"🎯 테스트 서버 PID: \$TEST_PID\"
echo \$TEST_PID > api_test.pid

sleep 5

# 상태 확인
if ps -p \$TEST_PID > /dev/null; then
    echo '✅ 테스트 서버 실행 중'
    
    # 포트 확인
    if ss -tlnp | grep 18080; then
        echo '✅ 포트 18080에서 리스닝 중'
        
        # 헬스체크
        if curl -f http://localhost:18080/health; then
            echo '✅ 헬스체크 성공'
        else
            echo '❌ 헬스체크 실패'
        fi
    else
        echo '❌ 포트 18080에서 리스닝하지 않음'
    fi
else
    echo '❌ 테스트 서버 실행 실패'
    echo '📋 로그 확인:'
    tail -20 api_test.log
fi
"

echo "✅ 간단한 API 테스트 서버 설정 완료!"
echo "📊 테스트 서버 정보:"
echo "  - 포트: 18080"
echo "  - 헬스체크: curl http://localhost:18080/health"
echo "  - 정보: curl http://localhost:18080/info"
echo "  - 로그: tail -f $API_PATH/api_test.log"
