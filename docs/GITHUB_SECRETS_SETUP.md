# GitHub Secrets 설정 가이드

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

### **4. SSH 연결 테스트 (`test-ssh.yml`)**

**사용 방법:**
1. GitHub 저장소 → Actions 탭
2. "Test SSH Connection" 워크플로우 선택
3. "Run workflow" 클릭

**확인 사항:**
- SSH 연결 성공 여부
- 서버 정보 (호스트명, IP, 사용자)
- 배포 경로 존재 여부
- Docker 및 Docker Compose 설치 여부

## 🔍 문제 해결

### **SSH 연결 실패 시**

#### **1. SSH 키 확인**
```bash
# 로컬에서 SSH 키 확인
ls -la ~/.ssh/
cat ~/.ssh/id_rsa.pub

# 서버에서 authorized_keys 확인
ssh admin@49.247.4.194 "cat ~/.ssh/authorized_keys"
```

#### **2. SSH 연결 테스트**
```bash
# 로컬에서 직접 SSH 연결 테스트
ssh -i ~/.ssh/id_rsa admin@49.247.4.194

# 연결 성공 시 서버에 접속됨
# 연결 실패 시 오류 메시지 확인
```

#### **3. GitHub Secrets 재설정**
1. GitHub 저장소 → Settings → Secrets and variables → Actions
2. 기존 시크릿 삭제
3. 새로운 시크릿 생성
4. SSH 키 전체 내용 복사 (BEGIN/END 라인 포함)

#### **4. 서버 SSH 설정 확인**
```bash
# 서버에서 SSH 설정 확인
sudo cat /etc/ssh/sshd_config | grep -E "(Port|PasswordAuthentication|PubkeyAuthentication)"

# SSH 서비스 재시작
sudo systemctl restart sshd
```

### **배포 경로 문제**

#### **1. 경로 존재 확인**
```bash
# 서버에서 배포 경로 확인
ls -la /home/admin/projects/mincenter

# 경로가 없으면 생성
mkdir -p /home/admin/projects/mincenter
```

#### **2. 권한 확인**
```bash
# 디렉토리 권한 확인
ls -la /home/admin/projects/

# 권한 수정 (필요시)
chmod 755 /home/admin/projects/mincenter
```

## 📊 배포 시나리오

### **시나리오 1: 사이트 UI 수정**
```bash
# frontends/site/src/routes/+page.svelte 수정 후
git add .
git commit -m "feat: 사이트 UI 개선"
git push origin main
```

**결과:**
- `detect-changes` 작업에서 `site-changed=true` 감지
- `deploy-site` 작업만 실행
- 사이트 컨테이너만 재시작

### **시나리오 2: API 로직 수정**
```bash
# backends/api/src/handlers/user.rs 수정 후
git add .
git commit -m "fix: 사용자 인증 로직 수정"
git push origin main
```

**결과:**
- `detect-changes` 작업에서 `api-changed=true` 감지
- `deploy-api` 작업만 실행
- API 빌드 및 컨테이너 재시작

### **시나리오 3: 환경변수 변경**
```bash
# .env 파일 수정 후
git add .
git commit -m "chore: 환경변수 업데이트"
git push origin main
```

**결과:**
- `detect-changes` 작업에서 `env-changed=true` 감지
- `deploy-env` 작업만 실행
- 모든 컨테이너 재시작

## 🚨 주의사항

### **1. SSH 키 보안**
- SSH 키는 절대 공개 저장소에 커밋하지 마세요
- GitHub Secrets에만 저장하세요
- 정기적으로 SSH 키를 교체하세요

### **2. 배포 경로**
- `DEPLOY_PATH`는 서버의 실제 경로와 일치해야 합니다
- 경로에 공백이나 특수문자가 없어야 합니다
- 사용자가 해당 경로에 쓰기 권한이 있어야 합니다

### **3. 서버 상태**
- 배포 전 서버가 정상 작동하는지 확인하세요
- 충분한 디스크 공간이 있는지 확인하세요
- Docker 서비스가 실행 중인지 확인하세요 