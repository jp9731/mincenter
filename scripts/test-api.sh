#!/bin/bash

# API 테스트 스크립트
echo "=== API 테스트 ==="

API_URL=${1:-"http://localhost:18080"}
echo "API URL: $API_URL"

# 1. Health Check
echo "1. Health Check..."
curl -v "$API_URL/api/health" 2>&1 | grep -E "(HTTP|Content-Type|^<|^>)"

echo ""

# 2. 메뉴 조회 (GET)
echo "2. 메뉴 조회..."
curl -v "$API_URL/api/site/menus" \
  -H "Origin: https://mincenter.kr" \
  2>&1 | grep -E "(HTTP|Content-Type|^<|^>)"

echo ""

# 3. 로그인 테스트 (POST)
echo "3. 로그인 테스트..."
curl -v "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "Origin: https://mincenter.kr" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword",
    "service_type": "site"
  }' 2>&1 | grep -E "(HTTP|Content-Type|^<|^>)"

echo ""

# 4. 상세 로그인 테스트 (응답 내용 포함)
echo "4. 상세 로그인 테스트..."
RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}\n" "$API_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "Origin: https://mincenter.kr" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword",
    "service_type": "site"
  }')

echo "$RESPONSE" | sed 's/HTTP_CODE:/\nHTTP_CODE:/'

echo ""
echo "=== 테스트 완료 ==="