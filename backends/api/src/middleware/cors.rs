use axum::{
    extract::Request,
    http::{HeaderValue, Method},
    middleware::Next,
    response::Response,
};
use tower_http::cors::CorsLayer;
use tracing::{info, warn, debug};

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

/// 환경변수에서 허용된 CORS 도메인 목록을 가져옵니다.
/// CORS_ALLOWED_ORIGINS 환경변수가 설정되어 있지 않으면 기본값을 사용합니다.
fn get_allowed_origins() -> Vec<String> {
    let default_origins = "https://mincenter.kr,https://www.mincenter.kr,http://localhost:5173,http://localhost:5174,http://localhost:3000";
    
    std::env::var("CORS_ALLOWED_ORIGINS")
        .unwrap_or_else(|_| default_origins.to_string())
        .split(',')
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect()
}

/// 요청의 Origin 헤더에서 도메인을 추출합니다.
fn extract_domain_from_origin(origin: &str) -> Option<String> {
    if origin.is_empty() {
        return None;
    }
    
    // URL에서 도메인 부분만 추출
    if let Some(domain) = origin.strip_prefix("https://") {
        Some(domain.to_string())
    } else if let Some(domain) = origin.strip_prefix("http://") {
        Some(domain.to_string())
    } else {
        None
    }
}

/// 도메인이 허용된 목록에 있는지 확인합니다.
fn is_domain_allowed(origin: &str, allowed_origins: &[String]) -> bool {
    if origin.is_empty() {
        return false;
    }
    
    // 정확한 매칭 확인
    if allowed_origins.contains(&origin.to_string()) {
        return true;
    }
    
    // 도메인만 추출해서 확인 (포트 제외)
    if let Some(domain) = extract_domain_from_origin(origin) {
        // 포트가 있는 경우 제거
        let domain_without_port = domain.split(':').next().unwrap_or(&domain);
        
        // 허용된 도메인 목록에서 포트 없는 버전과 비교
        for allowed in allowed_origins {
            if let Some(allowed_domain) = extract_domain_from_origin(allowed) {
                let allowed_without_port = allowed_domain.split(':').next().unwrap_or(&allowed_domain);
                if domain_without_port == allowed_without_port {
                    return true;
                }
            }
        }
    }
    
    false
}

/// 모든 CORS 관련 헤더를 제거합니다.
fn remove_all_cors_headers(response: &mut Response) {
    let headers = response.headers_mut();
    
    // 모든 CORS 헤더 제거 (대소문자 구분 없이)
    let cors_headers = [
        "Access-Control-Allow-Origin",
        "Access-Control-Allow-Methods",
        "Access-Control-Allow-Headers",
        "Access-Control-Allow-Credentials",
        "Access-Control-Expose-Headers",
        "Access-Control-Max-Age",
        "access-control-allow-origin",
        "access-control-allow-methods",
        "access-control-allow-headers",
        "access-control-allow-credentials",
        "access-control-expose-headers",
        "access-control-max-age",
    ];
    
    for header_name in &cors_headers {
        headers.remove(*header_name);
    }
    
    // 디버깅: 제거된 헤더들 로그
    debug!("모든 CORS 헤더 제거 완료");
}

/// 응답 헤더를 로깅합니다.
fn log_response_headers(response: &Response, origin: &str) {
    let headers = response.headers();
    
    // CORS 관련 헤더만 필터링하여 로그
    let cors_headers = headers
        .iter()
        .filter(|(name, _)| {
            let name_lower = name.as_str().to_lowercase();
            name_lower.contains("access-control")
        })
        .collect::<Vec<_>>();
    
    if !cors_headers.is_empty() {
        warn!("⚠️  CORS 헤더 발견: {:?}", cors_headers);
        warn!("⚠️  Origin: {}", origin);
    } else {
        debug!("✅ CORS 헤더 없음");
    }
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

    // 허용된 도메인 목록 가져오기
    let allowed_origins = get_allowed_origins();
    
    // 도메인 허용 여부 확인
    let is_allowed = is_domain_allowed(&origin, &allowed_origins);
    
    // 로깅: 접근 시도와 결과 기록
    if !origin.is_empty() {
        if is_allowed {
            info!("CORS 허용: {} -> 허용됨", origin);
        } else {
            warn!("CORS 거부: {} -> 허용되지 않은 도메인 (허용된 도메인: {:?})", origin, allowed_origins);
        }
    }

    // OPTIONS preflight 요청 처리
    if method == Method::OPTIONS {
        info!("OPTIONS preflight 요청 처리: {}", request.uri());
        
        let mut response = Response::new(axum::body::Body::empty());
        let headers = response.headers_mut();
        
        // 허용된 도메인에 대해서만 CORS 헤더 설정
        if is_allowed {
            headers.insert(
                "Access-Control-Allow-Origin",
                HeaderValue::from_str(&origin).unwrap_or_else(|_| HeaderValue::from_static("")),
            );
        }
        
        headers.insert(
            "Access-Control-Allow-Methods",
            HeaderValue::from_static("GET, POST, PUT, DELETE, OPTIONS"),
        );
        headers.insert(
            "Access-Control-Allow-Headers",
            HeaderValue::from_static("authorization, content-type, x-requested-with"),
        );
        headers.insert(
            "Access-Control-Allow-Credentials",
            HeaderValue::from_static("true"),
        );
        headers.insert(
            "Access-Control-Max-Age",
            HeaderValue::from_static("1728000"),
        );
        
        info!("✅ OPTIONS preflight 응답 생성 완료");
        return response;
    }

    let mut response = next.run(request).await;

    // 디버깅: 기존 응답 헤더 로깅
    log_response_headers(&response, &origin);

    // 모든 기존 CORS 헤더 제거 (중복 방지)
    remove_all_cors_headers(&mut response);

    // 허용된 도메인에 대해서만 CORS 헤더 설정
    if is_allowed {
        let header_value = HeaderValue::from_str(&origin).unwrap_or_else(|_| HeaderValue::from_static(""));
        response.headers_mut().insert("Access-Control-Allow-Origin", header_value);
        info!("✅ CORS 헤더 설정: Access-Control-Allow-Origin = {}", origin);
    }

    // 최종 응답 헤더 로깅
    log_response_headers(&response, &origin);

    response
} 