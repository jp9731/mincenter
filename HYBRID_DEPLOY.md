# 🚀 하이브리드 배포 가이드

## 📋 **개요**

이 방식은 **Rust API는 로컬에서 빌드한 바이너리**를, **Frontend는 GitHub Actions에서 빌드**하는 하이브리드 배포 방식입니다.

## 🎯 **장점**

- ✅ **빠른 배포**: API는 바이너리만 업로드
- ✅ **CentOS 7 호환**: 로컬에서 크로스 컴파일
- ✅ **리소스 절약**: 서버에서 Rust 빌드 불필요
- ✅ **안정성**: 의존성 문제 해결
- ✅ **자동화**: GitHub Actions로 자동 배포

## 🔧 **사전 준비**

### 1. CentOS 7용 바이너리 빌드

```bash
# CentOS 7용 바이너리 빌드
./scripts/build-centos7.sh

# 또는 캐시 정리 후 빌드
./scripts/build-centos7.sh --clean
```

### 2. 빌드 결과 확인

```bash
# 빌드된 파일 확인
ls -la build/centos7/

# 바이너리 정보 확인
file build/centos7/minshool-api
```

### 3. Git에 바이너리 추가

```bash
# 바이너리 파일 추가
git add build/centos7/minshool-api

# 커밋
git commit -m "Add CentOS 7 API binary"

# 푸시
git push
```

## 🔄 **배포 워크플로우**

### **1단계: 로컬에서 바이너리 빌드**
```bash
./scripts/build-centos7.sh
```

### **2단계: Git에 업로드**
```bash
git add build/centos7/minshool-api
git commit -m "Update API binary"
git push
```

### **3단계: GitHub Actions 자동 배포**
- GitHub Actions가 자동으로 실행
- Frontend 빌드 및 배포
- 바이너리 API 배포
- 데이터베이스 파일 배포

## 📁 **파일 구조**

```
project/
├── build/centos7/           # CentOS 7 바이너리
│   └── minshool-api
├── frontends/
│   ├── site/               # 사이트 프론트엔드
│   └── admin/              # 관리자 프론트엔드
├── backends/api/           # Rust API 소스
├── database/               # DB 스키마/데이터
│   ├── init.sql
│   └── seed.sql
└── .github/workflows/
    └── deploy-hybrid.yml   # 하이브리드 배포 워크플로우
```

## 🔧 **CentOS 7 호환성**

### **정적 링킹 (권장)**
```bash
# Ubuntu/Debian
sudo apt-get install gcc-multilib

# macOS
brew install gcc

# 환경변수 설정
export RUSTFLAGS="-C target-cpu=x86-64 -C target-feature=+crt-static"
```

### **동적 링킹 (대안)**
```bash
# CentOS 7에서 필요한 라이브러리
sudo yum install glibc-devel libstdc++-devel
```

## 🚨 **문제 해결**

### **바이너리 실행 오류**
```bash
# 서버에서 확인
ldd /opt/minshool-api/minshool-api

# 누락된 라이브러리 설치
sudo yum install glibc-devel libstdc++-devel
```

### **권한 문제**
```bash
# 실행 권한 설정
chmod +x /opt/minshool-api/minshool-api

# 소유자 변경
chown root:root /opt/minshool-api/minshool-api
```

### **서비스 시작 실패**
```bash
# 로그 확인
journalctl -u minshool-api -f

# 서비스 상태 확인
systemctl status minshool-api
```

## 📊 **배포 상태 확인**

### **GitHub Actions**
- Actions 탭에서 배포 진행 상황 확인
- 로그에서 각 단계별 성공/실패 확인

### **서버 상태**
```bash
# API 서버 상태
curl http://your-server:18080/health

# 프론트엔드 상태
curl http://your-server/site/
curl http://your-server/admin/

# 서비스 상태
systemctl status minshool-api
systemctl status nginx
```

## 🔄 **업데이트 프로세스**

### **API 업데이트**
1. 코드 수정
2. 로컬에서 바이너리 빌드: `./scripts/build-centos7.sh`
3. Git에 업로드: `git add build/ && git commit && git push`
4. GitHub Actions 자동 배포

### **Frontend 업데이트**
1. 코드 수정
2. Git에 업로드: `git add . && git commit && git push`
3. GitHub Actions 자동 배포

### **전체 업데이트**
1. 모든 코드 수정
2. 바이너리 빌드: `./scripts/build-centos7.sh`
3. Git에 업로드: `git add . && git commit && git push`
4. GitHub Actions 자동 배포

## 🎯 **최적화 팁**

### **바이너리 크기 최적화**
```bash
# Cargo.toml에 추가
[profile.release]
opt-level = 3
lto = true
codegen-units = 1
panic = 'abort'
strip = true
```

### **빌드 속도 향상**
```bash
# 병렬 빌드
export CARGO_BUILD_JOBS=$(nproc)

# 캐시 활용
cargo build --release
```

## 📞 **지원**

문제가 발생하면 다음을 확인하세요:
1. GitHub Actions 로그
2. 서버 로그: `journalctl -u minshool-api -f`
3. Nginx 로그: `tail -f /var/log/nginx/error.log` 