use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use crate::models::response::ApiResponse;
use crate::models::user::{User, AdminUser, AdminLoginRequest, AdminAuthResponse};
use crate::models::community::{Post, Board, Comment};
use crate::AppState;
use crate::utils::auth::{generate_tokens, hash_refresh_token};
use chrono::{Utc, Duration};

// Admin 로그인
pub async fn admin_login(
    State(state): State<AppState>,
    Json(data): Json<AdminLoginRequest>,
) -> Result<Json<ApiResponse<AdminAuthResponse>>, StatusCode> {
    // 관리자 계정 확인 (임시로 하드코딩된 계정 사용)
    if data.email != "admin@example.com" || data.password != "admin123" {
        return Ok(Json(ApiResponse::<AdminAuthResponse>::error("잘못된 이메일 또는 비밀번호입니다.")));
    }

    // 관리자 사용자 정보 생성
    let admin_user = AdminUser {
        id: uuid::Uuid::new_v4(),
        name: "관리자".to_string(),
        email: "admin@example.com".to_string(),
        role: "super_admin".to_string(),
        permissions: vec![
            "dashboard.view".to_string(),
            "users.view".to_string(),
            "users.edit".to_string(),
            "content.view".to_string(),
            "content.edit".to_string(),
            "files.view".to_string(),
            "analytics.view".to_string(),
            "system.view".to_string(),
        ],
        last_login: Some(Utc::now()),
    };

    // JWT 토큰 생성
    let (access_token, _refresh_token) = generate_tokens(&state.config, admin_user.id)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 관리자 로그인은 리프레시 토큰을 데이터베이스에 저장하지 않음
    // 단순히 JWT 토큰만 반환

    Ok(Json(ApiResponse::success(
        AdminAuthResponse {
            user: admin_user,
            token: access_token,
        },
        "관리자 로그인 성공"
    )))
}

// 대시보드 통계
#[derive(Serialize)]
pub struct DashboardStats {
    pub total_users: i64,
    pub total_posts: i64,
    pub total_comments: i64,
    pub total_boards: i64,
    pub active_volunteers: i64,
    pub total_donations: i64,
    pub monthly_visitors: i64,
    pub monthly_posts: i64,
}

pub async fn get_dashboard_stats(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<DashboardStats>>, StatusCode> {
    // 사용자 수
    let total_users = sqlx::query_scalar!("SELECT COUNT(*) FROM users")
        .fetch_one(&state.pool)
        .await
        .unwrap_or(Some(0))
        .unwrap_or(0);

    // 게시글 수
    let total_posts = sqlx::query_scalar!("SELECT COUNT(*) FROM posts")
        .fetch_one(&state.pool)
        .await
        .unwrap_or(Some(0))
        .unwrap_or(0);

    // 댓글 수
    let total_comments = sqlx::query_scalar!("SELECT COUNT(*) FROM comments")
        .fetch_one(&state.pool)
        .await
        .unwrap_or(Some(0))
        .unwrap_or(0);

    // 게시판 수
    let total_boards = sqlx::query_scalar!("SELECT COUNT(*) FROM boards")
        .fetch_one(&state.pool)
        .await
        .unwrap_or(Some(0))
        .unwrap_or(0);

    // 활성 봉사자 수 (임시로 활성 사용자로 대체)
    let active_volunteers = sqlx::query_scalar!("SELECT COUNT(*) FROM users WHERE status = 'active'")
        .fetch_one(&state.pool)
        .await
        .unwrap_or(Some(0))
        .unwrap_or(0);

    // 총 후원금 (임시로 0)
    let total_donations = 0;

    // 월간 방문자 (임시로 0)
    let monthly_visitors = 0;

    // 월간 게시글 수
    let monthly_posts = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM posts WHERE created_at >= NOW() - INTERVAL '1 month'"
    )
    .fetch_one(&state.pool)
    .await
    .unwrap_or(Some(0))
    .unwrap_or(0);

    let stats = DashboardStats {
        total_users,
        total_posts,
        total_comments,
        total_boards,
        active_volunteers,
        total_donations,
        monthly_visitors,
        monthly_posts,
    };

    Ok(Json(ApiResponse::success(stats, "대시보드 통계")))
}

// 사용자 관리
#[derive(Deserialize)]
pub struct UserQuery {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub search: Option<String>,
    pub status: Option<String>,
    pub role: Option<String>,
}

pub async fn get_users(
    State(state): State<AppState>,
    Query(query): Query<UserQuery>,
) -> Result<Json<ApiResponse<Vec<User>>>, StatusCode> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    let mut sql = "SELECT * FROM users".to_string();
    let mut conditions = Vec::new();

    if let Some(search) = query.search {
        conditions.push(format!("(username ILIKE '%{}%' OR email ILIKE '%{}%' OR name ILIKE '%{}%')", search, search, search));
    }

    if let Some(status) = query.status {
        conditions.push(format!("status = '{}'", status));
    }

    if let Some(role) = query.role {
        conditions.push(format!("role = '{}'", role));
    }

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY created_at DESC LIMIT {} OFFSET {}", limit, offset));

    let users = sqlx::query_as::<_, User>(&sql)
        .fetch_all(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(users, "사용자 목록")))
}

// 게시글 관리
#[derive(Deserialize)]
pub struct PostQuery {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub search: Option<String>,
    pub board_id: Option<String>,
    pub status: Option<String>,
}

pub async fn get_posts(
    State(state): State<AppState>,
    Query(query): Query<PostQuery>,
) -> Result<Json<ApiResponse<Vec<Post>>>, StatusCode> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    let mut sql = "SELECT * FROM posts".to_string();
    let mut conditions = Vec::new();

    if let Some(search) = query.search {
        conditions.push(format!("(title ILIKE '%{}%' OR content ILIKE '%{}%')", search, search));
    }

    if let Some(board_id) = query.board_id {
        conditions.push(format!("board_id = '{}'", board_id));
    }

    if let Some(status) = query.status {
        conditions.push(format!("status = '{}'", status));
    }

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY created_at DESC LIMIT {} OFFSET {}", limit, offset));

    let posts = sqlx::query_as::<_, Post>(&sql)
        .fetch_all(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(posts, "게시글 목록")))
}

// 게시판 관리
pub async fn get_boards(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Board>>>, StatusCode> {
    let boards = sqlx::query_as::<_, Board>("SELECT * FROM boards ORDER BY sort_order, created_at")
        .fetch_all(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(boards, "게시판 목록")))
}

// 댓글 관리
#[derive(Deserialize)]
pub struct CommentQuery {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub search: Option<String>,
    pub status: Option<String>,
}

pub async fn get_comments(
    State(state): State<AppState>,
    Query(query): Query<CommentQuery>,
) -> Result<Json<ApiResponse<Vec<Comment>>>, StatusCode> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    let mut sql = "SELECT * FROM comments".to_string();
    let mut conditions = Vec::new();

    if let Some(search) = query.search {
        conditions.push(format!("content ILIKE '%{}%'", search));
    }

    if let Some(status) = query.status {
        conditions.push(format!("status = '{}'", status));
    }

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY created_at DESC LIMIT {} OFFSET {}", limit, offset));

    let comments = sqlx::query_as::<_, Comment>(&sql)
        .fetch_all(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(comments, "댓글 목록")))
} 