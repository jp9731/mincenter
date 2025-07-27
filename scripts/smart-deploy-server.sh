#!/bin/bash

# 서버에서 실행하는 스마트 배포 스크립트
echo "=== 스마트 배포 시작 ==="

# 배포 마커 파일 경로
DEPLOY_MARKER_FILE=".deploy_marker"

# 현재 커밋 해시 저장
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "현재 커밋: $CURRENT_COMMIT"

# 1. 서버에 변경사항 반영
echo "📥 변경사항 가져오기..."
git fetch origin main
git pull origin main

# 새로운 커밋 해시
NEW_COMMIT=$(git rev-parse HEAD)
echo "새로운 커밋: $NEW_COMMIT"

# 2. 마지막 성공한 배포 커밋 확인
LAST_DEPLOYED_COMMIT=""
if [ -f "$DEPLOY_MARKER_FILE" ]; then
    LAST_DEPLOYED_COMMIT=$(cat "$DEPLOY_MARKER_FILE")
    echo "마지막 성공한 배포 커밋: $LAST_DEPLOYED_COMMIT"
else
    echo "마커 파일이 없습니다. 전체 변경사항을 확인합니다."
    # 마커 파일이 없으면 최근 10개 커밋을 확인
    LAST_DEPLOYED_COMMIT=$(git rev-parse HEAD~10 2>/dev/null || git rev-list --max-parents=0 HEAD | head -1)
fi

# 3. 변경사항 확인 (마지막 성공한 배포 이후의 모든 변경사항)
echo "🔍 변경된 파일 확인..."
if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ] && [ "$CURRENT_COMMIT" = "$LAST_DEPLOYED_COMMIT" ]; then
    echo "ℹ️ 변경사항이 없습니다."
    exit 0
fi

# 마지막 성공한 배포 이후의 모든 변경사항 확인
CHANGED_FILES=$(git diff --name-only $LAST_DEPLOYED_COMMIT..$NEW_COMMIT)
echo "변경된 파일들 (마지막 성공 배포 이후):"
echo "$CHANGED_FILES"

# 4. 각 컴포넌트 변경사항 확인
SITE_CHANGED=false
ADMIN_CHANGED=false
API_CHANGED=false

if echo "$CHANGED_FILES" | grep -q "frontends/site/"; then
    SITE_CHANGED=true
    echo "✅ Site 프론트엔드 변경됨"
fi

if echo "$CHANGED_FILES" | grep -q "frontends/admin/"; then
    ADMIN_CHANGED=true
    echo "✅ Admin 프론트엔드 변경됨"
fi

if echo "$CHANGED_FILES" | grep -E "backends/api/|Cargo\.toml|Cargo\.lock"; then
    API_CHANGED=true
    echo "✅ API 백엔드 변경됨"
fi

# 변경사항이 없으면 종료
if [ "$SITE_CHANGED" = false ] && [ "$ADMIN_CHANGED" = false ] && [ "$API_CHANGED" = false ]; then
    echo "ℹ️ 배포할 변경사항이 없습니다."
    exit 0
fi

# 5. .env 파일 확인
echo "🔧 환경변수 설정..."
if [ -f .env ]; then
    echo "✅ .env 파일 발견, Docker Compose가 자동으로 사용합니다"
else
    echo "❌ .env 파일을 찾을 수 없습니다."
    exit 1
fi

# 6. 선택적 빌드 및 배포
echo "🚀 선택적 배포 시작..."

# 배포 성공 여부 추적
DEPLOY_SUCCESS=true

# Site 프론트엔드 배포 (Docker Compose)
if [ "$SITE_CHANGED" = true ]; then
    echo "🌐 Site 프론트엔드 빌드 및 배포..."
    
    # Docker Compose로 Site만 재빌드 및 재시작 (.env 파일 자동 사용)
    echo "📦 Site 이미지 빌드 중..."
    if docker-compose -f docker-compose.prod.yml build site; then
        echo "🚀 Site 컨테이너 시작 중..."
        if docker-compose -f docker-compose.prod.yml up -d site; then
            echo "✅ Site 프론트엔드 배포 완료"
        else
            echo "❌ Site 컨테이너 실행 실패"
            DEPLOY_SUCCESS=false
        fi
    else
        echo "❌ Site Docker 빌드 실패"
        DEPLOY_SUCCESS=false
    fi
fi

