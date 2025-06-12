use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct User {
    pub id: Uuid,
    pub email: Option<String>,  // Option으로 변경
    pub name: Option<String>,   // Option으로 변경
    #[serde(skip_serializing)]
    pub password_hash: Option<String>,  // Option으로 변경
    pub created_at: Option<DateTime<Utc>>,  // Option으로 변경
    pub updated_at: Option<DateTime<Utc>>,  // Option으로 변경
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub name: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: User,
    pub token: String,
}