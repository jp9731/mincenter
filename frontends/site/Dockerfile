# SvelteKit Site Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# 빌드 시 환경변수 주입
ARG VITE_API_URL
ARG VITE_GOOGLE_CLIENT_ID
ARG VITE_KAKAO_CLIENT_ID

# 패키지 파일 복사
COPY package*.json ./
COPY svelte.config.js ./
COPY vite.config.ts ./
COPY tsconfig.json ./
COPY tailwind.config.js ./

# 의존성 설치
RUN npm ci --silent

# 소스 코드 복사
COPY src ./src
COPY static ./static

# 환경변수 파일 복사 (빌드 시점에 필요)
COPY .env* ./

# 환경변수 파일 생성 (ARG로 전달된 값 사용)
RUN echo "VITE_API_URL=${VITE_API_URL:-http://localhost:18080}" > .env.production && \
    echo "VITE_GOOGLE_CLIENT_ID=${VITE_GOOGLE_CLIENT_ID:-}" >> .env.production && \
    echo "VITE_KAKAO_CLIENT_ID=${VITE_KAKAO_CLIENT_ID:-}" >> .env.production

# 빌드
RUN npm run build

# 프로덕션 이미지
FROM node:20-alpine AS production

WORKDIR /app

# 패키지 파일 복사
COPY package*.json ./

# 프로덕션 의존성만 설치 (없으면 전체 설치)
RUN npm ci --only=production --silent || npm ci --silent

# 빌드된 파일 복사
COPY --from=builder /app/build ./build

# 포트 노출
EXPOSE 3000

# 환경변수 설정
ENV NODE_ENV=production
ENV PORT=3000

# 애플리케이션 실행
CMD ["node", "build/index.js", "--host", "0.0.0.0", "--port", "3000"]