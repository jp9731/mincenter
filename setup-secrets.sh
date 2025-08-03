#!/bin/bash
# GitHub Secrets 일괄 설정 스크립트
# 사용법: 
#   1. 대화형 모드: ./setup-secrets.sh
#   2. 설정 파일 모드: ./setup-secrets.sh config.json

# GitHub CLI 설치 확인
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI가 설치되지 않았습니다."
    echo "설치 방법: https://cli.github.com/"
    exit 1
fi

# 로그인 확인
if ! gh auth status &> /dev/null; then
    echo "GitHub에 로그인해주세요:"
    gh auth login
fi

# JSON 설정 파일 사용 여부 확인
CONFIG_FILE="$1"
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    echo "📄 설정 파일을 사용합니다: $CONFIG_FILE"
    
    # jq 설치 확인
    if ! command -v jq &> /dev/null; then
        echo "❌ jq가 설치되지 않았습니다. JSON 파일 처리를 위해 필요합니다."
        echo "설치 방법: brew install jq (macOS) 또는 apt-get install jq (Ubuntu)"
        echo "💡 대신 대화형 모드를 사용하려면: ./setup-secrets.sh"
        exit 1
    fi
    
    # JSON에서 값 읽기
    PROJECT_NAME=$(jq -r '.project.name' "$CONFIG_FILE")
    DOMAIN_NAME=$(jq -r '.project.domain' "$CONFIG_FILE")
    API_DOMAIN=$(jq -r '.project.api_domain' "$CONFIG_FILE")
    
    DEPLOY_HOST=$(jq -r '.server.host' "$CONFIG_FILE")
    DEPLOY_USER=$(jq -r '.server.user' "$CONFIG_FILE")
    DEPLOY_PATH=$(jq -r '.server.deploy_path' "$CONFIG_FILE")
    SSH_KEY_PATH=$(jq -r '.server.ssh_key_path' "$CONFIG_FILE")
    
    SITE_PORT=$(jq -r '.ports.site' "$CONFIG_FILE")
    ADMIN_PORT=$(jq -r '.ports.admin' "$CONFIG_FILE")
    API_PORT=$(jq -r '.ports.api' "$CONFIG_FILE")
    POSTGRES_PORT=$(jq -r '.ports.postgres' "$CONFIG_FILE")
    REDIS_PORT=$(jq -r '.ports.redis' "$CONFIG_FILE")
    
    DB_NAME=$(jq -r '.database.name' "$CONFIG_FILE")
    DB_USER=$(jq -r '.database.user' "$CONFIG_FILE")
    POSTGRES_PASSWORD=$(jq -r '.database.postgres_password' "$CONFIG_FILE")
    REDIS_PASSWORD=$(jq -r '.database.redis_password' "$CONFIG_FILE")
    
    DOCKER_NETWORK=$(jq -r '.network.docker_network' "$CONFIG_FILE")
    
    # 환경변수 읽기
    JWT_SECRET=$(jq -r '.environment.jwt_secret' "$CONFIG_FILE")
    REFRESH_SECRET=$(jq -r '.environment.refresh_secret' "$CONFIG_FILE")
    SESSION_SECRET=$(jq -r '.environment.session_secret' "$CONFIG_FILE")
    ADMIN_SESSION_SECRET=$(jq -r '.environment.admin_session_secret' "$CONFIG_FILE")
    ADMIN_EMAIL=$(jq -r '.environment.admin_email' "$CONFIG_FILE")
    SSL_EMAIL=$(jq -r '.environment.ssl_email' "$CONFIG_FILE")
    GOOGLE_CLIENT_ID=$(jq -r '.environment.google_client_id' "$CONFIG_FILE")
    KAKAO_CLIENT_ID=$(jq -r '.environment.kakao_client_id' "$CONFIG_FILE")
    ACCESS_TOKEN_EXPIRY_MINUTES=$(jq -r '.environment.access_token_expiry_minutes' "$CONFIG_FILE")
    REFRESH_TOKEN_EXPIRY_DAYS=$(jq -r '.environment.refresh_token_expiry_days' "$CONFIG_FILE")
    RUST_LOG_LEVEL=$(jq -r '.environment.rust_log_level' "$CONFIG_FILE")
    LOG_LEVEL=$(jq -r '.environment.log_level' "$CONFIG_FILE")
    MONITORING_ENABLED=$(jq -r '.environment.monitoring_enabled' "$CONFIG_FILE")
    BACKUP_SCHEDULE=$(jq -r '.environment.backup_schedule' "$CONFIG_FILE")
    BACKUP_RETENTION_DAYS=$(jq -r '.environment.backup_retention_days' "$CONFIG_FILE")
    
    # 추가 포트 읽기
    HTTP_PORT=$(jq -r '.ports.http' "$CONFIG_FILE")
    HTTPS_PORT=$(jq -r '.ports.https' "$CONFIG_FILE")
    
    # SSH 키 경로 확장 (~ 처리)
    SSH_KEY_PATH="${SSH_KEY_PATH/#\~/$HOME}"
    
    echo "✅ 설정 파일에서 모든 값을 읽어왔습니다."
    echo "📋 프로젝트: $PROJECT_NAME"
    echo "🌐 도메인: $DOMAIN_NAME"
    echo "🖥️  서버: $DEPLOY_HOST"
    echo ""
    
