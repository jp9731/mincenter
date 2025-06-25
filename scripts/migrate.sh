#!/bin/bash

# 데이터베이스 마이그레이션 스크립트 (납품 시 비활성화)
# 기존 데이터를 보존하면서 스키마 변경사항만 적용

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${BLUE}[MIGRATION]${NC} $1"
}

log_header "=== 마이그레이션 스크립트 비활성화 ==="

log_warn "⚠️  이 스크립트는 납품을 위해 비활성화되었습니다."
log_info "데이터베이스 스키마 변경사항은 수동으로 적용하세요."
log_info "필요한 경우 직접 DB에 접속하여 변경사항을 적용하시기 바랍니다."

log_header "=== 마이그레이션 스크립트 종료 ==="
log_info "납품 시 수동으로 DB 스키마를 관리하세요." 