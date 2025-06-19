use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use axum::{
    extract::State,
    http::StatusCode,
};
use axum_extra::{TypedHeader, headers::Authorization};
use axum_extra::headers::authorization::Bearer;
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