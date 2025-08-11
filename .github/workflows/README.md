# MinCenter GitHub Actions 배포 가이드

## 🚀 현재 사용 중인 워크플로우

### **Frontend 배포 (Cloudflare Pages)** ✅
- **Site**: `frontends/site/.github/workflows/deploy.yml`
- **Admin**: `frontends/admin/.github/workflows/deploy.yml`
- **트리거**: `push` to main/develop, `pull_request`
- **방식**: GitHub Actions → Cloudflare Pages 자동 배포

**배포 순서:**
1. 🔍 **코드 변경 감지** (main/develop 브랜치 push)
2. 🏗️ **빌드**: `npm run build` 
3. 📤 **Cloudflare Pages 배포**: `.svelte-kit/cloudflare` 디렉토리
4. 🔄 **캐시 퍼지**: Cloudflare 캐시 자동 정리

**특징:**
- 글로벌 CDN을 통한 빠른 배포
- 자동 HTTPS 및 도메인 관리
- 프리뷰 배포 (PR 시 자동 생성)
- 무제한 대역폭

### **Backend 배포 (수동)** ⚠️
- **API**: 현재 수동 배포만 가능
- **PostgreSQL**: 수동 마이그레이션 필요

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

### 배포 아키텍처
```
Frontend (Cloudflare Pages)
├── mincenter-site ────→ Cloudflare CDN
└── mincenter-admin ───→ Cloudflare CDN

Backend (Docker Server)
├── mincenter-api ─────→ Docker Container
├── mincenter-postgres → Docker Container  
└── mincenter-redis ───→ Docker Container
```

### 배포 흐름
```
Frontend: 개발자 Push → GitHub Actions → Cloudflare Pages
             ↓              ↓              ↓
          코드 변경    자동 빌드    글로벌 CDN 배포

Backend:  개발자 Push → 수동 SSH → Docker 재시작
             ↓              ↓              ↓
          코드 변경    서버 접속    컨테이너 교체
```

## 📋 사용 가이드

### Frontend 배포 (자동)
```bash
git add .
git commit -m "Feature: 새로운 기능 추가"
git push origin main  # → Cloudflare Pages 자동 배포
```

### Backend 배포 (수동)
```bash
# 서버에 SSH 접속
ssh user@server
cd /path/to/project
git pull origin main
docker-compose restart api
```

### 코드 검증 (PR)
```bash
git checkout -b feature/new-feature
# 코드 작성
git push origin feature/new-feature
# PR 생성 → test.yml 자동 실행
```

## 🔍 배포 모니터링

### Frontend 배포 모니터링
```bash
# Cloudflare Pages 배포 로그
GitHub → Actions → "Deploy to Cloudflare Pages"

# Cloudflare Pages 대시보드
https://dash.cloudflare.com/pages/

# 배포 상태 확인
curl -f https://your-site-domain.pages.dev
curl -f https://your-admin-domain.pages.dev
```

### Backend 배포 모니터링
```bash
# 서버 컨테이너 로그
docker compose logs -f api
docker compose logs -f postgres
docker compose logs -f redis

# 컨테이너 상태
docker compose ps

# API 헬스체크
curl -f http://localhost:18080/health
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