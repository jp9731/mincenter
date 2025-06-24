# site/Dockerfile, admin/Dockerfile
FROM node:20-alpine as builder
WORKDIR /app

# 패키지 파일 복사 및 의존성 설치
COPY package*.json ./
RUN npm ci --only=production=false

# 소스 코드 복사
COPY . .

# 빌드 실행 (오류 발생 시 상세 로그 출력)
RUN npm run build || (echo "Build failed. Checking for errors..." && exit 1)

FROM node:20-alpine
WORKDIR /app

# 빌드 결과물 복사
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./

# 프로덕션 의존성만 설치
RUN npm ci --only=production

ENV PORT=13001
EXPOSE ${PORT}

CMD ["node", "build"]