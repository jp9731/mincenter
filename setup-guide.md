# 🚀 GitHub Actions 자동 배포 설정 가이드 (초보자용)

GitHub Actions로 자동 배포를 설정하는 가장 쉬운 방법을 단계별로 안내합니다.

## 📋 설정 방법 2가지

### 🎯 방법 1: 설정 파일 사용 (초보자 추천!)
### 🎮 방법 2: 대화형 설정 (고급 사용자용)

---

## 🎯 방법 1: 설정 파일 사용 (초보자 추천!)

### 1단계: 설정 파일 준비

```bash
# 예제 파일을 복사해서 실제 설정 파일 만들기
cp secrets-config.example.json my-config.json
```

### 2단계: 설정 파일 수정

`my-config.json` 파일을 열어서 아래 내용들을 **본인 환경에 맞게** 수정하세요:

#### 📝 설정 파일 예시 (주석 참고해서 수정하세요)

```json
{
  "project": {
    "name": "내프로젝트이름",           // ← 여기를 수정
    "domain": "mydomain.com",          // ← 여기를 수정  
    "api_domain": "api.mydomain.com"   // ← 여기를 수정
  },
  "server": {
    "host": "111.222.333.444",         // ← 서버 IP 수정
    "user": "ubuntu",                  // ← SSH 사용자명 수정
    "deploy_path": "/home/ubuntu/app", // ← 배포 경로 수정
    "ssh_key_path": "~/.ssh/id_rsa"    // ← SSH 키 경로 수정
  },
  "ports": {
    "site": 13000,      // 웹사이트 포트 (그대로 둬도 됨)
    "admin": 13001,     // 관리자 포트 (그대로 둬도 됨)
    "api": 18080,       // API 포트 (그대로 둬도 됨)
    "postgres": 15432,  // DB 포트 (그대로 둬도 됨)
    "redis": 16379      // Redis 포트 (그대로 둬도 됨)
  },
  "database": {
    "name": "내프로젝트이름",                    // ← DB 이름 수정
    "user": "내프로젝트이름",                    // ← DB 사용자 수정
    "postgres_password": "강력한비밀번호123!",    // ← DB 비밀번호 수정
    "redis_password": "레디스비밀번호456!"       // ← Redis 비밀번호 수정
  },
  "network": {
    "docker_network": "proxy"  // (그대로 둬도 됨)
  },
  "environment": {
    // 🔐 보안 키들 (기본값 사용하거나 변경 가능)
    "jwt_secret": "y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=",
    "refresh_secret": "ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=", 
    "session_secret": "k1GBaqbI13HZDg2P4nFVfVvph9Q68ooqfYQqP/+Hsio=",
    "admin_session_secret": "mByehQKM5tYxlsAFTFpWiKBpsrBiSFwoLTblYKCu+Hs=",
    
    // 📧 이메일 설정 (꼭 수정하세요!)
    "admin_email": "admin@mydomain.com",    // ← 관리자 이메일
    "ssl_email": "ssl@mydomain.com",        // ← SSL 인증서 이메일
    
    // 🌐 소셜 로그인 (선택사항)
    "google_client_id": "",    // 구글 로그인 사용시만
    "kakao_client_id": "",     // 카카오 로그인 사용시만
    
    // ⚙️ 시스템 설정 (기본값 사용 권장)
    "access_token_expiry_minutes": 15,
    "refresh_token_expiry_days": 7,
    "rust_log_level": "info",
    "log_level": "info",
    "monitoring_enabled": false,
    "backup_schedule": "0 2 * * *",
    "backup_retention_days": 7
  }
}
```

### 3단계: 자동 설정 실행

```bash
# jq 설치 (macOS)
brew install jq

# jq 설치 (Ubuntu/Debian)
sudo apt-get install jq

# 설정 파일로 한 번에 설정
./setup-secrets.sh my-config.json
```

### ✅ 완료!
이제 GitHub에 모든 Secrets이 자동으로 등록되고, **자동으로 .env.production 파일도 생성**됩니다!

#### 🎉 자동으로 생성되는 것들:
- ✅ **GitHub Secrets 등록** (30개 이상의 설정값)
- ✅ **로컬 .env.production 파일 생성**
- ✅ **서버 배포시 각 서비스별 .env 파일 자동 생성**
  - `frontends/site/.env.production` (SvelteKit 프로덕션용)
  - `frontends/admin/.env.production` (SvelteKit 프로덕션용)
  - `backends/api/.env` (Rust API용 - dotenv 라이브러리 사용)