# Admin 프론트엔드 배포 (Docker Compose)
if [ "$ADMIN_CHANGED" = true ]; then
    echo "⚡ Admin 프론트엔드 빌드 및 배포..."
    
    # Docker Compose로 Admin만 재빌드 및 재시작 (.env 파일 자동 사용)
    echo "📦 Admin 이미지 빌드 중..."
    if docker-compose -f docker-compose.prod.yml build admin; then
        echo "🚀 Admin 컨테이너 시작 중..."
        if docker-compose -f docker-compose.prod.yml up -d admin; then
            echo "✅ Admin 프론트엔드 배포 완료"
        else
            echo "❌ Admin 컨테이너 실행 실패"
            DEPLOY_SUCCESS=false
        fi
    else
        echo "❌ Admin Docker 빌드 실패"
        DEPLOY_SUCCESS=false
    fi
fi

# API 백엔드 배포 (직접 빌드/실행)
if [ "$API_CHANGED" = true ]; then
    echo "🚀 API 백엔드 빌드 및 배포..."
    
    # API 디렉토리로 이동
    echo "🔍 API 디렉토리 확인..."
    echo "현재 디렉토리: $(pwd)"
    echo "backends/api 존재 여부: $([ -d "backends/api" ] && echo "✅" || echo "❌")"
    
    cd backends/api || {
        echo "❌ backends/api 디렉토리를 찾을 수 없습니다."
        echo "현재 디렉토리 내용:"
        ls -la
        DEPLOY_SUCCESS=false
        exit 1
    }
    
    echo "📦 API 빌드 중..."
    echo "이동 후 디렉토리: $(pwd)"
    
    # Rust 도구체인 확인
    echo "🔧 Rust 도구체인 확인..."
    if ! command -v rustc &> /dev/null; then
        echo "❌ Rust가 설치되지 않았습니다."
        DEPLOY_SUCCESS=false
        cd ../..
        exit 1
    fi
    
    if ! command -v cargo &> /dev/null; then
        echo "❌ Cargo가 설치되지 않았습니다."
        DEPLOY_SUCCESS=false
        cd ../..
        exit 1
    fi
    
    # Cargo.toml 파일 확인
    if [ ! -f "Cargo.toml" ]; then
        echo "❌ Cargo.toml 파일을 찾을 수 없습니다."
        DEPLOY_SUCCESS=false
        cd ../..
        exit 1
    fi
    
    # 환경변수 설정 (서버 실제 정보)
    export DATABASE_URL="postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter"
    export REDIS_URL="redis://:${REDIS_PASSWORD:-tnekwoddl}@localhost:6379"
    export JWT_SECRET="${JWT_SECRET:-default_jwt_secret}"
    export RUST_LOG="${RUST_LOG_LEVEL:-info}"
    
    # 데이터베이스 연결 확인
    echo "🔍 데이터베이스 연결 확인..."
    if command -v pg_isready >/dev/null 2>&1; then
        if ! pg_isready -h localhost -p 15432 -U mincenter >/dev/null 2>&1; then
            echo "❌ PostgreSQL 연결 실패 (pg_isready)"
            DEPLOY_SUCCESS=false
            cd ../..
            exit 1
        fi
        echo "✅ PostgreSQL 연결 성공 (pg_isready)"
    else
        echo "⚠️ pg_isready 명령어가 없습니다. 연결 확인을 건너뜁니다."
        echo "CentOS 7에서는 PostgreSQL 클라이언트가 설치되지 않을 수 있습니다."
    fi
    
    # 기존 프로세스 중지
    echo "🛑 기존 API 프로세스 중지 중..."
    pkill -f "mincenter-api" || true
    sleep 2
    
    # Rust 빌드
    echo "🔨 Rust 빌드 중..."
    echo "Rust 버전: $(rustc --version)"
    echo "Cargo 버전: $(cargo --version)"
    echo "현재 디렉토리: $(pwd)"
    echo "환경변수 확인:"
    echo "- DATABASE_URL: ${DATABASE_URL:0:50}..."
    echo "- REDIS_URL: ${REDIS_URL:0:30}..."
    echo "- JWT_SECRET: ${JWT_SECRET:0:10}..."
    echo "- RUST_LOG: $RUST_LOG"
    
    # SQLx 오프라인 모드 비활성화 (서버에서 빌드 시)
    # export SQLX_OFFLINE=true
    
    # SQLx prepare 실행 (쿼리 메타데이터 업데이트)
    echo "🔧 SQLx prepare 실행 중..."
    if cargo sqlx prepare --check; then
        echo "✅ SQLx prepare 성공"
    else
        echo "⚠️ SQLx prepare 실패, 오프라인 모드로 진행"
        export SQLX_OFFLINE=true
    fi
    
    if cargo build --release; then
        # 새 프로세스 시작
        echo "🚀 API 프로세스 시작 중..."
        nohup ./target/release/mincenter-api > api.log 2>&1 &
        API_PID=$!
        
        # 프로세스 시작 확인
        sleep 3
        if kill -0 $API_PID 2>/dev/null; then
            echo "✅ API 백엔드 배포 완료 (PID: $API_PID)"
        else
            echo "❌ API 프로세스 시작 실패"
            echo "API 로그 확인:"
            tail -20 api.log || echo "로그 파일이 없습니다."
            DEPLOY_SUCCESS=false
        fi
    else
        echo "❌ API 빌드 실패"
        echo "빌드 에러 상세 정보:"
        cargo build --release 2>&1 | tail -50
        DEPLOY_SUCCESS=false
    fi
    
    # 원래 디렉토리로 복귀
    cd ../..
