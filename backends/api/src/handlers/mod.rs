pub mod auth;
pub mod community;
pub mod admin;

use axum::{
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;

pub async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, Json(json!({ "status": "ok" })))
}