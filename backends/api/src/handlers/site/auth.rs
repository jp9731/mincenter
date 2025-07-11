use axum::{
    extract::{State, Json, Extension},
    http::StatusCode,
    response::Json as AxumJson,
};
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{Utc, Duration};
use jsonwebtoken::{decode, DecodingKey, Validation, encode, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use sqlx::PgPool;
use uuid::Uuid;
use crate::{
    config::Config,
    models::user::{User, LoginRequest, RegisterRequest, RefreshRequest, AuthResponse, RefreshResponse},
    models::response::ApiResponse,
    utils::auth::{generate_tokens, hash_refresh_token, Claims},
    AppState,
};

pub async fn register(
  State(state): State<AppState>,
  Json(data): Json<RegisterRequest>,
) -> Result<AxumJson<ApiResponse<User>>, StatusCode> {
  // 비밀번호 해시화
  let password_hash = hash(data.password.as_bytes(), DEFAULT_COST)
      .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  // 사용자 생성
  let user = sqlx::query_as::<_, User>(
      "INSERT INTO users (email, name, password_hash, role, status, created_at, updated_at) 
       VALUES ($1, $2, $3, 'user', 'active', NOW(), NOW()) 
       RETURNING *"
  )
  .bind(&data.email)
  .bind(&data.name)
  .bind(password_hash)
  .fetch_one(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

  let (access_token, refresh_token) = generate_tokens(&state.config, user.id, user.role.as_ref().map(|r| format!("{:?}", r)).unwrap_or_else(|| "user".to_string()))
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
      "SELECT * FROM users WHERE email = $1"
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

  let password_hash = match user.password_hash.as_ref() {
      Some(hash) => hash,
      None => {
          return Ok(AxumJson(ApiResponse::<AuthResponse>::error("이메일 또는 비밀번호가 올바르지 않습니다.")));
      }
  };

  if !crate::utils::auth::verify_password(&data.password, password_hash) {
      return Ok(AxumJson(ApiResponse::<AuthResponse>::error("이메일 또는 비밀번호가 올바르지 않습니다.")));
  }
  
  eprintln!("비밀번호 검증 성공, 토큰 생성 시작");
  eprintln!("사용자 정보: id={}, email={:?}, role={:?}", user.id, user.email, user.role);

  let (access_token, refresh_token) = generate_tokens(&state.config, user.id, user.role.as_ref().map(|r| format!("{:?}", r)).unwrap_or_else(|| "user".to_string()))
      .map_err(|e| {
          eprintln!("토큰 생성 실패: {:?}", e);
          StatusCode::INTERNAL_SERVER_ERROR
      })?;
  let expires_in = state.config.access_token_expiry * 60; // minutes to seconds
  
  eprintln!("토큰 생성 성공, 기존 토큰 무효화 시작");

  // 기존 리프레시 토큰들을 무효화 (같은 서비스 타입만)
  let service_type = data.service_type.unwrap_or_else(|| "site".to_string());
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND service_type = $2",
      user.id,
      service_type
  )
  .execute(&state.pool)
  .await
  .map_err(|e| {
      eprintln!("기존 토큰 무효화 실패: {:?}", e);
      StatusCode::INTERNAL_SERVER_ERROR
  })?;
  
  eprintln!("기존 토큰 무효화 성공, 새 토큰 저장 시작");

  // 새로운 리프레시 토큰을 데이터베이스에 저장
  let refresh_token_hash = hash_refresh_token(&refresh_token);
  let refresh_token_id = uuid::Uuid::new_v4();
  sqlx::query!(
      "INSERT INTO refresh_tokens (id, user_id, token_hash, service_type, expires_at) VALUES ($1, $2, $3, $4, $5)",
      refresh_token_id,
      user.id,
      refresh_token_hash,
      service_type,
      Utc::now() + Duration::days(state.config.refresh_token_expiry)
  )
  .execute(&state.pool)
  .await
  .map_err(|e| {
      eprintln!("리프레시 토큰 저장 실패: {:?}", e);
      StatusCode::INTERNAL_SERVER_ERROR
  })?;
  
  eprintln!("새 토큰 저장 성공, 응답 생성 시작");

  let auth_response = AuthResponse {
      user: user.clone(),
      access_token: access_token.clone(),
      refresh_token: refresh_token.clone(),
      expires_in,
  };
  
  eprintln!("응답 데이터 생성 완료: user_id={}, access_token_len={}, refresh_token_len={}", 
           auth_response.user.id, auth_response.access_token.len(), auth_response.refresh_token.len());

  let api_response = ApiResponse::success(auth_response, "로그인 성공");
  eprintln!("API 응답 래핑 완료, JSON 직렬화 시작");

  let result = AxumJson(api_response);
  eprintln!("✅ 로그인 응답 완료!");
  
  Ok(result)
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
  let user = sqlx::query_as::<_, User>(
      "SELECT * FROM users WHERE id = $1"
  )
  .bind(user_id)
  .fetch_optional(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
  .ok_or(StatusCode::UNAUTHORIZED)?;

  let (access_token, new_refresh_token) = generate_tokens(&state.config, user_id, user.role.as_ref().map(|r| format!("{:?}", r)).unwrap_or_else(|| "user".to_string()))
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
  eprintln!("로그아웃 요청 시작: service_type={:?}", data.service_type);
  
  let refresh_token_hash = hash_refresh_token(&data.refresh_token);
  let service_type = data.service_type.unwrap_or_else(|| "site".to_string());
  
  eprintln!("리프레시 토큰 무효화 시작: service_type={}", service_type);
  
  sqlx::query!(
      "UPDATE refresh_tokens SET is_revoked = TRUE WHERE token_hash = $1 AND service_type = $2",
      refresh_token_hash,
      service_type
  )
  .execute(&state.pool)
  .await
  .map_err(|e| {
      eprintln!("리프레시 토큰 무효화 실패: {:?}", e);
      StatusCode::INTERNAL_SERVER_ERROR
  })?;

  eprintln!("✅ 로그아웃 성공");
  Ok(AxumJson(ApiResponse::success((), "로그아웃 성공")))
}

pub async fn me(
  State(state): State<AppState>,
  Extension(claims): Extension<crate::utils::auth::Claims>,
) -> Result<AxumJson<ApiResponse<User>>, StatusCode> {
  let user = sqlx::query_as::<_, User>(
    "SELECT * FROM users WHERE id = $1"
  )
  .bind(claims.sub)
  .fetch_optional(&state.pool)
  .await
  .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
  .ok_or_else(|| StatusCode::NOT_FOUND)?;

  Ok(AxumJson(ApiResponse::success(user, "사용자 정보")))
} 