mod config;
mod database;
mod errors;
mod handlers;
mod middleware;
mod models;
mod routes;
mod services;
mod utils;

use axum::{
    extract::{Path, Query, State, Extension},
    http::{StatusCode, Method, header},
    response::IntoResponse,
    routing::{get, post, put, delete},
    Json, Router,
};
use axum::routing::options;
use std::collections::HashMap;
use tower_http::cors::CorsLayer;
use tower_http::services::fs::ServeDir;
use tracing::{info, error, warn};
use crate::config::Config;
use redis::Client as RedisClient;
use sqlx::PgPool;
use crate::routes::{site_routes, admin_routes};

// 애플리케이션 상태 구조체
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: Config,
    pub redis: RedisClient,
}

#[tokio::main]
async fn main() {
    // 환경 변수 로드
    dotenv::dotenv().ok();
    
    // 환경 변수가 없으면 기본값 설정
    if std::env::var("DATABASE_URL").is_err() {
        std::env::set_var("DATABASE_URL", "postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter");
    }
    if std::env::var("REDIS_URL").is_err() {
        std::env::set_var("REDIS_URL", "redis://:tnekwoddl@localhost:16379");
    }
    if std::env::var("JWT_SECRET").is_err() {
        std::env::set_var("JWT_SECRET", "y4WiGMHXVN2BwluiRJj9TGt7Fh/B1pPZM24xzQtCnD8=");
    }
    if std::env::var("REFRESH_SECRET").is_err() {
        std::env::set_var("REFRESH_SECRET", "ASH2HiFHXbIHfkFxWUOcC07QUodLMJBBIPkNKQ/GKcQ=");
    }
    if std::env::var("API_PORT").is_err() {
        std::env::set_var("API_PORT", "18080");
    }
    if std::env::var("RUST_LOG_LEVEL").is_err() {
        std::env::set_var("RUST_LOG_LEVEL", "info");
    }
    if std::env::var("CORS_ORIGIN").is_err() {
        std::env::set_var("CORS_ORIGIN", "https://mincenter.kr,https://admin.mincenter.kr");
    }
    
    // 로깅 초기화
    tracing_subscriber::fmt::init();
    
    // 설정 로드
    let config = Config::from_env();
    // env에서 포트 변경 
    let port = config.api_port;
    
    // 데이터베이스 연결
    let pool = crate::database::get_database().await.expect("Failed to connect to database");
    
    // Redis 연결
    let redis_url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string());
    let redis = RedisClient::open(redis_url).expect("Failed to connect to Redis");
    
    let state = AppState {
        pool,
        config,
        redis,
    };

    // 라우터 모듈 사용
    let site_router = site_routes(state.clone());
    let admin_router = admin_routes(state.clone());
    
    // 헬스 체크
    let health_routes = Router::new()
        .route("/api/health", get(handlers::health_check));

    // 라우터 결합
    let app = Router::new()
        .merge(health_routes)
        .merge(site_router)
        .merge(admin_router)
        // 정적 파일 서빙
        .nest_service("/uploads", ServeDir::new("static/uploads"))
        .layer(axum::middleware::from_fn(middleware::custom_cors_middleware))
        .with_state(state)
        // OPTIONS 요청을 위한 catch-all 핸들러
        .route("/*path", options(|| async { 
            info!("OPTIONS preflight 요청 처리");
            StatusCode::OK 
        }));

    info!("Server starting on port {}", port);
    
    let listener = match tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await {
        Ok(listener) => {
            info!("Server bound to port {}", port);
            listener
        }
        Err(e) => {
            error!("Failed to bind to port {}: {}", port, e);
            std::process::exit(1);
        }
    };

    info!("Server is running and ready to accept connections");
    
    if let Err(e) = axum::serve(listener, app).await {
        error!("Server error: {}", e);
        std::process::exit(1);
    }
}


