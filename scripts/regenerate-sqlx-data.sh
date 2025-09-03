#!/bin/bash

# SQLx 오프라인 데이터 재생성으로 타입 오류 해결

set -e

echo "🔧 SQLx 오프라인 데이터 재생성..."

SERVER_HOST="admin@mincenter.kr"

# 서버에서 SQLx 오프라인 데이터 재생성
ssh $SERVER_HOST << 'EOF'
  cd /home/admin/projects/mincenter/backends/api
  
  echo "📝 환경변수 로드..."
  source .env
  
  echo "🗑️ 기존 SQLx 데이터 제거..."
  rm -f sqlx-data.json .sqlx-data.json
  
  echo "🔧 SQLx CLI 설치 확인..."
  if ! command -v sqlx &> /dev/null; then
    echo "📦 SQLx CLI 설치 중..."
    cargo install sqlx-cli --no-default-features --features postgres
  fi
  
  echo "🔍 데이터베이스 연결 테스트..."
  if sqlx database --help > /dev/null 2>&1; then
    echo "✅ SQLx CLI 사용 가능"
  else
    echo "❌ SQLx CLI 설치 실패"
    exit 1
  fi
  
  echo "📊 SQLx 오프라인 데이터 생성 중..."
  # 오프라인 모드 비활성화하고 실제 DB에서 타입 정보 추출
  export SQLX_OFFLINE=false
  
  # prepare 명령으로 모든 쿼리 분석 및 데이터 생성
  if sqlx prepare --database-url "$DATABASE_URL"; then
    echo "✅ SQLx 오프라인 데이터 생성 성공!"
  else
    echo "❌ SQLx prepare 실패, 수동으로 시도..."
    
    # 대안: 직접 cargo check로 쿼리 검증
    echo "🔨 Cargo check로 쿼리 검증 중..."
    if cargo check --bin mincenter-api 2>&1 | tee /tmp/sqlx_check.log; then
      echo "✅ 타입 검증 성공"
    else
      echo "⚠️ 일부 타입 오류 존재, 계속 진행..."
    fi
  fi
  
  echo "📋 생성된 SQLx 파일 확인..."
  ls -la sqlx-data.json .sqlx-data.json 2>/dev/null || echo "SQLx 데이터 파일 없음"
  
  echo "🔨 오프라인 모드로 빌드 시도..."
  export SQLX_OFFLINE=true
  
  if cargo build --release --bin mincenter-api 2>&1 | tee /tmp/build.log; then
    echo "✅ 빌드 성공!"
    
    echo "🛑 기존 API 프로세스 종료..."
    pkill -f "mincenter-api" 2>/dev/null || true
    pkill -9 -f "18080" 2>/dev/null || true
    fuser -k 18080/tcp 2>/dev/null || true
    
    echo "🚀 API 서버 실행..."
    nohup ./target/release/mincenter-api > /tmp/api.log 2>&1 &
    
    echo "⏳ API 서버 시작 대기 중..."
    sleep 15
    
    echo "🏥 API 서버 헬스체크..."
    for i in {1..10}; do
      if curl -f http://localhost:18080/api/health 2>/dev/null; then
        echo "✅ API 서버가 정상적으로 실행 중입니다!"
        echo "🌐 API 접근 URL: http://49.247.4.194:18080"
        break
      else
        echo "⏳ API 서버 시작 대기 중... ($i/10)"
        sleep 3
      fi
    done
  else
    echo "❌ 빌드 실패"
    echo "📋 빌드 오류 로그:"
    tail -30 /tmp/build.log
  fi
  
  echo ""
  echo "📋 API 서버 로그 (마지막 20줄):"
  tail -20 /tmp/api.log 2>/dev/null || echo "로그 파일 없음"
EOF

echo "🎉 SQLx 오프라인 데이터 재생성 완료!"
















