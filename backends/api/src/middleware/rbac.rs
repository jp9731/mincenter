use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::Response,
};
use crate::{AppState, utils::auth::Claims, models::User, errors::ApiError};

// 권한 체크 미들웨어
pub async fn check_permission_middleware(
    State(state): State<AppState>,
    claims: Claims,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let path = request.uri().path();
    let method = request.method().as_str();
    
    // 리소스와 액션 매핑
    let (resource, action) = map_path_to_permission(path, method);
    
    // 권한 체크
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
    .bind(claims.sub)
    .bind(resource)
    .bind(action)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if !has_permission {
        return Err(StatusCode::FORBIDDEN);
    }

    Ok(next.run(request).await)
}

// 경로와 HTTP 메서드를 권한 리소스/액션으로 매핑
fn map_path_to_permission(path: &str, method: &str) -> (&'static str, &'static str) {
    match (path, method) {
        // 사용자 관리
        (path, "GET") if path.starts_with("/api/admin/users") => ("users", "read"),
        (path, "POST") if path.starts_with("/api/admin/users") => ("users", "create"),
        (path, "PUT") if path.starts_with("/api/admin/users") => ("users", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/users") => ("users", "delete"),
        
        // 게시판 관리
        (path, "GET") if path.starts_with("/api/admin/boards") => ("boards", "read"),
        (path, "POST") if path.starts_with("/api/admin/boards") => ("boards", "create"),
        (path, "PUT") if path.starts_with("/api/admin/boards") => ("boards", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/boards") => ("boards", "delete"),
        
        // 게시글 관리
        (path, "GET") if path.starts_with("/api/admin/posts") => ("posts", "read"),
        (path, "POST") if path.starts_with("/api/admin/posts") => ("posts", "create"),
        (path, "PUT") if path.starts_with("/api/admin/posts") => ("posts", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/posts") => ("posts", "delete"),
        
        // 댓글 관리
        (path, "GET") if path.starts_with("/api/admin/comments") => ("comments", "read"),
        (path, "POST") if path.starts_with("/api/admin/comments") => ("comments", "create"),
        (path, "PUT") if path.starts_with("/api/admin/comments") => ("comments", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/comments") => ("comments", "delete"),
        
        // 사이트 설정
        (path, "GET") if path.starts_with("/api/admin/site/settings") => ("settings", "read"),
        (path, "PUT") if path.starts_with("/api/admin/site/settings") => ("settings", "update"),
        
        // 메뉴 관리
        (path, "GET") if path.starts_with("/api/admin/menus") => ("menus", "read"),
        (path, "POST") if path.starts_with("/api/admin/menus") => ("menus", "create"),
        (path, "PUT") if path.starts_with("/api/admin/menus") => ("menus", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/menus") => ("menus", "delete"),
        
        // 페이지 관리
        (path, "GET") if path.starts_with("/api/admin/pages") => ("pages", "read"),
        (path, "POST") if path.starts_with("/api/admin/pages") => ("pages", "create"),
        (path, "PUT") if path.starts_with("/api/admin/pages") => ("pages", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/pages") => ("pages", "delete"),
        
        // 일정 관리
        (path, "GET") if path.starts_with("/api/admin/calendar") => ("calendar", "read"),
        (path, "POST") if path.starts_with("/api/admin/calendar") => ("calendar", "create"),
        (path, "PUT") if path.starts_with("/api/admin/calendar") => ("calendar", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/calendar") => ("calendar", "delete"),
        
        // 역할 관리
        (path, "GET") if path.starts_with("/api/admin/roles") => ("roles", "read"),
        (path, "POST") if path.starts_with("/api/admin/roles") => ("roles", "create"),
        (path, "PUT") if path.starts_with("/api/admin/roles") => ("roles", "update"),
        (path, "DELETE") if path.starts_with("/api/admin/roles") => ("roles", "delete"),
        
        // 권한 관리
        (path, "GET") if path.starts_with("/api/admin/permissions") => ("permissions", "read"),
        (path, "POST") if path.starts_with("/api/admin/check-permission") => ("permissions", "assign"),
        
        // 기본값: 읽기 권한
        _ => ("general", "read"),
    }
}

// 특정 권한이 필요한 미들웨어 팩토리
pub fn require_permission(resource: &'static str, action: &'static str) -> impl Fn(State<AppState>, Claims, Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, StatusCode>> + Send>> {
    move |state: State<AppState>, claims: Claims, request: Request, next: Next| {
        let state_clone = state.clone();
        let resource_clone = resource;
        let action_clone = action;
        
        Box::pin(async move {
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
            .bind(claims.sub)
            .bind(resource_clone)
            .bind(action_clone)
            .fetch_one(&state_clone.pool)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            if !has_permission {
                return Err(StatusCode::FORBIDDEN);
            }

            Ok(next.run(request).await)
        })
    }
}

/// 간단한 역할 기반 권한 체크 함수
pub fn require_role(user: &User, required_role: &str) -> Result<(), ApiError> {
    match &user.role {
        Some(role) if role.to_string().to_lowercase() == required_role.to_lowercase() => Ok(()),
        _ => Err(ApiError::Forbidden("관리자 권한이 필요합니다.".to_string()))
    }
} 