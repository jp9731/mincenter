# 관리형 서비스 사용 가이드

## ☁️ 클라우드별 관리형 서비스

### **AWS (Amazon Web Services)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS ALB       │    │ AWS ElastiCache │    │   AWS RDS       │
│ (Application    │    │   (Redis)       │    │ (PostgreSQL)    │
│  Load Balancer) │    │                 │    │                 │
│                 │    │ - 자동 백업      │    │ - 자동 백업      │
│ - 자동 헬스체크  │    │ - 멀티 AZ       │    │ - 멀티 AZ       │
│ - SSL 종료      │    │ - 클러스터 모드  │    │ - 읽기 전용 복제본│
│ - WAF 통합      │    │ - 자동 장애 복구 │    │ - 자동 장애 복구 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  EC2 Auto       │    │  ECS Tasks      │    │  Lambda         │
│  Scaling        │    │  (Fargate)      │    │  Functions      │
│                 │    │                 │    │                 │
│ - CPU/메모리    │    │ - 서버리스      │    │ - 이벤트 기반   │
│   기반 스케일링  │    │ - 자동 스케일링 │    │ - 자동 스케일링 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **GCP (Google Cloud Platform)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GCP CLB       │    │ GCP Memorystore │    │ GCP Cloud SQL   │
│ (Cloud Load     │    │   (Redis)       │    │ (PostgreSQL)    │
│  Balancer)      │    │                 │    │                 │
│                 │    │ - 자동 백업      │    │ - 자동 백업      │
│ - 글로벌 로드    │    │ - 고가용성      │    │ - 고가용성      │
│   밸런싱        │    │ - 자동 장애 복구 │    │ - 읽기 전용 복제본│
│ - SSL 종료      │    │ - 모니터링      │    │ - 자동 장애 복구 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  GKE Pods       │    │  Cloud Run      │    │  App Engine     │
│ (Kubernetes)    │    │  (Serverless)   │    │  (PaaS)         │
│                 │    │                 │    │                 │
│ - HPA 자동      │    │ - 요청 기반     │    │ - 자동 스케일링 │
│   스케일링      │    │   스케일링      │    │ - 관리형 환경   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Azure (Microsoft Azure)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Azure Load      │    │ Azure Cache     │    │ Azure Database  │
│ Balancer        │    │ for Redis       │    │ for PostgreSQL  │
│                 │    │                 │    │                 │
│ - 자동 헬스체크  │    │ - 자동 백업      │    │ - 자동 백업      │
│ - SSL 종료      │    │ - 고가용성      │    │ - 고가용성      │
│ - WAF 통합      │    │ - 자동 장애 복구 │    │ - 읽기 전용 복제본│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ AKS Pods        │    │ Azure Container │    │ Azure Functions │
│ (Kubernetes)    │    │ Instances       │    │ (Serverless)    │
│                 │    │ (Serverless)    │    │                 │
│ - HPA 자동      │    │ - 요청 기반     │    │ - 이벤트 기반   │
│   스케일링      │    │   스케일링      │    │ - 자동 스케일링 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 💰 비용 비교

### **자체 관리 vs 관리형 서비스**

#### **자체 관리 (On-Premise/VM)**
```
Nginx 서버: $50/월
Redis 서버: $50/월
PostgreSQL 서버: $100/월
총 비용: $200/월 + 관리 시간
```

#### **관리형 서비스 (AWS 예시)**
```
ALB: $20/월
ElastiCache Redis: $30/월
RDS PostgreSQL: $50/월
총 비용: $100/월 (관리 시간 없음)
```

## 🔧 설정 예시

### **AWS ElastiCache Redis 설정**
```bash
# Redis 클러스터 생성
aws elasticache create-cache-cluster \
  --cache-cluster-id minshool-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --num-cache-nodes 1 \
  --port 6379

# 연결 정보
REDIS_ENDPOINT="minshool-redis.xxxxx.cache.amazonaws.com"
REDIS_PORT=6379
```

### **AWS RDS PostgreSQL 설정**
```bash
# PostgreSQL 인스턴스 생성
aws rds create-db-instance \
  --db-instance-identifier minshool-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username admin \
  --master-user-password your-password \
  --allocated-storage 20

# 연결 정보
DB_ENDPOINT="minshool-db.xxxxx.rds.amazonaws.com"
DB_PORT=5432
```

### **AWS ALB 설정**
```bash
# 로드 밸런서 생성
aws elbv2 create-load-balancer \
  --name minshool-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx

# 타겟 그룹 생성
aws elbv2 create-target-group \
  --name minshool-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-xxxxx
```

## 🚀 애플리케이션 연결

### **Node.js 애플리케이션 설정**
```javascript
// Redis 연결 (AWS ElastiCache)
const redis = require('redis');
const redisClient = redis.createClient({
    host: process.env.REDIS_ENDPOINT,
    port: process.env.REDIS_PORT,
    password: process.env.REDIS_PASSWORD
});

// PostgreSQL 연결 (AWS RDS)
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_ENDPOINT,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: { rejectUnauthorized: false }
});
```

### **환경 변수 설정**
```bash
# .env 파일
REDIS_ENDPOINT=minshool-redis.xxxxx.cache.amazonaws.com
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password

DB_ENDPOINT=minshool-db.xxxxx.rds.amazonaws.com
DB_PORT=5432
DB_NAME=minshool_db
DB_USER=admin
DB_PASSWORD=your-db-password
```

## 📊 모니터링 및 알림

### **CloudWatch 메트릭 (AWS)**
```bash
# Redis 메트릭
- CPUUtilization
- DatabaseMemoryUsagePercentage
- CacheHits
- CacheMisses

# RDS 메트릭
- CPUUtilization
- FreeableMemory
- DatabaseConnections
- ReadIOPS
- WriteIOPS

# ALB 메트릭
- RequestCount
- TargetResponseTime
- HealthyHostCount
- UnHealthyHostCount
```

### **알림 설정**
```bash
# CloudWatch 알림 생성
aws cloudwatch put-metric-alarm \
  --alarm-name "High-CPU-Alarm" \
  --alarm-description "CPU usage is high" \
  --metric-name CPUUtilization \
  --namespace AWS/ElastiCache \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

## 🎯 장점

### **관리형 서비스 장점**
1. **관리 부담 감소**: 패치, 백업, 모니터링 자동화
2. **고가용성**: 멀티 AZ, 자동 장애 복구
3. **보안**: 클라우드 보안 기능 통합
4. **확장성**: 자동 스케일링 및 성능 최적화
5. **비용 효율성**: 사용한 만큼만 지불

### **자체 관리 장점**
1. **완전한 제어**: 모든 설정 커스터마이징 가능
2. **비용 예측 가능**: 고정 비용
3. **데이터 위치**: 온프레미스 보관 가능
4. **특수 요구사항**: 특별한 설정 가능

## 📈 마이그레이션 전략

### **단계별 마이그레이션**
```
1단계: Redis → ElastiCache
2단계: PostgreSQL → RDS
3단계: Nginx → ALB
4단계: 애플리케이션 서버 → ECS/EKS
```

### **하이브리드 접근**
```
- 개발/테스트: 관리형 서비스
- 프로덕션: 자체 관리 (보안 요구사항)
- 점진적 마이그레이션
``` 