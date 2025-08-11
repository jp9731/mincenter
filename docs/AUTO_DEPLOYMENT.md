# 자동 배포 설정 가이드

이 문서는 `git push`만으로 자동 배포가 되도록 설정하는 방법을 설명합니다.

## 🔄 배포 방식 비교

### 현재 방식 (수동 배포)
```bash
# 1. 코드 변경 후 커밋
git add .
git commit -m "업데이트 내용"
git push origin main

# 2. 서버에서 수동으로 배포
ssh user@server
cd /path/to/project
git pull origin main
./scripts/deploy.sh
```

### 자동 배포 방식
```bash
# 1. 코드 변경 후 커밋
git add .
git commit -m "업데이트 내용"
git push origin main

# 2. 자동으로 배포됨! 🎉
```

## 🚀 자동 배포 설정 방법

### 방법 1: GitHub Actions (권장)

#### 1단계: GitHub Secrets 설정

GitHub 저장소 → Settings → Secrets and variables → Actions에서 다음 시크릿을 추가:

```bash
SSH_PRIVATE_KEY=서버의_SSH_개인키_내용
SERVER_HOST=서버_IP_또는_도메인
SERVER_USER=서버_사용자명
PROJECT_PATH=/path/to/project
SITE_URL=http://your-domain.com
ADMIN_URL=http://your-domain.com/admin
API_URL=http://your-domain.com/api
```

#### 2단계: SSH 키 설정

```bash
# 서버에서 SSH 키 생성
ssh-keygen -t rsa -b 4096 -C "github-actions"

# 공개키를 authorized_keys에 추가
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# 개인키를 GitHub Secrets에 복사
cat ~/.ssh/id_rsa
```

#### 3단계: 워크플로우 활성화

`.github/workflows/deploy.yml` 파일이 이미 생성되어 있습니다. `git push`하면 자동으로 배포됩니다.

### 방법 2: Git Hooks (로컬 자동 배포)

#### 1단계: Git Hook 스크립트 생성

```bash
# .git/hooks/post-push 파일 생성
cat > .git/hooks/post-push << 'EOF'
#!/bin/bash
if [ "$1" = "origin" ] && [ "$2" = "main" ]; then
    echo "자동 배포를 시작합니다..."
    ./scripts/auto-deploy.sh
fi
EOF

chmod +x .git/hooks/post-push
```

#### 2단계: Git Alias 설정

```bash
# Git 설정에 push 후 자동 배포 추가
git config alias.push-deploy '!git push origin main && ./scripts/auto-deploy.sh'
```

### 방법 3: Cron Job (정기 배포)

#### 1단계: Cron Job 설정

```bash
# crontab 편집
crontab -e

# 5분마다 체크하여 새로운 커밋이 있으면 배포
*/5 * * * * cd /path/to/project && ./scripts/auto-deploy.sh
```

## 🔧 CentOS 7에서 자동 배포 설정

### 1단계: 시스템 서비스 생성

```bash
# /etc/systemd/system/auto-deploy.service 파일 생성
sudo tee /etc/systemd/system/auto-deploy.service << 'EOF'
[Unit]
Description=Auto Deploy Service
After=network.target

[Service]
Type=oneshot
User=your-user
WorkingDirectory=/path/to/project
ExecStart=/path/to/project/scripts/auto-deploy.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

### 2단계: 서비스 활성화

```bash
# 서비스 활성화
sudo systemctl daemon-reload
sudo systemctl enable auto-deploy.service

# 수동 실행 테스트
sudo systemctl start auto-deploy.service
sudo systemctl status auto-deploy.service
```

### 3단계: Git Hook 설정

```bash
# 프로젝트 디렉토리에서
cd /path/to/project

# Git Hook 생성
cat > .git/hooks/post-merge << 'EOF'
#!/bin/bash
echo "새로운 변경사항이 감지되었습니다. 배포를 시작합니다..."
./scripts/auto-deploy.sh
EOF

chmod +x .git/hooks/post-merge
```

## 📊 배포 모니터링

### 배포 로그 확인

```bash
# 배포 로그 파일 확인
tail -f deploy.log

# GitHub Actions 로그 확인
# GitHub 저장소 → Actions 탭에서 확인

