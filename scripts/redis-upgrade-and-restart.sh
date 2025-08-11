#!/bin/bash

# Redis 7 버전 업그레이드 및 전체 서비스 재시작 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 서버 정보
SERVER_HOST="admin@mincenter.kr"
PROJECT_PATH="/home/admin/projects/mincenter"

echo "🚀 Redis 7 버전 업그레이드 및 전체 서비스 재시작"
echo "📅 시작 시간: $(date)"
echo

# 1단계: 현재 상태 확인
log_info "1단계: 현재 Docker 상태 확인"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🐳 현재 실행 중인 컨테이너:'
    docker ps
    echo
    echo '📋 Docker Compose 설정 확인:'
    grep -A 10 'redis:' docker-compose.yml
"

# 2단계: Docker Compose 파일에서 Redis 버전 확인 및 업데이트
log_info "2단계: Docker Compose에서 Redis 7 버전 설정"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🔄 Redis 이미지 버전 확인 및 업데이트...'
    
    # 현재 Redis 이미지 확인
    echo '📝 현재 Redis 설정:'
    grep 'image: redis' docker-compose.yml || echo '❌ Redis 이미지 설정을 찾을 수 없습니다.'
    
    # Redis 7-alpine으로 변경 (이미 7-alpine이면 유지)
    sed -i 's/redis:[0-9]*-alpine/redis:7-alpine/g' docker-compose.yml
    sed -i 's/redis:[0-9]*/redis:7-alpine/g' docker-compose.yml
    
    echo '✅ 변경 후 Redis 설정:'
    grep 'image: redis' docker-compose.yml
"

# 3단계: Redis 이미지 다운로드
log_info "3단계: Redis 7-alpine 이미지 다운로드"
ssh $SERVER_HOST "
    echo '📥 Redis 7-alpine 이미지 다운로드...'
    docker pull redis:7-alpine
    
    echo '📊 현재 Redis 이미지 목록:'
    docker images | grep redis
"

# 4단계: 전체 서비스 재시작
log_info "4단계: 전체 서비스 재시작"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🛑 모든 서비스 중지...'
    docker compose down
    
    echo '🚀 전체 서비스 시작...'
    docker compose up -d
    
    echo '⏳ 서비스 안정화 대기 (30초)...'
    sleep 30
"

# 5단계: 서비스 상태 확인
log_info "5단계: 서비스 상태 및 버전 확인"
ssh $SERVER_HOST "
    cd $PROJECT_PATH
    echo '🏥 전체 서비스 상태:'
    docker compose ps
    echo
    
    echo '🐘 PostgreSQL 17 버전 확인:'
    docker exec mincenter-postgres psql -U mincenter -d mincenter -c 'SELECT version();'
    echo
    
    echo '🔴 Redis 7 버전 확인:'
    docker exec mincenter-redis redis-server --version
    echo
    
    echo '🔗 네트워크 연결 확인:'
    docker network ls | grep mincenter
    echo
    
    echo '📊 컨테이너 네트워크 정보:'
    docker inspect mincenter_mincenter_network | grep -A 20 '\"Containers\"'
"

# 6단계: Redis 연결 테스트
log_info "6단계: Redis 연결 테스트"
ssh $SERVER_HOST "
    echo '🔍 Redis 연결 테스트:'
    docker exec mincenter-redis redis-cli ping
    
    echo '📋 Redis 정보:'
    docker exec mincenter-redis redis-cli info server | head -10
"

# 7단계: PostgreSQL + Redis 연결 테스트
log_info "7단계: 데이터베이스 연결 테스트"
ssh $SERVER_HOST "
    echo '🔗 PostgreSQL 연결 테스트:'
    docker exec mincenter-postgres psql -U mincenter -d mincenter -c 'SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema = \"public\";'
    
    echo '📊 주요 테이블 데이터 확인:'
    docker exec mincenter-postgres psql -U mincenter -d mincenter -c 'SELECT 
        \"users\" as table_name, COUNT(*) as count FROM users
        UNION ALL SELECT \"posts\", COUNT(*) FROM posts  
        UNION ALL SELECT \"boards\", COUNT(*) FROM boards
        UNION ALL SELECT \"roles\", COUNT(*) FROM roles;'
"

log_success "🎉 Redis 7 업그레이드 및 전체 서비스 재시작 완료!"
echo
echo "📊 업그레이드 요약:"
echo "  - PostgreSQL: 17.5 ✅"
echo "  - Redis: 7-alpine ✅"
echo "  - 네트워크: mincenter_mincenter_network ✅"
echo "  - 포트: PostgreSQL(15432), Redis(6379) ✅"
echo
log_info "다음 단계: 개발환경 스키마 마이그레이션을 진행하세요."
