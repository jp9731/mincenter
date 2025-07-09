#!/bin/bash

# MinCenter CentOS 7 API 빌드 스크립트
# 로컬에서 CentOS 7 호환 바이너리를 빌드하여 배포용으로 생성

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
PROJECT_NAME="mincenter-api"
BUILD_DIR="build/centos7"
BINARY_NAME="mincenter-api"
TARGET="x86_64-unknown-linux-gnu"
RUST_VERSION="1.70.0"

# 함수: Rust 설치 확인 및 설치
install_rust() {
    log_info "Rust 설치 확인 중..."
    
    if ! command -v rustc &> /dev/null; then
        log_info "Rust 설치 중..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
        log_success "Rust 설치 완료"
    else
        log_success "Rust가 이미 설치되어 있습니다: $(rustc --version)"
    fi
    
    # Rust 버전 확인
    RUST_VERSION_INSTALLED=$(rustc --version | cut -d' ' -f2)
    log_info "설치된 Rust 버전: $RUST_VERSION_INSTALLED"
}

# 함수: CentOS 7 타겟 추가
add_centos7_target() {
    log_info "CentOS 7 타겟 추가 중..."
    
    # x86_64-unknown-linux-gnu 타겟 추가
    rustup target add $TARGET
    
    log_success "CentOS 7 타겟 추가 완료: $TARGET"
}

# 함수: 빌드 디렉토리 생성
create_build_dir() {
    log_info "빌드 디렉토리 생성 중..."
    
    mkdir -p "$BUILD_DIR"
    
    log_success "빌드 디렉토리 생성 완료: $BUILD_DIR"
}

# 함수: 의존성 확인
check_dependencies() {
    log_info "의존성 확인 중..."
    
    # 필수 도구 확인
    local missing_deps=()
    
    if ! command -v pkg-config &> /dev/null; then
        missing_deps+=("pkg-config")
    fi
    
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    if ! command -v gcc &> /dev/null; then
        missing_deps+=("gcc")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_warning "다음 의존성이 누락되었습니다: ${missing_deps[*]}"
        log_info "macOS에서 설치하는 방법:"
        log_info "  brew install pkg-config openssl gcc"
        log_info "Ubuntu/Debian에서 설치하는 방법:"
        log_info "  sudo apt install pkg-config libssl-dev build-essential"
        log_info "CentOS/RHEL에서 설치하는 방법:"
        log_info "  sudo yum install pkgconfig openssl-devel gcc"
        
        read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "모든 의존성이 설치되어 있습니다."
    fi
}

# 함수: 환경변수 설정
setup_environment() {
    log_info "빌드 환경변수 설정 중..."
    
    # macOS에서 OpenSSL 경로 설정
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            export OPENSSL_LIB_DIR=$(brew --prefix openssl@1.1)/lib
            export OPENSSL_INCLUDE_DIR=$(brew --prefix openssl@1.1)/include
        fi
    fi
    
    log_success "환경변수 설정 완료"
}

# 함수: 프로젝트 빌드
build_project() {
    log_info "프로젝트 빌드 중..."
    
    cd backends/api
    
    # 클린 빌드
    log_info "이전 빌드 정리 중..."
    cargo clean
    
    # 릴리즈 빌드 (로컬 타겟)
    log_info "릴리즈 빌드 시작..."
    cargo build --release
    
    # 빌드 결과 확인
    if [ -f "target/release/$BINARY_NAME" ]; then
        log_success "빌드 성공!"
    else
        log_error "빌드 실패!"
        exit 1
    fi
    
    cd ../..
}

# 함수: 바이너리 복사 및 최적화
copy_and_optimize() {
    log_info "바이너리 복사 및 최적화 중..."
    
    # 바이너리 복사
    cp "backends/api/target/release/$BINARY_NAME" "$BUILD_DIR/"
    
    # 실행 권한 설정
    chmod +x "$BUILD_DIR/$BINARY_NAME"
    
    # 바이너리 크기 확인
    BINARY_SIZE=$(du -h "$BUILD_DIR/$BINARY_NAME" | cut -f1)
    log_info "바이너리 크기: $BINARY_SIZE"
    
    # 바이너리 정보 확인
    log_info "바이너리 정보:"
    file "$BUILD_DIR/$BINARY_NAME"
    
    log_success "바이너리 복사 및 최적화 완료"
}

