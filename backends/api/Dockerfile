# api/Dockerfile
FROM rust:1.70 as builder
WORKDIR /app
COPY Cargo.* ./
COPY src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=builder /app/target/release/api /usr/local/bin/api
ENV PORT=18080
EXPOSE ${PORT}
CMD ["api"]