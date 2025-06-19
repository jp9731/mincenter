mod config;
mod database;
mod errors;
mod handlers;
mod middleware;
mod models;
mod services;
mod utils;

use axum::{
    routing::{post, get, put, delete},
    Router,
    middleware::from_fn_with_state,
    extract::Extension,
};
use tower_http::cors::CorsLayer;
use sqlx::PgPool;
use crate::config::Config;

// 애플리케이션 상태 구조체
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: Config,
}

#[tokio::main]
async fn main() {
    // 환경 변수 로드
    dotenv::dotenv().ok();
    
    // 설정 로드
    let config = Config::from_env();
    let port = config.api_port; // 포트 번호를 미리 저장
    
    // 데이터베이스 연결
    let pool = PgPool::connect(&config.database_url)
        .await
        .expect("Failed to connect to Postgres");

    // 애플리케이션 상태 생성
    let state = AppState { pool, config: config.clone() };

    // 공개 라우터
    let public_routes = Router::new()
        .route("/health", get(|| async { "OK" }))
        // Auth routes
        .route("/api/auth/register", post(handlers::auth::register))
        .route("/api/auth/login", post(handlers::auth::login))
        .route("/api/auth/refresh", post(handlers::auth::refresh))
        .route("/api/auth/logout", post(handlers::auth::logout))
        // Admin auth routes
        .route("/api/admin/auth/login", post(handlers::admin::admin_login))
        // Community routes (public)
        .route("/api/community/boards", get(handlers::community::get_boards))
        .route("/api/community/boards/:board_id/categories", get(handlers::community::get_categories))
        .route("/api/community/posts", get(handlers::community::get_posts))
        .route("/api/community/posts/:post_id", get(handlers::community::get_post))
        .route("/api/community/posts/:post_id/comments", get(handlers::community::get_comments));

    // 인증이 필요한 라우터
    let protected_routes = Router::new()
        .route("/api/auth/me", get(handlers::auth::me))
        .route("/api/community/posts", post(handlers::community::create_post))
        .route("/api/community/posts/:post_id", put(handlers::community::update_post))
        .route("/api/community/posts/:post_id", delete(handlers::community::delete_post))
        .route("/api/community/comments", post(handlers::community::create_comment))
        .route("/api/community/comments/:comment_id", put(handlers::community::update_comment))
        .route("/api/community/comments/:comment_id", delete(handlers::community::delete_comment))
        .layer(from_fn_with_state(state.clone(), middleware::auth_middleware));

    // 관리자 라우터 (관리자 권한 필요) - 실제로 구현된 함수들만 포함
    let admin_routes = Router::new()
        // 대시보드
        .route("/api/admin/dashboard/stats", get(handlers::admin::get_dashboard_stats))
        // 사용자 관리
        .route("/api/admin/users", get(handlers::admin::get_users))
        // 게시글 관리
        .route("/api/admin/posts", get(handlers::admin::get_posts))
        // 게시판 관리
        .route("/api/admin/boards", get(handlers::admin::get_boards))
        // 댓글 관리
        .route("/api/admin/comments", get(handlers::admin::get_comments))
        .layer(from_fn_with_state(state.clone(), middleware::admin_middleware));

    // 라우터 결합
    let app = Router::new()
        .merge(public_routes)
        .merge(protected_routes)
        .merge(admin_routes)
        .layer(CorsLayer::permissive())
        .with_state(state);

    println!("Server running on port {}", port);
    
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port))
        .await
        .unwrap();
    axum::serve(listener, app)
        .await
        .unwrap();
}


