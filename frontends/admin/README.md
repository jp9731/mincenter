# 장애인 봉사단체 관리자 웹사이트

장애인 봉사단체의 활동을 관리하는 관리자 전용 웹사이트입니다.

## 기술 스택

- **프레임워크**: SvelteKit
- **스타일링**: TailwindCSS
- **컴포넌트**: shadcn-svelte
- **언어**: TypeScript
- **빌드 도구**: Vite

## 주요 기능

### 🔐 인증 및 권한 관리
- 관리자 로그인/로그아웃
- JWT 토큰 기반 인증
- 역할 기반 권한 관리 (super_admin, admin, moderator)

### 📊 대시보드
- 시스템 통계 현황
- 최근 활동 모니터링
- 빠른 액션 메뉴
- 시스템 상태 확인

### 👥 사용자 관리
- 사용자 목록 조회 및 검색
- 사용자 상태 관리 (활성/정지/대기)
- 역할 변경 및 권한 관리
- 사용자 상세 정보 조회

### 📝 콘텐츠 관리
- 게시글 목록 조회 및 검색
- 게시글 상태 관리 (공개/숨김/임시저장)
- 게시판 관리
- 댓글 관리

### 🤝 봉사 활동 관리
- 봉사 활동 등록 및 관리
- 봉사자 신청 현황
- 활동 일정 관리
- 봉사 통계

### 💰 후원 관리
- 후원 내역 조회
- 후원자 정보 관리
- 영수증 발송 관리
- 후원 통계

### 🔔 알림 관리
- 시스템 알림 발송
- 대상 사용자 선택
- 알림 템플릿 관리
- 발송 이력 조회

### 📋 시스템 관리
- 시스템 로그 조회
- 에러 모니터링
- 성능 통계
- 백업 관리

## 설치 및 실행

### 1. 의존성 설치
```bash
npm install
```

### 2. shadcn-svelte 컴포넌트 설치
```bash
# 기본 컴포넌트
npx shadcn-svelte@latest add button card input select badge separator

# 추가 컴포넌트
npx shadcn-svelte@latest add table dialog alert-dialog tabs navigation-menu

# 폼 컴포넌트
npx shadcn-svelte@latest add textarea checkbox radio-group switch
```

### 3. 개발 서버 실행
```bash
npm run dev
```

### 4. 빌드
```bash
npm run build
```

## 환경 설정

### 환경 변수
`.env` 파일을 생성하고 다음 변수들을 설정하세요:

```env
VITE_API_URL=http://localhost:8080
VITE_ADMIN_URL=http://localhost:5174
```

## 테스트 계정

개발 환경에서 사용할 수 있는 테스트 계정:

- **사용자명**: admin
- **비밀번호**: admin123
- **역할**: super_admin

## 프로젝트 구조

```
src/
├── app.html                 # HTML 템플릿
├── app.css                  # 글로벌 스타일
├── app.d.ts                 # 타입 정의
├── routes/
│   ├── +layout.svelte       # 관리자 레이아웃
│   ├── +layout.ts           # 인증 미들웨어
│   ├── +page.svelte         # 대시보드
│   ├── login/               # 로그인
│   │   └── +page.svelte
│   ├── users/               # 사용자 관리
│   │   └── +page.svelte
│   ├── posts/               # 게시글 관리
│   │   └── +page.svelte
│   ├── boards/              # 게시판 관리
│   │   └── +page.svelte
│   ├── comments/            # 댓글 관리
│   │   └── +page.svelte
│   ├── volunteer/           # 봉사 활동
│   │   └── +page.svelte
│   ├── donations/           # 후원 관리
│   │   └── +page.svelte
│   ├── notifications/       # 알림 관리
│   │   └── +page.svelte
│   └── logs/                # 시스템 로그
│       └── +page.svelte
├── lib/
│   ├── components/
│   │   └── ui/              # shadcn-svelte 컴포넌트
│   ├── stores/
│   │   └── admin.ts         # 관리자 상태 관리
│   ├── api/
│   │   └── admin.ts         # API 클라이언트
│   ├── types/
│   │   └── admin.ts         # 타입 정의
│   └── utils/               # 유틸리티 함수
└── static/                  # 정적 파일
```

## API 연동

관리자 웹사이트는 백엔드 API와 연동되어 다음과 같은 기능을 제공합니다:

- **인증**: JWT 토큰 기반 인증
- **사용자 관리**: 사용자 CRUD, 상태 관리
- **콘텐츠 관리**: 게시글, 댓글, 게시판 관리
- **봉사 활동**: 봉사 활동 등록 및 관리
- **후원 관리**: 후원 내역 및 관리
- **알림**: 시스템 알림 발송
- **로그**: 시스템 로그 조회

## 보안

- 모든 관리자 기능에 권한 검증
- JWT 토큰 기반 인증
- API 요청에 인증 헤더 포함
- 민감한 정보 암호화

## 개발 가이드

### 새로운 페이지 추가
1. `src/routes/` 디렉토리에 새 폴더 생성
2. `+page.svelte` 파일 생성
3. 레이아웃에 메뉴 아이템 추가

### API 연동
1. `src/lib/api/admin.ts`에 API 메서드 추가
2. `src/lib/stores/admin.ts`에 스토어 함수 추가
3. 컴포넌트에서 스토어 사용

### 스타일링
- TailwindCSS 클래스 사용
- shadcn-svelte 컴포넌트 활용
- 관리자 전용 CSS 클래스 사용

## 배포

### Docker 배포
```bash
# 이미지 빌드
docker build -t admin-frontend .

# 컨테이너 실행
docker run -p 3000:3000 admin-frontend
```

### 정적 배포
```bash
# 빌드
npm run build

# 정적 파일 배포
# build/ 디렉토리의 파일들을 웹 서버에 업로드
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
