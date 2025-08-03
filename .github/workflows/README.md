# MinCenter GitHub Actions 배포 가이드

## 🚀 현재 사용 중인 워크플로우

### `deploy.yml` ✅ **메인 배포 워크플로우**
- **트리거**: `push` to main, `pull_request` merge
- **방식**: Docker 이미지 기반 선택적 배포
- **네트워크**: nginx proxy manager와 통합 (`proxy` 네트워크)

**배포 순서:**
1. 🔄 **데이터베이스 마이그레이션** (가장 먼저 실행)
2. 🔍 **변경 감지** (site, admin, api, env, db)
3. 🏗️ **선택적 빌드 및 배포**
   - Site: Docker 이미지 → GitHub Container Registry → 서버 배포
   - Admin: Docker 이미지 → GitHub Container Registry → 서버 배포

**특징:**
- 변경된 컴포넌트만 선별 배포
- Docker 이미지 캐싱으로 빌드 시간 단축
- 자동 Docker 리소스 정리 (용량 최적화)
- SSH 터널을 통한 안전한 데이터베이스 연결

### `test.yml` 🧪 **테스트 및 빌드 검증**
- **트리거**: `pull_request`, `push` to main/develop
- **목적**: 코드 품질 검증 및 배포 전 사전 검사

**검증 항목:**
- **프론트엔드**: npm test, npm build (site, admin)
- **백엔드**: cargo test, cargo build (SQLx + SSH 터널)
- **보안**: Trivy 취약점 스캔

### `manual-deploy.yml` 🔧 **수동 배포** (비상용)
- **트리거**: `workflow_dispatch` (수동 실행만)
- **용도**: 긴급 배포, 개별 컴포넌트 배포, 문제 해결

## 📦 배포 아키텍처

### Docker 네트워크 구조
```
nginx-proxy-manager ──┐
                      │ (proxy 네트워크)
mincenter-site ───────┤
mincenter-admin ──────┤
mincenter-api ────────┤
mincenter-postgres ───┤
mincenter-redis ──────┘
```

### 빌드 및 배포 흐름
```
개발자 Push → GitHub Actions → Docker Build → Container Registry → 서버 배포
     ↓              ↓              ↓              ↓              ↓
  코드 변경    변경 감지    이미지 생성    이미지 저장    컨테이너 교체
```

## 📋 사용 가이드

### 일반적인 배포 (자동)
```bash
git add .
git commit -m "Feature: 새로운 기능 추가"
git push origin main  # → deploy.yml 자동 실행
```

### 수동 배포 (긴급상황)
1. GitHub → Actions → "Manual Deploy"
2. "Run workflow" 클릭
3. 배포 대상 선택 (all/site/admin/api/env)

### 코드 검증 (PR)
```bash
git checkout -b feature/new-feature
# 코드 작성
git push origin feature/new-feature
# PR 생성 → test.yml 자동 실행
```

## 🔍 배포 모니터링

### 실시간 로그 확인
```bash
# GitHub Actions 로그 (실시간)
GitHub → Actions → 실행 중인 워크플로우

# 서버 컨테이너 로그
docker compose logs -f site
docker compose logs -f admin
docker compose logs -f api
```

### 배포 상태 확인
```bash
# 컨테이너 상태
docker compose ps

# 서비스 헬스체크
curl -f http://localhost:13000  # Site
curl -f http://localhost:13001  # Admin
curl -f http://localhost:18080/health  # API
```

## ⚠️ 주의사항 및 문제 해결

### 배포 실패 시 체크리스트
1. **GitHub Actions 로그 확인**: 빌드 오류, 네트워크 문제
2. **서버 리소스 확인**: 디스크 용량, 메모리 사용량
3. **데이터베이스 연결**: PostgreSQL 컨테이너 상태
4. **네트워크 설정**: nginx proxy manager 설정
5. **Docker 이미지**: Container Registry에 이미지 존재 여부

### 일반적인 해결 방법
```bash
# Docker 리소스 정리
docker system prune -f

# 컨테이너 재시작
docker compose restart

# 네트워크 재연결
docker network disconnect proxy mincenter-site
docker network connect proxy mincenter-site
```

### 롤백 절차
1. 이전 커밋으로 되돌리기
2. `git push origin main` (자동 배포)
3. 또는 Manual Deploy로 특정 버전 배포

## 🔐 보안 및 설정

### GitHub Secrets
- `DEPLOY_HOST`: 서버 IP 주소
- `DEPLOY_USER`: SSH 사용자명  
- `DEPLOY_SSH_KEY`: SSH 개인키
- `DEPLOY_PATH`: 배포 경로
- `POSTGRES_PASSWORD`: PostgreSQL 비밀번호
- `GITHUB_TOKEN`: Container Registry 접근용

### 네트워크 보안
- SSH 키 기반 인증
- SSH 터널을 통한 데이터베이스 접근
- GitHub Container Registry 비공개 저장소
- nginx proxy manager를 통한 외부 접근 제어

---

💡 **도움이 필요하시면 이 문서를 참고하시거나 팀에 문의해주세요!**