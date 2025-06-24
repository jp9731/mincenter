# GitHub Secrets 설정 가이드

## 🔑 SSH 키 생성 및 GitHub Secrets 설정

### **1. SSH 키 생성**

#### **로컬에서 SSH 키 생성**
```bash
# SSH 키 생성 (GitHub Actions용)
ssh-keygen -t rsa -b 4096 -C "github-actions@your-domain.com" -f ~/.ssh/github_actions

# 키 생성 시 질문들:
# Enter passphrase (empty for no passphrase): [엔터] (패스프레이즈 없음)
# Enter same passphrase again: [엔터]
```

#### **생성된 키 확인**
```bash
# 프라이빗 키 확인
cat ~/.ssh/github_actions
# 출력 예시:
# -----BEGIN OPENSSH PRIVATE KEY-----
# b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
# ... (긴 키 내용)
# -----END OPENSSH PRIVATE KEY-----

# 퍼블릭 키 확인
cat ~/.ssh/github_actions.pub
# 출력 예시:
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... github-actions@your-domain.com
```

### **2. 서버에 공개키 등록**

#### **SSH를 통한 등록 (포트 22000 사용)**
```bash
# 방법 1: ssh-copy-id 사용
ssh-copy-id -i ~/.ssh/github_actions.pub -p 22000 your-username@your-server-ip

# 방법 2: 수동 등록
cat ~/.ssh/github_actions.pub | ssh -p 22000 your-username@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# 방법 3: 직접 복사
scp -P 22000 ~/.ssh/github_actions.pub your-username@your-server-ip:~/
ssh -p 22000 your-username@your-server-ip "mkdir -p ~/.ssh && cat ~/github_actions.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

#### **서버에서 권한 설정**
```bash
# 서버에 SSH 접속
ssh -p 22000 your-username@your-server-ip

# 권한 설정
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# 설정 확인
ls -la ~/.ssh/
```

### **3. GitHub Secrets 설정**

#### **GitHub 저장소에서 Secrets 설정**
1. GitHub 저장소로 이동
2. **Settings** 탭 클릭
3. 왼쪽 메뉴에서 **Secrets and variables** > **Actions** 클릭
4. **New repository secret** 버튼 클릭

#### **필요한 Secrets 목록**

##### **DEPLOY_SSH_KEY**
- **Name**: `DEPLOY_SSH_KEY`
- **Value**: 프라이빗 키 전체 내용 (BEGIN/END 라인 포함)
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
NhAAAAAAABAAAAAgAAAAEAAABIAAAAEAAAAAAAABAAAAAgAAAAIAAAAEAAAAAgAAAAEAAAA
... (전체 키 내용)
-----END OPENSSH PRIVATE KEY-----
```

##### **DEPLOY_HOST**
- **Name**: `DEPLOY_HOST`
- **Value**: 서버 IP 주소 또는 도메인
```
192.168.1.100
또는
your-server-domain.com
```

##### **DEPLOY_USER**
- **Name**: `DEPLOY_USER`
- **Value**: 서버 사용자명
```
centos
또는
your-username
```

##### **DEPLOY_PATH**
- **Name**: `DEPLOY_PATH`
- **Value**: 프로젝트 경로
```
/home/centos/mincenter
또는
/var/www/mincenter
```

### **4. 포트 설정 정보**

실제 .env 파일을 기반으로 한 포트 설정:

```bash
# API 서버
API_PORT=18080

# 프론트엔드 서버
SITE_PORT=3000      # 메인 사이트
ADMIN_PORT=13001    # 관리자 페이지

# 데이터베이스
POSTGRES_PORT=15432

# Redis
REDIS_PORT=6379

# HTTP/HTTPS (Nginx)
HTTP_PORT=80
HTTPS_PORT=443
```

### **5. SSH 연결 테스트**

#### **로컬에서 테스트**
```bash
# SSH 연결 테스트
ssh -p 22000 -i ~/.ssh/github_actions your-username@your-server-ip

# 연결 성공 시 서버에 접속됨
# 연결 실패 시 오류 메시지 확인
```

#### **GitHub Actions에서 테스트**
```yaml
# .github/workflows/test-ssh.yml
name: Test SSH Connection

on:
  workflow_dispatch:

jobs:
  test-ssh:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Debug SSH Key
      run: |
        echo "DEPLOY_SSH_KEY 길이: ${#DEPLOY_SSH_KEY}"
        if [ -z "${{ secrets.DEPLOY_SSH_KEY }}" ]; then
          echo "❌ DEPLOY_SSH_KEY가 비어있습니다!"
          exit 1
        else
          echo "✅ DEPLOY_SSH_KEY가 설정되어 있습니다."
        fi
        
    - name: Setup SSH
      uses: webfactory/ssh-agent@v0.8.0
      with:
        ssh-private-key: ${{ secrets.DEPLOY_SSH_KEY }}
        log-public-key: true
        
    - name: Test SSH Connection
      run: |
        ssh -p 22000 ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} "echo 'SSH 연결 성공!'"
```

### **6. 문제 해결**

#### **DEPLOY_SSH_KEY가 비어있는 경우**
```bash
# 1. 프라이빗 키 내용 확인
cat ~/.ssh/github_actions

# 2. GitHub Secrets에서 다시 설정
# - BEGIN/END 라인 포함
# - 줄바꿈 문자 포함
# - 공백이나 특수문자 확인
```

#### **SSH 연결 실패**
```bash
# 1. 서버 SSH 설정 확인
sudo vim /etc/ssh/sshd_config

# 포트 설정 확인
Port 22000

# SSH 서비스 재시작
sudo systemctl restart sshd

# 2. 방화벽 설정 확인
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=22000/tcp --permanent
sudo firewall-cmd --reload

# 3. SELinux 설정 확인
sudo semanage port -l | grep ssh
sudo semanage port -a -t ssh_port_t -p tcp 22000
```

#### **권한 문제**
```bash
# 서버에서 권한 확인
ls -la ~/.ssh/
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
```

### **7. 보안 고려사항**

1. **SSH 키 보안**
   - 프라이빗 키는 절대 공개하지 마세요
   - GitHub Secrets에만 저장
   - 로컬에서도 안전하게 보관

2. **서버 보안**
   - 기본 SSH 포트(22) 대신 22000 사용
   - 패스워드 인증 비활성화
   - 키 기반 인증만 사용

3. **정기 관리**
   - SSH 키 정기 교체
   - 서버 로그 모니터링
   - 불필요한 사용자 계정 제거

### **8. 완료 확인**

모든 설정이 완료되면:

1. **GitHub Actions 실행**
   - GitHub 저장소 > Actions 탭
   - "Test SSH Connection" 워크플로우 먼저 실행
   - "Deploy to Production" 워크플로우 실행

2. **로그 확인**
   - 각 단계별 성공/실패 확인
   - SSH 연결 성공 메시지 확인

3. **배포 확인**
   - 서버에서 서비스 정상 동작 확인
   - 웹사이트 접속 테스트:
     - 메인 사이트: http://your-server-ip:3000
     - 관리자 페이지: http://your-server-ip:13001
     - API: http://your-server-ip:18080

이제 GitHub Actions를 통해 CentOS 7 서버로 자동 배포가 가능합니다! 🚀 