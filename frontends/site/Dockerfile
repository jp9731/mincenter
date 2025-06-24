# site/Dockerfile - 메모리 최적화 버전
FROM node:20-alpine as builder
WORKDIR /app

# 메모리 제한 설정
ENV NODE_OPTIONS="--max-old-space-size=2048"

# 패키지 파일 복사 및 의존성 설치
COPY package*.json ./
RUN npm ci --only=production=false --no-audit --no-fund

# 소스 코드 복사
COPY . .

# 빌드 실행 (메모리 최적화)
RUN npm run build || (echo "Build failed. Checking for errors..." && exit 1)

FROM node:20-alpine
WORKDIR /app

# 빌드 결과물 복사
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./

# 프로덕션 의존성만 설치
RUN npm ci --only=production --no-audit --no-fund

ENV PORT=13000
EXPOSE ${PORT}
CMD ["node", "build"]