else
    echo "🔧 GitHub Secrets 설정을 시작합니다..."
    echo "💡 팁: 설정 파일을 사용하려면 'secrets-config.example.json'을 복사해서 수정하세요"
    echo ""

    # 프로젝트 설정
    read -p "프로젝트 이름을 입력하세요 (예: mincenter): " PROJECT_NAME
    read -p "도메인을 입력하세요 (예: mincenter.kr): " DOMAIN_NAME
    read -p "API 도메인을 입력하세요 (예: api.mincenter.kr): " API_DOMAIN

    # 서버 정보
    read -p "서버 IP를 입력하세요: " DEPLOY_HOST
    read -p "SSH 사용자명을 입력하세요: " DEPLOY_USER
    read -p "배포 경로를 입력하세요 (예: /home/user/app): " DEPLOY_PATH
    echo "SSH 개인키 파일 경로를 입력하세요 (예: ~/.ssh/id_rsa):"
    read -p "> " SSH_KEY_PATH

    # 포트 설정 (기본값 제공)
    read -p "Site 포트 (기본값: 13000): " SITE_PORT
    SITE_PORT=${SITE_PORT:-13000}

    read -p "Admin 포트 (기본값: 13001): " ADMIN_PORT
    ADMIN_PORT=${ADMIN_PORT:-13001}

    read -p "API 포트 (기본값: 18080): " API_PORT
    API_PORT=${API_PORT:-18080}

    read -p "PostgreSQL 포트 (기본값: 15432): " POSTGRES_PORT
    POSTGRES_PORT=${POSTGRES_PORT:-15432}

    read -p "Redis 포트 (기본값: 16379): " REDIS_PORT
    REDIS_PORT=${REDIS_PORT:-16379}

    # 데이터베이스 설정
    read -p "데이터베이스 이름 (기본값: ${PROJECT_NAME}): " DB_NAME
    DB_NAME=${DB_NAME:-$PROJECT_NAME}

    read -p "데이터베이스 사용자 (기본값: ${PROJECT_NAME}): " DB_USER
    DB_USER=${DB_USER:-$PROJECT_NAME}

    read -s -p "PostgreSQL 비밀번호: " POSTGRES_PASSWORD
    echo
    read -s -p "Redis 비밀번호: " REDIS_PASSWORD
    echo

    # 네트워크 설정
    read -p "Docker 네트워크 이름 (기본값: proxy): " DOCKER_NETWORK
    DOCKER_NETWORK=${DOCKER_NETWORK:-proxy}
    
    # 환경변수 설정 (대화형 모드에서는 기본값 제공)
    echo ""
    echo "🔐 보안 설정 (엔터를 누르면 기본값 사용)"
    
    read -p "JWT Secret (기본값: 자동 생성): " JWT_SECRET
    JWT_SECRET=${JWT_SECRET:-$(openssl rand -base64 32)}
    
    read -p "Refresh Secret (기본값: 자동 생성): " REFRESH_SECRET
    REFRESH_SECRET=${REFRESH_SECRET:-$(openssl rand -base64 32)}
    
    read -p "Session Secret (기본값: 자동 생성): " SESSION_SECRET
    SESSION_SECRET=${SESSION_SECRET:-$(openssl rand -base64 32)}
    
    read -p "Admin Session Secret (기본값: 자동 생성): " ADMIN_SESSION_SECRET
    ADMIN_SESSION_SECRET=${ADMIN_SESSION_SECRET:-$(openssl rand -base64 32)}
    
    read -p "Admin Email (기본값: admin@${DOMAIN_NAME}): " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-admin@${DOMAIN_NAME}}
    
    read -p "SSL Email (기본값: ssl@${DOMAIN_NAME}): " SSL_EMAIL
    SSL_EMAIL=${SSL_EMAIL:-ssl@${DOMAIN_NAME}}
    
    read -p "Google Client ID (선택사항): " GOOGLE_CLIENT_ID
    GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID:-""}
    
    read -p "Kakao Client ID (선택사항): " KAKAO_CLIENT_ID
    KAKAO_CLIENT_ID=${KAKAO_CLIENT_ID:-""}
    
    # 기본값들
    ACCESS_TOKEN_EXPIRY_MINUTES=15
    REFRESH_TOKEN_EXPIRY_DAYS=7
    RUST_LOG_LEVEL="info"
    LOG_LEVEL="info"
    MONITORING_ENABLED=false
    BACKUP_SCHEDULE="0 2 * * *"
    BACKUP_RETENTION_DAYS=7
    HTTP_PORT=80
    HTTPS_PORT=443
