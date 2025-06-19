use tower_http::cors::CorsLayer;
use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
    http::StatusCode,
    Json,
};
use crate::{
    models::response::ApiResponse,
    models::user::User,
    utils::auth::verify_token,
    config::Config,
    AppState,
};
use axum::extract::State;

pub fn cors() -> CorsLayer {
    CorsLayer::new()
        .allow_origin(tower_http::cors::Any)
        .allow_methods(tower_http::cors::Any)
        .allow_headers(tower_http::cors::Any)
}

pub async fn auth_middleware(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, (StatusCode, Json<ApiResponse<()>>)> {
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|auth_header| auth_header.to_str().ok())
        .and_then(|auth_str| auth_str.strip_prefix("Bearer "));

    let token = auth_header.ok_or((
        StatusCode::UNAUTHORIZED,
        Json(ApiResponse::error("Missing authorization header")),
    ))?;

    let claims = verify_token(token, &state.config).map_err(|_| {
        (
            StatusCode::UNAUTHORIZED,
            Json(ApiResponse::error("Invalid token")),
        )
    })?;

    // 사용자 정보를 데이터베이스에서 가져오기
    let user = sqlx::query_as::<_, User>(
        "SELECT id, email, name, role::text, password_hash, created_at, updated_at FROM users WHERE id = $1"
    )
    .bind(claims.sub)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to fetch user")),
    ))?
    .ok_or((
        StatusCode::UNAUTHORIZED,
        Json(ApiResponse::error("User not found")),
    ))?;

    // 사용자 정보를 request extensions에 추가
    let mut request = request;
    request.extensions_mut().insert(user);

    Ok(next.run(request).await)
}