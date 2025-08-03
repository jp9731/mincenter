#!/bin/bash

echo "=== 502 Bad Gateway 디버깅 ==="
echo "현재 시간: $(date)"
echo

echo "=== 컨테이너 상태 확인 ==="
docker compose ps
echo

echo "=== Site 컨테이너 로그 (최근 20줄) ==="
docker compose logs --tail=20 site
echo

echo "=== Site 컨테이너 헬스체크 ==="
docker compose exec -T site curl -f http://localhost:3000 || echo "Site 컨테이너 내부 접속 실패"
echo

echo "=== 호스트에서 Site 컨테이너 접속 테스트 ==="
curl -f http://localhost:13000 || echo "호스트에서 Site 접속 실패"
echo

echo "=== nginx/openresty 프로세스 확인 ==="
ps aux | grep nginx || echo "nginx 프로세스 없음"
echo

echo "=== 포트 사용 현황 ==="
netstat -tlnp | grep -E "(80|443|13000)" || echo "관련 포트 사용 현황 없음"
echo

echo "=== nginx 설정 파일 존재 확인 ==="
ls -la /etc/nginx/ 2>/dev/null || echo "/etc/nginx/ 없음"
ls -la ./nginx/ 2>/dev/null || echo "./nginx/ 없음"
echo

echo "=== Docker 네트워크 확인 ==="
docker network ls
echo

echo "=== mincenter 네트워크 상세 정보 ==="
docker network inspect mincenter_default 2>/dev/null || echo "mincenter_default 네트워크 없음"