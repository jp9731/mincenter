# 배포 스크립트 사용법

이 디렉토리에는 CentOS 7 서버에 시스템을 배포하기 위한 스크립트들이 있습니다.

## 🚀 바이너리 배포 방식 (권장)

Docker 대신 로컬에서 빌드한 바이너리를 직접 서버에 배포하는 방식입니다.

### 장점
- ✅ 빠른 배포 속도
- ✅ 서버 리소스 절약
- ✅ CentOS 7 호환성 문제 해결
- ✅ 더 작은 이미지 크기
- ✅ 의존성 문제 없음

## 📁 스크립트 목록

### 1. `deploy-binary.sh` - 백엔드 API 배포
- Rust 바이너리를 서버에 배포
- systemd 서비스로 등록
- 자동 시작/재시작 설정

### 2. `deploy-frontend.sh` - 프론트엔드 배포
- Svelte 빌드 파일을 서버에 배포
- Nginx 설정 및 재시작
- 사이트/관리자 페이지 배포

### 3. `deploy-all.sh` - 전체 시스템 배포
- 백엔드 + 프론트엔드 + 데이터베이스 전체 배포
- 순차적 빌드 및 배포
- 최종 상태 확인

## 🔧 사용법

### 환경변수 설정
```bash
export REMOTE_HOST="your-server-ip"
export REMOTE_USER="root"  # 기본값
export REMOTE_PORT="22"     # 기본값
```

### 개별 배포

#### 백엔드만 배포
```bash
# 1. 백엔드 빌드
cd backends/api && cargo build --release && cd ../..

# 2. 배포
./scripts/deploy-binary.sh
```

#### 프론트엔드만 배포
```bash
# 1. 프론트엔드 빌드
cd frontends/site && npm run build && cd ../..
cd frontends/admin && npm run build && cd ../..

# 2. 배포
./scripts/deploy-frontend.sh
```

### 전체 시스템 배포
```bash
./scripts/deploy-all.sh
```

## 🗂️ 서버 디렉토리 구조

배포 후 서버의 디렉토리 구조:
```
/opt/
├── minshool-api/           # API 바이너리
│   └── minshool-api
├── database/              # DB 스키마/데이터
│   ├── init.sql
│   └── seed.sql
└── ...

/var/www/html/
├── site/                  # 사이트 프론트엔드
│   ├── index.html
│   └── ...
└── admin/                 # 관리자 프론트엔드
    ├── index.html
    └── ...

/etc/systemd/system/
└── minshool-api.service   # API 서비스 파일
```

## 🔍 서비스 관리

### API 서비스 관리
```bash
# 상태 확인
systemctl status minshool-api

# 로그 확인
journalctl -u minshool-api -f

# 서비스 제어
systemctl start minshool-api
systemctl stop minshool-api
systemctl restart minshool-api
```

### Nginx 관리
```bash
# 설정 확인
nginx -t

# 재시작
systemctl reload nginx

# 로그 확인
tail -f /var/log/nginx/error.log
```

## 🌐 접속 URL

배포 완료 후 접속 가능한 URL:
- **API 서버**: `http://your-server-ip:18080`
- **사이트**: `http://your-server-ip/site/`
- **관리자**: `http://your-server-ip/admin/`

## ⚠️ 주의사항

1. **환경변수 설정**: `REMOTE_HOST`를 반드시 설정해야 합니다.
2. **SSH 키**: 서버에 SSH 키 인증이 설정되어 있어야 합니다.
3. **서버 준비**: PostgreSQL, Redis, Nginx가 설치되어 있어야 합니다.
4. **방화벽**: 포트 18080이 열려있어야 합니다.

## 🔧 문제 해결

### 빌드 실패
```bash
# 백엔드 빌드 오류
cd backends/api
cargo clean && cargo build --release

# 프론트엔드 빌드 오류
cd frontends/site
npm install && npm run build
```

### 배포 실패
```bash
# 서버 연결 확인
ssh root@your-server-ip

# 서비스 상태 확인
systemctl status minshool-api
journalctl -u minshool-api -n 50
```

### 접속 불가
```bash
# 포트 확인
netstat -tlnp | grep 18080

# 방화벽 확인
firewall-cmd --list-ports
firewall-cmd --add-port=18080/tcp --permanent
firewall-cmd --reload
``` 