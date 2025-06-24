# MinSchool 아키텍처 가이드

## 🏗️ 전체 시스템 아키텍처

```
                    Internet
                       │
                       ▼
                ┌─────────────┐
                │   DNS/CDN   │
                └─────────────┘
                       │
                       ▼
                ┌─────────────┐
                │   Nginx     │ ← 로드 밸런서
                │ Load Balancer│
                └─────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  App Server │ │  App Server │ │  App Server │
│     1       │ │     2       │ │     3       │
│             │ │             │ │             │
│ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
│ │  Site   │ │ │ │  Site   │ │ │ │  Site   │ │
│ │ (3000)  │ │ │ │ (3000)  │ │ │ │ (3000)  │ │
│ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
│ ┌─────────┐ │ │ ┌─────────┐ │ │ ┌─────────┐ │
│ │  Admin  │ │ │ │  Admin  │ │ │ │  Admin  │ │
│ │ (3001)  │ │ │ │ (3001)  │ │ │ │ (3001)  │ │
│ └─────────┘ │ │ └─────────┘ │ │ └─────────┘ │
└─────────────┘ └─────────────┘ └─────────────┘
        │              │              │
        └──────────────┼──────────────┘
                       ▼
                ┌─────────────┐
                │    Redis    │ ← 세션/상태 저장소
                │   (6379)    │
                └─────────────┘
                       │
                       ▼
                ┌─────────────┐
                │ PostgreSQL  │ ← 메인 데이터베이스
                │   (5432)    │
                └─────────────┘
```

## 🔄 요청 처리 흐름

### 1. 사용자 로그인
```
1. 사용자 → Nginx → App Server 1
2. App Server 1 → PostgreSQL (인증 확인)
3. App Server 1 → Redis (세션 저장)
4. App Server 1 → 사용자 (로그인 성공)
```

### 2. 사용자 요청 (로그인 후)
```
1. 사용자 → Nginx → App Server 2 (로드 밸런싱)
2. App Server 2 → Redis (세션 조회)
3. App Server 2 → PostgreSQL (데이터 조회)
4. App Server 2 → 사용자 (응답)
```

### 3. 세션 관리
```
- 모든 App Server가 동일한 Redis에 접근
- 세션 정보는 Redis에 저장
- 서버가 다운되어도 세션 유지
- 로드 밸런싱으로 어떤 서버든 접근 가능
```

## 🗄️ 데이터 저장소 역할

### Redis (인메모리 저장소)
```javascript
// 세션 데이터
{
  "session:user123": {
    "userId": "user123",
    "email": "user@example.com",
    "role": "admin",
    "lastAccess": "2024-01-15T10:30:00Z",
    "permissions": ["read", "write", "delete"]
  }
}

// 캐시 데이터
{
  "cache:posts:recent": [
    {"id": 1, "title": "최신 게시글", "author": "user1"},
    {"id": 2, "title": "두 번째 게시글", "author": "user2"}
  ],
  "cache:user:profile:user123": {
    "name": "홍길동",
    "avatar": "avatar.jpg",
    "joinDate": "2024-01-01"
  }
}

// 실시간 상태
{
  "online:users": ["user1", "user2", "user3"],
  "notifications:user123": [
    {"id": 1, "message": "새 댓글이 달렸습니다", "read": false}
  ]
}
```

### PostgreSQL (영구 저장소)
```sql
-- 사용자 테이블
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 게시글 테이블
CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    author_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## ⚙️ 설정 예시

### Nginx 로드 밸런서 설정
```nginx
upstream app_servers {
    least_conn;
    server 192.168.1.100:3000 max_fails=3 fail_timeout=30s;
    server 192.168.1.101:3000 max_fails=3 fail_timeout=30s;
    server 192.168.1.102:3000 max_fails=3 fail_timeout=30s;
}

server {
    listen 80;
    server_name mincenter.kr;
    
    location / {
        proxy_pass http://app_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Redis 연결 설정
```javascript
// Node.js/Express 예시
const session = require('express-session');
const RedisStore = require('connect-redis')(session);
const redis = require('redis');

const redisClient = redis.createClient({
    host: '192.168.1.200',
    port: 6379,
    password: 'your-redis-password'
});

app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: 'your-session-secret',
    resave: false,
    saveUninitialized: false,
    cookie: { secure: true, maxAge: 24 * 60 * 60 * 1000 } // 24시간
}));
```

## 🚀 장점

### 1. **확장성**
- 서버 추가/제거가 쉬움
- 트래픽 증가에 유연하게 대응

### 2. **고가용성**
- 단일 서버 장애 시에도 서비스 중단 없음
- Redis 장애 시에도 기본 기능 유지

### 3. **성능**
- Redis를 통한 빠른 세션 조회
- 캐싱으로 데이터베이스 부하 감소

### 4. **유지보수**
- 서버별 독립적인 배포 가능
- 무중단 업데이트 가능

## 🔧 실제 구현 단계

### 1단계: 기본 설정
```bash
# Redis 설치
sudo yum install redis

# Nginx 설정
sudo cp nginx/minshool-loadbalancer.conf /etc/nginx/conf.d/

# 애플리케이션 서버 설정
pm2 start ecosystem.config.js
```

### 2단계: 세션 설정
```bash
# Redis 세션 스토어 설정
npm install connect-redis express-session

# 세션 미들웨어 구성
```

### 3단계: 모니터링
```bash
# Redis 모니터링
redis-cli monitor

# Nginx 상태 확인
curl http://localhost/upstream_status

# PM2 모니터링
pm2 monit
```

## 📊 모니터링 지표

### Redis 모니터링
- 연결 수
- 메모리 사용량
- 명령어 처리량
- 키 만료율

### Nginx 모니터링
- 업스트림 서버 상태
- 요청 분배 비율
- 응답 시간
- 에러율

### 애플리케이션 모니터링
- 서버별 CPU/메모리 사용량
- 세션 수
- 데이터베이스 연결 수
- API 응답 시간