fi

# SSH 키 읽기
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH 키 파일을 찾을 수 없습니다: $SSH_KEY_PATH"
    exit 1
fi

SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")

echo ""
echo "🚀 Secrets 등록 중..."

# GitHub Secrets 등록
gh secret set DEPLOY_HOST --body "$DEPLOY_HOST"
gh secret set DEPLOY_USER --body "$DEPLOY_USER"
gh secret set DEPLOY_PATH --body "$DEPLOY_PATH"
gh secret set DEPLOY_SSH_KEY --body "$SSH_KEY_CONTENT"

gh secret set PROJECT_NAME --body "$PROJECT_NAME"
gh secret set DOMAIN_NAME --body "$DOMAIN_NAME"
gh secret set API_DOMAIN --body "$API_DOMAIN"

gh secret set SITE_PORT --body "$SITE_PORT"
gh secret set ADMIN_PORT --body "$ADMIN_PORT"
gh secret set API_PORT --body "$API_PORT"
gh secret set POSTGRES_PORT --body "$POSTGRES_PORT"
gh secret set REDIS_PORT --body "$REDIS_PORT"

gh secret set DB_NAME --body "$DB_NAME"
gh secret set DB_USER --body "$DB_USER"
gh secret set POSTGRES_PASSWORD --body "$POSTGRES_PASSWORD"
gh secret set REDIS_PASSWORD --body "$REDIS_PASSWORD"

gh secret set DOCKER_NETWORK --body "$DOCKER_NETWORK"

