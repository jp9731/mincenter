use axum::{
    routing::{get, post, put, delete},
    Router,
};
use crate::handlers;
use crate::middleware;
use crate::AppState;

pub fn admin_routes(state: AppState) -> Router<AppState> {
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
        .route("/api/admin/menus", post(handlers::menu::create_menu))
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
        // 사이트 설정
        .route("/api/admin/site/settings", get(handlers::admin::settings::get_site_settings))
        .route("/api/admin/site/settings", put(handlers::admin::settings::save_site_settings))
        .layer(axum::middleware::from_fn_with_state(state.clone(), middleware::admin_middleware));

    admin_auth_routes.merge(admin_protected_routes)
}