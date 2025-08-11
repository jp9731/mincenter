# GitHub Secrets 설정 가이드

GitHub Actions가 서버에 자동 배포하기 위해 필요한 Secrets를 설정해야 합니다.

## 📋 필수 Secrets 목록

GitHub 저장소 → Settings → Secrets and variables → Actions → New repository secret

| Secret Name | Value | 설명 |
|-------------|-------|------|
| `SERVER_HOST` | `mincenter.kr` | 서버 호스트명 |
| `SERVER_USER` | `admin` | 서버 사용자명 |
| `SERVER_SSH_KEY` | [SSH 개인키] | 서버 접속용 SSH 개인키 |
| `DATABASE_PASSWORD` | `!@swjp0209^^` | PostgreSQL 비밀번호 |
| `REDIS_PASSWORD` | `tnekwoddl` | Redis 비밀번호 |
| `JWT_SECRET` | `y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=` | JWT 토큰 시크릿 |
| `REFRESH_SECRET` | `ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=` | 리프레시 토큰 시크릿 |

## 🔑 SSH 키 설정

### 1. 서버에서 SSH 키 확인
```bash
# 서버에 접속해서 SSH 공개키 확인
ssh mincenter.kr
cat ~/.ssh/authorized_keys
```

### 2. 로컬에서 SSH 개인키 확인
```bash
# 로컬에서 개인키 내용 확인 (전체 내용 복사)
cat ~/.ssh/id_rsa
# 또는
cat ~/.ssh/id_ed25519
```

### 3. GitHub Secrets에 개인키 등록
- SECRET_SSH_KEY에는 **개인키 전체 내용**을 붙여넣기
- `-----BEGIN OPENSSH PRIVATE KEY-----`부터 `-----END OPENSSH PRIVATE KEY-----`까지 전부

## ✅ 설정 완료 후

1. **Secrets 설정 완료**
2. **코드를 main 브랜치에 push**
3. **GitHub Actions 탭에서 워크플로우 실행 확인**
4. **서버에서 컨테이너 상태 확인**

```bash
# 서버에서 확인
docker compose ps
docker compose logs api
curl http://localhost:18080/health
```

## 🚨 주의사항

- SSH 개인키는 절대 공개하지 마세요
- Secrets 값에 따옴표나 공백이 들어가지 않도록 주의하세요
- 서버의 SSH 접속이 키 기반 인증으로 설정되어 있어야 합니다

## 📋 배포 방식 설명

**GitHub Actions는 테스트 빌드를 하지 않습니다**
- SQLx 매크로가 컴파일 타임에 데이터베이스 연결을 시도하기 때문
- GitHub Actions 러너에서는 데이터베이스에 접근할 수 없어 빌드 실패 발생
- 대신 서버에서 직접 빌드하여 데이터베이스 접근 문제 해결

**배포 프로세스:**
1. GitHub Actions가 서버에 SSH 접속
2. 서버에서 Git으로 최신 코드 다운로드
3. 서버에서 Docker 빌드 (데이터베이스 연결 가능한 환경)
4. 컨테이너 배포 및 헬스체크