# 환경변수 Secrets 등록
gh secret set JWT_SECRET --body "$JWT_SECRET"
gh secret set REFRESH_SECRET --body "$REFRESH_SECRET"
gh secret set SESSION_SECRET --body "$SESSION_SECRET"
gh secret set ADMIN_SESSION_SECRET --body "$ADMIN_SESSION_SECRET"
gh secret set ADMIN_EMAIL --body "$ADMIN_EMAIL"
gh secret set SSL_EMAIL --body "$SSL_EMAIL"
gh secret set GOOGLE_CLIENT_ID --body "$GOOGLE_CLIENT_ID"
gh secret set KAKAO_CLIENT_ID --body "$KAKAO_CLIENT_ID"
gh secret set ACCESS_TOKEN_EXPIRY_MINUTES --body "$ACCESS_TOKEN_EXPIRY_MINUTES"
gh secret set REFRESH_TOKEN_EXPIRY_DAYS --body "$REFRESH_TOKEN_EXPIRY_DAYS"
gh secret set RUST_LOG_LEVEL --body "$RUST_LOG_LEVEL"
gh secret set LOG_LEVEL --body "$LOG_LEVEL"
gh secret set MONITORING_ENABLED --body "$MONITORING_ENABLED"
gh secret set BACKUP_SCHEDULE --body "$BACKUP_SCHEDULE"
gh secret set BACKUP_RETENTION_DAYS --body "$BACKUP_RETENTION_DAYS"
gh secret set HTTP_PORT --body "$HTTP_PORT"
gh secret set HTTPS_PORT --body "$HTTPS_PORT"

# .env.production 파일 생성
echo ""
echo "📄 .env.production 파일 생성 중..."

cat > .env.production << EOF
# =============================================================================
# MinCenter 프로덕션 환경 설정 파일 (자동 생성됨)
# =============================================================================

# Application Configuration
APP_NAME=$PROJECT_NAME
NODE_ENV=production
DOMAIN=$DOMAIN_NAME

# Database Configuration
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_PORT=$POSTGRES_PORT
DATABASE_URL=postgresql://$DB_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$DB_NAME

# API Configuration
API_PORT=$API_PORT
API_URL=https://$API_DOMAIN
PUBLIC_API_URL=https://$API_DOMAIN
JWT_SECRET=$JWT_SECRET
REFRESH_SECRET=$REFRESH_SECRET
ACCESS_TOKEN_EXPIRY_MINUTES=$ACCESS_TOKEN_EXPIRY_MINUTES
REFRESH_TOKEN_EXPIRY_DAYS=$REFRESH_TOKEN_EXPIRY_DAYS
RUST_LOG_LEVEL=$RUST_LOG_LEVEL

# CORS Configuration
CORS_ORIGIN=https://$DOMAIN_NAME,https://admin.$DOMAIN_NAME
CORS_ALLOWED_ORIGINS=https://$DOMAIN_NAME,https://admin.$DOMAIN_NAME,https://$API_DOMAIN

# Site Configuration
SITE_PORT=$SITE_PORT
SESSION_SECRET=$SESSION_SECRET
VITE_API_PORT=$API_PORT
VITE_API_URL=https://$API_DOMAIN
VITE_GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
VITE_KAKAO_CLIENT_ID=$KAKAO_CLIENT_ID

# Admin Configuration
ADMIN_PORT=$ADMIN_PORT
ADMIN_SESSION_SECRET=$ADMIN_SESSION_SECRET
ADMIN_EMAIL=$ADMIN_EMAIL

# Redis Configuration
REDIS_PORT=$REDIS_PORT
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_URL=redis://:$REDIS_PASSWORD@localhost:$REDIS_PORT

# Nginx Configuration
HTTP_PORT=$HTTP_PORT
HTTPS_PORT=$HTTPS_PORT

# SSL Configuration
SSL_EMAIL=$SSL_EMAIL

# Backup Configuration
BACKUP_SCHEDULE=$BACKUP_SCHEDULE
BACKUP_RETENTION_DAYS=$BACKUP_RETENTION_DAYS

# Monitoring Configuration
MONITORING_ENABLED=$MONITORING_ENABLED
LOG_LEVEL=$LOG_LEVEL
EOF

echo "✅ .env.production 파일이 생성되었습니다!"
echo ""
echo "✅ 모든 Secrets이 성공적으로 등록되었습니다!"
echo ""
echo "📋 등록된 Secrets 목록:"
gh secret list

echo ""
echo "🔄 이제 GitHub Actions를 실행할 수 있습니다."
echo "💡 팁: 'gh secret list'로 언제든 확인할 수 있습니다."
echo "📄 생성된 .env.production 파일을 서버에 업로드하세요."