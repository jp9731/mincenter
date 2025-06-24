#!/bin/bash

# PM2 설치 스크립트 (CentOS 7 호환)
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Node.js 설치 확인
check_nodejs() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js가 설치되지 않았습니다."
        log_info "Node.js를 먼저 설치하세요."
        exit 1
    fi
    
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    log_info "Node.js 버전: $NODE_VERSION"
    log_info "npm 버전: $NPM_VERSION"
}

# PM2 설치
install_pm2() {
    log_step "PM2를 설치합니다..."
    
    if command -v pm2 &> /dev/null; then
        log_warn "PM2가 이미 설치되어 있습니다."
        PM2_VERSION=$(pm2 --version)
        log_info "PM2 버전: $PM2_VERSION"
        
        read -p "PM2를 재설치하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # PM2 전역 설치
    log_info "PM2를 전역으로 설치합니다..."
    npm install -g pm2
    
    # PM2 버전 확인
    PM2_VERSION=$(pm2 --version)
    log_info "PM2 설치 완료. 버전: $PM2_VERSION"
}

# PM2 설정
setup_pm2() {
    log_step "PM2를 설정합니다..."
    
    # PM2 시작 스크립트 생성
    log_info "PM2 시작 스크립트를 생성합니다..."
    pm2 startup
    
    # PM2 로그 설정
    log_info "PM2 로그 설정을 구성합니다..."
    pm2 install pm2-logrotate
    
    # 로그 로테이션 설정
    pm2 set pm2-logrotate:max_size 10M
    pm2 set pm2-logrotate:retain 30
    pm2 set pm2-logrotate:compress true
    pm2 set pm2-logrotate:dateFormat YYYY-MM-DD_HH-mm-ss
    pm2 set pm2-logrotate:workerInterval 30
    pm2 set pm2-logrotate:rotateInterval '0 0 * * *'
    
    log_info "PM2 로그 설정이 완료되었습니다."
}

# 시스템 서비스 설정
setup_systemd() {
    log_step "시스템 서비스를 설정합니다..."
    
    # PM2 서비스 파일 생성
    sudo tee /etc/systemd/system/pm2.service << 'EOF'
[Unit]
Description=PM2 process manager
Documentation=https://pm2.keymetrics.io/
After=network.target

[Service]
Type=forking
User=root
LimitNOFILE=infinity
LimitNPROC=infinity
PIDFile=/root/.pm2/pm2.pid
Restart=on-failure

ExecStart=/usr/bin/pm2 resurrect
ExecReload=/usr/bin/pm2 reload all
ExecStop=/usr/bin/pm2 kill

[Install]
WantedBy=multi-user.target
EOF

    # 서비스 활성화
    sudo systemctl daemon-reload
    sudo systemctl enable pm2.service
    
    log_info "PM2 시스템 서비스가 설정되었습니다."
}

# 모니터링 설정
setup_monitoring() {
    log_step "모니터링을 설정합니다..."
    
    # PM2 모니터링 설치
    log_info "PM2 모니터링을 설치합니다..."
    pm2 install pm2-server-monit
    
    # 웹 인터페이스 설정
    log_info "PM2 웹 인터페이스를 설정합니다..."
    pm2 install pm2-web-interface
    
    # 웹 인터페이스 포트 설정
    pm2 set pm2-web-interface:port 9615
    
    log_info "모니터링 설정이 완료되었습니다."
    log_info "PM2 웹 인터페이스: http://localhost:9615"
}

# 로그 디렉토리 생성
create_directories() {
    log_step "필요한 디렉토리를 생성합니다..."
    
    mkdir -p frontends/site/logs
    mkdir -p frontends/admin/logs
    mkdir -p logs
    
    log_info "디렉토리 생성이 완료되었습니다."
}

# 권한 설정
setup_permissions() {
    log_step "권한을 설정합니다..."
    
    # 로그 디렉토리 권한
    chmod 755 frontends/site/logs
    chmod 755 frontends/admin/logs
    chmod 755 logs
    
    log_info "권한 설정이 완료되었습니다."
}

# 테스트
test_pm2() {
    log_step "PM2 설치를 테스트합니다..."
    
    # 간단한 테스트 앱 생성
    cat > test-app.js << 'EOF'
const http = require('http');
const port = process.env.PORT || 3002;

const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('PM2 Test App Running!\n');
});

server.listen(port, () => {
  console.log(`Test app listening on port ${port}`);
});
EOF

    # 테스트 앱 시작
    pm2 start test-app.js --name "test-app"
    
    # 잠시 대기
    sleep 3
    
    # 테스트
    if curl -f http://localhost:3002 > /dev/null 2>&1; then
        log_info "✅ PM2 테스트 성공!"
    else
        log_error "❌ PM2 테스트 실패"
    fi
    
    # 테스트 앱 정리
    pm2 delete test-app
    rm test-app.js
}

# 메인 실행
main() {
    log_step "PM2 설치 및 설정을 시작합니다..."
    
    check_nodejs
    install_pm2
    setup_pm2
    setup_systemd
    setup_monitoring
    create_directories
    setup_permissions
    test_pm2
    
    log_step "PM2 설치 및 설정이 완료되었습니다!"
    
    log_info "다음 단계:"
    echo "  1. 환경 변수 파일(.env)을 설정하세요"
    echo "  2. ./scripts/pm2-deploy.sh를 실행하여 배포하세요"
    echo "  3. pm2 list로 상태를 확인하세요"
    echo "  4. pm2 logs로 로그를 확인하세요"
    
    log_info "유용한 PM2 명령어:"
    echo "  - pm2 list: 프로세스 목록"
    echo "  - pm2 logs: 로그 확인"
    echo "  - pm2 monit: 모니터링"
    echo "  - pm2 restart all: 모든 프로세스 재시작"
    echo "  - pm2 stop all: 모든 프로세스 중지"
    echo "  - pm2 delete all: 모든 프로세스 삭제"
}

# 스크립트 실행
main "$@" 