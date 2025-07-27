#!/bin/bash

# 배포 마커 파일 관리 스크립트
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
    echo -e "${BLUE}[DEPLOY MARKER]${NC} $1"
}

# 배포 마커 파일 경로
DEPLOY_MARKER_FILE=".deploy_marker"

# 현재 마커 상태 확인
check_marker() {
    log_header "=== 배포 마커 상태 확인 ==="
    
    if [ -f "$DEPLOY_MARKER_FILE" ]; then
        local marker_commit=$(cat "$DEPLOY_MARKER_FILE")
        local current_commit=$(git rev-parse HEAD)
        
        log_info "마커 파일: ✅ 존재"
        log_info "마커 커밋: $marker_commit"
        log_info "현재 커밋: $current_commit"
        
        if [ "$marker_commit" = "$current_commit" ]; then
            log_info "상태: ✅ 최신 배포됨"
        else
            log_info "상태: ⚠️ 배포되지 않은 변경사항 있음"
            
            # 배포되지 않은 변경사항 확인
            local changed_files=$(git diff --name-only $marker_commit..$current_commit)
            if [ -n "$changed_files" ]; then
                echo ""
                log_info "배포되지 않은 변경사항:"
                echo "$changed_files"
            fi
        fi
    else
        log_warn "마커 파일: ❌ 없음"
        log_info "상태: ⚠️ 배포 이력 없음"
    fi
}

# 마커 파일 생성/업데이트
set_marker() {
    log_header "=== 배포 마커 설정 ==="
    
    local commit_hash="${1:-$(git rev-parse HEAD)}"
    
    # 커밋 해시 유효성 확인
    if ! git rev-parse --verify $commit_hash >/dev/null 2>&1; then
        log_error "유효하지 않은 커밋 해시: $commit_hash"
        exit 1
    fi
    
    echo "$commit_hash" > "$DEPLOY_MARKER_FILE"
    log_info "✅ 배포 마커 설정: $commit_hash"
    
    # 설정된 마커 확인
    check_marker
}

# 마커 파일 삭제
clear_marker() {
    log_header "=== 배포 마커 삭제 ==="
    
    if [ -f "$DEPLOY_MARKER_FILE" ]; then
        local marker_commit=$(cat "$DEPLOY_MARKER_FILE")
        rm "$DEPLOY_MARKER_FILE"
        log_info "✅ 배포 마커 삭제됨 (이전 마커: $marker_commit)"
    else
        log_warn "마커 파일이 이미 없습니다."
    fi
}

# 마커 파일 백업
backup_marker() {
    log_header "=== 배포 마커 백업 ==="
    
    if [ -f "$DEPLOY_MARKER_FILE" ]; then
        local marker_commit=$(cat "$DEPLOY_MARKER_FILE")
        local backup_file="${DEPLOY_MARKER_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        
        cp "$DEPLOY_MARKER_FILE" "$backup_file"
        log_info "✅ 배포 마커 백업: $backup_file"
        log_info "백업된 커밋: $marker_commit"
    else
        log_warn "백업할 마커 파일이 없습니다."
    fi
}

# 마커 파일 복원
restore_marker() {
    log_header "=== 배포 마커 복원 ==="
    
    local backup_file="${1:-}"
    
    if [ -z "$backup_file" ]; then
        # 가장 최근 백업 파일 찾기
        backup_file=$(ls -t ${DEPLOY_MARKER_FILE}.backup.* 2>/dev/null | head -1)
        
        if [ -z "$backup_file" ]; then
            log_error "복원할 백업 파일이 없습니다."
            exit 1
        fi
    fi
    
    if [ -f "$backup_file" ]; then
        local marker_commit=$(cat "$backup_file")
        cp "$backup_file" "$DEPLOY_MARKER_FILE"
        log_info "✅ 배포 마커 복원: $backup_file"
        log_info "복원된 커밋: $marker_commit"
    else
        log_error "백업 파일을 찾을 수 없습니다: $backup_file"
        exit 1
    fi
}

# 배포되지 않은 변경사항 강제 배포
force_deploy() {
    log_header "=== 강제 배포 설정 ==="
    
    # 마커 파일을 이전 커밋으로 설정하여 모든 변경사항을 배포 대상으로 만듦
    local previous_commit=$(git rev-parse HEAD~1 2>/dev/null || git rev-list --max-parents=0 HEAD | head -1)
    
    echo "$previous_commit" > "$DEPLOY_MARKER_FILE"
    log_info "✅ 강제 배포 설정 완료"
    log_info "마커 커밋: $previous_commit"
    log_info "다음 배포 시 모든 변경사항이 포함됩니다."
}

# 메인 실행
main() {
    case "${1:-check}" in
        check)
            check_marker
            ;;
        set)
            set_marker "$2"
            ;;
        clear)
            clear_marker
            ;;
        backup)
            backup_marker
            ;;
        restore)
            restore_marker "$2"
            ;;
        force)
            force_deploy
            ;;
        *)
            echo "사용법: $0 {check|set|clear|backup|restore|force}"
            echo ""
            echo "명령어:"
            echo "  check           - 마커 상태 확인"
            echo "  set [commit]    - 마커 설정 (기본값: 현재 커밋)"
            echo "  clear           - 마커 삭제"
            echo "  backup          - 마커 백업"
            echo "  restore [file]  - 마커 복원 (기본값: 최근 백업)"
            echo "  force           - 강제 배포 설정 (모든 변경사항 배포)"
            echo ""
            echo "예시:"
            echo "  $0 check"
            echo "  $0 set abc123..."
            echo "  $0 force"
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 