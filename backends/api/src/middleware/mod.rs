use tower_http::cors::CorsLayer;
use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
    http::StatusCode,
};
use crate::{
    utils::auth::verify_token,
    AppState,
};
use axum::extract::State;
use tracing::{info, error, debug};

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
) -> Result<Response, StatusCode> {
    // Authorization 헤더에서 토큰 추출
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|header| header.to_str().ok())
        .and_then(|header| header.strip_prefix("Bearer "));

    let token = auth_header.ok_or(StatusCode::UNAUTHORIZED)?;

    // 토큰 검증
    let claims = verify_token(token, &state.config)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // 요청에 사용자 정보 추가
    let mut request = request;
    request.extensions_mut().insert(claims);

    Ok(next.run(request).await)
}

pub async fn admin_middleware(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // Authorization 헤더에서 토큰 추출
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|header| header.to_str().ok())
        .and_then(|header| header.strip_prefix("Bearer "));

    let token = auth_header.ok_or(StatusCode::UNAUTHORIZED)?;

    // 토큰 검증
    let claims = verify_token(token, &state.config)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    // 요청에 사용자 정보 추가
    let mut request = request;
    request.extensions_mut().insert(claims);

    Ok(next.run(request).await)
}