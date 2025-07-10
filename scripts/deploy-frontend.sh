#!/bin/bash

# 프론트엔드 배포 스크립트
# 환경변수 설정 및 빌드

FRONTEND_TYPE=$1  # "site" 또는 "admin"
DEPLOY_PATH="/opt/mincenter/frontends"

echo "🚀 $FRONTEND_TYPE 프론트엔드 배포 시작..."

if [ "$FRONTEND_TYPE" = "site" ]; then
    FRONTEND_DIR="frontends/site"
    API_URL="https://api.mincenter.kr"
elif [ "$FRONTEND_TYPE" = "admin" ]; then
    FRONTEND_DIR="frontends/admin"
    API_URL="https://api.mincenter.kr"
else
    echo "❌ 잘못된 프론트엔드 타입: $FRONTEND_TYPE"
    echo "사용법: ./scripts/deploy-frontend.sh [site|admin]"
    exit 1
fi

# 환경변수 파일 생성
cat > "$FRONTEND_DIR/.env.production" << EOF
VITE_API_URL=$API_URL
EOF

echo "✅ 환경변수 파일 생성: $FRONTEND_DIR/.env.production"

# 빌드 실행
cd "$FRONTEND_DIR"
npm run build

if [ $? -eq 0 ]; then
    echo "✅ $FRONTEND_TYPE 빌드 완료"
    
    # 서버에 배포
    rsync -avz --delete dist/ $DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_PATH/$FRONTEND_TYPE/
    
    echo "🎉 $FRONTEND_TYPE 배포 완료"
else
    echo "❌ $FRONTEND_TYPE 빌드 실패"
    exit 1
fi 