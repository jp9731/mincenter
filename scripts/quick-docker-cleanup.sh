#!/bin/bash

# 빠른 Docker 정리 스크립트 (배포 전용)
set -e

echo "🔍 Docker 디스크 공간 정리 시작..."

# 현재 디스크 사용량 확인
echo "현재 디스크 사용량:"
df -h /

# Docker 사용량 확인
echo ""
echo "Docker 사용량:"
docker system df

# 사용하지 않는 Docker 리소스 정리
echo ""
echo "🧹 Docker 정리 중..."

# 중지된 컨테이너 삭제
echo "중지된 컨테이너 삭제..."
docker container prune -f

# 사용하지 않는 이미지 삭제
echo "사용하지 않는 이미지 삭제..."
docker image prune -a -f

# 사용하지 않는 볼륨 삭제
echo "사용하지 않는 볼륨 삭제..."
docker volume prune -f

# 사용하지 않는 네트워크 삭제
echo "사용하지 않는 네트워크 삭제..."
docker network prune -f

# 빌드 캐시 정리
echo "빌드 캐시 정리..."
docker builder prune -a -f

# 전체 시스템 정리
echo "전체 시스템 정리..."
docker system prune -a -f --volumes

# 정리 후 확인
echo ""
echo "✅ 정리 완료!"
echo "정리 후 디스크 사용량:"
df -h /

echo "정리 후 Docker 사용량:"
docker system df

echo "🎉 Docker 정리가 완료되었습니다!" 