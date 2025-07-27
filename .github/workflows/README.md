# GitHub Actions 워크플로우 가이드

## 🚀 활성 워크플로우

### `smart-deploy.yml` ✅ **기본 배포**
- **트리거**: `push` to main, `workflow_dispatch`
- **방식**: 서버에서 직접 빌드 및 배포
- **특징**: 변경된 컴포넌트만 선별 배포
- **사용**: 일반적인 코드 변경 시 자동 배포

## 🔧 선택적 워크플로우 (수동 실행)

### `build-and-deploy.yml` 🛠️ **사전 빌드 배포**
- **트리거**: `workflow_dispatch` (수동 실행만)
- **방식**: GitHub Actions에서 빌드 후 이미지 전송
- **특징**: Node.js 20 환경에서 사전 빌드 검증
- **사용**: 
  - 빌드 환경 이슈 해결시
  - 복잡한 의존성 변경시
  - 안전한 배포가 필요할 때

### `deploy-hybrid.yml` 📦 **레거시 배포**
- **트리거**: `workflow_dispatch` (수동 실행만)
- **방식**: 하이브리드 배포 (프론트엔드 Docker + API 직접)
- **특징**: 기존 배포 방식 호환
- **사용**: 긴급 상황 또는 롤백시

## 📋 사용 가이드

### 일반적인 개발 흐름
```bash
git push origin main  # → smart-deploy.yml 자동 실행
```

### 복잡한 변경사항이 있을 때
1. GitHub Actions → Actions 탭
2. "Build and Deploy with Pre-built Images" 선택
3. "Run workflow" 클릭

### 긴급 상황시
1. GitHub Actions → Actions 탭  
2. "Deploy Frontend Services (Legacy)" 선택
3. "Run workflow" 클릭

## ⚠️ 주의사항

- **동시 실행 금지**: 여러 워크플로우를 동시에 실행하지 마세요
- **서버 리소스**: 빌드 중에는 서버 성능이 저하될 수 있습니다
- **롤백**: 문제 발생시 `smart-deploy.yml`로 이전 버전 배포 가능

## 🔍 디버깅

배포 실패시 확인 순서:
1. GitHub Actions 로그 확인
2. 서버 로그 확인: `ssh server && cd /path && tail -f api.log`
3. Docker 컨테이너 상태: `docker ps`
4. 서비스 응답: `curl http://localhost:13000`