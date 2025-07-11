#!/bin/bash

# 서버에서 실행하는 스마트 배포 스크립트
echo "=== 스마트 배포 시작 ==="

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

# 변경사항이 없으면 종료
if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
    echo "ℹ️ 변경사항이 없습니다."
    exit 0
fi

# 2. 변경된 파일 확인
echo "🔍 변경된 파일 확인..."
CHANGED_FILES=$(git diff --name-only $CURRENT_COMMIT..$NEW_COMMIT)
echo "변경된 파일들:"
echo "$CHANGED_FILES"

# 3. 각 컴포넌트 변경사항 확인
SITE_CHANGED=false
ADMIN_CHANGED=false
API_CHANGED=false
DATABASE_CHANGED=false

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

if echo "$CHANGED_FILES" | grep -E "database/|scripts/.*\.sql"; then
    DATABASE_CHANGED=true
    echo "✅ 데이터베이스 변경됨"
fi

# 4. 선택적 빌드 및 배포
echo "🚀 선택적 배포 시작..."

# Site 프론트엔드 배포
if [ "$SITE_CHANGED" = true ]; then
    echo "🌐 Site 프론트엔드 빌드 및 배포..."
    cd frontends/site
    
    # Docker 빌드
    docker build -t mincenter-site . || {
        echo "❌ Site Docker 빌드 실패"
        exit 1
    }
    
    # 기존 컨테이너 중지 및 제거
    docker stop mincenter-site || true
    docker rm mincenter-site || true
    
    # 새 컨테이너 실행
    docker run -d --name mincenter-site -p 13000:80 mincenter-site || {
        echo "❌ Site 컨테이너 실행 실패"
        exit 1
    }
    
    echo "✅ Site 프론트엔드 배포 완료"
    cd ../..
fi

# Admin 프론트엔드 배포
if [ "$ADMIN_CHANGED" = true ]; then
    echo "⚡ Admin 프론트엔드 빌드 및 배포..."
    cd frontends/admin
    
    # Docker 빌드
    docker build -t mincenter-admin . || {
        echo "❌ Admin Docker 빌드 실패"
        exit 1
    }
    
    # 기존 컨테이너 중지 및 제거
    docker stop mincenter-admin || true
    docker rm mincenter-admin || true
    
    # 새 컨테이너 실행
    docker run -d --name mincenter-admin -p 13001:80 mincenter-admin || {
        echo "❌ Admin 컨테이너 실행 실패"
        exit 1
    }
    
    echo "✅ Admin 프론트엔드 배포 완료"
    cd ../..
fi

# API 백엔드 배포
if [ "$API_CHANGED" = true ]; then
    echo "🚀 API 백엔드 빌드 및 배포..."
    cd backends/api
    
    # 기존 프로세스 중지
    pkill -f mincenter-api || true
    sleep 3
    
    # 빌드
    cargo build --release --bin mincenter-api || {
        echo "❌ API 빌드 실패"
        exit 1
    }
    
    # 새 프로세스 시작
    cd ../..
    ./scripts/start-api.sh || {
        echo "❌ API 시작 실패"
        exit 1
    }
    
    echo "✅ API 백엔드 배포 완료"
fi

# 데이터베이스 마이그레이션
if [ "$DATABASE_CHANGED" = true ]; then
    echo "🗄️ 데이터베이스 마이그레이션..."
    
    # 마이그레이션 스크립트 실행
    if [ -f "scripts/migrate.sh" ]; then
        ./scripts/migrate.sh || {
            echo "❌ 데이터베이스 마이그레이션 실패"
            exit 1
        }
    else
        echo "⚠️ 마이그레이션 스크립트 없음 (scripts/migrate.sh)"
    fi
    
    echo "✅ 데이터베이스 마이그레이션 완료"
fi

# 5. 배포 결과 요약
echo ""
echo "📊 배포 결과 요약:"
echo "- Site 프론트엔드: $([ "$SITE_CHANGED" = true ] && echo "✅ 배포됨" || echo "➖ 변경 없음")"
echo "- Admin 프론트엔드: $([ "$ADMIN_CHANGED" = true ] && echo "✅ 배포됨" || echo "➖ 변경 없음")"
echo "- API 백엔드: $([ "$API_CHANGED" = true ] && echo "✅ 배포됨" || echo "➖ 변경 없음")"
echo "- 데이터베이스: $([ "$DATABASE_CHANGED" = true ] && echo "✅ 마이그레이션됨" || echo "➖ 변경 없음")"

# 6. 서비스 상태 확인
echo ""
echo "🔍 서비스 상태 확인..."

# API 상태 확인
if [ "$API_CHANGED" = true ]; then
    sleep 5
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

echo ""
echo "🎉 스마트 배포 완료!"