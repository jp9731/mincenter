use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub refresh_secret: String,
    pub access_token_expiry: i64,  // minutes
    pub refresh_token_expiry: i64, // days
    pub api_port: u16,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            database_url: env::var("DATABASE_URL")
                .expect("DATABASE_URL must be set"),
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
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .expect("API_PORT must be a number"),
        }
    }
} 