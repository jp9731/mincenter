use axum::{
    extract::{Path, Query, State, Extension},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post, put},
    Json, Router,
};
use axum_extra::{TypedHeader, headers::Authorization};
use axum_extra::headers::authorization::Bearer;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use chrono;
use crate::{
    AppState,
    models::admin::post_management::*,
    services::post_management::PostManagementService,
    middleware::rbac::require_role,
    utils::auth::get_current_user,
    utils::url_id::resolve_post_uuid,
};
use crate::errors::ApiError;

#[derive(Debug, Deserialize)]
pub struct PaginationQuery {
    page: Option<i64>,
    limit: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct StatisticsQuery {
    board_id: Option<Uuid>,
    start_date: Option<chrono::NaiveDate>,
    end_date: Option<chrono::NaiveDate>,
}

/// 게시글 이동
pub async fn move_post(
    Path(post_id_str): Path<String>,
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Json(mut request): Json<PostMoveRequest>,
) -> Result<impl IntoResponse, ApiError> {
    println!("🔄 게시글 이동 요청 - post_id: {}", post_id_str);
    println!("🔄 요청 데이터: {:?}", request);
    
    let user = get_current_user(State(state.clone()), auth_header).await?;
    println!("👤 인증된 사용자: {:?}", user);
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    println!("✅ 관리자 권한 확인 완료");
    
    // post_id를 UUID 또는 URL ID에서 실제 UUID로 변환
    let post_uuid = if let Ok(uuid) = uuid::Uuid::parse_str(&post_id_str) {
        // 이미 UUID 형식인 경우
        uuid
    } else {
        // URL ID 형식인 경우 UUID로 변환
        resolve_post_uuid(&state.pool, &post_id_str).await?
    };
    
    // posts 테이블에서 해당 UUID가 존재하는지 확인
    let _post_exists = sqlx::query!("SELECT id FROM posts WHERE id = $1", post_uuid)
        .fetch_one(&state.pool)
        .await
        .map_err(|_| ApiError::NotFound("게시글을 찾을 수 없습니다.".to_string()))?;
    
    // post_id는 URL에서 추출하므로 별도로 설정할 필요 없음
    
    let service = PostManagementService::new(state.pool);
    let result = service.move_post(post_uuid, request, user.id).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 숨김
pub async fn hide_post(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Json(request): Json<PostHideRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let service = PostManagementService::new(state.pool);
    let result = service.hide_post(request, user.id).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 숨김 해제
pub async fn unhide_post(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Json(request): Json<PostUnhideRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let service = PostManagementService::new(state.pool);
    let result = service.unhide_post(request, user.id).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 이동 이력 조회
pub async fn get_move_history(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Path(post_id): Path<i32>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let service = PostManagementService::new(state.pool);
    let result = service.get_move_history(post_id).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 숨김 이력 조회
pub async fn get_hide_history(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Path(post_id): Path<i32>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let service = PostManagementService::new(state.pool);
    let result = service.get_hide_history(post_id).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 숨겨진 게시글 목록 조회
pub async fn get_hidden_posts(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Query(query): Query<PaginationQuery>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20).min(100); // 최대 100개로 제한
    
    let service = PostManagementService::new(state.pool);
    let result = service.get_hidden_posts(page, limit).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 이동 이력 통계
pub async fn get_move_statistics(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Query(query): Query<StatisticsQuery>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let service = PostManagementService::new(state.pool);
    let result = service.get_move_statistics(
        query.board_id,
        query.start_date,
        query.end_date,
    ).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 숨김 상태 업데이트
pub async fn update_hide_status(
    State(state): State<AppState>,
    auth_header: Option<TypedHeader<Authorization<Bearer>>>,
    Path(post_id): Path<i32>,
    Json(request): Json<UpdatePostHideHistory>,
) -> Result<impl IntoResponse, ApiError> {
    let user = get_current_user(State(state.clone()), auth_header).await?;
    
    // 관리자 권한 확인
    require_role(&user, "admin")?;
    
    let service = PostManagementService::new(state.pool);
    let result = service.update_hide_status(post_id, request).await?;
    
    Ok((StatusCode::OK, Json(result)))
}

/// 게시글 관리 라우터 생성 (관리자용)
pub fn post_management_routes() -> Router<AppState> {
    Router::new()
        .route("/posts/:post_id/move", post(move_post))
        .route("/posts/:post_id/hide", post(hide_post))
        .route("/posts/:post_id/unhide", post(unhide_post))
        .route("/posts/:post_id/move-history", get(get_move_history))
        .route("/posts/:post_id/hide-history", get(get_hide_history))
        .route("/posts/hidden", get(get_hidden_posts))
        .route("/posts/:post_id/hide-status", put(update_hide_status))
        .route("/statistics/move", get(get_move_statistics))
}

/// 사이트용 게시글 관리 라우터 생성 (관리자 권한 필요)
pub fn site_post_management_routes() -> Router<AppState> {
    Router::new()
        .route("/api/site/posts/:post_id/move", post(move_post))
        .route("/api/site/posts/:post_id/hide", post(hide_post))
        .route("/api/site/posts/:post_id/unhide", post(unhide_post))
}
