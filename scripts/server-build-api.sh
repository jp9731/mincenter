#!/bin/bash

# MinCenter API 서버 빌드 및 systemd 서비스 등록 스크립트
# 서버에서 직접 실행 (CentOS 7, Ubuntu 등)

set -e

SERVICE_NAME="mincenter-api"
API_DIR="$(dirname "$0")/../backends/api"
BINARY_NAME="mincenter-api"
INSTALL_DIR="/opt/mincenter-api"
SYSTEMD_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

# 1. 의존성 설치
install_dependencies() {
    echo "[INFO] 필수 패키지 설치..."
    if command -v yum &> /dev/null; then
        sudo yum install -y gcc openssl-devel pkgconfig
    elif command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y build-essential libssl-dev pkg-config
    fi
    if ! command -v rustc &> /dev/null; then
        echo "[INFO] Rust 설치 중..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    fi
}

# 2. 빌드
build_api() {
    echo "[INFO] API 빌드 중..."
    cd "$API_DIR"
    cargo clean
    cargo build --release --bin mincenter-api
    cd -
}

# 3. 바이너리 설치
install_binary() {
    echo "[INFO] 바이너리 설치..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo cp "$API_DIR/target/release/$BINARY_NAME" "$INSTALL_DIR/"
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
    sudo chown root:root "$INSTALL_DIR/$BINARY_NAME"
}

# 4. systemd 서비스 파일 생성
setup_systemd() {
    echo "[INFO] systemd 서비스 파일 생성..."
    sudo tee "$SYSTEMD_PATH" > /dev/null <<EOF
[Unit]
Description=MinCenter API Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$BINARY_NAME
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
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
}

# 5. 서비스 재시작
restart_service() {
    echo "[INFO] API 서비스 재시작..."
    sudo systemctl restart $SERVICE_NAME
    sudo systemctl status $SERVICE_NAME --no-pager
}

# 메인
install_dependencies
build_api
install_binary
setup_systemd
restart_service

echo "[SUCCESS] API 빌드 및 서비스 등록 완료! (포트 18080)" 