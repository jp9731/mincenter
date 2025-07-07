use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use uuid::Uuid;
use crate::{
    models::response::ApiResponse,
    models::rbac::*,
    AppState,
};
use serde::Deserialize;

// 역할 목록 조회
pub async fn get_roles(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Role>>>, StatusCode> {
    let roles = sqlx::query_as::<_, Role>(
        "SELECT * FROM roles WHERE is_active = true ORDER BY name"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(roles, "역할 목록을 성공적으로 조회했습니다.")))
}

// 역할 상세 조회 (권한 포함)
pub async fn get_role(
    State(state): State<AppState>,
    Path(role_id): Path<Uuid>,
) -> Result<Json<ApiResponse<RoleDetail>>, StatusCode> {
    // 역할 조회
    let role = sqlx::query_as::<_, Role>(
        "SELECT * FROM roles WHERE id = $1"
    )
    .bind(role_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    // 역할의 권한 조회
    let permissions = sqlx::query_as::<_, Permission>(
        r#"
        SELECT p.* FROM permissions p
        INNER JOIN role_permissions rp ON p.id = rp.permission_id
        WHERE rp.role_id = $1 AND p.is_active = true
        ORDER BY p.resource, p.action
        "#
    )
    .bind(role_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let role_detail = RoleDetail {
        role,
        permissions,
    };

    Ok(Json(ApiResponse::success(role_detail, "역할 정보를 성공적으로 조회했습니다.")))
}

// 역할 생성
pub async fn create_role(
    State(state): State<AppState>,
    Json(payload): Json<CreateRoleRequest>,
) -> Result<Json<ApiResponse<RoleDetail>>, StatusCode> {
    let mut tx = state.pool.begin().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 역할 생성
    let role = sqlx::query_as::<_, Role>(
        r#"
        INSERT INTO roles (name, description)
        VALUES ($1, $2)
        RETURNING *
        "#
    )
    .bind(&payload.name)
    .bind(&payload.description)
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 권한 할당
    for permission_id in payload.permissions {
        sqlx::query(
            "INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)"
        )
        .bind(role.id)
        .bind(permission_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    }

    tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 생성된 역할의 상세 정보 조회
    let permissions = sqlx::query_as::<_, Permission>(
        r#"
        SELECT p.* FROM permissions p
        INNER JOIN role_permissions rp ON p.id = rp.permission_id
        WHERE rp.role_id = $1 AND p.is_active = true
        ORDER BY p.resource, p.action
        "#
    )
    .bind(role.id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let role_detail = RoleDetail {
        role,
        permissions,
    };

    Ok(Json(ApiResponse::success(role_detail, "역할이 성공적으로 생성되었습니다.")))
}

// 역할 수정
pub async fn update_role(
    State(state): State<AppState>,
    Path(role_id): Path<Uuid>,
    Json(payload): Json<UpdateRoleRequest>,
) -> Result<Json<ApiResponse<RoleDetail>>, StatusCode> {
    let mut tx = state.pool.begin().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 역할 정보 수정
    let role = sqlx::query_as::<_, Role>(
        r#"
        UPDATE roles SET
            name = COALESCE($1, name),
            description = $2,
            is_active = COALESCE($3, is_active),
            updated_at = NOW()
        WHERE id = $4
        RETURNING *
        "#
    )
    .bind(&payload.name)
    .bind(&payload.description)
    .bind(&payload.is_active)
    .bind(role_id)
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    // 권한 업데이트 (제공된 경우)
    if let Some(permissions) = payload.permissions {
        // 기존 권한 삭제
        sqlx::query("DELETE FROM role_permissions WHERE role_id = $1")
            .bind(role_id)
            .execute(&mut *tx)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        // 새로운 권한 할당
        for permission_id in permissions {
            sqlx::query(
                "INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)"
            )
            .bind(role_id)
            .bind(permission_id)
            .execute(&mut *tx)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        }
    }

    tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 수정된 역할의 상세 정보 조회
    let permissions = sqlx::query_as::<_, Permission>(
        r#"
        SELECT p.* FROM permissions p
        INNER JOIN role_permissions rp ON p.id = rp.permission_id
        WHERE rp.role_id = $1 AND p.is_active = true
        ORDER BY p.resource, p.action
        "#
    )
    .bind(role_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let role_detail = RoleDetail {
        role,
        permissions,
    };

    Ok(Json(ApiResponse::success(role_detail, "역할이 성공적으로 수정되었습니다.")))
}

// 역할 삭제
pub async fn delete_role(
    State(state): State<AppState>,
    Path(role_id): Path<Uuid>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 기본 역할은 삭제 불가
    let role = sqlx::query_as::<_, Role>(
        "SELECT * FROM roles WHERE id = $1"
    )
    .bind(role_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    if role.name == "super_admin" || role.name == "admin" {
        return Err(StatusCode::BAD_REQUEST);
    }

    // 역할 비활성화 (실제 삭제 대신)
    sqlx::query("UPDATE roles SET is_active = false WHERE id = $1")
        .bind(role_id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success((), "역할이 성공적으로 삭제되었습니다.")))
}

// 권한 목록 조회
pub async fn get_permissions(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Permission>>>, StatusCode> {
    let permissions = sqlx::query_as::<_, Permission>(
        "SELECT * FROM permissions WHERE is_active = true ORDER BY resource, action"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(permissions, "권한 목록을 성공적으로 조회했습니다.")))
}

// 권한 생성
#[derive(Debug, Deserialize)]
pub struct CreatePermissionRequest {
    pub name: String,
    pub description: Option<String>,
    pub resource: String,
    pub action: String,
}

pub async fn create_permission(
    State(state): State<AppState>,
    Json(payload): Json<CreatePermissionRequest>,
) -> Result<Json<ApiResponse<Permission>>, StatusCode> {
    let permission = sqlx::query_as::<_, Permission>(
        r#"
        INSERT INTO permissions (name, description, resource, action)
        VALUES ($1, $2, $3, $4)
        RETURNING *
        "#
    )
    .bind(&payload.name)
    .bind(&payload.description)
    .bind(&payload.resource)
    .bind(&payload.action)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(permission, "권한이 성공적으로 생성되었습니다.")))
}

// 권한 수정
#[derive(Debug, Deserialize)]
pub struct UpdatePermissionRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub resource: Option<String>,
    pub action: Option<String>,
    pub is_active: Option<bool>,
}

pub async fn update_permission(
    State(state): State<AppState>,
    Path(permission_id): Path<Uuid>,
    Json(payload): Json<UpdatePermissionRequest>,
) -> Result<Json<ApiResponse<Permission>>, StatusCode> {
    let permission = sqlx::query_as::<_, Permission>(
        r#"
        UPDATE permissions SET
            name = COALESCE($1, name),
            description = $2,
            resource = COALESCE($3, resource),
            action = COALESCE($4, action),
            is_active = COALESCE($5, is_active),
            updated_at = NOW()
        WHERE id = $6
        RETURNING *
        "#
    )
    .bind(&payload.name)
    .bind(&payload.description)
    .bind(&payload.resource)
    .bind(&payload.action)
    .bind(&payload.is_active)
    .bind(permission_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    Ok(Json(ApiResponse::success(permission, "권한이 성공적으로 수정되었습니다.")))
}

// 권한 삭제
pub async fn delete_permission(
    State(state): State<AppState>,
    Path(permission_id): Path<Uuid>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 기본 권한은 삭제 불가
    let permission = sqlx::query_as::<_, Permission>(
        "SELECT * FROM permissions WHERE id = $1"
    )
    .bind(permission_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    // 기본 권한들은 삭제 불가 (시스템 필수 권한)
    let protected_permissions = [
        "users.read", "boards.read", "posts.read", "comments.read", 
        "settings.read", "roles.read", "permissions.read"
    ];
    
    if protected_permissions.contains(&permission.name.as_str()) {
        return Err(StatusCode::BAD_REQUEST);
    }

    // 권한 비활성화 (실제 삭제 대신)
    sqlx::query("UPDATE permissions SET is_active = false WHERE id = $1")
        .bind(permission_id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success((), "권한이 성공적으로 삭제되었습니다.")))
}

// 사용자 권한 조회
pub async fn get_user_permissions(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<ApiResponse<UserPermissions>>, StatusCode> {
    // 사용자의 역할 조회
    let roles = sqlx::query_as::<_, Role>(
        r#"
        SELECT r.* FROM roles r
        INNER JOIN user_roles ur ON r.id = ur.role_id
        WHERE ur.user_id = $1 AND r.is_active = true
        ORDER BY r.name
        "#
    )
    .bind(user_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 사용자의 권한 조회
    let permissions = sqlx::query_as::<_, Permission>(
        r#"
        SELECT DISTINCT p.* FROM permissions p
        INNER JOIN role_permissions rp ON p.id = rp.permission_id
        INNER JOIN user_roles ur ON rp.role_id = ur.role_id
        WHERE ur.user_id = $1 AND p.is_active = true
        ORDER BY p.resource, p.action
        "#
    )
    .bind(user_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let user_permissions = UserPermissions {
        user_id,
        roles,
        permissions,
    };

    Ok(Json(ApiResponse::success(user_permissions, "사용자 권한을 성공적으로 조회했습니다.")))
}

// 사용자 역할 할당
pub async fn assign_user_roles(
    State(state): State<AppState>,
    Json(payload): Json<AssignUserRoleRequest>,
) -> Result<Json<ApiResponse<UserPermissions>>, StatusCode> {
    let mut tx = state.pool.begin().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 기존 역할 삭제
    sqlx::query("DELETE FROM user_roles WHERE user_id = $1")
        .bind(payload.user_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 새로운 역할 할당
    for role_id in payload.role_ids {
        sqlx::query(
            "INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)"
        )
        .bind(payload.user_id)
        .bind(role_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    }

    tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 할당된 사용자 권한 조회
    let roles = sqlx::query_as::<_, Role>(
        r#"
        SELECT r.* FROM roles r
        INNER JOIN user_roles ur ON r.id = ur.role_id
        WHERE ur.user_id = $1 AND r.is_active = true
        ORDER BY r.name
        "#
    )
    .bind(payload.user_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let permissions = sqlx::query_as::<_, Permission>(
        r#"
        SELECT DISTINCT p.* FROM permissions p
        INNER JOIN role_permissions rp ON p.id = rp.permission_id
        INNER JOIN user_roles ur ON rp.role_id = ur.role_id
        WHERE ur.user_id = $1 AND p.is_active = true
        ORDER BY p.resource, p.action
        "#
    )
    .bind(payload.user_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let user_permissions = UserPermissions {
        user_id: payload.user_id,
        roles,
        permissions,
    };

    Ok(Json(ApiResponse::success(user_permissions, "사용자 역할이 성공적으로 할당되었습니다.")))
}

// 권한 체크
pub async fn check_permission(
    State(state): State<AppState>,
    Json(payload): Json<CheckPermissionRequest>,
) -> Result<Json<ApiResponse<bool>>, StatusCode> {
    let has_permission = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM permissions p
            INNER JOIN role_permissions rp ON p.id = rp.permission_id
            INNER JOIN user_roles ur ON rp.role_id = ur.role_id
            WHERE ur.user_id = $1 
            AND p.resource = $2 
            AND p.action = $3 
            AND p.is_active = true
        )
        "#
    )
    .bind(payload.user_id)
    .bind(&payload.resource)
    .bind(&payload.action)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(has_permission, "권한 체크가 완료되었습니다.")))
} 