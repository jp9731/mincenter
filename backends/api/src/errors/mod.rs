use axum::{
  response::{IntoResponse, Response},
  http::StatusCode,
  Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ApiError {
  #[error("Authentication error: {0}")]
  Authentication(String),
  
  #[error("Authorization error: {0}")]
  Authorization(String),
  
  #[error("Validation error: {0}")]
  Validation(String),
  
  #[error("Database error: {0}")]
  Database(#[from] sqlx::Error),
  
  #[error("Not found: {0}")]
  NotFound(String),
  
  #[error("Internal server error: {0}")]
  Internal(String),
}

impl IntoResponse for ApiError {
  fn into_response(self) -> Response {
      let (status, error_message) = match self {
          ApiError::Authentication(msg) => (StatusCode::UNAUTHORIZED, msg),
          ApiError::Authorization(msg) => (StatusCode::FORBIDDEN, msg),
          ApiError::Validation(msg) => (StatusCode::BAD_REQUEST, msg),
          ApiError::NotFound(msg) => (StatusCode::NOT_FOUND, msg),
          ApiError::Database(e) => (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()),
          ApiError::Internal(msg) => (StatusCode::INTERNAL_SERVER_ERROR, msg),
      };

      let body = Json(json!({
          "success": false,
          "error": {
              "message": error_message,
          }
      }));

      (status, body).into_response()
  }
}