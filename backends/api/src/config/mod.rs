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
    pub rust_log: String,
}

impl Config {
    pub fn from_env() -> Self {
        let node_env = env::var("NODE_ENV").unwrap_or_else(|_| "development".to_string());
        
        // 환경별 기본값 설정 (민감한 정보는 환경변수에서만 읽음)
        let (default_api_port, default_api_base_url) = match node_env.as_str() {
            "production" => (
                "8080",
                "http://mincenter-api:8080"
            ),
            _ => (
                "18080",
                "http://localhost:18080"
            )
        };

        let default_rust_log = match node_env.as_str() {
            "production" => "info",
            _ => "debug"
        };

        Self {
            database_url: env::var("DATABASE_URL")
                .expect("DATABASE_URL environment variable is required"),
            jwt_secret: env::var("JWT_SECRET")
                .expect("JWT_SECRET environment variable is required"),
            refresh_secret: env::var("REFRESH_SECRET")
                .expect("REFRESH_SECRET environment variable is required"),
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
            redis_url: env::var("REDIS_URL")
                .expect("REDIS_URL environment variable is required"),
            rust_log: env::var("RUST_LOG_LEVEL")
                .unwrap_or_else(|_| default_rust_log.to_string()),
        }
    }

    pub fn is_production(&self) -> bool {
        env::var("NODE_ENV").unwrap_or_else(|_| "development".to_string()) == "production"
    }

    pub fn is_development(&self) -> bool {
        !self.is_production()
    }
} 