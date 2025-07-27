# SvelteKit Admin Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# 빌드 시 환경변수 주입 (GitHub Actions에서 전달)
ARG VITE_API_URL
ARG PUBLIC_API_URL
ARG API_URL
ARG NODE_ENV

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
RUN echo "VITE_API_URL=${VITE_API_URL:-https://api.mincenter.kr}" > .env.production && \
    echo "PUBLIC_API_URL=${PUBLIC_API_URL:-https://api.mincenter.kr}" >> .env.production && \
    echo "API_URL=${API_URL:-https://api.mincenter.kr}" >> .env.production && \
    echo "NODE_ENV=${NODE_ENV:-production}" >> .env.production

# 빌드
RUN npm run build

# 프로덕션 이미지
FROM node:20-alpine AS production

WORKDIR /app

# 패키지 파일 복사
COPY package*.json ./

# 전체 의존성 설치 (빌드된 앱 실행에 필요)
RUN npm ci --silent

# 빌드된 파일 복사
COPY --from=builder /app/build ./build

# 포트 노출
EXPOSE 3000

# 환경변수 설정
ENV NODE_ENV=production
ENV PORT=3000

# 애플리케이션 실행
CMD ["node", "build/index.js", "--host", "0.0.0.0", "--port", "3000"]