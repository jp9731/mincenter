#!/bin/bash

# MinSchool API 설치 스크립트

set -e

echo "MinSchool API 설치 시작..."

# 바이너리 복사
sudo mkdir -p /opt/minshool-api
sudo cp minshool-api /opt/minshool-api/
sudo chmod +x /opt/minshool-api/minshool-api
sudo chown root:root /opt/minshool-api/minshool-api

# systemd 서비스 설치
sudo cp minshool-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable minshool-api

echo "설치 완료!"
echo "서비스 시작: sudo systemctl start minshool-api"
echo "서비스 상태 확인: sudo systemctl status minshool-api"
echo "로그 확인: sudo journalctl -u minshool-api -f"
