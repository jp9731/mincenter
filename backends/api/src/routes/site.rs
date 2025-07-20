use axum::{
    routing::{get, post, put, delete},
    Router,
};
use crate::handlers;
use crate::middleware;
use crate::AppState;

pub fn site_routes(state: AppState) -> Router<AppState> {
    let public_routes = Router::new()
        // 인증
        .route("/api/auth/login", post(handlers::auth::login))
        .route("/api/auth/register", post(handlers::auth::register))
        .route("/api/auth/refresh", post(handlers::auth::refresh))
        .route("/api/auth/logout", post(handlers::auth::logout))
        // Community
        .route("/api/community/boards", get(handlers::community::get_boards))
        .route("/api/community/posts", get(handlers::community::get_posts))
        .route("/api/community/posts/recent", get(handlers::community::get_recent_posts))
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
        .route("/api/upload/posts/chunk", post(handlers::upload::upload_post_file_chunk))
        .route("/api/upload/profiles", post(handlers::upload::upload_profile_file))
        .route("/api/upload/site", post(handlers::upload::upload_site_file))
        // 파일 다운로드
        .route("/api/upload/files/:file_id/download", get(handlers::upload::download_original_file))
        // 썸네일 상태 확인
        .route("/api/upload/files/:file_id/thumbnail-status", get(handlers::upload::check_thumbnail_status))
        .layer(axum::middleware::from_fn_with_state(state.clone(), middleware::optional_auth_middleware));

    let protected_routes = Router::new()
        // 인증된 사용자 API
        .route("/api/auth/me", get(handlers::auth::me))
        // Community (인증된 사용자)
        .route("/api/community/posts", post(handlers::community::create_post))
        .route("/api/community/posts/:id", put(handlers::community::update_post))
        .route("/api/community/posts/:id", delete(handlers::community::delete_post))
        .route("/api/community/comments", post(handlers::community::create_comment))
        .route("/api/community/comments/:id", put(handlers::community::update_comment))
        .route("/api/community/comments/:id", delete(handlers::community::delete_comment))
        .route("/api/community/boards/:slug/posts", post(handlers::community::create_post_by_slug))
        .route("/api/community/boards/:slug/replies", post(handlers::community::create_reply_by_slug))
        // 좋아요 API
        .route("/api/community/posts/:id/like", post(handlers::community::toggle_post_like))
        .route("/api/community/posts/:id/like/status", get(handlers::community::get_post_like_status))
        .route("/api/community/comments/:id/like", post(handlers::community::toggle_comment_like))
        .route("/api/community/comments/:id/like/status", get(handlers::community::get_comment_like_status))
        // 파일 삭제 API
        .route("/api/upload/files/:file_id", delete(handlers::upload::delete_file))
        .route("/api/community/posts/:post_id/attachments/:file_id", delete(handlers::upload::delete_post_attachment))
        .layer(axum::middleware::from_fn_with_state(state.clone(), middleware::auth_middleware));

    public_routes.merge(protected_routes)
}