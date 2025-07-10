#!/bin/bash

# CORS 환경변수 설정 스크립트
# 사용법: ./scripts/setup-cors-env.sh [도메인1,도메인2,...]

set -e

# 기본 허용 도메인
DEFAULT_ORIGINS="https://mincenter.kr,https://www.mincenter.kr,http://localhost:5173,http://localhost:3000"

# 사용자가 도메인을 지정한 경우 사용, 아니면 기본값 사용
if [ $# -eq 0 ]; then
    CORS_ORIGINS="$DEFAULT_ORIGINS"
    echo "기본 CORS 도메인을 사용합니다: $CORS_ORIGINS"
else
    CORS_ORIGINS="$1"
    echo "사용자 지정 CORS 도메인을 사용합니다: $CORS_ORIGINS"
fi

# .env 파일 경로
ENV_FILE="backends/api/.env"

# .env 파일이 없으면 생성
if [ ! -f "$ENV_FILE" ]; then
    echo "Creating $ENV_FILE..."
    touch "$ENV_FILE"
fi

# CORS_ALLOWED_ORIGINS 설정 추가/업데이트
if grep -q "CORS_ALLOWED_ORIGINS" "$ENV_FILE"; then
    # 기존 설정 업데이트
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/CORS_ALLOWED_ORIGINS=.*/CORS_ALLOWED_ORIGINS=$CORS_ORIGINS/" "$ENV_FILE"
    else
        # Linux
        sed -i "s/CORS_ALLOWED_ORIGINS=.*/CORS_ALLOWED_ORIGINS=$CORS_ORIGINS/" "$ENV_FILE"
    fi
    echo "✅ CORS_ALLOWED_ORIGINS 업데이트됨"
else
    # 새 설정 추가
    echo "CORS_ALLOWED_ORIGINS=$CORS_ORIGINS" >> "$ENV_FILE"
    echo "✅ CORS_ALLOWED_ORIGINS 추가됨"
fi

echo ""
echo "🔧 CORS 설정 완료!"
echo "허용된 도메인: $CORS_ORIGINS"
echo ""
echo "📝 사용 예시:"
echo "  # 기본 도메인 사용"
echo "  ./scripts/setup-cors-env.sh"
echo ""
echo "  # 사용자 지정 도메인 사용"
echo "  ./scripts/setup-cors-env.sh 'https://mincenter.kr,https://admin.mincenter.kr,http://localhost:5173'"
echo ""
echo "⚠️  API 서버를 재시작해야 변경사항이 적용됩니다:"
echo "  cd backends/api && cargo run" 