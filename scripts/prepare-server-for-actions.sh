#!/bin/bash

# 서버를 GitHub Actions 배포에 맞게 준비하는 스크립트

set -e

SERVER_HOST="admin@mincenter.kr"

echo "🔧 서버를 GitHub Actions 자동 배포에 맞게 준비"

ssh $SERVER_HOST << 'EOF'
set -e

echo "📁 프로젝트 디렉토리 확인..."
cd /home/admin/projects/mincenter

# Git 저장소 초기화 (필요시)
if [ ! -d ".git" ]; then
    echo "📥 Git 저장소 초기화..."
    git init
    git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
    git fetch origin
    git checkout -b main
    git branch --set-upstream-to=origin/main main
fi

# 현재 실행 중인 호스트 API 서버 중지
echo "🛑 기존 호스트 API 서버 중지..."
pkill -f mincenter-api 2>/dev/null || echo "ℹ️  실행 중인 호스트 API 서버 없음"

# Docker 및 Docker Compose 설치 확인
echo "🐳 Docker 설치 확인..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker가 설치되어 있지 않습니다."
    echo "Docker 설치 가이드: https://docs.docker.com/engine/install/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose가 설치되어 있지 않습니다."
    exit 1
fi

# Docker 서비스 시작
echo "🔄 Docker 서비스 시작..."
sudo systemctl enable docker
sudo systemctl start docker

# 사용자를 docker 그룹에 추가 (필요시)
if ! groups $USER | grep -q docker; then
    echo "👥 사용자를 docker 그룹에 추가..."
    sudo usermod -aG docker $USER
    echo "⚠️  로그아웃 후 다시 로그인하여 docker 그룹 권한을 적용하세요."
fi

# curl 설치 확인 (헬스체크용)
if ! command -v curl &> /dev/null; then
    echo "📦 curl 설치..."
    sudo apt update
    sudo apt install -y curl
fi

# 기존 API 컨테이너 정리 (있다면)
echo "🧹 기존 API 컨테이너 정리..."
docker compose stop api 2>/dev/null || true
docker compose rm -f api 2>/dev/null || true

# 사용하지 않는 Docker 이미지 정리
echo "🗑️  사용하지 않는 Docker 이미지 정리..."
docker image prune -f

echo "✅ 서버 준비 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. GitHub에서 Secrets 설정"
echo "2. 코드를 main 브랜치에 push"
echo "3. GitHub Actions 워크플로우 실행 확인"
echo ""
echo "🔍 유용한 명령어:"
echo "  - 컨테이너 상태 확인: docker compose ps"
echo "  - API 로그 확인: docker compose logs api"
echo "  - 헬스체크: curl http://localhost:18080/health"

EOF

echo "🎉 서버 준비 완료!"
