use axum::{
  extract::State,
  Json,
};
use sqlx::PgPool;
use bcrypt::{hash, verify, DEFAULT_COST};
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Serialize, Deserialize};
use chrono::{Utc, Duration};
use uuid::Uuid;
use crate::{
  models::user::{User, LoginRequest, RegisterRequest, AuthResponse},
  errors::ApiError,
  models::response::ApiResponse,
};

const JWT_SECRET: &[u8] = b"your-secret-key";

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
  sub: Uuid,
  exp: i64,
  iat: i64,
}

pub async fn register(
  State(pool): State<PgPool>,
  Json(req): Json<RegisterRequest>,
) -> Result<Json<ApiResponse<AuthResponse>>, ApiError> {
  let existing_user = sqlx::query!(
      "SELECT id FROM users WHERE email = $1",
      req.email
  )
  .fetch_optional(&pool)
  .await?;

  if existing_user.is_some() {
      return Err(ApiError::Validation("이미 존재하는 이메일입니다.".into()));
  }

  let password_hash = hash(req.password.as_bytes(), DEFAULT_COST)
      .map_err(|_| ApiError::Internal("비밀번호 해싱 실패".into()))?;

  let user = sqlx::query_as!(
      User,
      r#"
      INSERT INTO users (email, name, password_hash, created_at, updated_at)
      VALUES ($1, $2, $3, NOW(), NOW())
      RETURNING id, email, name, password_hash, created_at, updated_at
      "#,
      req.email,
      req.name,
      password_hash
  )
  .fetch_one(&pool)
  .await?;

  let token = generate_token(user.id)?;

  Ok(Json(ApiResponse::success(
      AuthResponse { user, token },
      "회원가입이 완료되었습니다."
  )))
}

pub async fn login(
  State(pool): State<PgPool>,
  Json(req): Json<LoginRequest>,
) -> Result<Json<ApiResponse<AuthResponse>>, ApiError> {
  let user = sqlx::query_as!(
      User,
      "SELECT id, email, name, password_hash, created_at, updated_at FROM users WHERE email = $1",
      req.email
  )
  .fetch_optional(&pool)
  .await?
  .ok_or_else(|| ApiError::Authentication("이메일 또는 비밀번호가 일치하지 않습니다.".into()))?;

  let password_hash = user.password_hash
      .as_ref()
      .ok_or_else(|| ApiError::Internal("비밀번호 해시가 없습니다.".into()))?;

  if !verify(&req.password, password_hash)
      .map_err(|_| ApiError::Internal("비밀번호 검증 실패".into()))? {
      return Err(ApiError::Authentication("이메일 또는 비밀번호가 일치하지 않습니다.".into()));
  }

  let token = generate_token(user.id)?;

  Ok(Json(ApiResponse::success(
      AuthResponse { user, token },
      "로그인 성공"
  )))
}

fn generate_token(user_id: Uuid) -> Result<String, ApiError> {
  let now = Utc::now();
  let exp = (now + Duration::days(7)).timestamp() as i64;
  
  let claims = Claims {
      sub: user_id,
      exp,
      iat: now.timestamp() as i64,
  };

  encode(
      &Header::default(),
      &claims,
      &EncodingKey::from_secret(JWT_SECRET)
  )
  .map_err(|_| ApiError::Internal("토큰 생성 실패".into()))
}