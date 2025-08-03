# 🚀 자동 배포 시스템 설정 가이드

이 프로젝트의 GitHub Actions 기반 자동 배포 시스템을 다른 프로젝트에 적용하는 방법을 설명합니다.

## 📋 배포 시스템 개요

### 주요 특징
- ✅ **선택적 배포**: 변경된 컴포넌트만 자동 감지하여 배포
- ✅ **Docker 기반**: 컨테이너화된 안정적인 배포
- ✅ **nginx proxy manager 통합**: 리버스 프록시 자동 연결
- ✅ **데이터베이스 마이그레이션**: 스키마 변경 자동 적용
- ✅ **SSH 터널**: 보안된 데이터베이스 접근
- ✅ **용량 최적화**: 자동 Docker 리소스 정리

### 워크플로우 구성
```
📁 .github/workflows/
├── deploy.yml           # 메인 배포 워크플로우
├── test.yml            # 테스트 및 빌드 검증
├── manual-deploy.yml   # 수동 배포 (비상용)
└── README.md          # 워크플로우 문서
```

## 🔧 필수 GitHub Secrets 설정

### 1. 서버 연결 정보
```
DEPLOY_HOST=your-server-ip          # 서버 IP 주소
DEPLOY_USER=your-username           # SSH 사용자명
DEPLOY_SSH_KEY=your-private-key     # SSH 개인키 (전체 내용)
DEPLOY_PATH=/path/to/deployment     # 서버 배포 경로
```

### 2. 프로젝트 설정 (다른 프로젝트 적용 시 변경 필요)
```
PROJECT_NAME=mincenter              # 프로젝트 이름
DOMAIN_NAME=mincenter.kr            # 메인 도메인
API_DOMAIN=api.mincenter.kr         # API 도메인
```

### 3. 포트 설정
```
SITE_PORT=13000                     # 사이트 포트
ADMIN_PORT=13001                    # 관리자 포트
API_PORT=18080                      # API 포트
POSTGRES_PORT=15432                 # PostgreSQL 포트
REDIS_PORT=16379                    # Redis 포트
```

### 4. 데이터베이스 설정
```
DB_NAME=mincenter                   # 데이터베이스 이름
DB_USER=mincenter                   # 데이터베이스 사용자
POSTGRES_PASSWORD=your-db-password  # PostgreSQL 비밀번호
REDIS_PASSWORD=your-redis-password  # Redis 비밀번호
```

### 5. 네트워크 설정
```
DOCKER_NETWORK=proxy                # Docker 네트워크 이름
```

## 📝 GitHub Secrets 등록 방법

1. **GitHub 저장소 접속**
2. **Settings → Secrets and variables → Actions**
3. **"New repository secret" 클릭**
4. **위의 각 항목을 하나씩 등록**

![GitHub Secrets 설정 예시]
```
Name: DEPLOY_HOST
Secret: 192.168.1.100
```

## 🏗️ 서버 환경 준비

### 1. 필수 소프트웨어 설치
```bash
# Docker 및 Docker Compose 설치
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# nginx proxy manager 설치 (선택사항)
# 또는 기존 nginx 사용
```

### 2. 디렉토리 구조 준비
```bash
# 배포 디렉토리 생성
mkdir -p /path/to/deployment
cd /path/to/deployment

# 하위 디렉토리 구조
mkdir -p database frontends/{site,admin} backends/api
```

### 3. nginx proxy manager 설정
```bash
# nginx proxy manager에서 프록시 호스트 설정
Domain: your-domain.com
Forward Hostname/IP: your-project-site    # 컨테이너 이름
Forward Port: 3000
```

## 🔄 배포 프로세스

### 자동 배포 (권장)
```bash
# 일반적인 개발 워크플로우
git add .
git commit -m "feat: 새로운 기능 추가"
git push origin main    # 자동 배포 트리거
```

