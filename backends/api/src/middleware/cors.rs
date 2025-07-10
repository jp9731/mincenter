use axum::{
    extract::Request,
    http::{HeaderValue, Method},
    middleware::Next,
    response::Response,
};
use tower_http::cors::CorsLayer;

pub fn cors_middleware() -> CorsLayer {
    CorsLayer::new()
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE, Method::OPTIONS])
        .allow_headers([
            "authorization".parse().unwrap(),
            "content-type".parse().unwrap(),
            "x-requested-with".parse().unwrap(),
        ])
        .allow_credentials(true)
}

fn get_allowed_origins() -> Vec<String> {
    std::env::var("CORS_ALLOWED_ORIGINS")
        .unwrap_or_else(|_| "https://mincenter.kr,https://www.mincenter.kr,http://localhost:5173,http://localhost:3000".to_string())
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

pub async fn custom_cors_middleware(
    request: Request,
    next: Next,
) -> Response {
    let origin = request
        .headers()
        .get("origin")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("")
        .to_string();

    // request.method()를 미리 저장 (request가 이동되기 전에)
    let method = request.method().clone();

    // 허용된 도메인 목록
    let allowed_origins = get_allowed_origins();
    let is_allowed = allowed_origins.contains(&origin);

    let mut response = next.run(request).await;

    // 기존 CORS 헤더 제거 (중복 방지)
    response.headers_mut().remove("Access-Control-Allow-Origin");
    response.headers_mut().remove("Access-Control-Allow-Methods");
    response.headers_mut().remove("Access-Control-Allow-Headers");
    response.headers_mut().remove("Access-Control-Allow-Credentials");

    // 허용된 도메인에 대해서만 CORS 헤더 설정
    if is_allowed {
        response.headers_mut().insert(
            "Access-Control-Allow-Origin",
            HeaderValue::from_str(&origin).unwrap_or_else(|_| HeaderValue::from_static("")),
        );
    }

    // OPTIONS 요청에 대한 preflight 응답
    if method == Method::OPTIONS {
        response.headers_mut().insert(
            "Access-Control-Allow-Methods",
            HeaderValue::from_static("GET, POST, PUT, DELETE, OPTIONS"),
        );
        response.headers_mut().insert(
            "Access-Control-Allow-Headers",
            HeaderValue::from_static("authorization, content-type, x-requested-with"),
        );
        response.headers_mut().insert(
            "Access-Control-Allow-Credentials",
            HeaderValue::from_static("true"),
        );
    }

    response
} 