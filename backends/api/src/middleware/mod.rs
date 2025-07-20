use tower_http::cors::CorsLayer;
use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
    http::StatusCode,
};
use crate::{
    utils::auth::{verify_token, Claims},
    AppState,
};
use axum::extract::State;
use tracing::{info, error, debug};

pub mod rbac;
pub mod cors;

pub use rbac::*;
pub use cors::*;

pub async fn optional_auth_middleware(
    State(state): State<AppState>,
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // Authorization 헤더에서 토큰 추출 (선택적)
    let auth_header = request
        .headers()
        .get("Authorization")
        .and_then(|header| header.to_str().ok())
        .and_then(|header| header.strip_prefix("Bearer "));

    let claims: Option<Claims> = if let Some(token) = auth_header {
        // 토큰이 있으면 검증
        match verify_token(token, &state.config) {
            Ok(claims) => Some(claims),
            Err(_) => None, // 토큰이 유효하지 않으면 None
        }
    } else {
        None // 토큰이 없으면 None
    };

    // 요청에 사용자 정보 추가 (None일 수도 있음)
    let mut request = request;
    request.extensions_mut().insert(claims);

    Ok(next.run(request).await)
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

    eprintln!("🔐 인증 미들웨어 - Authorization 헤더: {:?}", auth_header);
    
    let token = auth_header.ok_or_else(|| {
        eprintln!("❌ 토큰 없음");
        StatusCode::UNAUTHORIZED
    })?;

    eprintln!("🔐 토큰 추출 성공, 길이: {}", token.len());

    // 토큰 검증
    let claims = verify_token(token, &state.config)
        .map_err(|e| {
            eprintln!("❌ 토큰 검증 실패: {:?}", e);
            StatusCode::UNAUTHORIZED
        })?;

    eprintln!("✅ 토큰 검증 성공, 사용자 ID: {}", claims.sub);

    // 요청에 사용자 정보 추가
    let mut request = request;
    request.extensions_mut().insert(Some(claims));

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