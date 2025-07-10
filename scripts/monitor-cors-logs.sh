#!/bin/bash

# CORS 로그 모니터링 스크립트
# 사용법: ./scripts/monitor-cors-logs.sh [옵션]

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 기본 설정
LOG_SOURCE="local"  # local, systemd, docker
FILTER_CORS=true
SHOW_TIMESTAMP=true

# 도움말 함수
show_help() {
    echo "CORS 로그 모니터링 스크립트"
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -s, --source SOURCE    로그 소스 선택 (local|systemd|docker) [기본값: local]"
    echo "  -a, --all              모든 로그 표시 (CORS 필터링 비활성화)"
    echo "  -n, --no-timestamp     타임스탬프 숨기기"
    echo "  -h, --help             이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                    # 로컬 CORS 로그 모니터링"
    echo "  $0 -s systemd         # systemd 서비스 CORS 로그 모니터링"
    echo "  $0 -s docker          # Docker 컨테이너 CORS 로그 모니터링"
    echo "  $0 -a                 # 모든 로그 표시"
}

# 옵션 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            LOG_SOURCE="$2"
            shift 2
            ;;
        -a|--all)
            FILTER_CORS=false
            shift
            ;;
        -n|--no-timestamp)
            SHOW_TIMESTAMP=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

# 로그 소스별 모니터링 함수
monitor_local_logs() {
    echo -e "${BLUE}🔍 로컬 API 서버 CORS 로그 모니터링 시작...${NC}"
    echo -e "${YELLOW}💡 API 서버가 실행 중이어야 합니다 (cargo run)${NC}"
    echo ""
    
    if [ "$FILTER_CORS" = true ]; then
        echo -e "${GREEN}✅ CORS 관련 로그만 필터링하여 표시${NC}"
        echo ""
        # 로컬에서 실행 중인 프로세스의 로그를 캡처
        # 실제로는 API 서버가 실행 중일 때만 작동
        echo -e "${YELLOW}⚠️  API 서버가 실행 중인지 확인하세요${NC}"
        echo -e "${YELLOW}   cd backends/api && cargo run${NC}"
    else
        echo -e "${GREEN}✅ 모든 로그 표시${NC}"
    fi
}

monitor_systemd_logs() {
    echo -e "${BLUE}🔍 systemd 서비스 CORS 로그 모니터링 시작...${NC}"
    
    if ! systemctl is-active --quiet mincenter-api; then
        echo -e "${RED}❌ mincenter-api 서비스가 실행 중이 아닙니다${NC}"
        echo -e "${YELLOW}💡 서비스 시작: sudo systemctl start mincenter-api${NC}"
        exit 1
    fi
    
    if [ "$FILTER_CORS" = true ]; then
        echo -e "${GREEN}✅ CORS 관련 로그만 필터링하여 표시${NC}"
        echo ""
        sudo journalctl -u mincenter-api -f | grep -i cors
    else
        echo -e "${GREEN}✅ 모든 로그 표시${NC}"
        echo ""
        sudo journalctl -u mincenter-api -f
    fi
}

monitor_docker_logs() {
    echo -e "${BLUE}🔍 Docker 컨테이너 CORS 로그 모니터링 시작...${NC}"
    
    # Docker 컨테이너 확인
    CONTAINER_ID=$(docker ps --filter "name=mincenter" --filter "name=api" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" | tail -n +2 | head -1 | awk '{print $1}')
    
    if [ -z "$CONTAINER_ID" ]; then
        echo -e "${RED}❌ mincenter 관련 Docker 컨테이너를 찾을 수 없습니다${NC}"
        echo -e "${YELLOW}💡 컨테이너 목록 확인: docker ps${NC}"
        exit 1
    fi
    
    CONTAINER_NAME=$(docker ps --filter "id=$CONTAINER_ID" --format "{{.Names}}")
    echo -e "${GREEN}✅ 컨테이너 발견: $CONTAINER_NAME ($CONTAINER_ID)${NC}"
    
    if [ "$FILTER_CORS" = true ]; then
        echo -e "${GREEN}✅ CORS 관련 로그만 필터링하여 표시${NC}"
        echo ""
        docker logs -f "$CONTAINER_ID" | grep -i cors
    else
        echo -e "${GREEN}✅ 모든 로그 표시${NC}"
        echo ""
        docker logs -f "$CONTAINER_ID"
    fi
}

# 메인 실행
echo -e "${BLUE}🚀 CORS 로그 모니터링 시작${NC}"
echo ""

case $LOG_SOURCE in
    "local")
        monitor_local_logs
        ;;
    "systemd")
        monitor_systemd_logs
        ;;
    "docker")
        monitor_docker_logs
        ;;
    *)
        echo -e "${RED}❌ 잘못된 로그 소스: $LOG_SOURCE${NC}"
        echo -e "${YELLOW}💡 사용 가능한 옵션: local, systemd, docker${NC}"
        exit 1
        ;;
esac 