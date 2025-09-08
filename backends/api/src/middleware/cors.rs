// 이 파일은 이제 사용하지 않습니다. 
// CORS 처리는 main.rs의 cors_middleware에서 직접 처리합니다.

use tower_http::cors::{CorsLayer, Any};
use axum::http::Method;

/// 기본 tower-http CORS 레이어 (필요 시 사용)
pub fn tower_cors_layer() -> CorsLayer {
    CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE, Method::OPTIONS])
        .allow_headers([
            "authorization".parse().unwrap(),
            "content-type".parse().unwrap(),
            "x-requested-with".parse().unwrap(),
        ])
        .allow_credentials(false)
} 