---

## 🎮 방법 2: 대화형 설정 (고급 사용자용)

질문에 하나씩 답하면서 설정하는 방법입니다:

```bash
./setup-secrets.sh
```

그러면 이런 질문들이 나옵니다:

```
프로젝트 이름을 입력하세요 (예: mincenter): myproject
도메인을 입력하세요 (예: mincenter.kr): myproject.com
API 도메인을 입력하세요 (예: api.mincenter.kr): api.myproject.com
서버 IP를 입력하세요: 111.222.333.444
SSH 사용자명을 입력하세요: ubuntu
배포 경로를 입력하세요 (예: /home/user/app): /home/ubuntu/app
SSH 개인키 파일 경로를 입력하세요 (예: ~/.ssh/id_rsa): ~/.ssh/id_rsa
...
```

---

## 📝 설정 전 체크리스트

### ✅ 준비물 확인
- [ ] GitHub 계정 및 저장소
- [ ] 배포할 서버 (클라우드 서버 등)
- [ ] 도메인 (선택사항)
- [ ] SSH 키 (서버 접속용)

### 🔧 필수 설치 프로그램
```bash
# GitHub CLI 설치 (macOS)
brew install gh

# GitHub CLI 설치 (Ubuntu/Debian)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# GitHub 로그인
gh auth login
```

### 🔐 SSH 키 설정
```bash
# SSH 키 생성 (없는 경우)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 공개키를 서버에 등록
ssh-copy-id user@your-server-ip
```

---

## 🎯 어떤 방법을 선택할까?

| 상황 | 추천 방법 |
|------|-----------|
| 🔰 처음 해보는 경우 | **방법 1: 설정 파일** |
| 🔄 여러 프로젝트에 반복 적용 | **방법 1: 설정 파일** |
| 👥 팀에서 같은 설정 공유 | **방법 1: 설정 파일** |
| ⚡ 빠르게 한 번만 설정 | 방법 2: 대화형 |

---

## 🆘 자주 발생하는 문제들

### ❌ "GitHub CLI가 설치되지 않았습니다"
```bash
# 해결방법: GitHub CLI 설치
brew install gh  # macOS
# 또는
sudo apt install gh  # Ubuntu
```

### ❌ "jq가 설치되지 않았습니다"
```bash
# 해결방법: jq 설치
brew install jq  # macOS
# 또는  
sudo apt install jq  # Ubuntu
```

### ❌ "SSH 키 파일을 찾을 수 없습니다"
```bash
# 해결방법: SSH 키 생성
ssh-keygen -t rsa -b 4096
# 그리고 설정 파일에서 올바른 경로 지정
```

### ❌ 서버 접속 실패
```bash
# 해결방법: SSH 연결 테스트
ssh user@server-ip
# 접속되면 OK, 안 되면 서버 설정 확인
```

---

## 🎉 설정 완료 후

### 🚀 자동 배포 프로세스

설정이 완료되면 이제 코드를 푸시할 때마다 **완전 자동 배포**됩니다:

```bash
git add .
git commit -m "새로운 기능 추가"  
git push origin main  # ← 이때 자동 배포 시작!
```

#### 🔄 배포 순서:
1. **환경설정 배포** - 모든 .env 파일 서버에 자동 생성
2. **데이터베이스 마이그레이션** - 스키마 변경사항 적용
3. **변경 감지** - 어떤 서비스가 변경되었는지 자동 감지
4. **선택적 배포** - 변경된 서비스만 빌드 및 배포

#### 📊 모니터링
- **GitHub → Actions** 탭에서 배포 진행 상황 실시간 확인
- **각 단계별 로그** 상세 확인 가능
- **실패시 알림** 및 롤백 기능

---

## 💡 다음 단계

1. ✅ 설정 완료
2. 🚀 첫 번째 자동 배포 테스트
3. 📊 GitHub Actions에서 배포 로그 확인
4. 🌐 웹사이트 접속해서 정상 작동 확인

---

**🎯 이 가이드로 누구나 쉽게 자동 배포를 설정할 수 있습니다!**