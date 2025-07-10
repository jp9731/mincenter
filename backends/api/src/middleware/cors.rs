use axum::{
    extract::Request,
    http::{HeaderValue, Method},
    middleware::Next,
    response::Response,
};
use tower_http::cors::CorsLayer;

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
        ])
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE, Method::OPTIONS])
        .allow_headers([
            "authorization".parse().unwrap(),
            "content-type".parse().unwrap(),
            "x-requested-with".parse().unwrap(),
        ])
        .allow_credentials(true)
}

pub async fn custom_cors_middleware(
    request: Request,
    next: Next,
) -> Response {
    // Origin 헤더와 경로를 먼저 추출
    let origin = request
        .headers()
        .get("origin")
        .and_then(|h| h.to_str().ok())
        .unwrap_or("")
        .to_string();
    
    let path = request.uri().path().to_string();

    // 요청 처리
    let mut response = next.run(request).await;

    // 요청 경로에 따라 CORS 정책 결정
    let allowed_origins = if path.starts_with("/api/admin") {
        // Admin API: admin.mincenter.kr만 허용
        vec![
            "http://admin.mincenter.kr",
            "https://admin.mincenter.kr",
            "http://localhost:13000",
        ]
    } else {
        // Site API: mincenter.kr, www.mincenter.kr 허용
        vec![
            "http://mincenter.kr",
            "https://mincenter.kr",
            "http://www.mincenter.kr",
            "https://www.mincenter.kr",
            "http://localhost:3000",
            "http://localhost:3001",
        ]
    };

    // Origin이 허용된 목록에 있는지 확인
    let is_allowed = allowed_origins.contains(&origin.as_str());

    // CORS 헤더 설정
    if is_allowed {
        response.headers_mut().insert(
            "Access-Control-Allow-Origin",
            HeaderValue::from_str(&origin).unwrap_or_else(|_| HeaderValue::from_static("")),
        );
    } else {
        // 허용되지 않은 Origin인 경우 빈 값 설정
        response.headers_mut().insert(
            "Access-Control-Allow-Origin",
            HeaderValue::from_static(""),
        );
    }

    // 공통 CORS 헤더
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

    response
} 