# 시스템 서비스 로그 확인
sudo journalctl -u auto-deploy.service -f
```

### 배포 상태 확인

```bash
# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 헬스체크
curl http://localhost:8080/health
curl http://localhost:3000
curl http://localhost:3001
```

## 🛡️ 안전한 자동 배포

### 롤백 기능 추가

```bash
# scripts/rollback.sh 파일 생성
cat > scripts/rollback.sh << 'EOF'
#!/bin/bash
set -e

# 이전 커밋으로 롤백
git reset --hard HEAD~1
./scripts/deploy.sh

echo "롤백이 완료되었습니다."
EOF

chmod +x scripts/rollback.sh
```

### 배포 전 테스트

```bash
# scripts/test-before-deploy.sh 파일 생성
cat > scripts/test-before-deploy.sh << 'EOF'
#!/bin/bash
set -e

echo "배포 전 테스트를 실행합니다..."

# 빌드 테스트
docker-compose -f docker-compose.prod.yml build --no-cache

# 단위 테스트 (API)
cd backends/api && cargo test

# 프론트엔드 빌드 테스트
cd frontends/site && npm run build
cd ../admin && npm run build

echo "테스트가 완료되었습니다."
EOF

chmod +x scripts/test-before-deploy.sh
```

## 🔍 문제 해결

### 일반적인 문제들

#### 1. 권한 문제
```bash
# 스크립트 실행 권한 확인
ls -la scripts/

