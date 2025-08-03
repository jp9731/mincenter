# 🔧 환경변수 파일 관리 가이드

각 프레임워크별로 올바른 환경변수 파일 사용법을 설명합니다.

## 📁 파일 구조

```
프로젝트/
├── .env.production                    # 최상위 통합 환경변수
├── frontends/
│   ├── site/
│   │   └── .env.production           # SvelteKit Site용
│   └── admin/
│       └── .env.production           # SvelteKit Admin용
└── backends/
    └── api/
        └── .env                      # Rust API용
```

## 🎯 각 서비스별 환경변수 파일

### 1. SvelteKit (Site/Admin)
**파일명**: `.env.production`

```bash
# frontends/site/.env.production
NODE_ENV=production
VITE_API_URL=https://api.yourdomain.com
PUBLIC_API_URL=https://api.yourdomain.com
API_BASE_URL=https://api.yourdomain.com
PUBLIC_DOMAIN=yourdomain.com
PUBLIC_NODE_ENV=production
VITE_GOOGLE_CLIENT_ID=your-google-client-id
VITE_KAKAO_CLIENT_ID=your-kakao-client-id
```

**특징**:
- SvelteKit은 `NODE_ENV`에 따라 자동으로 `.env.production` 로드
- `VITE_` 접두사: 클라이언트 사이드에서 접근 가능
- `PUBLIC_` 접두사: 클라이언트 사이드에서 접근 가능 (SvelteKit 5.0+)

### 2. Rust API
**파일명**: `.env`

```bash
# backends/api/.env
API_PORT=18080
NODE_ENV=production

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
POSTGRES_DB=dbname
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_PORT=5432

# Redis Configuration
REDIS_URL=redis://:password@localhost:6379
REDIS_PORT=6379
REDIS_PASSWORD=password

# JWT Configuration
JWT_SECRET=your-jwt-secret
REFRESH_SECRET=your-refresh-secret
ACCESS_TOKEN_EXPIRY_MINUTES=15
REFRESH_TOKEN_EXPIRY_DAYS=7

# Logging and CORS
RUST_LOG_LEVEL=info
CORS_ORIGIN=https://yourdomain.com,https://admin.yourdomain.com
```

**특징**:
- `dotenv` 라이브러리가 `.env` 파일을 자동 로드
- 프로덕션에서도 동일한 `.env` 파일명 사용
- `std::env::var()`로 환경변수 접근

## 🚀 자동 배포시 생성 과정

### GitHub Actions 배포 순서:

1. **환경설정 배포** (deploy-environment job)
   ```bash
   # 서버에서 자동 실행됨
   cd /deploy/path
   
   # 최상위 통합 .env.production 생성
   cat > .env.production << 'EOF'
   # 모든 환경변수 포함
   EOF
   
   # SvelteKit Site용
   mkdir -p frontends/site
   cat > frontends/site/.env.production << 'EOF'
   VITE_API_URL=https://api.yourdomain.com
   # Site 전용 환경변수
   EOF
   
   # SvelteKit Admin용  
   mkdir -p frontends/admin
   cat > frontends/admin/.env.production << 'EOF'
   VITE_API_URL=https://api.yourdomain.com
   # Admin 전용 환경변수
   EOF
   
   # Rust API용
   mkdir -p backends/api
   cat > backends/api/.env << 'EOF'
   DATABASE_URL=postgresql://...
   # API 전용 환경변수
   EOF
   ```

2. **Docker 빌드시 환경변수 주입**
   ```yaml
   # GitHub Actions에서
   - name: Build Docker image
     env:
       VITE_API_URL: https://api.yourdomain.com
       NODE_ENV: production
   ```

## 🔍 환경변수 우선순위

### SvelteKit
1. 빌드 시점 환경변수 (`docker build --build-arg`)
2. `.env.production` 파일
3. `.env.local` 파일  
4. `.env` 파일

### Rust API
1. 시스템 환경변수
2. `.env` 파일 (dotenv 로드)
3. 코드 내 기본값

## 🛠️ 로컬 개발 vs 프로덕션

### 로컬 개발
```bash
# 로컬에서는 개발용 파일 사용
frontends/site/.env.local          # 로컬 개발용
frontends/admin/.env.local         # 로컬 개발용
backends/api/.env                  # 로컬 개발용 (동일 파일명)
```

### 프로덕션 배포
```bash
# 배포시에는 프로덕션용 파일 자동 생성
frontends/site/.env.production     # Docker 빌드시 사용
frontends/admin/.env.production    # Docker 빌드시 사용  
backends/api/.env                  # 런타임시 사용 (덮어씀)
```

## ⚠️ 주의사항

### 1. SvelteKit 환경변수 노출
- `VITE_*`, `PUBLIC_*` 접두사가 있는 변수는 **클라이언트에 노출**됨
- 민감한 정보 (API 키, 시크릿)는 절대 사용 금지
- 서버 전용 정보는 접두사 없이 사용

### 2. Rust API 보안
- `.env` 파일은 서버에서만 사용됨 (안전)
- 모든 민감한 정보 저장 가능
- GitHub Secrets에서 안전하게 주입됨

### 3. 파일 버전 관리
```gitignore
# .gitignore에 추가 권장
.env.local
.env.production
.env.*.local
```

## 🔄 환경변수 업데이트 방법

### 1. GitHub Secrets 업데이트
```bash
# 새로운 설정으로 Secrets 업데이트
./setup-secrets.sh my-config.json
```

### 2. 자동 배포
```bash
# 코드 푸시하면 자동으로 새 환경변수 배포
git push origin main
```

### 3. 수동 환경변수 업데이트
```bash
# 서버에서 직접 수정 (비상시만)
ssh user@server
cd /deploy/path
nano backends/api/.env
docker compose restart api
```

---

**💡 이 가이드를 참고하여 각 서비스에 맞는 올바른 환경변수 파일을 사용하세요!**