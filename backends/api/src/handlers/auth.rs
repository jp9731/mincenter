use axum::{
  extract::State,
  Json,
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

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
  sub: Uuid,
  exp: i64,
  iat: i64,
}

pub async fn register(
  State(state): State<AppState>,
  Json(req): Json<RegisterRequest>,
) -> Result<Json<ApiResponse<AuthResponse>>, ApiError> {
  let existing_user = sqlx::query!(
      "SELECT id FROM users WHERE email = $1",
      req.email
  )
  .fetch_optional(&state.pool)
  .await?;

  if existing_user.is_some() {
      return Err(ApiError::Validation("이미 존재하는 이메일입니다.".into()));
  }

  let password_hash = hash(req.password.as_bytes(), DEFAULT_COST)
      .map_err(|_| ApiError::Internal("비밀번호 해싱 실패".into()))?;

  let user = sqlx::query_as::<_, User>(
      r#"
      INSERT INTO users (email, name, password_hash, created_at, updated_at, role)
      VALUES ($1, $2, $3, NOW(), NOW(), 'user')
      RETURNING id, email, name, role::text, password_hash, created_at, updated_at
      "#
  )
  .bind(req.email)
  .bind(req.name)
  .bind(password_hash)
  .fetch_one(&state.pool)
  .await?;

  let (access_token, refresh_token) = generate_tokens(&state.config, user.id)?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

  // 리프레시 토큰을 데이터베이스에 저장
  let refresh_token_hash = hash_refresh_token(&refresh_token);
  sqlx::query!(
      "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)",
      user.id,
      refresh_token_hash,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await?;

  Ok(Json(ApiResponse::success(
      AuthResponse {
          user,
          access_token,
          refresh_token,
          expires_in,
      },
      "회원가입이 완료되었습니다."
  )))
}

pub async fn login(
  State(state): State<AppState>,
  Json(req): Json<LoginRequest>,
) -> Result<Json<ApiResponse<AuthResponse>>, ApiError> {
  let user = sqlx::query_as::<_, User>(
      "SELECT id, email, name, role::text, password_hash, created_at, updated_at FROM users WHERE email = $1"
  )
  .bind(req.email)
  .fetch_optional(&state.pool)
  .await?
  .ok_or_else(|| ApiError::Authentication("이메일 또는 비밀번호가 일치하지 않습니다.".into()))?;

  let password_hash = user.password_hash
      .as_ref()
      .ok_or_else(|| ApiError::Internal("비밀번호 해시가 없습니다.".into()))?;

  if !verify(&req.password, password_hash)
      .map_err(|_| ApiError::Internal("비밀번호 검증 실패".into()))? {
      return Err(ApiError::Authentication("이메일 또는 비밀번호가 일치하지 않습니다.".into()));
  }

  let (access_token, refresh_token) = generate_tokens(&state.config, user.id)?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

  // 기존 리프레시 토큰들을 무효화
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1",
      user.id
  )
  .execute(&state.pool)
  .await?;

  // 새로운 리프레시 토큰을 데이터베이스에 저장
  let refresh_token_hash = hash_refresh_token(&refresh_token);
  sqlx::query!(
      "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)",
      user.id,
      refresh_token_hash,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await?;

  Ok(Json(ApiResponse::success(
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
  Json(req): Json<RefreshRequest>,
) -> Result<Json<ApiResponse<RefreshResponse>>, ApiError> {
  // 리프레시 토큰 검증
  let token_data = decode::<Claims>(
      &req.refresh_token,
      &DecodingKey::from_secret(state.config.refresh_secret.as_ref()),
      &Validation::default()
  )
  .map_err(|_| ApiError::Authentication("유효하지 않은 리프레시 토큰입니다.".into()))?;

  let user_id = token_data.claims.sub;

  // 데이터베이스에서 리프레시 토큰 확인
  let refresh_token_hash = hash_refresh_token(&req.refresh_token);
  let stored_token = sqlx::query!(
      "SELECT * FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2 AND is_revoked = FALSE AND expires_at > NOW()",
      user_id,
      refresh_token_hash
  )
  .fetch_optional(&state.pool)
  .await?;

  if stored_token.is_none() {
      return Err(ApiError::Authentication("유효하지 않은 리프레시 토큰입니다.".into()));
  }

  // 새로운 토큰 생성
  let (access_token, new_refresh_token) = generate_tokens(&state.config, user_id)?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

  // 기존 리프레시 토큰 무효화
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND token_hash = $2",
      user_id,
      refresh_token_hash
  )
  .execute(&state.pool)
  .await?;

  // 새로운 리프레시 토큰 저장
  let new_refresh_token_hash = hash_refresh_token(&new_refresh_token);
  sqlx::query!(
      "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)",
      user_id,
      new_refresh_token_hash,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await?;

  Ok(Json(ApiResponse::success(
      RefreshResponse {
          access_token,
          refresh_token: new_refresh_token,
          expires_in,
      },
      "토큰이 갱신되었습니다."
  )))
}

pub async fn logout(
  State(state): State<AppState>,
  Json(req): Json<RefreshRequest>,
) -> Result<Json<ApiResponse<()>>, ApiError> {
  // 리프레시 토큰 검증
  let token_data = decode::<Claims>(
      &req.refresh_token,
      &DecodingKey::from_secret(state.config.refresh_secret.as_ref()),
      &Validation::default()
  )
  .map_err(|_| ApiError::Authentication("유효하지 않은 리프레시 토큰입니다.".into()))?;

  let user_id = token_data.claims.sub;

  // 리프레시 토큰 무효화
  let refresh_token_hash = hash_refresh_token(&req.refresh_token);
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND token_hash = $2",
      user_id,
      refresh_token_hash
  )
  .execute(&state.pool)
  .await?;

  Ok(Json(ApiResponse::success((), "로그아웃되었습니다.")))
}

// 사용자 프로필 가져오기
pub async fn me(
  State(state): State<AppState>,
  headers: axum::http::HeaderMap,
) -> Result<Json<ApiResponse<User>>, ApiError> {
  // Authorization 헤더에서 토큰 추출
  let auth_header = headers
    .get("Authorization")
    .and_then(|h| h.to_str().ok())
    .ok_or_else(|| ApiError::Authentication("Authorization header missing".into()))?;

  if !auth_header.starts_with("Bearer ") {
    return Err(ApiError::Authentication("Invalid authorization header format".into()));
  }

  let token = &auth_header[7..]; // "Bearer " 제거

  // 토큰 검증
  let token_data = decode::<Claims>(
    token,
    &DecodingKey::from_secret(state.config.jwt_secret.as_ref()),
    &Validation::default()
  )
  .map_err(|_| ApiError::Authentication("Invalid token".into()))?;

  let user_id = token_data.claims.sub;

  // 데이터베이스에서 사용자 정보 가져오기
  let user = sqlx::query_as::<_, User>(
    "SELECT id, email, name, role::text, password_hash, created_at, updated_at FROM users WHERE id = $1"
  )
  .bind(user_id)
  .fetch_optional(&state.pool)
  .await?
  .ok_or_else(|| ApiError::Authentication("유저를 찾을 수 없습니다.".into()))?;

  Ok(Json(ApiResponse::success(user, "사용자 정보를 성공적으로 가져왔습니다.")))
}

fn generate_tokens(config: &Config, user_id: Uuid) -> Result<(String, String), ApiError> {
  let now = Utc::now();
  
  // Access Token (15분)
  let access_exp = (now + Duration::minutes(config.access_token_expiry)).timestamp() as i64;
  let access_claims = Claims {
      sub: user_id,
      exp: access_exp,
      iat: now.timestamp() as i64,
  };
  
  // Refresh Token (7일)
  let refresh_exp = (now + Duration::days(config.refresh_token_expiry)).timestamp() as i64;
  let refresh_claims = Claims {
      sub: user_id,
      exp: refresh_exp,
      iat: now.timestamp() as i64,
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