fi

# 7. 배포 성공 시 마커 파일 업데이트
if [ "$DEPLOY_SUCCESS" = true ]; then
    echo "$NEW_COMMIT" > "$DEPLOY_MARKER_FILE"
    echo "✅ 배포 마커 파일 업데이트: $NEW_COMMIT"
else
    echo "❌ 배포 실패 - 마커 파일 업데이트하지 않음"
    echo "다음 배포 시 이번 변경사항들이 다시 포함됩니다."
fi

# 8. 배포 결과 요약
echo ""
echo "📊 배포 결과 요약:"
echo "- Site 프론트엔드: $([ "$SITE_CHANGED" = true ] && echo "✅ 배포됨" || echo "➖ 변경 없음")"
echo "- Admin 프론트엔드: $([ "$ADMIN_CHANGED" = true ] && echo "✅ 배포됨" || echo "➖ 변경 없음")"
echo "- API 백엔드: $([ "$API_CHANGED" = true ] && echo "✅ 배포됨" || echo "➖ 변경 없음")"
echo "- 전체 배포: $([ "$DEPLOY_SUCCESS" = true ] && echo "✅ 성공" || echo "❌ 실패")"

# 9. 서비스 상태 확인
echo ""
echo "🔍 서비스 상태 확인..."

# 서비스 상태 확인
if [ "$API_CHANGED" = true ] || [ "$SITE_CHANGED" = true ] || [ "$ADMIN_CHANGED" = true ]; then
    sleep 10  # 서비스 시작 대기
    
    # Docker Compose 서비스 상태 (프론트엔드만)
    if [ "$SITE_CHANGED" = true ] || [ "$ADMIN_CHANGED" = true ]; then
        if [ -f "docker-compose.prod.yml" ]; then
            docker-compose -f docker-compose.prod.yml ps
        else
            echo "⚠️ docker-compose.prod.yml 파일을 찾을 수 없습니다."
            echo "현재 디렉토리: $(pwd)"
            echo "파일 목록:"
            ls -la *.yml 2>/dev/null || echo "YAML 파일이 없습니다."
        fi
    fi
    
    # API 상태 확인 (직접 실행)
    if [ "$API_CHANGED" = true ]; then
        API_PID=$(pgrep -f "mincenter-api" || echo "")
        if [ -n "$API_PID" ]; then
            echo "- API 프로세스: ✅ 실행 중 (PID: $API_PID)"
        else
            echo "- API 프로세스: ❌ 실행되지 않음"
        fi
        
        API_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:18080/api/health || echo '000')
        echo "- API 상태: $API_STATUS $([ "$API_STATUS" = "200" ] && echo "✅" || echo "❌")"
    fi

    # 프론트엔드 상태 확인
    if [ "$SITE_CHANGED" = true ]; then
        SITE_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:13000 || echo '000')
        echo "- Site 상태: $SITE_STATUS $([ "$SITE_STATUS" = "200" ] && echo "✅" || echo "❌")"
    fi

    if [ "$ADMIN_CHANGED" = true ]; then
        ADMIN_STATUS=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:13001 || echo '000')
        echo "- Admin 상태: $ADMIN_STATUS $([ "$ADMIN_STATUS" = "200" ] && echo "✅" || echo "❌")"
    fi
fi

echo ""
if [ "$DEPLOY_SUCCESS" = true ]; then
    echo "🎉 스마트 배포 완료!"
else
    echo "⚠️ 배포 중 오류가 발생했습니다. 로그를 확인하세요."
    exit 1
fi