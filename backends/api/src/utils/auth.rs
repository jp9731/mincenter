use jsonwebtoken::{decode, DecodingKey, Validation, encode, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use axum::{
    extract::State,
    http::StatusCode,
};
use axum_extra::{TypedHeader, headers::Authorization};
use axum_extra::headers::authorization::Bearer;
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{Utc, Duration};
use sha2::{Sha256, Digest};
use crate::{
    config::Config,
    models::user::User,
    AppState,
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: Uuid,
    pub exp: i64,
    pub iat: i64,
}

pub fn verify_token(token: &str, config: &Config) -> Result<Claims, jsonwebtoken::errors::Error> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(config.jwt_secret.as_ref()),
        &Validation::default()
    )?;
    
    Ok(token_data.claims)
}

pub fn hash_password(password: &str) -> String {
    hash(password, DEFAULT_COST).unwrap()
}

pub fn verify_password(password: &str, hash: &str) -> bool {
    verify(password, hash).unwrap_or(false)
}

pub fn create_token(claims: &Claims, secret: &str) -> Result<String, jsonwebtoken::errors::Error> {
    encode(
        &Header::default(),
        claims,
        &EncodingKey::from_secret(secret.as_ref())
    )
}

pub fn generate_tokens(config: &Config, user_id: Uuid) -> Result<(String, String), jsonwebtoken::errors::Error> {
    let now = Utc::now();
    
    // Access token claims
    let access_claims = Claims {
        sub: user_id,
        exp: (now + Duration::minutes(config.access_token_expiry)).timestamp(),
        iat: now.timestamp(),
    };
    
    // Refresh token claims
    let refresh_claims = Claims {
        sub: user_id,
        exp: (now + Duration::days(config.refresh_token_expiry)).timestamp(),
        iat: now.timestamp(),
    };
    
    let access_token = create_token(&access_claims, &config.jwt_secret)?;
    let refresh_token = create_token(&refresh_claims, &config.refresh_secret)?;
    
    Ok((access_token, refresh_token))
}

pub fn hash_refresh_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    format!("{:x}", hasher.finalize())
}

pub async fn get_current_user(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
) -> Result<User, StatusCode> {
    let auth_header = auth_header
        .ok_or(StatusCode::UNAUTHORIZED)?
        .0;

    let token_data = verify_token(auth_header.token(), &state.config)
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    let user = sqlx::query_as::<_, User>(
        "SELECT id, email, name, role::text, password_hash, created_at, updated_at FROM users WHERE id = $1"
    )
    .bind(token_data.sub)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::UNAUTHORIZED)?;

    Ok(user)
} 