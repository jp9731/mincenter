# SSH 보안 강화 가이드

## 🚨 현재 상황
서버에서 무차별 대입 공격(brute force attack)이 발생하고 있습니다.

## 🔧 즉시 적용할 보안 조치

### 1. SSH 포트 변경 (이미 적용됨)
```bash
# 현재 SSH 포트: 22000
# /etc/ssh/sshd_config에서 확인
Port 22000
```

### 2. fail2ban 설치 및 설정
```bash
# fail2ban 설치
sudo yum install -y epel-release
sudo yum install -y fail2ban

# fail2ban 설정 파일 생성
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# SSH 보호 설정 편집
sudo vi /etc/fail2ban/jail.local
```

#### fail2ban 설정 내용:
```ini
[sshd]
enabled = true
port = 22000
filter = sshd
logpath = /var/log/secure
maxretry = 3
bantime = 3600
findtime = 600
```

### 3. fail2ban 시작
```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
sudo systemctl status fail2ban
```

### 4. 방화벽 설정 강화
```bash
# SSH 포트만 허용 (22000)
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --permanent --add-port=22000/tcp
sudo firewall-cmd --reload

# 현재 방화벽 상태 확인
sudo firewall-cmd --list-all
```

### 5. SSH 설정 강화
```bash
sudo vi /etc/ssh/sshd_config
```

#### 추가할 보안 설정:
```bash
# 루트 로그인 비활성화
PermitRootLogin no

# 패스워드 인증 비활성화 (키 기반 인증만 사용)
PasswordAuthentication no
PubkeyAuthentication yes

# 빈 패스워드 비활성화
PermitEmptyPasswords no

# 최대 인증 시도 횟수
MaxAuthTries 3

# 로그인 타임아웃
LoginGraceTime 30

# 사용자별 접근 제한
AllowUsers mincenter

# SSH 프로토콜 버전 제한
Protocol 2
```

### 6. SSH 서비스 재시작
```bash
sudo systemctl restart sshd
sudo systemctl status sshd
```

## 🔍 모니터링

### fail2ban 상태 확인
```bash
# 현재 차단된 IP 확인
sudo fail2ban-client status sshd

# 로그 확인
sudo tail -f /var/log/fail2ban.log
```

### SSH 로그 모니터링
```bash
# SSH 접속 시도 로그 확인
sudo tail -f /var/log/secure | grep sshd
```

## 🛡️ 추가 보안 조치

### 1. 키 기반 인증 설정
```bash
# 클라이언트에서 SSH 키 생성
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# 서버에 공개키 복사
ssh-copy-id -i ~/.ssh/id_rsa.pub mincenter@your_server_ip -p 22000
```

### 2. UFW 방화벽 설치 (선택사항)
```bash
# CentOS 7에서는 기본 방화벽 사용 권장
# UFW는 Ubuntu에서 주로 사용
```

### 3. 로그 로테이션 설정
```bash
sudo vi /etc/logrotate.d/sshd
```

```bash
/var/log/secure {
    missingok
    notifempty
    compress
    size 100k
    daily
    rotate 7
    postrotate
        /bin/kill -HUP `cat /var/run/syslogd.pid 2>/dev/null` 2> /dev/null || true
    endscript
}
```

## 📊 보안 상태 확인

### 현재 SSH 설정 확인
```bash
# SSH 설정 검증
sudo sshd -t

# SSH 서비스 상태
sudo systemctl status sshd

# 방화벽 상태
sudo firewall-cmd --list-all

# fail2ban 상태
sudo fail2ban-client status
```

### 보안 스캔 (선택사항)
```bash
# nmap으로 포트 스캔
sudo yum install -y nmap
nmap -sS -p- your_server_ip
```

## 🚨 응급 상황 대응

### SSH 접속이 차단된 경우
```bash
# fail2ban에서 IP 제거
sudo fail2ban-client set sshd unbanip YOUR_IP_ADDRESS

# 또는 fail2ban 재시작
sudo systemctl restart fail2ban
```

### 서버에 직접 접근이 필요한 경우
- 클라우드 제공업체의 콘솔 접근
- VNC 또는 KVM 접근
- 서버 재부팅 후 설정 수정

## 📝 체크리스트

- [ ] fail2ban 설치 및 설정
- [ ] SSH 포트 변경 확인 (22000)
- [ ] 루트 로그인 비활성화
- [ ] 패스워드 인증 비활성화
- [ ] SSH 키 기반 인증 설정
- [ ] 방화벽 설정 강화
- [ ] 로그 모니터링 설정
- [ ] 정기적인 보안 업데이트

## 🔗 참고 자료

- [CentOS 7 Security Guide](https://wiki.centos.org/HowTos/OS_Protection)
- [SSH Hardening Guide](https://www.ssh.com/academy/ssh/hardening)
- [fail2ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page) 