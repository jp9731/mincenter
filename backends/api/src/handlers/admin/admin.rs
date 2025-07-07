use axum::{
    extract::{Path, Query, State, Extension},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use tracing::{info, error, warn, debug};
use crate::{
    models::response::ApiResponse,
    models::user::User,
    models::site::menu::{Menu, CreateMenuRequest, UpdateMenuRequest, MenuType},
    models::site::page::{Page, CreatePageRequest, UpdatePageRequest},
    models::admin::board::Board,
    models::site::community::{Post, PostDetail, CommentDetail, PostStatus, UpdatePostRequest},
    utils::auth::{generate_tokens, hash_refresh_token, get_current_user, Claims},
    AppState,
    errors::ApiError,
};
use chrono::{Utc, Duration};
use jsonwebtoken::{decode, DecodingKey, Validation};
use uuid::Uuid;
use serde_json;
use std::str::FromStr;

// 리프레시 토큰 응답 구조체
#[derive(Debug, Serialize)]
pub struct RefreshResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
}

// 관리자 로그인 요청 구조체
#[derive(Debug, Deserialize)]
pub struct AdminLoginRequest {
    pub email: String,
    pub password: String,
    pub service_type: Option<String>,
}

// 관리자 인증 응답 구조체
#[derive(Debug, Serialize)]
pub struct AdminAuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_in: i64,
    pub user: AdminUser,
}

// 관리자 사용자 정보
#[derive(Debug, Serialize)]
pub struct AdminUser {
    pub id: Uuid,
    pub name: String,
    pub email: String,
    pub role: String,
    pub status: String,
}

// Pagination 정보 구조체
#[derive(Serialize)]
pub struct PaginationInfo {
    pub page: i64,
    pub limit: i64,
    pub total: i64,
    pub total_pages: i64,
}

// 사용자 목록 응답 구조체
#[derive(Serialize)]
pub struct UsersResponse {
    pub users: Vec<User>,
    pub pagination: PaginationInfo,
}

// PostDetailRaw 구조체 (문자열 status용)
#[derive(Debug, sqlx::FromRow)]
struct PostDetailRaw {
    pub id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub title: String,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: Option<String>,
    pub created_at: Option<chrono::DateTime<Utc>>,
    pub updated_at: Option<chrono::DateTime<Utc>>,
    pub user_name: Option<String>,
    pub board_name: Option<String>,
    pub category_name: Option<String>,
    pub comment_count: Option<i64>,
}

