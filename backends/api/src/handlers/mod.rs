use axum::response::IntoResponse;

pub mod site;
pub mod admin;

// Site handlers
pub use site::auth;
pub use site::community;
pub use site::menu;
pub use site::page;
pub use site::upload;
pub use site::calendar;

// Admin handlers
pub use admin::board;

pub async fn health_check() -> impl IntoResponse {
    "OK"
}