# GitHub Actions 설정 가이드

## 🔧 GitHub Secrets 설정

GitHub 저장소의 Settings → Secrets and variables → Actions에서 다음 시크릿을 설정하세요:

### **필수 시크릿**

| 시크릿 이름 | 설명 | 예시 값 |
|------------|------|---------|
| `DEPLOY_HOST` | 서버 IP 주소 | `49.247.4.194` |
| `DEPLOY_USER` | 서버 사용자명 | `admin` |
| `DEPLOY_SSH_KEY` | SSH 개인키 (전체 내용) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `DEPLOY_PATH` | 서버의 프로젝트 디렉토리 | `/home/admin/projects/mincenter` |

### **SSH 키 설정 방법**

1. **로컬에서 SSH 키 생성** (이미 있다면 생략):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions@mincenter.kr"
   ```

2. **서버에 공개키 등록**:
   ```bash
   ssh-copy-id -i ~/.ssh/id_rsa.pub admin@49.247.4.194
   ```

3. **GitHub에 개인키 등록**:
   - `~/.ssh/id_rsa` 파일의 전체 내용을 복사
   - GitHub Secrets의 `DEPLOY_SSH_KEY`에 붙여넣기

## 🚀 워크플로우 설명

### **1. 자동 배포 (`deploy.yml`)**

**트리거 조건:**
- `main` 브랜치에 push
- PR이 `main` 브랜치에 머지됨

**동작 방식:**
1. **변경 감지**: Git diff로 변경된 파일 분석
2. **선택적 배포**: 변경된 컴포넌트만 배포
3. **헬스체크**: 배포 후 서비스 상태 확인

### **2. 테스트 (`test.yml`)**

**트리거 조건:**
- PR 생성/수정
- `main`, `develop` 브랜치에 push

**동작 방식:**
1. **프론트엔드 테스트**: Site, Admin 각각 테스트
2. **백엔드 테스트**: API 테스트 및 빌드
3. **보안 검사**: Trivy로 취약점 스캔

### **3. 수동 배포 (`manual-deploy.yml`)**

**사용 방법:**
1. GitHub 저장소 → Actions 탭
2. "Manual Deploy" 워크플로우 선택
3. "Run workflow" 클릭
4. 배포 대상 및 환경 선택

## 📊 배포 시나리오

### **시나리오 1: 사이트 UI 수정**
```bash
# frontends/site/src/routes/+page.svelte 수정 후
git add .
git commit -m "사이트 UI 개선"
git push origin main
# → 자동으로 사이트만 배포됨
```

### **시나리오 2: API 엔드포인트 추가**
```bash
# backends/api/src/handlers/community.rs 수정 후
git add .
git commit -m "새 API 엔드포인트 추가"
git push origin main
# → 자동으로 API만 배포됨
```

### **시나리오 3: 긴급 수동 배포**
1. GitHub Actions → Manual Deploy
2. 대상: `api`, 환경: `production`
3. Run workflow
4. → API만 수동 배포

## 🔍 모니터링

### **GitHub Actions 대시보드**
- Actions 탭에서 모든 워크플로우 실행 상태 확인
- 실패한 배포의 로그 확인
- 배포 시간 및 성능 모니터링

### **서버 상태 확인**
```bash
# 서버에서 직접 확인
ssh admin@49.247.4.194
cd /home/admin/projects/mincenter
docker compose ps
docker compose logs -f
```

## 🛠️ 문제 해결

### **일반적인 문제들**

1. **SSH 연결 실패**
   - SSH 키가 올바르게 설정되었는지 확인
   - 서버 방화벽 설정 확인

2. **빌드 실패**
   - GitHub Actions 로그에서 구체적인 오류 확인
   - 로컬에서 동일한 빌드 테스트

3. **배포 후 서비스 오류**
   - 헬스체크 로그 확인
   - 서버에서 컨테이너 로그 확인

### **디버깅 명령어**
```bash
# 서버에서 컨테이너 상태 확인
docker compose ps

# 특정 컨테이너 로그 확인
docker logs mincenter-api -f

# 서비스 헬스체크
curl http://localhost:18080/health
curl http://localhost:13000
curl http://localhost:13001
```

## 📈 성능 최적화

### **캐싱 전략**
- **Node.js**: `package-lock.json` 기반 캐싱
- **Rust**: `Cargo.lock` 기반 캐싱
- **Docker**: 레이어 캐싱 활용

### **병렬 처리**
- Site, Admin, API 배포를 병렬로 실행
- 테스트와 빌드를 동시에 실행

### **선택적 배포**
- 변경된 컴포넌트만 배포하여 시간 단축
- 불필요한 빌드 과정 생략 