### 수동 배포 (비상 시)
1. GitHub → Actions → "Manual Deploy"
2. "Run workflow" 클릭
3. 배포 대상 선택 (all/site/admin/api/env)

## 📦 다른 프로젝트 적용 가이드

### 1. 파일 복사
```bash
# 워크플로우 파일들 복사
cp -r .github/workflows/ /path/to/new-project/
```

### 2. 프로젝트별 수정 사항

#### A. 워크플로우 파일에서 하드코딩 값 변경
```yaml
# deploy.yml에서 수정 필요한 부분들
container_name: mincenter-site
# ↓ 변경 후
container_name: ${{ secrets.PROJECT_NAME }}-site

# 도메인 관련
VITE_API_URL=https://api.mincenter.kr
# ↓ 변경 후  
VITE_API_URL=https://${{ secrets.API_DOMAIN }}
```

#### B. Docker Compose 템플릿 수정
```yaml
# 컨테이너 이름들을 변수화
postgres:
  container_name: ${{ secrets.PROJECT_NAME }}-postgres
  environment:
    POSTGRES_DB: ${{ secrets.DB_NAME }}
    POSTGRES_USER: ${{ secrets.DB_USER }}
```

### 3. 프로젝트 구조 맞추기
```
your-project/
├── .github/workflows/     # 복사한 워크플로우 파일들
├── frontends/
│   ├── site/             # 메인 사이트 (SvelteKit/React/Vue 등)
│   └── admin/            # 관리자 페이지
├── backends/
│   └── api/              # API 서버 (Rust/Node.js/Python 등)
├── database/
│   ├── init.sql          # 스키마 정의
│   └── seed.sql          # 초기 데이터
└── docker-compose.yml    # 로컬 개발용
```

## 🔍 모니터링 및 디버깅

### 배포 상태 확인
```bash
# GitHub Actions 로그 확인
GitHub → Actions → 실행 중인 워크플로우

# 서버에서 상태 확인
docker compose ps
docker compose logs -f site
curl -f http://localhost:13000
```

### 일반적인 문제 해결
```bash
# Docker 리소스 정리
docker system prune -f

# 컨테이너 재시작
docker compose restart

# 네트워크 재연결
docker network disconnect proxy project-site
docker network connect proxy project-site
```

## ⚠️ 주의사항

### 보안
- SSH 키는 반드시 GitHub Secrets에 안전하게 저장
- 데이터베이스 비밀번호 등 민감 정보 보호
- 서버 방화벽 설정 확인

### 성능
- Docker 이미지 빌드 시간 고려
- 서버 리소스 모니터링
- 자동 정리로 디스크 용량 관리

### 배포 순서
1. 데이터베이스 마이그레이션 먼저 실행
2. 변경 감지 후 선택적 배포
3. 의존성 있는 서비스 순서 고려

## 🆘 문제 해결 체크리스트

배포 실패 시 확인 순서:
- [ ] GitHub Secrets 모든 항목 설정 확인
- [ ] 서버 SSH 접속 가능 여부
- [ ] Docker 및 Docker Compose 설치 상태
- [ ] 네트워크 설정 (nginx proxy manager)
- [ ] 포트 충돌 여부
- [ ] 디스크 공간 부족 여부
- [ ] 데이터베이스 연결 상태

## 📞 지원

문제가 발생하거나 도움이 필요한 경우:
1. `.github/workflows/README.md` 참조
2. GitHub Actions 로그 확인
3. 팀 내 문의 또는 이슈 등록

---

💡 **이 가이드를 따라하면 안정적이고 효율적인 자동 배포 시스템을 구축할 수 있습니다!**

## 🔄 버전 히스토리

- v1.0: 초기 배포 시스템 구축
- v1.1: nginx proxy manager 통합
- v1.2: SSH 터널 보안 강화
- v1.3: 용량 최적화 및 선택적 배포
- v1.4: 다른 프로젝트 적용 가능하도록 변수화