// Admin 로그인
pub async fn admin_login(
    State(state): State<AppState>,
    Json(data): Json<AdminLoginRequest>,
) -> Result<Json<ApiResponse<AdminAuthResponse>>, StatusCode> {
    info!("Admin login attempt for email: {}", data.email);

    // DB에서 실제 admin 계정 찾기
    let admin_user_db = match sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE email = $1"
    )
    .bind(&data.email)
    .fetch_optional(&state.pool)
    .await {
        Ok(Some(user)) => user,
        Ok(None) => {
            warn!("Admin login failed for email: {} - not found", data.email);
            return Ok(Json(ApiResponse::<AdminAuthResponse>::error("잘못된 이메일 또는 비밀번호입니다.")));
        }
        Err(e) => {
            error!("Failed to fetch admin user from database: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 비밀번호 체크
    if !crate::utils::auth::verify_password(&data.password, admin_user_db.password_hash.as_deref().unwrap_or("")) {
        warn!("Admin login failed for email: {} - wrong password", data.email);
        return Ok(Json(ApiResponse::<AdminAuthResponse>::error("잘못된 이메일 또는 비밀번호입니다.")));
    }

    // role 체크
    match admin_user_db.role {
        Some(crate::models::user::UserRole::Admin) | Some(crate::models::user::UserRole::SuperAdmin) => {}
        _ => {
            warn!("Admin login failed for email: {} - not admin", data.email);
            return Ok(Json(ApiResponse::<AdminAuthResponse>::error("관리자 권한이 없습니다.")));
        }
    }

    // 관리자 사용자 정보 생성
    let admin_user = AdminUser {
        id: admin_user_db.id,
        name: admin_user_db.name.unwrap_or_else(|| "관리자".to_string()),
        email: admin_user_db.email.unwrap_or_else(|| "admin@example.com".to_string()),
        role: admin_user_db.role.map(|r| format!("{:?}", r)).unwrap_or_else(|| "super_admin".to_string()),
        status: admin_user_db.status.map(|s| format!("{:?}", s).to_lowercase()).unwrap_or_else(|| "active".to_string()),
    };

    // JWT 토큰 생성
    let (access_token, refresh_token) = match generate_tokens(&state.config, admin_user.id, admin_user.role.clone()) {
        Ok(tokens) => tokens,
        Err(e) => {
            error!("Failed to generate tokens for admin: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 리프레시 토큰을 데이터베이스에 저장
    let hashed_refresh_token = hash_refresh_token(&refresh_token);
    
    if let Err(e) = sqlx::query!(
        "INSERT INTO refresh_tokens (user_id, token_hash, expires_at, service_type) VALUES ($1, $2, $3, $4)",
        admin_user.id,
        hashed_refresh_token,
        Utc::now() + Duration::days(30),
        data.service_type
    )
    .execute(&state.pool)
    .await {
        error!("Failed to save refresh token to database: {}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    info!("Admin login completed successfully for email: {}", data.email);

    Ok(Json(ApiResponse::success(
        AdminAuthResponse {
            user: admin_user,
            access_token,
            refresh_token,
            expires_in: state.config.access_token_expiry * 60,
        },
        "관리자 로그인 성공"
    )))
}

// Admin 프로필 조회
pub async fn admin_me(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<ApiResponse<AdminUser>>, StatusCode> {
    debug!("Admin profile request for user: {}", claims.sub);

    // DB에서 관리자 사용자 정보 조회
    let admin_user_db = match sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE id = $1"
    )
    .bind(&claims.sub)
    .fetch_one(&state.pool)
    .await {
        Ok(user) => user,
        Err(e) => {
            error!("Failed to fetch admin user from database: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 관리자 사용자 정보 생성
    let admin_user = AdminUser {
        id: admin_user_db.id,
        name: admin_user_db.name.unwrap_or_else(|| "관리자".to_string()),
        email: admin_user_db.email.unwrap_or_else(|| "admin@example.com".to_string()),
        role: admin_user_db.role.map(|r| format!("{:?}", r).to_lowercase()).unwrap_or_else(|| "user".to_string()),
        status: admin_user_db.status.map(|s| format!("{:?}", s).to_lowercase()).unwrap_or_else(|| "active".to_string()),
    };

    Ok(Json(ApiResponse::success(admin_user, "관리자 프로필")))
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
    debug!("Fetching dashboard stats");
    
    // 사용자 수
    let total_users = match sqlx::query_scalar!("SELECT COUNT(*) FROM users")
        .fetch_one(&state.pool)
        .await {
        Ok(count) => count.unwrap_or(0),
        Err(e) => {
            error!("Failed to get total users count: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 게시글 수
    let total_posts = match sqlx::query_scalar!("SELECT COUNT(*) FROM posts")
        .fetch_one(&state.pool)
        .await {
        Ok(count) => count.unwrap_or(0),
        Err(e) => {
            error!("Failed to get total posts count: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 댓글 수
    let total_comments = match sqlx::query_scalar!("SELECT COUNT(*) FROM comments")
        .fetch_one(&state.pool)
        .await {
        Ok(count) => count.unwrap_or(0),
        Err(e) => {
            error!("Failed to get total comments count: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 게시판 수
    let total_boards = match sqlx::query_scalar!("SELECT COUNT(*) FROM boards")
        .fetch_one(&state.pool)
        .await {
        Ok(count) => count.unwrap_or(0),
        Err(e) => {
            error!("Failed to get total boards count: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 활성 봉사자 수 (임시로 활성 사용자로 대체)
    let active_volunteers = match sqlx::query_scalar!("SELECT COUNT(*) FROM users WHERE status = 'active'")
        .fetch_one(&state.pool)
        .await {
        Ok(count) => count.unwrap_or(0),
        Err(e) => {
            error!("Failed to get active volunteers count: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // 총 후원금 (임시로 0)
    let total_donations = 0;

    // 월간 방문자 (임시로 0)
    let monthly_visitors = 0;

    // 월간 게시글 수
    let monthly_posts = match sqlx::query_scalar!(
        "SELECT COUNT(*) FROM posts WHERE created_at >= NOW() - INTERVAL '1 month'"
    )
    .fetch_one(&state.pool)
    .await {
        Ok(count) => count.unwrap_or(0),
        Err(e) => {
            error!("Failed to get monthly posts count: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

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

    info!("Dashboard stats retrieved successfully");
    Ok(Json(ApiResponse::success(stats, "대시보드 통계")))
}

// 사용자 관리
#[derive(Deserialize, Debug)]
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
) -> Result<Json<ApiResponse<UsersResponse>>, StatusCode> {
    debug!("Fetching users with query: {:?}", query);
    
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    // 전체 사용자 수 조회
    let mut count_sql = "SELECT COUNT(*) FROM users".to_string();
    let mut conditions = Vec::new();

    if let Some(search) = &query.search {
        conditions.push(format!("(username ILIKE '%{}%' OR email ILIKE '%{}%' OR name ILIKE '%{}%' OR phone ILIKE '%{}%')", search, search, search, search));
    }

    if let Some(status) = &query.status {
        conditions.push(format!("status = '{}'", status));
    }

    if let Some(role) = &query.role {
        conditions.push(format!("role = '{}'", role));
    }

    if !conditions.is_empty() {
        count_sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    let total_users = sqlx::query_scalar::<_, i64>(&count_sql)
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            error!("Failed to count users: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 사용자 목록 조회
    let mut sql = "SELECT * FROM users".to_string();

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY created_at DESC LIMIT {} OFFSET {}", limit, offset));

    let users = match sqlx::query_as::<_, User>(&sql)
        .fetch_all(&state.pool)
        .await {
        Ok(users) => users,
        Err(e) => {
            error!("Failed to fetch users: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    let total_pages = (total_users + limit - 1) / limit;

    let pagination = PaginationInfo {
        page,
        limit,
        total: total_users,
        total_pages,
    };

    let response = UsersResponse {
        users: users.clone(),
        pagination,
    };

    info!("Retrieved {} users out of {} total", users.len(), total_users);
    Ok(Json(ApiResponse::success(response, "사용자 목록")))
}

// 사용자 상세 정보 조회
pub async fn get_user(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    debug!("Fetching user details for user ID: {}", user_id);
    
    // 사용자 기본 정보 조회
    let user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to fetch user: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    match user {
        Some(user) => {
            // 게시글 수 조회
            let post_count = sqlx::query_scalar!(
                "SELECT COUNT(*) FROM posts WHERE user_id = $1",
                user_id
            )
            .fetch_one(&state.pool)
            .await
            .unwrap_or(Some(0))
            .unwrap_or(0);

            // 포인트 잔액 조회
            let point_balance = sqlx::query_scalar!(
                "SELECT points FROM users WHERE id = $1",
                user_id
            )
            .fetch_one(&state.pool)
            .await
            .unwrap_or(Some(0))
            .unwrap_or(0);

            // JSON 응답 구성
            let user_data = serde_json::json!({
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "role": user.role.map(|r| format!("{:?}", r).to_lowercase()),
                "status": user.status.map(|s| format!("{:?}", s).to_lowercase()),
                "profile_image": user.profile_image,
                "last_login_at": user.last_login_at,
                "created_at": user.created_at,
                "updated_at": user.updated_at,
                "post_count": post_count,
                "point_balance": point_balance
            });

            info!("User details retrieved successfully for user ID: {}", user_id);
            Ok(Json(ApiResponse::success(user_data, "사용자 상세 정보")))
        },
        None => {
            warn!("User not found with ID: {}", user_id);
            Err(StatusCode::NOT_FOUND)
        }
    }
}

// 사용자 정보 수정
#[derive(Deserialize)]
pub struct UpdateUserRequest {
    pub name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub role: Option<String>,
    pub status: Option<String>,
}

pub async fn update_user(
    State(state): State<AppState>,
    Path(user_id): Path<Uuid>,
    Json(data): Json<UpdateUserRequest>,
) -> Result<Json<ApiResponse<User>>, StatusCode> {
    debug!("Updating user with ID: {}", user_id);
    
    // 사용자 존재 확인
    let existing_user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to check user existence: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if existing_user.is_none() {
        warn!("User not found with ID: {}", user_id);
        return Err(StatusCode::NOT_FOUND);
    }

    // 업데이트할 필드들 구성
    let mut updates = Vec::new();
    let mut params: Vec<String> = Vec::new();
    let mut param_count = 0;

    if let Some(name) = data.name {
        param_count += 1;
        updates.push(format!("name = ${}", param_count));
        params.push(name);
    }

    if let Some(email) = data.email {
        param_count += 1;
        updates.push(format!("email = ${}", param_count));
        params.push(email);
    }

    if let Some(phone) = data.phone {
        param_count += 1;
        updates.push(format!("phone = ${}", param_count));
        params.push(phone);
    }

    if let Some(role) = data.role {
        param_count += 1;
        updates.push(format!("role = ${}::user_role", param_count));
        params.push(role);
    }

    if let Some(status) = data.status {
        param_count += 1;
        updates.push(format!("status = ${}::user_status", param_count));
        params.push(status);
    }

    // updated_at 필드 추가 (파라미터 없음)
    updates.push("updated_at = NOW()".to_string());

    if updates.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    // 업데이트 쿼리 실행
    param_count += 1;
    let sql = format!(
        "UPDATE users SET {} WHERE id = ${} RETURNING *",
        updates.join(", "),
        param_count
    );
    params.push(user_id.to_string());

    let mut query_builder = sqlx::query_as::<_, User>(&sql);
    for (i, param) in params.iter().enumerate() {
        if i == params.len() - 1 {
            // 마지막 파라미터는 UUID
            query_builder = query_builder.bind(user_id);
        } else {
            // 나머지는 문자열
            query_builder = query_builder.bind(param);
        }
    }

    let updated_user = query_builder
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            error!("Failed to update user: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    info!("User updated successfully with ID: {}", user_id);
    Ok(Json(ApiResponse::success(updated_user, "사용자 정보가 수정되었습니다.")))
}

// 게시글 관리
#[derive(Deserialize, Debug)]
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
) -> Result<Json<ApiResponse<Vec<PostDetail>>>, StatusCode> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    println!("[DEBUG] Admin get_posts - page: {}, limit: {}, offset: {}", page, limit, offset);
    println!("[DEBUG] Query params - search: {:?}, board_id: {:?}, status: {:?}", query.search, query.board_id, query.status);

    // 전체 게시글 수 조회
    let mut count_sql = "SELECT COUNT(*) as total FROM posts p".to_string();
    let mut count_conditions = Vec::new();
    let mut count_param_count = 1;

    if let Some(ref search) = query.search {
        count_conditions.push(format!("(p.title ILIKE ${} OR p.content ILIKE ${} OR EXISTS (SELECT 1 FROM users u WHERE u.id = p.user_id AND u.name ILIKE ${}))", 
            count_param_count, count_param_count, count_param_count));
        count_param_count += 1;
    }

    if let Some(ref board_id) = query.board_id {
        // board_id를 UUID로 파싱
        match board_id.parse::<Uuid>() {
            Ok(uuid) => {
                count_conditions.push(format!("p.board_id = ${}", count_param_count));
                count_param_count += 1;
            }
            Err(_) => {
                // 잘못된 UUID 형식인 경우 빈 결과 반환
                return Ok(Json(ApiResponse {
                    success: true,
                    data: Some(Vec::new()),
                    message: "잘못된 게시판 ID입니다.".to_string(),
                    pagination: Some(crate::models::response::PaginationInfo {
                        page: page as u32,
                        limit: limit as u32,
                        total: 0,
                        total_pages: 0,
                    }),
                }));
            }
        }
    }

    if let Some(ref status) = query.status {
        count_conditions.push(format!("p.status = ${}", count_param_count));
        count_param_count += 1;
    }

    if !count_conditions.is_empty() {
        count_sql.push_str(&format!(" WHERE {}", count_conditions.join(" AND ")));
    }

    println!("[DEBUG] Count SQL: {}", count_sql);

    let mut count_query_builder = sqlx::query_scalar::<_, i64>(&count_sql);
    
    // 카운트 쿼리 파라미터 바인딩
    if let Some(ref search) = query.search {
        count_query_builder = count_query_builder.bind(format!("%{}%", search));
    }
    if let Some(ref board_id) = query.board_id {
        match board_id.parse::<Uuid>() {
            Ok(uuid) => count_query_builder = count_query_builder.bind(uuid),
            Err(_) => {} // 잘못된 UUID 형식은 무시
        }
    }
    if let Some(ref status) = query.status {
        count_query_builder = count_query_builder.bind(status);
    }

    let total = count_query_builder
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Error counting posts: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    println!("[DEBUG] Total posts count: {}", total);

    // 게시글 목록 조회
    let mut sql = r#"
        SELECT 
            p.id, p.board_id, p.category_id, p.user_id, p.title, p.content, 
            p.views, p.likes, p.is_notice, p.status::text as status, p.created_at, p.updated_at,
            u.name as user_name,
            b.name as board_name,
            c.name as category_name,
            COALESCE(comment_count.count, 0) as comment_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN (
            SELECT post_id, COUNT(*) as count 
            FROM comments 
            WHERE status = 'active' 
            GROUP BY post_id
        ) comment_count ON p.id = comment_count.post_id
    "#.to_string();
    
    let mut conditions = Vec::new();
    let mut param_count = 1;

    if let Some(ref search) = query.search {
        conditions.push(format!("(p.title ILIKE ${} OR p.content ILIKE ${} OR u.name ILIKE ${})", 
            param_count, param_count, param_count));
        param_count += 1;
    }

    if let Some(ref board_id) = query.board_id {
        match board_id.parse::<Uuid>() {
            Ok(uuid) => {
                conditions.push(format!("p.board_id = ${}", param_count));
                param_count += 1;
            }
            Err(_) => {} // 잘못된 UUID 형식은 무시
        }
    }

    if let Some(ref status) = query.status {
        conditions.push(format!("p.status = ${}", param_count));
        param_count += 1;
    }

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY p.created_at DESC LIMIT ${} OFFSET ${}", param_count, param_count + 1));

    println!("[DEBUG] Posts SQL: {}", sql);

    let mut query_builder = sqlx::query_as::<_, PostDetailRaw>(&sql);
    
    // 파라미터 바인딩
    if let Some(ref search) = query.search {
        query_builder = query_builder.bind(format!("%{}%", search));
    }
    if let Some(ref board_id) = query.board_id {
        match board_id.parse::<Uuid>() {
            Ok(uuid) => query_builder = query_builder.bind(uuid),
            Err(_) => {} // 잘못된 UUID 형식은 무시
        }
    }
    if let Some(ref status) = query.status {
        query_builder = query_builder.bind(status);
    }
    
    // LIMIT과 OFFSET은 숫자로 바인딩
    query_builder = query_builder.bind(limit as i64);
    query_builder = query_builder.bind(offset as i64);

    let posts_raw = query_builder
        .fetch_all(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Error fetching posts: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    println!("[DEBUG] Fetched posts count: {}", posts_raw.len());

    // PostDetailRaw를 PostDetail로 변환
    let posts: Vec<PostDetail> = posts_raw.into_iter().map(|post_raw| PostDetail {
        id: post_raw.id,
        board_id: post_raw.board_id,
        category_id: post_raw.category_id,
        user_id: post_raw.user_id,
        title: post_raw.title,
        content: post_raw.content,
        views: post_raw.views,
        likes: post_raw.likes,
        dislikes: None, // 기본값
        is_notice: post_raw.is_notice,
        status: post_raw.status.and_then(|s| PostStatus::from_str(&s).ok()),
        created_at: post_raw.created_at,
        updated_at: post_raw.updated_at,
        user_name: post_raw.user_name,
        user_email: None, // 기본값
        board_name: post_raw.board_name,
        board_slug: None, // admin에서는 board_slug가 필요하지 않음
        category_name: post_raw.category_name,
        comment_count: post_raw.comment_count,
        attached_files: None,
        thumbnail_urls: None, // 기본값
        is_liked: None, // 관리자 API에서는 좋아요 상태가 필요하지 않음
    }).collect();

    // 페이지네이션 정보 계산
    let total_pages = (total + limit - 1) / limit;
    let pagination = crate::models::response::PaginationInfo {
        page: page as u32,
        limit: limit as u32,
        total: total as u64,
        total_pages: total_pages as u32,
    };

    Ok(Json(ApiResponse {
        success: true,
        data: Some(posts),
        message: "게시글 목록을 성공적으로 조회했습니다.".to_string(),
        pagination: Some(pagination),
    }))
}

// 단일 게시글 조회
pub async fn get_post(
    State(state): State<AppState>,
    Path(post_id): Path<Uuid>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    println!("[DEBUG] Admin get_post - post_id: {}", post_id);

    // 게시글 상세 정보 조회
    let post_raw = match sqlx::query_as::<_, PostDetailRaw>(
        r#"
        SELECT 
            p.id, p.board_id, p.category_id, p.user_id, p.title, p.content, 
            p.views, p.likes, p.is_notice, p.status::text as status, p.created_at, p.updated_at,
            u.name as user_name, b.name as board_name, c.name as category_name,
            COALESCE(comment_count.count, 0) as comment_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN (
            SELECT post_id, COUNT(*) as count
            FROM comments
            WHERE status = 'active'
            GROUP BY post_id
        ) comment_count ON p.id = comment_count.post_id
        WHERE p.id = $1
        "#
    )
    .bind(post_id)
    .fetch_one(&state.pool)
    .await {
        Ok(post) => post,
        Err(sqlx::Error::RowNotFound) => {
            return Ok(Json(ApiResponse::<PostDetail>::error("게시글을 찾을 수 없습니다.")));
        }
        Err(e) => {
            error!("Failed to fetch post: {}", e);
            return Err(StatusCode::INTERNAL_SERVER_ERROR);
        }
    };

    // PostDetailRaw를 PostDetail로 변환
    let post = PostDetail {
        id: post_raw.id,
        board_id: post_raw.board_id,
        category_id: post_raw.category_id,
        user_id: post_raw.user_id,
        title: post_raw.title,
        content: post_raw.content,
        views: post_raw.views,
        likes: post_raw.likes,
        dislikes: None, // 기본값
        is_notice: post_raw.is_notice,
        status: post_raw.status.and_then(|s| PostStatus::from_str(&s).ok()),
        created_at: post_raw.created_at,
        updated_at: post_raw.updated_at,
        user_name: post_raw.user_name,
        user_email: None, // 기본값
        board_name: post_raw.board_name,
        board_slug: None, // admin에서는 board_slug가 필요하지 않을 수 있음
        category_name: post_raw.category_name,
        comment_count: post_raw.comment_count,
        attached_files: None,
        thumbnail_urls: None, // 기본값
        is_liked: None, // 관리자 API에서는 좋아요 상태가 필요하지 않음
    };

    println!("[DEBUG] Found post: {:?}", post);

    Ok(Json(ApiResponse::success(post, "게시글을 성공적으로 조회했습니다.")))
}

// 게시판 관리
pub async fn get_boards(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Board>>>, StatusCode> {
    let boards = sqlx::query_as::<_, Board>("SELECT * FROM boards ORDER BY display_order, created_at")
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
    pub post: Option<String>, // 게시글 ID
}

pub async fn get_comments(
    State(state): State<AppState>,
    Query(query): Query<CommentQuery>,
) -> Result<Json<ApiResponse<Vec<CommentDetail>>>, StatusCode> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    let mut sql = r#"
        SELECT 
            c.id, c.post_id, c.user_id, c.parent_id, c.content, c.likes, 
            c.status, c.created_at, c.updated_at,
            u.name as user_name
        FROM comments c
        LEFT JOIN users u ON c.user_id = u.id
    "#.to_string();
    let mut conditions = Vec::new();

    // 특정 게시글의 댓글만 조회
    if let Some(post_id) = query.post {
        match post_id.parse::<Uuid>() {
            Ok(uuid) => {
                conditions.push(format!("c.post_id = '{}'", uuid));
            }
            Err(_) => {
                return Ok(Json(ApiResponse::<Vec<CommentDetail>>::error("잘못된 게시글 ID입니다.")));
            }
        }
    }

    if let Some(search) = query.search {
        conditions.push(format!("c.content ILIKE '%{}%'", search));
    }

    if let Some(status) = query.status {
        conditions.push(format!("c.status = '{}'", status));
    }

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY c.created_at DESC LIMIT {} OFFSET {}", limit, offset));

    let comments = sqlx::query_as::<_, CommentDetail>(&sql)
        .fetch_all(&state.pool)
        .await
        .map_err(|e| {
            error!("Failed to fetch comments: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(Json(ApiResponse::success(comments, "댓글 목록")))
}

// Admin 로그아웃
pub async fn admin_logout(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> Result<Json<ApiResponse<String>>, StatusCode> {
    info!("Admin logout for user: {}", claims.sub);
    
    // 리프레시 토큰 삭제 (선택사항)
    // 실제로는 클라이언트에서 토큰을 삭제하므로 서버에서는 로그만 남김
    
    info!("Admin logout completed for user: {}", claims.sub);
    
    Ok(Json(ApiResponse::success("로그아웃 성공".to_string(), "관리자 로그아웃 성공")))
}

// 리프레시 토큰 요청 구조체
#[derive(Deserialize)]
pub struct AdminRefreshRequest {
    pub refresh_token: String,
    pub service_type: Option<String>,
}

// 관리자 토큰 재발행
pub async fn admin_refresh(
    State(state): State<AppState>,
    Json(data): Json<AdminRefreshRequest>,
) -> Result<Json<ApiResponse<RefreshResponse>>, StatusCode> {
    info!("Admin token refresh request");

    // 리프레시 토큰 검증
    let token_data = decode::<Claims>(
        &data.refresh_token,
        &DecodingKey::from_secret(state.config.refresh_secret.as_ref()),
        &Validation::default()
    )
    .map_err(|e| {
        error!("Failed to decode refresh token: {}", e);
        StatusCode::UNAUTHORIZED
    })?;

    let user_id = token_data.claims.sub;

    // 데이터베이스에서 리프레시 토큰 확인
    let refresh_token_hash = hash_refresh_token(&data.refresh_token);
    let service_type = data.service_type.unwrap_or_else(|| "admin".to_string());
    
    let stored_token = sqlx::query!(
        "SELECT * FROM refresh_tokens WHERE user_id = $1 AND token_hash = $2 AND service_type = $3 AND is_revoked = FALSE AND expires_at > NOW()",
        user_id,
        refresh_token_hash,
        service_type
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to check refresh token in database: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if stored_token.is_none() {
        error!("Invalid or expired refresh token for admin user: {}", user_id);
        return Err(StatusCode::UNAUTHORIZED);
    }

    // 새로운 토큰 생성
    let admin_user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to fetch admin user: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or(StatusCode::UNAUTHORIZED)?;

    let (access_token, new_refresh_token) = generate_tokens(&state.config, user_id, admin_user.role.as_ref().map(|r| format!("{:?}", r)).unwrap_or_else(|| "user".to_string()))
        .map_err(|e| {
            error!("Failed to generate new tokens: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let expires_in = state.config.access_token_expiry * 60; // minutes to seconds

    // 기존 리프레시 토큰 무효화
    if let Err(e) = sqlx::query!(
        "UPDATE refresh_tokens SET is_revoked = TRUE WHERE user_id = $1 AND token_hash = $2 AND service_type = $3",
        user_id,
        refresh_token_hash,
        service_type
    )
    .execute(&state.pool)
    .await {
        error!("Failed to revoke old refresh token: {}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    // 새로운 리프레시 토큰 저장
    let new_refresh_token_hash = hash_refresh_token(&new_refresh_token);
    if let Err(e) = sqlx::query!(
        "INSERT INTO refresh_tokens (user_id, token_hash, service_type, expires_at) VALUES ($1, $2, $3, $4)",
        user_id,
        new_refresh_token_hash,
        service_type,
        Utc::now() + Duration::days(state.config.refresh_token_expiry)
    )
    .execute(&state.pool)
    .await {
        error!("Failed to save new refresh token: {}", e);
        return Err(StatusCode::INTERNAL_SERVER_ERROR);
    }

    info!("Admin token refresh completed successfully for user: {}", user_id);

    Ok(Json(ApiResponse::success(
        RefreshResponse {
            access_token,
            refresh_token: new_refresh_token,
            expires_in,
        },
        "토큰 재발행 성공"
    )))
}

// 게시글 수정 (관리자)
pub async fn update_post(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
    Json(payload): Json<UpdatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 게시글 존재 확인
    let _post = sqlx::query_as::<_, Post>(
        "SELECT * FROM posts WHERE id = $1 AND status = 'active'"
    )
    .bind(post_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to check post existence: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 업데이트할 필드들
    let mut updates = Vec::new();
    let mut param_count = 0;

    if payload.board_id.is_some() {
        param_count += 1;
        updates.push(format!("board_id = ${}", param_count));
    }
    if payload.category_id.is_some() {
        param_count += 1;
        updates.push(format!("category_id = ${}", param_count));
    }
    if payload.title.is_some() {
        param_count += 1;
        updates.push(format!("title = ${}", param_count));
    }
    if payload.content.is_some() {
        param_count += 1;
        updates.push(format!("content = ${}", param_count));
    }
    if payload.is_notice.is_some() {
        param_count += 1;
        updates.push(format!("is_notice = ${}", param_count));
    }
    if updates.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }
    updates.push("updated_at = NOW()".to_string());
    param_count += 1;
    let sql = format!(
        "UPDATE posts SET {} WHERE id = ${} RETURNING id, board_id, category_id, user_id, title, content, views, likes, is_notice, status::text as status, created_at, updated_at,\n         (SELECT name FROM users WHERE id = user_id) as user_name,\n         (SELECT name FROM boards WHERE id = board_id) as board_name,\n         (SELECT name FROM categories WHERE id = category_id) as category_name,\n         (SELECT COUNT(*)::bigint FROM comments WHERE post_id = posts.id AND status = 'active') as comment_count",
        updates.join(", "),
        param_count
    );

    let mut query_builder = sqlx::query_as::<_, PostDetailRaw>(&sql);
    if let Some(board_id) = payload.board_id {
        query_builder = query_builder.bind(board_id);
    }
    if let Some(category_id) = payload.category_id {
        query_builder = query_builder.bind(category_id);
    }
    if let Some(title) = payload.title {
        query_builder = query_builder.bind(title);
    }
    if let Some(content) = payload.content {
        query_builder = query_builder.bind(content);
    }
    if let Some(is_notice) = payload.is_notice {
        query_builder = query_builder.bind(is_notice);
    }
    query_builder = query_builder.bind(post_id);

    let updated_post_raw = query_builder
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            error!("Failed to update post: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // PostDetailRaw를 PostDetail로 변환
    let updated_post = PostDetail {
        id: updated_post_raw.id,
        board_id: updated_post_raw.board_id,
        category_id: updated_post_raw.category_id,
        user_id: updated_post_raw.user_id,
        title: updated_post_raw.title,
        content: updated_post_raw.content,
        views: updated_post_raw.views,
        likes: updated_post_raw.likes,
        dislikes: None, // 기본값
        is_notice: updated_post_raw.is_notice,
        status: updated_post_raw.status.and_then(|s| PostStatus::from_str(&s).ok()),
        created_at: updated_post_raw.created_at,
        updated_at: updated_post_raw.updated_at,
        user_name: updated_post_raw.user_name,
        user_email: None, // 기본값
        board_name: updated_post_raw.board_name,
        board_slug: None, // admin에서는 board_slug가 필요하지 않을 수 있음
        category_name: updated_post_raw.category_name,
        comment_count: updated_post_raw.comment_count,
        attached_files: None,
        thumbnail_urls: None, // 기본값
        is_liked: None, // 관리자 API에서는 좋아요 상태가 필요하지 않음
    };

    Ok(Json(ApiResponse::success(updated_post, "게시글이 성공적으로 수정되었습니다.")))
} 