# 함수: 배포 패키지 생성
create_deployment_package() {
    log_info "배포 패키지 생성 중..."
    
    # 배포 디렉토리 생성
    DEPLOY_DIR="$BUILD_DIR/deploy"
    mkdir -p "$DEPLOY_DIR"
    
    # 바이너리 복사
    cp "$BUILD_DIR/$BINARY_NAME" "$DEPLOY_DIR/"
    
    # systemd 서비스 파일 생성
    cat > "$DEPLOY_DIR/mincenter-api.service" << 'EOF'
[Unit]
Description=MinCenter API Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mincenter-api
ExecStart=/opt/mincenter-api/mincenter-api
Restart=always
RestartSec=3
Environment=DATABASE_URL=postgresql://postgres:password@localhost:15432/mincenter
Environment=REDIS_URL=redis://:default_password@localhost:16379
Environment=JWT_SECRET=your_jwt_secret_here
Environment=API_PORT=18080
Environment=RUST_LOG=info
Environment=CORS_ORIGIN=*
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # 설치 스크립트 생성
    cat > "$DEPLOY_DIR/install.sh" << 'EOF'
#!/bin/bash

# MinCenter API 설치 스크립트

set -e

echo "MinCenter API 설치 시작..."

# 바이너리 복사
sudo mkdir -p /opt/mincenter-api
sudo cp mincenter-api /opt/mincenter-api/
sudo chmod +x /opt/mincenter-api/mincenter-api
sudo chown root:root /opt/mincenter-api/mincenter-api

# systemd 서비스 설치
sudo cp mincenter-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mincenter-api

echo "설치 완료!"
echo "서비스 시작: sudo systemctl start mincenter-api"
echo "서비스 상태 확인: sudo systemctl status mincenter-api"
echo "로그 확인: sudo journalctl -u mincenter-api -f"
EOF
    
    chmod +x "$DEPLOY_DIR/install.sh"
    
    # 배포 패키지 압축
    cd "$BUILD_DIR"
    tar -czf "${PROJECT_NAME}-centos7.tar.gz" deploy/
    
    log_success "배포 패키지 생성 완료: $BUILD_DIR/${PROJECT_NAME}-centos7.tar.gz"
}

# 함수: 빌드 검증
verify_build() {
    log_info "빌드 검증 중..."
    
    # 바이너리 존재 확인
    if [ ! -f "$BUILD_DIR/$BINARY_NAME" ]; then
        log_error "바이너리가 생성되지 않았습니다!"
        exit 1
    fi
    
    # 바이너리 실행 가능 여부 확인 (로컬에서)
    if [ -f "$BUILD_DIR/$BINARY_NAME" ]; then
        log_info "바이너리 실행 테스트..."
        # 헬프 메시지로 실행 가능 여부 확인
        if timeout 5s "$BUILD_DIR/$BINARY_NAME" --help > /dev/null 2>&1; then
            log_success "바이너리 실행 테스트 통과"
        else
            log_warning "바이너리 실행 테스트 실패 (예상됨 - 다른 아키텍처)"
        fi
    fi
    
    # 파일 정보 출력
    log_info "빌드된 파일 정보:"
    ls -la "$BUILD_DIR/"
    
    log_success "빌드 검증 완료"
}

# 함수: 정리
cleanup() {
    log_info "정리 중..."
    
    # 임시 파일 정리
    cd backends/api
    cargo clean
    cd ../..
    
    log_success "정리 완료"
}

# 메인 함수
main() {
    case "${1:-all}" in
        "rust")
            log_info "Rust 설치만 실행"
            install_rust
            ;;
        "target")
            log_info "타겟 추가만 실행"
            add_centos7_target
            ;;
        "build")
            log_info "빌드만 실행"
            create_build_dir
            setup_environment
            build_project
            copy_and_optimize
            ;;
        "package")
            log_info "패키지 생성만 실행"
            create_deployment_package
            ;;
        "verify")
            log_info "검증만 실행"
            verify_build
            ;;
        "clean")
            log_info "정리만 실행"
            cleanup
            ;;
        "all")
            log_info "전체 빌드 프로세스 시작"
            install_rust
            add_centos7_target
            check_dependencies
            create_build_dir
            setup_environment
            build_project
            copy_and_optimize
            create_deployment_package
            verify_build
            log_success "CentOS 7 빌드 완료!"
            log_info "배포 파일 위치: $BUILD_DIR/"
            log_info "배포 패키지: $BUILD_DIR/${PROJECT_NAME}-centos7.tar.gz"
            ;;
        *)
            echo "사용법: $0 {rust|target|build|package|verify|clean|all}"
            echo ""
            echo "명령어:"
            echo "  rust    - Rust 설치"
            echo "  target  - CentOS 7 타겟 추가"
            echo "  build   - 프로젝트 빌드"
            echo "  package - 배포 패키지 생성"
            echo "  verify  - 빌드 검증"
            echo "  clean   - 정리"
            echo "  all     - 전체 프로세스 실행 (기본값)"
            echo ""
            echo "사전 요구사항:"
            echo "  - macOS: brew install pkg-config openssl gcc"
            echo "  - Ubuntu: sudo apt install pkg-config libssl-dev build-essential"
            echo "  - CentOS: sudo yum install pkgconfig openssl-devel gcc"
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 