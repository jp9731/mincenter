mod config;
mod database;
mod errors;
mod handlers;
mod middleware;
mod models;
mod services;
mod utils;

use axum::{
    extract::{Path, Query, State, Extension},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post, put, delete},
    Json, Router,
};
use std::collections::HashMap;
use tower_http::cors::CorsLayer;
use tower_http::services::fs::ServeDir;
use tracing::{info, error, warn};
use crate::config::Config;
use redis::Client as RedisClient;
use sqlx::PgPool;
use crate::handlers::admin::settings;
use crate::handlers::admin::rbac;

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
    
    // 로깅 초기화
    tracing_subscriber::fmt::init();
    
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let port: u16 = port.parse().expect("PORT must be a number");
    
    // 데이터베이스 연결
    let pool = crate::database::get_database().await.expect("Failed to connect to database");
    
    // Redis 연결
    let redis_url = std::env::var("REDIS_URL").unwrap_or_else(|_| "redis://localhost:6379".to_string());
    let redis = RedisClient::open(redis_url).expect("Failed to connect to Redis");
    
    // 설정 로드
    let config = Config::from_env();
    
    let state = AppState {
        pool,
        config,
        redis,
    };

    // 공개 라우터 (인증 불필요)
    let public_routes = Router::new()
        .route("/api/health", get(handlers::health_check))
        // 인증
        .route("/api/auth/login", post(handlers::auth::login))
        .route("/api/auth/register", post(handlers::auth::register))
        .route("/api/auth/refresh", post(handlers::auth::refresh))
        // Community
        .route("/api/community/boards", get(handlers::community::get_boards))
        .route("/api/community/posts", get(handlers::community::get_posts))
        .route("/api/community/posts/recent", get(handlers::community::get_recent_posts))
        //.route("/api/community/boards/:id/posts", get(handlers::community::get_posts))
        .route("/api/community/posts/:id", get(handlers::community::get_post))
        .route("/api/community/posts/:id/comments", get(handlers::community::get_comments))
        .route("/api/community/boards/:slug", get(handlers::community::get_board_by_slug))
        .route("/api/community/boards/:slug/posts", get(handlers::community::get_posts_by_slug))
        .route("/api/community/boards/:slug/categories", get(handlers::community::get_categories_by_slug))
        // Pages (공개)
        .route("/api/pages", get(handlers::page::get_published_pages))
        .route("/api/pages/:slug", get(handlers::page::get_page_by_slug))
        // 사이트 메뉴 (공개)
        .route("/api/site/menus", get(handlers::menu::get_site_menus))
        // 공개 일정 (사이트용)
        .route("/api/calendar/events", get(handlers::calendar::get_public_events))
        // 파일 업로드
        .route("/api/upload/posts", post(handlers::upload::upload_post_file))
        .route("/api/upload/profiles", post(handlers::upload::upload_profile_file))
        .route("/api/upload/site", post(handlers::upload::upload_site_file))
        .layer(axum::middleware::from_fn_with_state(state.clone(), middleware::optional_auth_middleware));

    // 보호된 라우터 (인증 필요)
    let protected_routes = Router::new()
        .route("/api/auth/me", get(handlers::auth::me))
        // Community (인증된 사용자)
        .route("/api/community/posts", post(handlers::community::create_post))
        .route("/api/community/posts/:id", put(handlers::community::update_post))
        .route("/api/community/posts/:id", delete(handlers::community::delete_post))
        .route("/api/community/comments", post(handlers::community::create_comment))
        .route("/api/community/comments/:id", put(handlers::community::update_comment))
        .route("/api/community/comments/:id", delete(handlers::community::delete_comment))
        .route("/api/community/boards/:slug/posts", post(handlers::community::create_post_by_slug))
        // 좋아요 API
        .route("/api/community/posts/:id/like", post(handlers::community::toggle_post_like))
        .route("/api/community/posts/:id/like/status", get(handlers::community::get_post_like_status))
        .route("/api/community/comments/:id/like", post(handlers::community::toggle_comment_like))
        .route("/api/community/comments/:id/like/status", get(handlers::community::get_comment_like_status))
        // 파일 삭제 API
        .route("/api/upload/files/:file_id", delete(handlers::upload::delete_file))
        .route("/api/community/posts/:post_id/attachments/:file_id", delete(handlers::upload::delete_post_attachment))
        .layer(axum::middleware::from_fn_with_state(state.clone(), middleware::auth_middleware));

    // 관리자 인증 라우터 (미들웨어 적용 안함)
    let admin_auth_routes = Router::new()
        .route("/api/admin/login", post(handlers::admin::admin_login))
        .route("/api/admin/refresh", post(handlers::admin::admin_refresh));

    // 관리자 보호 라우터 (미들웨어 적용)
    let admin_protected_routes = Router::new()
        // 관리자 로그아웃
        .route("/api/admin/logout", post(handlers::admin::admin_logout))
        // 관리자 프로필
        .route("/api/admin/me", get(handlers::admin::admin_me))
        // 대시보드
        .route("/api/admin/dashboard/stats", get(handlers::admin::get_dashboard_stats))
        // 사용자 관리
        .route("/api/admin/users", get(handlers::admin::get_users))
        .route("/api/admin/users/:id", get(handlers::admin::get_user))
        .route("/api/admin/users/:id", put(handlers::admin::update_user))
        // 게시글 관리
        .route("/api/admin/posts", get(handlers::admin::get_posts))
        .route("/api/admin/posts/:id", get(handlers::admin::get_post))
        .route("/api/admin/posts/:id", put(handlers::admin::update_post))
        // 게시판 관리
        .route("/api/admin/boards", get(handlers::board::list_boards))
        .route("/api/admin/boards", post(handlers::board::create_board))
        .route("/api/admin/boards/:id", get(handlers::board::get_board))
        .route("/api/admin/boards/:id", put(handlers::board::update_board))
        .route("/api/admin/boards/:id", delete(handlers::board::delete_board))
        .route("/api/admin/boards/:id/categories", get(handlers::board::list_categories))
        .route("/api/admin/boards/:id/categories", post(handlers::board::create_category))
        .route("/api/admin/boards/:id/categories/:category_id", put(handlers::board::update_category))
        .route("/api/admin/boards/:id/categories/:category_id", delete(handlers::board::delete_category))
        // 댓글 관리
        .route("/api/admin/comments", get(handlers::admin::get_comments))
        // 메뉴 관리
        .route("/api/admin/menus", get(handlers::menu::get_menus))
        .route("/api/admin/menus", put(handlers::menu::update_menus))
        // 페이지 관리
        .route("/api/admin/pages", get(handlers::page::get_pages))
        .route("/api/admin/pages", post(handlers::page::create_page))
        .route("/api/admin/pages/:id", get(handlers::page::get_page))
        .route("/api/admin/pages/:id", put(handlers::page::update_page))
        .route("/api/admin/pages/:id", delete(handlers::page::delete_page))
        .route("/api/admin/pages/:id/status", put(handlers::page::update_page_status))
        // 일정 관리
        .route("/api/admin/calendar/events", get(handlers::calendar::get_events))
        .route("/api/admin/calendar/events", post(handlers::calendar::create_event))
        .route("/api/admin/calendar/events/:id", put(handlers::calendar::update_event))
        .route("/api/admin/calendar/events/:id", delete(handlers::calendar::delete_event))
        // 사이트 설정 관리
        .route("/api/admin/site/settings", get(settings::get_site_settings))
        .route("/api/admin/site/settings", put(settings::save_site_settings))
        // RBAC 관리
        .route("/api/admin/roles", get(rbac::get_roles))
        .route("/api/admin/roles", post(rbac::create_role))
        .route("/api/admin/roles/:id", get(rbac::get_role))
        .route("/api/admin/roles/:id", put(rbac::update_role))
        .route("/api/admin/roles/:id", delete(rbac::delete_role))
        .route("/api/admin/permissions", get(rbac::get_permissions))
        .route("/api/admin/permissions", post(rbac::create_permission))
        .route("/api/admin/permissions/:id", put(rbac::update_permission))
        .route("/api/admin/permissions/:id", delete(rbac::delete_permission))
        .route("/api/admin/users/:id/permissions", get(rbac::get_user_permissions))
        .route("/api/admin/users/:id/roles", put(rbac::assign_user_roles))
        .route("/api/admin/check-permission", post(rbac::check_permission))
        .layer(axum::middleware::from_fn_with_state(state.clone(), middleware::admin_middleware));

    // 라우터 결합
    let app = Router::new()
        .merge(public_routes)
        .merge(protected_routes)
        .merge(admin_auth_routes)
        .merge(admin_protected_routes)
        // 정적 파일 서빙
        .nest_service("/uploads", ServeDir::new("static/uploads"))
        .layer(CorsLayer::permissive())
        .with_state(state);

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