# 권한 부여
chmod +x scripts/*.sh
```

#### 2. SSH 연결 문제
```bash
# SSH 연결 테스트
ssh user@server "echo 'SSH 연결 성공'"

# SSH 키 권한 확인
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

#### 3. Git Hook 실행 문제
```bash
# Git Hook 디버깅
bash -x .git/hooks/post-merge

# Git 설정 확인
git config --list | grep hook
```

## 📝 권장사항

1. **테스트 환경 먼저**: 자동 배포 전에 테스트 환경에서 충분히 테스트
2. **롤백 계획**: 문제 발생 시 빠른 롤백 방법 준비
3. **모니터링**: 배포 후 서비스 상태 지속적 모니터링
4. **알림 설정**: 배포 성공/실패 알림 설정
5. **백업**: 배포 전 데이터베이스 백업

## 🎯 결론

자동 배포 설정 후에는 `git push origin main`만으로 배포가 자동으로 진행됩니다!

```bash
# 개발 워크플로우
git add .
git commit -m "새로운 기능 추가"
git push origin main
# 🎉 자동으로 배포됨!
```

## 🚀 GitHub Actions를 통한 자동 배포

### **1. GitHub Secrets 설정**

GitHub 저장소의 Settings > Secrets and variables > Actions에서 다음 시크릿을 설정하세요:

```bash
# 서버 정보
SERVER_HOST=your-server-ip-or-domain
SERVER_USER=your-username
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
your-private-key-content
-----END OPENSSH PRIVATE KEY-----

# 프로젝트 경로
PROJECT_PATH=/path/to/your/project

# API URL (헬스체크용)
API_URL=http://your-domain:18080

# Note: Site and Admin are deployed to Cloudflare Pages
# SITE_URL=https://your-site.pages.dev
# ADMIN_URL=https://your-admin.pages.dev
```

### **2. SSH 키 생성 및 설정**

#### **로컬에서 SSH 키 생성**
```bash
# SSH 키 생성
ssh-keygen -t rsa -b 4096 -C "github-actions@example.com" -f ~/.ssh/github_actions

# 공개키를 서버에 등록
ssh-copy-id -i ~/.ssh/github_actions.pub -p 22000 your-username@your-server-ip

# 또는 수동으로 등록
cat ~/.ssh/github_actions.pub | ssh -p 22000 your-username@your-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### **서버에서 SSH 설정 확인**
```bash
# SSH 설정 파일 확인
sudo vim /etc/ssh/sshd_config

# 포트 설정 확인
Port 22000

# SSH 서비스 재시작
sudo systemctl restart sshd
```

### **3. GitHub Actions 워크플로우**

`.github/workflows/deploy.yml` 파일이 자동으로 생성됩니다:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Setup SSH
      uses: webfactory/ssh-agent@v0.8.0
      with:
        ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
        
    - name: Configure SSH for CentOS 7
      run: |
        mkdir -p ~/.ssh
        cat >> ~/.ssh/config << EOF
        Host ${{ secrets.SERVER_HOST }}
          HostName ${{ secrets.SERVER_HOST }}
          User ${{ secrets.SERVER_USER }}
          Port 22000
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null
        EOF
        
    - name: Add server to known hosts
      run: |
        ssh-keyscan -H -p 22000 ${{ secrets.SERVER_HOST }} >> ~/.ssh/known_hosts
        
    - name: Deploy to server
      run: |
        ssh ${{ secrets.SERVER_HOST }} << 'EOF'
          cd ${{ secrets.PROJECT_PATH }}
          git pull origin main
          ./scripts/deploy.sh
        EOF
        
    - name: Health check
      run: |
        sleep 60
        curl -f ${{ secrets.SITE_URL }}/health || echo "사이트 헬스체크 실패"
        curl -f ${{ secrets.ADMIN_URL }}/health || echo "관리자 페이지 헬스체크 실패"
        curl -f ${{ secrets.API_URL }}/health || echo "API 헬스체크 실패"
```

### **4. 배포 프로세스**

1. **코드 푸시**: `main` 브랜치에 푸시하면 자동 배포 시작
2. **SSH 연결**: 포트 22000을 통해 서버에 연결
3. **코드 업데이트**: 최신 코드를 가져옴
4. **배포 실행**: `deploy.sh` 스크립트 실행
5. **헬스체크**: 모든 서비스 정상 동작 확인

### **5. 수동 배포**

GitHub Actions 페이지에서 "Run workflow" 버튼을 클릭하여 수동으로 배포할 수 있습니다.

### **6. 배포 로그 확인**

#### **GitHub Actions 로그**
- GitHub 저장소 > Actions 탭에서 실시간 로그 확인
- 각 단계별 성공/실패 상태 확인

#### **서버 로그**
```bash
# 배포 스크립트 로그
tail -f deploy.log

# Docker 컨테이너 로그
docker-compose -f docker-compose.prod.yml logs -f

# 특정 서비스 로그
docker-compose -f docker-compose.prod.yml logs -f api
docker-compose -f docker-compose.prod.yml logs -f site
docker-compose -f docker-compose.prod.yml logs -f admin
```

### **7. 문제 해결**

#### **SSH 연결 실패**
```bash
# SSH 연결 테스트
ssh -p 22000 -i ~/.ssh/github_actions your-username@your-server-ip

# SSH 설정 확인
ssh -p 22000 -v your-username@your-server-ip
```

#### **권한 문제**
```bash
# 서버에서 권한 확인
ls -la ~/.ssh/
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh/
```

#### **포트 문제**
```bash
# 방화벽 설정 확인
sudo firewall-cmd --list-all
sudo firewall-cmd --add-port=22000/tcp --permanent
sudo firewall-cmd --reload

# SELinux 설정 확인
sudo semanage port -l | grep ssh
sudo semanage port -a -t ssh_port_t -p tcp 22000
```

### **8. 보안 고려사항**

1. **SSH 키 보안**: 프라이빗 키는 절대 공개하지 마세요
2. **포트 변경**: 기본 SSH 포트(22) 대신 22000 사용
3. **방화벽 설정**: 필요한 포트만 열어두기
4. **정기 업데이트**: 서버 및 애플리케이션 정기 업데이트

### **9. 모니터링**

#### **배포 상태 모니터링**
```bash
# 서비스 상태 확인
docker-compose -f docker-compose.prod.yml ps

# 리소스 사용량 확인
docker stats

# 로그 모니터링
docker-compose -f docker-compose.prod.yml logs -f --tail=100
```

#### **알림 설정**
- GitHub Actions 실패 시 이메일 알림
- 서버 모니터링 도구 설정 (예: Prometheus, Grafana)

### **10. 롤백 전략**

#### **자동 롤백**
```bash
# 이전 버전으로 롤백
git checkout HEAD~1
./scripts/deploy.sh
```

#### **수동 롤백**
```bash
# 특정 커밋으로 롤백
git checkout <commit-hash>
./scripts/deploy.sh
```

이제 GitHub Actions를 통해 CentOS 7 서버(포트 22000)로 자동 배포가 가능합니다! 🚀 