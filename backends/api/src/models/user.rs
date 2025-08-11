use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: Option<String>,  // Option으로 변경
    pub name: Option<String>,   // Option으로 변경
    pub phone: Option<String>,
    pub profile_image: Option<String>,
    pub points: Option<i32>,
    pub role: Option<UserRole>,   // user_role enum 타입으로 변경
    pub status: Option<UserStatus>,
    #[serde(skip_serializing)]
    pub password_hash: Option<String>,  // Option으로 변경
    pub email_verified: Option<bool>,
    pub email_verified_at: Option<DateTime<Utc>>,
    pub last_login_at: Option<DateTime<Utc>>,
    pub created_at: Option<DateTime<Utc>>,  // Option으로 변경
    pub updated_at: Option<DateTime<Utc>>,  // Option으로 변경
}

#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type, PartialEq)]
#[sqlx(type_name = "user_role", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum UserRole {
    User,
    Admin,
}

impl std::fmt::Display for UserRole {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserRole::User => write!(f, "user"),
            UserRole::Admin => write!(f, "admin"),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, sqlx::Type)]
#[sqlx(type_name = "user_status", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum UserStatus {
    Active,
    Inactive,
    Suspended,
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
    pub access_token: String,
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct RefreshResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}