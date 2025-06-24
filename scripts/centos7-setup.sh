#!/bin/bash

# CentOS 7 환경 설정 스크립트
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# CentOS 7 버전 확인
check_centos_version() {
    if [ -f /etc/redhat-release ]; then
        CENTOS_VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | head -1)
        log_info "CentOS 버전: $CENTOS_VERSION"
        
        if [[ "$CENTOS_VERSION" != "7"* ]]; then
            log_warn "이 스크립트는 CentOS 7용입니다. 현재 버전: $CENTOS_VERSION"
        fi
    else
        log_warn "CentOS가 아닌 시스템에서 실행 중입니다."
    fi
}

# 시스템 업데이트
update_system() {
    log_info "시스템을 업데이트합니다..."
    sudo yum update -y
    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
}

# Docker 설치
install_docker() {
    log_info "Docker를 설치합니다..."
    
    # 기존 Docker 제거
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    
    # Docker 저장소 추가
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Docker CE 설치
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Docker 서비스 시작 및 자동 시작 설정
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # 현재 사용자를 docker 그룹에 추가
    sudo usermod -aG docker $USER
    
    log_info "Docker 설치가 완료되었습니다. 재로그인이 필요할 수 있습니다."
}

# Docker Compose 설치
install_docker_compose() {
    log_info "Docker Compose를 설치합니다..."
    
    # 최신 버전 다운로드
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # 실행 권한 부여
    sudo chmod +x /usr/local/bin/docker-compose
    
    # 심볼릭 링크 생성
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_info "Docker Compose 설치가 완료되었습니다."
}

# 방화벽 설정
configure_firewall() {
    log_info "방화벽을 설정합니다..."
    
    # 필요한 포트 열기
    sudo firewall-cmd --permanent --add-port=80/tcp
    sudo firewall-cmd --permanent --add-port=443/tcp
    sudo firewall-cmd --permanent --add-port=3000/tcp
    sudo firewall-cmd --permanent --add-port=3001/tcp
    sudo firewall-cmd --permanent --add-port=8080/tcp
    sudo firewall-cmd --permanent --add-port=5432/tcp
    sudo firewall-cmd --permanent --add-port=6379/tcp
    
    # 방화벽 재시작
    sudo firewall-cmd --reload
    
    log_info "방화벽 설정이 완료되었습니다."
}

# SELinux 설정
configure_selinux() {
    log_info "SELinux를 설정합니다..."
    
    # SELinux 상태 확인
    SELINUX_STATUS=$(getenforce)
    log_info "현재 SELinux 상태: $SELINUX_STATUS"
    
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        log_warn "SELinux가 활성화되어 있습니다. Docker 컨테이너 실행에 영향을 줄 수 있습니다."
        log_info "SELinux를 비활성화하려면: sudo setenforce 0"
        log_info "영구적으로 비활성화하려면 /etc/selinux/config에서 SELINUX=disabled로 설정"
    fi
}

# 시스템 리소스 설정
configure_system_resources() {
    log_info "시스템 리소스를 설정합니다..."
    
    # 파일 디스크립터 제한 증가
    echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
    
    # 커널 파라미터 설정
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
    echo "net.core.somaxconn=65535" | sudo tee -a /etc/sysctl.conf
    
    # 설정 적용
    sudo sysctl -p
    
    log_info "시스템 리소스 설정이 완료되었습니다."
}

# 메인 실행
main() {
    log_info "CentOS 7 환경 설정을 시작합니다..."
    
    check_centos_version
    update_system
    install_docker
    install_docker_compose
    configure_firewall
    configure_selinux
    configure_system_resources
    
    log_info "CentOS 7 환경 설정이 완료되었습니다!"
    log_info "다음 단계:"
    echo "  1. 시스템을 재부팅하거나 재로그인하세요"
    echo "  2. .env 파일을 설정하세요"
    echo "  3. ./scripts/deploy.sh를 실행하세요"
}

# 스크립트 실행
main "$@" 