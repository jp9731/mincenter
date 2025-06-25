# 서브도메인 설정 가이드

## 개요

MinSchool 애플리케이션을 서브도메인 방식으로 구성하여 더 나은 보안과 관리성을 제공합니다.

## 서브도메인 구조

```
- 메인 사이트: https://mincenter.kr
- 관리자: https://admin.mincenter.kr
- API: https://api.mincenter.kr
- PM2 모니터링: https://pm2.mincenter.kr (선택사항)
```

## 1. DNS 설정

도메인 관리자 페이지에서 다음 A 레코드를 추가하세요:

```
Type: A
Name: @ (또는 mincenter.kr)
Value: [서버 IP 주소]
TTL: 300

Type: A
Name: www
Value: [서버 IP 주소]
TTL: 300

Type: A
Name: admin
Value: [서버 IP 주소]
TTL: 300

Type: A
Name: api
Value: [서버 IP 주소]
TTL: 300

Type: A
Name: pm2
Value: [서버 IP 주소]
TTL: 300
```

## 2. SSL 인증서 설정

### Let's Encrypt 사용 (권장)

```bash
# Certbot 설치
sudo yum install certbot python3-certbot-nginx

# 와일드카드 인증서 발급
sudo certbot certonly --manual --preferred-challenges=dns \
  -d mincenter.kr \
  -d *.mincenter.kr \
  --email your-email@example.com

# 또는 개별 도메인별로 발급
sudo certbot --nginx -d mincenter.kr -d www.mincenter.kr
sudo certbot --nginx -d admin.mincenter.kr
sudo certbot --nginx -d api.mincenter.kr
sudo certbot --nginx -d pm2.mincenter.kr
```

### 수동 인증서 설정

SSL 인증서 파일을 다음 위치에 배치:
```
/etc/nginx/ssl/cert.pem
/etc/nginx/ssl/key.pem
```

## 3. 환경 변수 설정

```bash
# 환경 변수 파일 복사
cp env.subdomain.example .env

# 환경 변수 편집
nano .env
```

주요 설정:
```env
API_URL=https://api.mincenter.kr
PUBLIC_API_URL=https://api.mincenter.kr
SITE_URL=https://mincenter.kr
ADMIN_URL=https://admin.mincenter.kr
CORS_ORIGIN=https://mincenter.kr,https://admin.mincenter.kr
```

## 4. Nginx 설정

```bash
# 기존 설정 백업
sudo cp /etc/nginx/conf.d/minshool.conf /etc/nginx/conf.d/minshool.conf.backup

# 새 설정 적용
sudo cp nginx/minshool-subdomain.conf /etc/nginx/conf.d/minshool.conf

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

## 5. 애플리케이션 배포

```bash
# 환경 변수 적용
source .env

# 애플리케이션 빌드 및 배포
./scripts/auto-deploy.sh
```

## 6. 프론트엔드 설정 확인

### 관리자 프론트엔드 (frontends/admin)

`src/lib/stores/admin.ts`에서 API_URL이 올바르게 설정되었는지 확인:

```typescript
const API_URL = import.meta.env.VITE_API_URL || 'https://api.mincenter.kr';
```

### 사이트 프론트엔드 (frontends/site)

`src/lib/api/site.ts`에서 API_URL이 올바르게 설정되었는지 확인:

```typescript
const API_URL = import.meta.env.VITE_API_URL || 'https://api.mincenter.kr';
```

## 7. 테스트

각 서브도메인이 올바르게 작동하는지 확인:

```bash
# 메인 사이트
curl -I https://mincenter.kr

# 관리자
curl -I https://admin.mincenter.kr

# API
curl -I https://api.mincenter.kr

# PM2 (선택사항)
curl -I https://pm2.mincenter.kr
```

## 8. 보안 고려사항

### 관리자 사이트 보안
- `X-Robots-Tag: noindex, nofollow` 헤더로 검색엔진 크롤링 방지
- IP 화이트리스트 설정 고려
- 2FA 인증 고려

### API 보안
- CORS 설정으로 허용된 도메인만 접근 가능
- Rate limiting 설정 고려
- API 키 인증 고려

## 9. 모니터링

### 로그 파일 위치
```
/var/log/nginx/minshool_site_access.log
/var/log/nginx/minshool_site_error.log
/var/log/nginx/minshool_admin_access.log
/var/log/nginx/minshool_admin_error.log
/var/log/nginx/minshool_api_access.log
/var/log/nginx/minshool_api_error.log
```

### 헬스체크
```bash
# 사이트 헬스체크
curl https://mincenter.kr/health

# API 헬스체크
curl https://api.mincenter.kr/health
```

## 10. 문제 해결

### DNS 전파 확인
```bash
nslookup mincenter.kr
nslookup admin.mincenter.kr
nslookup api.mincenter.kr
```

### SSL 인증서 확인
```bash
openssl s_client -connect mincenter.kr:443 -servername mincenter.kr
openssl s_client -connect admin.mincenter.kr:443 -servername admin.mincenter.kr
openssl s_client -connect api.mincenter.kr:443 -servername api.mincenter.kr
```

### Nginx 로그 확인
```bash
sudo tail -f /var/log/nginx/minshool_*_error.log
```

## 장점

1. **보안 향상**: 관리자와 API가 완전히 분리됨
2. **라우팅 충돌 방지**: SvelteKit 라우팅과 nginx 라우팅 충돌 없음
3. **독립적인 관리**: 각 서비스별 독립적인 설정 가능
4. **캐싱 최적화**: 각 도메인별 독립적인 캐싱 정책 적용 가능
5. **모니터링 개선**: 각 서비스별 독립적인 로그와 모니터링 