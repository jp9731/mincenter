# api/Dockerfile
FROM rust:latest as builder

WORKDIR /app

# 의존성 파일만 먼저 복사하여 캐시 활용
COPY Cargo.toml Cargo.lock ./

# 더미 프로젝트 생성 및 의존성 빌드
RUN mkdir -p src && \
  echo "fn main() {}" > src/main.rs && \
  echo "pub mod models; pub mod handlers; pub mod errors; pub mod database;" > src/lib.rs && \
  cargo build --release || true && \
  rm -rf src

# 소스 코드 복사
COPY src ./src

# SQLx 오프라인 모드 설정
ENV SQLX_OFFLINE=true
ENV SQLX_OFFLINE_DIR=.sqlx

# sqlx-data 디렉토리가 있다면 복사
COPY .sqlx ./sqlx-data/

RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/minshool-api /usr/local/bin/api

ENV PORT=18080
EXPOSE ${PORT}

CMD ["api"]