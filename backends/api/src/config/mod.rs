use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub refresh_secret: String,
    pub access_token_expiry: i64,  // minutes
    pub refresh_token_expiry: i64, // days
    pub api_port: u16,
    pub api_base_url: String,
    pub redis_url: String,
    pub cors_origin: String,
    pub rust_log: String,
}

impl Config {
    pub fn from_env() -> Self {
        let node_env = env::var("NODE_ENV").unwrap_or_else(|_| "development".to_string());
        
        // 환경별 기본값 설정
        let (default_db_url, default_api_port, default_api_base_url) = match node_env.as_str() {
            "production" => (
                "postgresql://mincenter:!@swjp0209^^@postgres:5432/mincenter",
                "8080",
                "http://mincenter-api:8080"
            ),
            _ => (
                "postgresql://mincenter:!@swjp0209^^@localhost:15432/mincenter",
                "18080",
                "http://localhost:18080"
            )
        };

        let (default_redis_url, default_cors_origin, default_rust_log) = match node_env.as_str() {
            "production" => (
                "redis://:tnekwoddl@redis:6379",
                "https://mincenter.kr,https://admin.mincenter.kr",
                "info"
            ),
            _ => (
                "redis://:tnekwoddl@localhost:6379",
                "http://localhost:13000,http://localhost:13001",
                "debug"
            )
        };

        Self {
            database_url: env::var("DATABASE_URL").unwrap_or_else(|_| default_db_url.to_string()),
            jwt_secret: env::var("JWT_SECRET")
                .unwrap_or_else(|_| "your-secret-key".to_string()),
            refresh_secret: env::var("REFRESH_SECRET")
                .unwrap_or_else(|_| "your-refresh-secret-key".to_string()),
            access_token_expiry: env::var("ACCESS_TOKEN_EXPIRY_MINUTES")
                .unwrap_or_else(|_| "15".to_string())
                .parse()
                .expect("ACCESS_TOKEN_EXPIRY_MINUTES must be a number"),
            refresh_token_expiry: env::var("REFRESH_TOKEN_EXPIRY_DAYS")
                .unwrap_or_else(|_| "7".to_string())
                .parse()
                .expect("REFRESH_TOKEN_EXPIRY_DAYS must be a number"),
            api_port: env::var("API_PORT")
                .unwrap_or_else(|_| default_api_port.to_string())
                .parse()
                .expect("API_PORT must be a number"),
            api_base_url: env::var("API_BASE_URL")
                .unwrap_or_else(|_| default_api_base_url.to_string()),
            redis_url: env::var("REDIS_URL").unwrap_or_else(|_| default_redis_url.to_string()),
            cors_origin: env::var("CORS_ORIGIN").unwrap_or_else(|_| default_cors_origin.to_string()),
            rust_log: env::var("RUST_LOG").unwrap_or_else(|_| default_rust_log.to_string()),
        }
    }

    pub fn is_production(&self) -> bool {
        env::var("NODE_ENV").unwrap_or_else(|_| "development".to_string()) == "production"
    }

    pub fn is_development(&self) -> bool {
        !self.is_production()
    }
} 