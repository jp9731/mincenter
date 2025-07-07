use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

// 역할
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Role {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// 권한
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Permission {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub resource: String,
    pub action: String,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// 역할-권한 매핑
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct RolePermission {
    pub id: Uuid,
    pub role_id: Uuid,
    pub permission_id: Uuid,
    pub created_at: DateTime<Utc>,
}

// 사용자-역할 매핑
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct UserRole {
    pub id: Uuid,
    pub user_id: Uuid,
    pub role_id: Uuid,
    pub created_at: DateTime<Utc>,
}

// 역할 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreateRoleRequest {
    pub name: String,
    pub description: Option<String>,
    pub permissions: Vec<Uuid>, // 권한 ID 목록
}

// 역할 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdateRoleRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub is_active: Option<bool>,
    pub permissions: Option<Vec<Uuid>>, // 권한 ID 목록
}

// 사용자 역할 할당 요청
#[derive(Debug, Deserialize)]
pub struct AssignUserRoleRequest {
    pub user_id: Uuid,
    pub role_ids: Vec<Uuid>, // 역할 ID 목록
}

// 사용자 권한 정보
#[derive(Debug, Serialize)]
pub struct UserPermissions {
    pub user_id: Uuid,
    pub roles: Vec<Role>,
    pub permissions: Vec<Permission>,
}

// 역할 상세 정보 (권한 포함)
#[derive(Debug, Serialize)]
pub struct RoleDetail {
    pub role: Role,
    pub permissions: Vec<Permission>,
}

// 권한 체크 요청
#[derive(Debug, Deserialize)]
pub struct CheckPermissionRequest {
    pub user_id: Uuid,
    pub resource: String,
    pub action: String,
} 