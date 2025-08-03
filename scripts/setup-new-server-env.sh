#!/bin/bash

# 새로운 서버 환경 설정 스크립트
# nginx proxy manager 환경에 맞춘 설정

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 설정
REMOTE_USER="admin"
REMOTE_HOST="49.247.4.194"
REMOTE_PORT="22"
SSH_KEY="~/.ssh/firsthous_server_rsa"
APP_NAME="mincenter"
REMOTE_DIR="/home/admin/projects/mincenter"

# SSH 명령어 헬퍼 (에이전트 사용)
ssh_cmd() {
    ssh -o BatchMode=yes -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST "$1"
}

log_info "=== 새로운 서버 환경 설정 시작 ==="
log_info "서버: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}"

# 1. 서버 연결 테스트
log_info "1. 서버 연결 테스트 중..."
if ! ssh_cmd "echo '연결 성공'" > /dev/null 2>&1; then
    log_error "서버에 연결할 수 없습니다."
    exit 1
fi

# 2. Docker Compose 설치 확인
log_info "2. Docker Compose 설치 확인 중..."
if ssh_cmd "docker compose version" > /dev/null 2>&1; then
    log_success "Docker Compose v2가 이미 설치되어 있습니다."
elif ssh_cmd "docker-compose --version" > /dev/null 2>&1; then
    log_success "Docker Compose v1이 설치되어 있습니다."
else
    log_error "Docker Compose가 설치되어 있지 않습니다."
    exit 1
fi

# 3. 필요한 디렉토리 생성
log_info "3. 필요한 디렉토리 생성 중..."
ssh_cmd "mkdir -p $REMOTE_DIR/{api,site,admin,database,static}"

# 4. 정적 파일 디렉토리 생성
log_info "4. 정적 파일 디렉토리 생성 중..."
ssh_cmd "mkdir -p $REMOTE_DIR/static/{uploads,profiles,site}"

# 5. 환경 변수 파일 생성
log_info "5. 환경 변수 파일 생성 중..."
cat > /tmp/.env << 'EOF'
# MinCenter 환경 변수
APP_NAME=mincenter
DATABASE_URL=postgresql://mincenter:!@swjp0209^^@postgres:5432/mincenter
REDIS_URL=redis://:tnekwoddl@redis:6379
JWT_SECRET=your_jwt_secret_here_change_this_in_production
API_PORT=18080
RUST_LOG=info
CORS_ORIGIN=*

# 프론트엔드 환경 변수
PUBLIC_API_URL=http://api.mincenter.kr
PUBLIC_DOMAIN=mincenter.kr
PUBLIC_NODE_ENV=production
EOF

ssh_cmd "cat > $REMOTE_DIR/.env" < /tmp/.env

# 6. 백업 스크립트 생성
log_info "6. 백업 스크립트 생성 중..."
cat > /tmp/backup.sh << 'EOF'
#!/bin/bash

# MinCenter 백업 스크립트
BACKUP_DIR="/home/admin/projects/mincenter/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# PostgreSQL 백업
docker exec mincenter-postgres pg_dump -U mincenter mincenter > $BACKUP_DIR/database_$DATE.sql

# 정적 파일 백업
tar -czf $BACKUP_DIR/static_$DATE.tar.gz -C /home/admin/projects/mincenter static/

# 7일 이상 된 백업 삭제
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "백업 완료: $BACKUP_DIR"
EOF

ssh_cmd "cat > $REMOTE_DIR/backup.sh" < /tmp/backup.sh
ssh_cmd "chmod +x $REMOTE_DIR/backup.sh"

# 7. 관리 스크립트 생성
log_info "7. 관리 스크립트 생성 중..."
cat > /tmp/manage.sh << 'EOF'
#!/bin/bash

# MinCenter 관리 스크립트
APP_DIR="/home/admin/projects/mincenter"

case "$1" in
    start)
        echo "서비스 시작 중..."
        cd $APP_DIR && docker compose up -d
        ;;
    stop)
        echo "서비스 중지 중..."
        cd $APP_DIR && docker compose down
        ;;
    restart)
        echo "서비스 재시작 중..."
        cd $APP_DIR && docker compose restart
        ;;
    status)
        echo "서비스 상태 확인 중..."
        cd $APP_DIR && docker compose ps
        ;;
    logs)
        echo "로그 확인 중..."
        cd $APP_DIR && docker compose logs -f
        ;;
    backup)
        echo "백업 실행 중..."
        $APP_DIR/backup.sh
        ;;
    update)
        echo "서비스 업데이트 중..."
        cd $APP_DIR && docker compose pull && docker compose up -d
        ;;
    *)
        echo "사용법: $0 {start|stop|restart|status|logs|backup|update}"
        exit 1
        ;;
esac
EOF

ssh_cmd "cat > $REMOTE_DIR/manage.sh" < /tmp/manage.sh
ssh_cmd "chmod +x $REMOTE_DIR/manage.sh"

# 8. cron 작업 설정 (백업 자동화)
log_info "8. cron 작업 설정 중..."
ssh_cmd "echo '0 2 * * * $REMOTE_DIR/backup.sh' | crontab -"

# 9. 방화벽 설정 확인
log_info "9. 방화벽 설정 확인 중..."
ssh_cmd "ufw status | grep -E '(18080|13000|13001|15432|16379)' || echo '포트가 열려있지 않습니다.'"

log_success "=== 환경 설정 완료 ==="
echo ""
log_info "설정된 포트:"
log_info "  API 서버: 18080"
log_info "  사이트: 13000"
log_info "  관리자: 13001"
log_info "  PostgreSQL: 15432"
log_info "  Redis: 16379"
echo ""
log_info "관리 명령어:"
log_info "  서비스 관리: ssh $REMOTE_USER@$REMOTE_HOST '$REMOTE_DIR/manage.sh {start|stop|restart|status|logs|backup|update}'"
log_info "  백업: ssh $REMOTE_USER@$REMOTE_HOST '$REMOTE_DIR/backup.sh'"
echo ""
log_info "다음 단계:"
log_info "  1. ./scripts/deploy-new-server.sh 실행"
log_info "  2. Nginx Proxy Manager에서 도메인 설정"
log_info "  3. SSL 인증서 설정" 