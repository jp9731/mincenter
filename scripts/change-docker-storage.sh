#!/bin/bash

# Docker 스토리지 드라이버 변경 스크립트
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
    echo -e "${BLUE}[STORAGE CHANGE]${NC} $1"
}

# 현재 Docker 설정 확인
check_current_config() {
    log_header "=== 현재 Docker 설정 확인 ==="
    
    log_info "현재 Docker 스토리지 드라이버:"
    docker info | grep "Storage Driver"
    
    echo ""
    log_info "현재 Docker 데몬 설정:"
    if [ -f "/etc/docker/daemon.json" ]; then
        cat /etc/docker/daemon.json
    else
        log_warn "Docker 데몬 설정 파일이 없습니다."
    fi
    
    echo ""
    log_info "현재 Docker 사용량:"
    docker system df
}

# 백업 생성
create_backup() {
    log_header "=== 백업 생성 ==="
    
    BACKUP_DIR="/tmp/docker_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR
    
    log_info "Docker 설정 백업 중..."
    
    # Docker 데몬 설정 백업
    if [ -f "/etc/docker/daemon.json" ]; then
        cp /etc/docker/daemon.json $BACKUP_DIR/
    fi
    
    # Docker 데이터 백업 (중요한 볼륨만)
    log_info "중요한 Docker 볼륨 백업 중..."
    docker volume ls --format "{{.Name}}" | grep -E "(postgres|mysql|data)" | while read volume; do
        log_info "볼륨 백업: $volume"
        docker run --rm -v $volume:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/${volume}.tar.gz -C /data .
    done
    
    log_info "백업 완료: $BACKUP_DIR"
}

# Docker 서비스 중지
stop_docker() {
    log_header "=== Docker 서비스 중지 ==="
    
    log_info "Docker 서비스 중지 중..."
    sudo systemctl stop docker
    
    log_info "Docker 프로세스 확인:"
    ps aux | grep docker | grep -v grep || true
}

# overlay2 설정 생성
create_overlay2_config() {
    log_header "=== overlay2 설정 생성 ==="
    
    log_info "Docker 데몬 설정 디렉토리 생성:"
    sudo mkdir -p /etc/docker
    
    log_info "overlay2 설정 파일 생성:"
    cat << EOF | sudo tee /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
    
    log_info "설정 파일 생성 완료:"
    cat /etc/docker/daemon.json
}

# 기존 Docker 데이터 정리
cleanup_old_data() {
    log_header "=== 기존 Docker 데이터 정리 ==="
    
    log_warn "⚠️  주의: 기존 Docker 데이터를 삭제합니다!"
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "데이터 정리가 취소되었습니다."
        return
    fi
    
    log_info "기존 Docker 데이터 삭제 중..."
    sudo rm -rf /var/lib/docker/devicemapper
    sudo rm -rf /var/lib/docker/containers
    sudo rm -rf /var/lib/docker/image
    sudo rm -rf /var/lib/docker/overlay2
    sudo rm -rf /var/lib/docker/volumes
    sudo rm -rf /var/lib/docker/network
    
    log_info "Docker 데이터 디렉토리 재생성:"
    sudo mkdir -p /var/lib/docker
}

# Docker 서비스 시작
start_docker() {
    log_header "=== Docker 서비스 시작 ==="
    
    log_info "Docker 서비스 시작 중..."
    sudo systemctl start docker
    
    log_info "Docker 서비스 상태 확인:"
    sudo systemctl status docker --no-pager -l
    
    # 잠시 대기
    sleep 5
    
    log_info "새로운 스토리지 드라이버 확인:"
    docker info | grep "Storage Driver"
}

# 백업 복원
restore_backup() {
    log_header "=== 백업 복원 ==="
    
    log_info "백업된 볼륨 복원 중..."
    for backup_file in /tmp/docker_backup_*/postgres*.tar.gz; do
        if [ -f "$backup_file" ]; then
            volume_name=$(basename "$backup_file" .tar.gz)
            log_info "볼륨 복원: $volume_name"
            docker volume create $volume_name
            docker run --rm -v $volume_name:/data -v $(dirname "$backup_file"):/backup alpine tar xzf /backup/$(basename "$backup_file") -C /data
        fi
    done
}

# 메인 실행
main() {
    log_info "Docker 스토리지 드라이버를 overlay2로 변경합니다..."
    
    # 현재 설정 확인
    check_current_config
    
    # 사용자 확인
    log_warn "⚠️  주의: 이 작업은 모든 Docker 컨테이너와 이미지를 삭제합니다!"
    log_warn "중요한 데이터가 있다면 백업하세요."
    read -p "계속하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "작업이 취소되었습니다."
        exit 0
    fi
    
    # 백업 생성
    create_backup
    
    # Docker 서비스 중지
    stop_docker
    
    # 기존 데이터 정리
    cleanup_old_data
    
    # overlay2 설정 생성
    create_overlay2_config
    
    # Docker 서비스 시작
    start_docker
    
    # 백업 복원 (선택사항)
    read -p "백업된 데이터를 복원하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        restore_backup
    fi
    
    log_info "Docker 스토리지 드라이버 변경이 완료되었습니다!"
    log_info "백업 위치: /tmp/docker_backup_*"
}

# 스크립트 실행
main 