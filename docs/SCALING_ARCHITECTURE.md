# 자동 스케일링 아키텍처 가이드

## 🏗️ 서버 구성 전략

### 1. **고정 서버 (Static Infrastructure)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx LB      │    │     Redis       │    │   PostgreSQL    │
│   (1-2대)       │    │     (1-3대)     │    │   (1-3대)       │
│   고정 서버      │    │    고정 서버     │    │    고정 서버     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2. **자동 스케일링 서버 (Auto Scaling)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx LB      │    │     Redis       │    │   PostgreSQL    │
│   (고정)        │    │    (고정)       │    │    (고정)       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  App Server 1   │    │  App Server 2   │    │  App Server N   │
│   (자동 증감)    │    │   (자동 증감)    │    │   (자동 증감)    │
│   Min: 2대      │    │   Max: 10대     │    │   CPU > 70%     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📊 트래픽에 따른 서버 증감

### **낮은 트래픽 (평상시)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx LB      │    │     Redis       │    │   PostgreSQL    │
│   (1대)         │    │     (1대)       │    │   (1대)         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  App Server 1   │
                    │  App Server 2   │
                    │   (최소 2대)    │
                    └─────────────────┘
```

### **높은 트래픽 (피크 시간)**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx LB      │    │     Redis       │    │   PostgreSQL    │
│   (1대)         │    │     (1대)       │    │   (1대)         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  App Server 1   │    │  App Server 2   │    │  App Server 8   │
│  App Server 3   │    │  App Server 4   │    │  App Server 9   │
│  App Server 5   │    │  App Server 6   │    │  App Server 10  │
│  App Server 7   │    │                 │    │   (자동 추가)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ⚙️ 자동 스케일링 설정

### **AWS Auto Scaling Group 예시**
```yaml
# Auto Scaling Group 설정
AutoScalingGroup:
  MinSize: 2
  MaxSize: 10
  DesiredCapacity: 2
  
  # 스케일링 정책
  ScalingPolicies:
    - ScaleUpPolicy:
        Metric: CPUUtilization
        Threshold: 70
        Period: 300
        Adjustment: +1
        
    - ScaleDownPolicy:
        Metric: CPUUtilization
        Threshold: 30
        Period: 300
        Adjustment: -1
```

### **Kubernetes HPA (Horizontal Pod Autoscaler)**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: minshool-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: minshool-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 🔧 실제 구현 방법

### **1. Docker Swarm 방식**
```bash
# 서비스 생성 (자동 복제)
docker service create \
  --name minshool-app \
  --replicas 2 \
  --publish 3000:3000 \
  minshool-app:latest

# 스케일링
docker service scale minshool-app=5
```

### **2. PM2 Cluster 방식**
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'minshool-app',
    script: './app.js',
    instances: 'max',  // CPU 코어 수만큼
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production'
    }
  }]
}
```

### **3. Nginx Upstream 자동 감지**
```nginx
# 동적 upstream 설정
upstream app_servers {
    least_conn;
    
    # 서버 목록을 동적으로 업데이트
    include /etc/nginx/upstream.conf;
    
    # 헬스체크
    keepalive 32;
}

# 헬스체크 설정
match health_check {
    status 200;
    header Content-Type = application/json;
    body ~ '"status":"healthy"';
}
```

## 📈 모니터링 및 알림

### **스케일링 메트릭**
```bash
# CPU 사용률 모니터링
watch -n 1 'top -bn1 | grep "Cpu(s)"'

# 메모리 사용률
free -h

# 네트워크 연결 수
netstat -an | grep :3000 | wc -l

# 응답 시간
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:3000"
```

### **알림 설정**
```bash
# CPU 사용률이 80% 이상일 때 알림
if [ $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1) -gt 80 ]; then
    echo "High CPU usage detected!" | mail -s "Server Alert" admin@example.com
fi
```

## 💰 비용 최적화

### **스케일링 전략**
1. **예측 기반 스케일링**: 시간대별 트래픽 패턴 분석
2. **반응형 스케일링**: 실시간 메트릭 기반 자동 조정
3. **비용 기반 스케일링**: 비용 효율적인 리소스 사용

### **리소스 사용률**
```
- CPU: 60-70% (스케일업 임계값)
- Memory: 80% (스케일업 임계값)
- Disk I/O: 70% (스케일업 임계값)
- Network: 80% (스케일업 임계값)
```

## 🚀 배포 전략

### **Blue-Green 배포**
```
1. Blue 환경 (현재 운영)
2. Green 환경 (새 버전 배포)
3. 트래픽 전환
4. Blue 환경 제거
```

### **Rolling Update**
```
1. 서버 1 업데이트 → 헬스체크 → 트래픽 전환
2. 서버 2 업데이트 → 헬스체크 → 트래픽 전환
3. 서버 3 업데이트 → 헬스체크 → 트래픽 전환
```

## 📊 실제 사용 사례

### **Netflix**
- 수천 대의 마이크로서비스
- 실시간 트래픽에 따른 자동 스케일링
- 지역별 CDN 및 로드 밸런싱

### **Amazon**
- Auto Scaling Groups
- ELB (Elastic Load Balancer)
- RDS (관리형 데이터베이스)

### **Google**
- Kubernetes 기반 오케스트레이션
- GKE (Google Kubernetes Engine)
- Cloud Load Balancing 