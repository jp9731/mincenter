use axum::response::IntoResponse;

pub mod site;
pub mod admin;

// Site handlers
pub use site::auth;
pub use site::community;
pub use site::menu as site_menu;
pub use site::page;
pub use site::upload;
pub use site::calendar;
pub use site::site_info;

// Admin handlers
pub use admin::board;
pub use admin::menu as admin_menu;
pub use admin::upload as admin_upload;

pub async fn health_check() -> impl IntoResponse {
    "OK"
}