# site/Dockerfile, admin/Dockerfile
FROM node:20-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./
RUN npm ci --only=production
ENV PORT=13001
EXPOSE ${PORT}
CMD ["node", "build"]