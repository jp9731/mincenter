use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: Option<String>,  // Option으로 변경
    pub name: Option<String>,   // Option으로 변경
    pub role: Option<String>,   // 역할 필드 추가
    #[serde(skip_serializing)]
    pub password_hash: Option<String>,  // Option으로 변경
    pub created_at: Option<DateTime<Utc>>,  // Option으로 변경
    pub updated_at: Option<DateTime<Utc>>,  // Option으로 변경
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AdminUser {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub role: String,
    pub permissions: Vec<String>,
    pub last_login: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
    pub service_type: Option<String>, // "site", "admin", "mobile" 등
}

#[derive(Debug, Deserialize)]
pub struct AdminLoginRequest {
    pub email: String,
    pub password: String,
    pub service_type: Option<String>, // "site", "admin", "mobile" 등
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub name: String,
    pub service_type: Option<String>, // "site", "admin", "mobile" 등
}

#[derive(Debug, Deserialize)]
pub struct RefreshRequest {
    pub refresh_token: String,
    pub service_type: Option<String>, // "site", "admin", "mobile" 등
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: User,
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,  // seconds
}

#[derive(Debug, Serialize)]
pub struct AdminAuthResponse {
    pub user: AdminUser,
    pub token: String,
}

#[derive(Debug, Serialize)]
pub struct RefreshResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}