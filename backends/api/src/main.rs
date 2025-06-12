mod config;
mod database;
mod errors;
mod handlers;
mod middleware;
mod models;
mod services;
mod utils;

use axum::{
    routing::{post,get},
    Router,
};
use tower_http::cors::CorsLayer;
use sqlx::PgPool;

#[tokio::main]
async fn main() {
    // 환경 변수 로드
    dotenv::dotenv().ok();
    
    // 데이터베이스 연결
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    let pool = PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to Postgres");

    // 라우터 설정
    let app = Router::new()
        .route("/health", get(|| async { "OK" }))
        .route("/api/auth/register", post(handlers::auth::register))
        .route("/api/auth/login", post(handlers::auth::login))
        .layer(CorsLayer::permissive())
        .with_state(pool);

    // 서버 시작
    let port = std::env::var("API_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT must be a number");

    println!("Server running on port {}", port);
    
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port))
        .await
        .unwrap();
    axum::serve(listener, app)
        .await
        .unwrap();
}


