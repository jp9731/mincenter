use axum::{
    extract::Request,
    http::{HeaderValue, Method, StatusCode},
    middleware::Next,
    response::Response,
};
use tower_http::cors::CorsLayer;
use std::collections::HashMap;

pub fn cors_middleware() -> CorsLayer {
    CorsLayer::new()
        .allow_origin([
            // Site API용 도메인 (site 핸들러)
            "http://mincenter.kr".parse().unwrap(),
            "https://mincenter.kr".parse().unwrap(),
            "http://www.mincenter.kr".parse().unwrap(),
            "https://www.mincenter.kr".parse().unwrap(),
            // Admin API용 도메인 (admin 핸들러)
            "http://admin.mincenter.kr".parse().unwrap(),
            "https://admin.mincenter.kr".parse().unwrap(),
            // 개발용 도메인
            "http://localhost:3000".parse().unwrap(),
            "http://localhost:3001".parse().unwrap(),
            "http://localhost:13000".parse().unwrap(),
            "http://localhost:13001".parse().unwrap(),
        ])
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE, Method::OPTIONS])
        .allow_headers([
            axum::http::header::AUTHORIZATION,
            axum::http::header::CONTENT_TYPE,
        ])
        .allow_credentials(true)
}

pub async fn custom_cors_middleware(
    request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let mut response = next.run(request).await;
    
    // Origin 헤더 가져오기
    let origin = request
        .headers()
        .get("origin")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("");
    
    // 요청 경로에 따라 다른 CORS 정책 적용
    let path = request.uri().path();
    
    if path.starts_with("/api/admin") {
        // Admin API: admin.mincenter.kr만 허용
        if origin.contains("admin.mincenter.kr") || origin.contains("localhost") {
            response.headers_mut().insert(
                "Access-Control-Allow-Origin",
                HeaderValue::from_static(origin),
            );
        }
    } else if path.starts_with("/api/site") || path.starts_with("/api/community") || path.starts_with("/api/auth") {
        // Site API: mincenter.kr, www.mincenter.kr만 허용
        if origin.contains("mincenter.kr") && !origin.contains("admin.mincenter.kr") || origin.contains("localhost") {
            response.headers_mut().insert(
                "Access-Control-Allow-Origin",
                HeaderValue::from_static(origin),
            );
        }
    } else {
        // 기타 API: 모든 허용된 도메인
        if origin.contains("mincenter.kr") || origin.contains("localhost") {
            response.headers_mut().insert(
                "Access-Control-Allow-Origin",
                HeaderValue::from_static(origin),
            );
        }
    }
    
    // 공통 CORS 헤더
    response.headers_mut().insert(
        "Access-Control-Allow-Methods",
        HeaderValue::from_static("GET, POST, PUT, DELETE, OPTIONS"),
    );
    response.headers_mut().insert(
        "Access-Control-Allow-Headers",
        HeaderValue::from_static("Content-Type, Authorization"),
    );
    response.headers_mut().insert(
        "Access-Control-Allow-Credentials",
        HeaderValue::from_static("true"),
    );
    
    Ok(response)
} 