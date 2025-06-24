use axum::{
  extract::{Json, State, Extension},
  http::StatusCode,
  response::Json as AxumJson,
};
use bcrypt::{hash, verify, DEFAULT_COST};
use jsonwebtoken::{encode, decode, EncodingKey, DecodingKey, Header, Validation};
use serde::{Serialize, Deserialize};
use chrono::{Utc, Duration};
use uuid::Uuid;
use sha2::{Sha256, Digest};
use crate::{
  models::user::{User, LoginRequest, RegisterRequest, RefreshRequest, AuthResponse, RefreshResponse},
  errors::ApiError,
  models::response::ApiResponse,
  config::Config,
  AppState,
};
use sqlx::PgPool;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
  pub sub: Uuid,
  pub exp: i64,
  pub iat: i64,
}

pub async fn register(
  State(state): State<AppState>,
  Json(data): Json<RegisterRequest>,
) -> Result<AxumJson<ApiResponse<User>>, StatusCode> {
  let existing_user = sqlx::query!(
      "SELECT id FROM users WHERE email = $1",
      data.email
  )
  .fetch_optional(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  if existing_user.is_some() {
      return Ok(AxumJson(ApiResponse::<User>::error("이미 존재하는 이메일입니다.")));
  }

  let password_hash = crate::utils::auth::hash_password(&data.password);

  let user = sqlx::query_as::<_, User>(
      "INSERT INTO users (email, name, password_hash, created_at, updated_at, role)
      VALUES ($1, $2, $3, NOW(), NOW(), 'user')
      RETURNING id, email, name, role::text, password_hash, created_at, updated_at"
  )
  .bind(&data.email)
  .bind(&data.name)
  .bind(password_hash)
  .fetch_one(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  let (access_token, refresh_token) = generate_tokens(&state.config, user.id)
      .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

  // 리프레시 토큰을 데이터베이스에 저장
  let refresh_token_hash = hash_refresh_token(&refresh_token);
  let service_type = data.service_type.unwrap_or_else(|| "site".to_string());
  sqlx::query!(
      "INSERT INTO refresh_tokens (user_id, token_hash, service_type, expires_at) VALUES ($1, $2, $3, $4)",
      user.id,
      refresh_token_hash,
      service_type,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  Ok(AxumJson(ApiResponse::success(
      user,
      "회원가입이 완료되었습니다."
  )))
}

pub async fn login(
  State(state): State<AppState>,
  Json(data): Json<LoginRequest>,
) -> Result<AxumJson<ApiResponse<AuthResponse>>, StatusCode> {
  let user = match sqlx::query_as::<_, User>(
      "SELECT id, email, name, role, password_hash, created_at, updated_at FROM users WHERE email = $1"
  )
  .bind(&data.email)
  .fetch_optional(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)? {
      Some(user) => user,
      None => {
          return Ok(AxumJson(ApiResponse::<AuthResponse>::error("이메일 또는 비밀번호가 올바르지 않습니다.")));
      }
  };

  let password_hash = user.password_hash
      .as_ref()
      .ok_or_else(|| StatusCode::INTERNAL_SERVER_ERROR)?;

  if !crate::utils::auth::verify_password(&data.password, password_hash) {
      return Ok(AxumJson(ApiResponse::<AuthResponse>::error("이메일 또는 비밀번호가 올바르지 않습니다.")));
  }

  let (access_token, refresh_token) = generate_tokens(&state.config, user.id)
      .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

  // 기존 리프레시 토큰들을 무효화 (같은 서비스 타입만)
  let service_type = data.service_type.unwrap_or_else(|| "site".to_string());
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND service_type = $2",
      user.id,
      service_type
  )
  .execute(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  // 새로운 리프레시 토큰을 데이터베이스에 저장
  let refresh_token_hash = hash_refresh_token(&refresh_token);
  sqlx::query!(
      "INSERT INTO refresh_tokens (user_id, token_hash, service_type, expires_at) VALUES ($1, $2, $3, $4)",
      user.id,
      refresh_token_hash,
      service_type,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  Ok(AxumJson(ApiResponse::success(
      AuthResponse {
          user,
          access_token,
          refresh_token,
          expires_in,
      },
      "로그인 성공"
  )))
}

pub async fn refresh(
  State(state): State<AppState>,
  Json(data): Json<RefreshRequest>,
) -> Result<AxumJson<ApiResponse<RefreshResponse>>, StatusCode> {
  // 리프레시 토큰 검증
  let token_data = decode::<Claims>(
      &data.refresh_token,
      &DecodingKey::from_secret(state.config.refresh_secret.as_ref()),
      &Validation::default()
  )
  .map_err(|_| StatusCode::UNAUTHORIZED)?;

  let user_id = token_data.claims.sub;

  // 데이터베이스에서 리프레시 토큰 확인
  let refresh_token_hash = hash_refresh_token(&data.refresh_token);
  let service_type = data.service_type.unwrap_or_else(|| "site".to_string());
  let stored_token = sqlx::query!(
      "SELECT * FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2 AND service_type = $3 AND is_revoked = FALSE AND expires_at > NOW()",
      user_id,
      refresh_token_hash,
      service_type
  )
  .fetch_optional(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  if stored_token.is_none() {
      return Err(StatusCode::UNAUTHORIZED);
  }

  // 새로운 토큰 생성
  let (access_token, new_refresh_token) = generate_tokens(&state.config, user_id)
      .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

  // 기존 리프레시 토큰 무효화
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND token_hash = $2 AND service_type = $3",
      user_id,
      refresh_token_hash,
      service_type
  )
  .execute(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  // 새로운 리프레시 토큰 저장
  let new_refresh_token_hash = hash_refresh_token(&new_refresh_token);
  sqlx::query!(
      "INSERT INTO refresh_tokens (user_id, token_hash, service_type, expires_at) VALUES ($1, $2, $3, $4)",
      user_id,
      new_refresh_token_hash,
      service_type,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  Ok(AxumJson(ApiResponse::success(
      RefreshResponse {
          access_token,
          refresh_token: new_refresh_token,
          expires_in,
      },
      "토큰 갱신 성공"
  )))
}

pub async fn logout(
  State(state): State<AppState>,
  Json(data): Json<RefreshRequest>,
) -> Result<AxumJson<ApiResponse<()>>, StatusCode> {
  let refresh_token_hash = hash_refresh_token(&data.refresh_token);
  let service_type = data.service_type.unwrap_or_else(|| "site".to_string());
  
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE token_hash = $1 AND service_type = $2",
      refresh_token_hash,
      service_type
  )
  .execute(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  Ok(AxumJson(ApiResponse::success((), "로그아웃 성공")))
}

pub async fn me(
  State(state): State<AppState>,
  Extension(claims): Extension<crate::utils::auth::Claims>,
) -> Result<AxumJson<ApiResponse<User>>, StatusCode> {
  let user = sqlx::query_as::<_, User>(
    "SELECT id, email, name, role, password_hash, created_at, updated_at FROM users WHERE id = $1"
  )
  .bind(claims.sub)
  .fetch_optional(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
  .ok_or_else(|| StatusCode::NOT_FOUND)?;

  Ok(AxumJson(ApiResponse::success(user, "사용자 정보")))
}

fn generate_tokens(config: &Config, user_id: Uuid) -> Result<(String, String), ApiError> {
    let now = Utc::now();
    let access_exp = now + Duration::minutes(config.access_token_expiry);
    let refresh_exp = now + Duration::days(config.refresh_token_expiry);

    let access_claims = Claims {
        sub: user_id,
        exp: access_exp.timestamp(),
        iat: now.timestamp(),
    };

    let refresh_claims = Claims {
        sub: user_id,
        exp: refresh_exp.timestamp(),
        iat: now.timestamp(),
    };

    let access_token = encode(
        &Header::default(),
        &access_claims,
        &EncodingKey::from_secret(config.jwt_secret.as_ref())
    )
    .map_err(|_| ApiError::Internal("Access 토큰 생성 실패".into()))?;

    let refresh_token = encode(
        &Header::default(),
        &refresh_claims,
        &EncodingKey::from_secret(config.refresh_secret.as_ref())
    )
    .map_err(|_| ApiError::Internal("Refresh 토큰 생성 실패".into()))?;

    Ok((access_token, refresh_token))
}

fn hash_refresh_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    format!("{:x}", hasher.finalize())
}