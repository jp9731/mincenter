# SSH 연결 문제 해결 가이드

## 🔍 SSH 연결 오류 진단 및 해결

### **오류 메시지 분석**
```
Permission denied, please try again.
Permission denied, please try again.
***@***: Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password).
```

이 오류는 SSH 키 인증에 실패했음을 의미합니다.

## 🛠️ 단계별 문제 해결

### **1. SSH 키 확인**

#### **로컬에서 SSH 키 상태 확인**
```bash
# SSH 키 파일 확인
ls -la ~/.ssh/github_actions*

# 프라이빗 키 내용 확인 (BEGIN/END 라인 포함)
cat ~/.ssh/github_actions

# 퍼블릭 키 내용 확인
cat ~/.ssh/github_actions.pub
```

#### **GitHub Secrets에서 SSH 키 확인**
1. GitHub 저장소 → Settings → Secrets and variables → Actions
2. `DEPLOY_SSH_KEY` 값 확인
3. 다음 형식인지 확인:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
... (키 내용)
-----END OPENSSH PRIVATE KEY-----
```

### **2. 서버에서 SSH 키 등록 확인**

#### **서버에 SSH 접속 (기존 방법으로)**
```bash
# 기존 SSH 키나 패스워드로 서버 접속
ssh -p 22000 your-username@your-server-ip
```

#### **authorized_keys 파일 확인**
```bash
# authorized_keys 파일 확인
cat ~/.ssh/authorized_keys

# 권한 확인
ls -la ~/.ssh/

# 올바른 권한 설정
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

#### **GitHub Actions용 공개키 등록**
```bash
# 로컬에서 공개키 복사
cat ~/.ssh/github_actions.pub

# 서버에서 수동으로 등록
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... github-actions@your-domain.com" >> ~/.ssh/authorized_keys

# 또는 scp로 복사 후 등록
scp -P 22000 ~/.ssh/github_actions.pub your-username@your-server-ip:~/
ssh -p 22000 your-username@your-server-ip "cat ~/github_actions.pub >> ~/.ssh/authorized_keys"
```

### **3. 서버 SSH 설정 확인**

#### **SSH 서버 설정 확인**
```bash
# SSH 설정 파일 확인
sudo vim /etc/ssh/sshd_config

# 다음 설정 확인
Port 22000
PubkeyAuthentication yes
PasswordAuthentication no
AuthorizedKeysFile .ssh/authorized_keys
```

#### **SSH 서비스 재시작**
```bash
# SSH 서비스 재시작
sudo systemctl restart sshd

# SSH 서비스 상태 확인
sudo systemctl status sshd
```

### **4. 방화벽 및 SELinux 설정**

#### **방화벽 설정**
```bash
# 방화벽 상태 확인
sudo firewall-cmd --list-all

# SSH 포트 추가
sudo firewall-cmd --add-port=22000/tcp --permanent
sudo firewall-cmd --reload

# 포트 확인
sudo firewall-cmd --list-ports
```

#### **SELinux 설정**
```bash
# SELinux 상태 확인
getenforce

# SSH 포트 허용
sudo semanage port -l | grep ssh
sudo semanage port -a -t ssh_port_t -p tcp 22000

# 또는 SELinux 비활성화 (임시)
sudo setenforce 0
```

### **5. 로컬에서 SSH 연결 테스트**

#### **기본 연결 테스트**
```bash
# SSH 연결 테스트
ssh -p 22000 -i ~/.ssh/github_actions your-username@your-server-ip

# 상세 로그와 함께 테스트
ssh -v -p 22000 -i ~/.ssh/github_actions your-username@your-server-ip
```

#### **SSH 설정 파일 생성**
```bash
# SSH 설정 파일 생성
mkdir -p ~/.ssh
cat >> ~/.ssh/config << EOF
Host your-server-ip
  HostName your-server-ip
  User your-username
  Port 22000
  IdentityFile ~/.ssh/github_actions
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

chmod 600 ~/.ssh/config

# 설정 파일로 연결 테스트
ssh your-server-ip "echo 'SSH 연결 성공!'"
```

### **6. GitHub Actions 디버깅**

#### **SSH 키 디버깅**
```yaml
- name: Debug SSH Key
  run: |
    echo "SSH 키 길이: ${#DEPLOY_SSH_KEY}"
    echo "SSH 키 시작: ${DEPLOY_SSH_KEY:0:50}..."
    echo "SSH 키 끝: ...${DEPLOY_SSH_KEY: -50}"
```

#### **SSH 연결 상세 로그**
```yaml
- name: Test SSH Connection
  run: |
    ssh -vvv -p 22000 ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} "echo '테스트'"
```

### **7. 대안 해결 방법**

#### **새로운 SSH 키 생성**
```bash
# 기존 키 백업
cp ~/.ssh/github_actions ~/.ssh/github_actions.backup

# 새 키 생성
ssh-keygen -t rsa -b 4096 -C "github-actions@your-domain.com" -f ~/.ssh/github_actions_new

# 새 키로 교체
mv ~/.ssh/github_actions_new ~/.ssh/github_actions
mv ~/.ssh/github_actions_new.pub ~/.ssh/github_actions.pub

# 서버에 새 공개키 등록
ssh-copy-id -i ~/.ssh/github_actions.pub -p 22000 your-username@your-server-ip
```

#### **임시로 패스워드 인증 활성화**
```bash
# 서버에서 SSH 설정 수정
sudo vim /etc/ssh/sshd_config

# 패스워드 인증 임시 활성화
PasswordAuthentication yes

# SSH 서비스 재시작
sudo systemctl restart sshd
```

### **8. 일반적인 문제 및 해결책**

#### **문제 1: SSH 키 형식 오류**
```bash
# GitHub Secrets에서 키 형식 확인
# BEGIN/END 라인이 정확한지 확인
# 줄바꿈 문자가 포함되었는지 확인
```

#### **문제 2: 권한 문제**
```bash
# 로컬 SSH 키 권한
chmod 600 ~/.ssh/github_actions
chmod 644 ~/.ssh/github_actions.pub

# 서버 authorized_keys 권한
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

#### **문제 3: 포트 문제**
```bash
# 포트 사용 중인지 확인
sudo netstat -tlnp | grep 22000

# 다른 포트로 테스트
ssh -p 22 your-username@your-server-ip
```

### **9. 성공적인 연결 확인**

#### **연결 성공 시 나타나는 메시지**
```
✅ SSH 연결 성공!
your-username
/home/your-username
Wed Dec 20 10:30:00 KST 2023
```

#### **다음 단계**
1. SSH 연결이 성공하면 "Test SSH Connection" 워크플로우 실행
2. 모든 테스트가 통과하면 "Deploy to Production" 워크플로우 실행

### **10. 추가 도움말**

#### **SSH 로그 확인**
```bash
# 서버에서 SSH 로그 확인
sudo tail -f /var/log/secure

# GitHub Actions에서 SSH 연결 시도 시 로그 확인
```

#### **연락처**
문제가 지속되면 다음 정보와 함께 문의하세요:
- 오류 메시지 전체
- SSH 설정 파일 내용
- 방화벽 설정 상태
- SELinux 상태 