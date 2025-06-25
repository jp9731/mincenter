use axum::response::IntoResponse;

pub mod admin;
pub mod auth;
pub mod community;
pub mod menu;
pub mod page;
pub mod upload;
pub mod calendar;

pub use admin::*;
pub use auth::*;
pub use community::*;
pub use menu::*;
pub use page::*;
pub use upload::*;
pub use calendar::*;

pub async fn health_check() -> impl IntoResponse {
    "OK"
}