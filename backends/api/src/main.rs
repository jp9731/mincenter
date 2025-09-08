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
    extract::Request,
    http::{Method, HeaderValue},
    response::Response,
    routing::get,
    Router,
    middleware::Next,
};
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

// CORS 미들웨어
async fn cors_middleware(request: Request, next: Next) -> Response {
    let origin = request
        .headers()
        .get("origin")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("")
        .to_string();

    let method = request.method().clone();
    
    // 허용된 Origin 목록 (환경변수에서만 읽어옴)
    let allowed_origins: Vec<String> = std::env::var("CORS_ORIGIN")
        .expect("CORS_ORIGIN environment variable is required")
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    // OPTIONS preflight 처리
    if method == Method::OPTIONS {
        let mut response = Response::new(axum::body::Body::empty());
        let headers = response.headers_mut();
        
        let allowed_origin = if allowed_origins.contains(&origin) {
            origin
        } else {
            "*".to_string()
        };
        
        headers.insert("Access-Control-Allow-Origin", HeaderValue::from_str(&allowed_origin).unwrap_or_else(|_| HeaderValue::from_static("*")));
        headers.insert("Access-Control-Allow-Methods", HeaderValue::from_static("GET, POST, PUT, DELETE, OPTIONS"));
        headers.insert("Access-Control-Allow-Headers", HeaderValue::from_static("authorization, content-type, x-requested-with"));
        headers.insert("Access-Control-Max-Age", HeaderValue::from_static("86400"));
        
        return response;
    }

    // 일반 요청 처리
    let mut response = next.run(request).await;
    
    let allowed_origin = if allowed_origins.contains(&origin) {
        origin
    } else {
        "*".to_string()
    };

    response.headers_mut().insert(
        "Access-Control-Allow-Origin",
        HeaderValue::from_str(&allowed_origin).unwrap_or_else(|_| HeaderValue::from_static("*"))
    );

    response
}

#[tokio::main]
async fn main() {
    // 환경 변수 로드
    dotenv::dotenv().ok();
    
    // 환경 변수는 .env 파일에서 로드됨
    
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
        .route("/health", get(handlers::health_check));
    

    // 라우터 결합
    let app = Router::new()
        .merge(health_routes)
        .merge(site_router)
        .merge(admin_router)
        // 정적 파일 서빙
        .nest_service("/uploads", ServeDir::new("static/uploads"))
        .with_state(state)
        .layer(axum::middleware::from_fn(cors_middleware));

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


