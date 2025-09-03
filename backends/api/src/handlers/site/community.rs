use axum::{
    extract::{Path, Query, State, Extension},
    http::StatusCode,
    response::Json,
    routing::{delete, get, post, put},
    Router,
};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;
use tracing::error;
use std::collections::HashMap;
use crate::utils::auth::get_current_user;
use crate::{
    models::site::community,
    models::admin::board::{Board, Category, CreateBoardRequest, UpdateBoardRequest},
    models::response::{ApiResponse, PaginationInfo},
    models::{FilePurpose, EntityType},
    errors::ApiError,
    utils::auth::Claims,
    utils::url_id::{resolve_post_uuid, generate_post_url_id},
    utils::uuid_compression::compress_uuid_to_base62,
    services::thumbnail::ThumbnailService,
    AppState,
};
use chrono::{DateTime, Utc};
use community::{Post, PostDetail, Comment, CommentDetail, CreatePostRequest, CreateReplyRequest, UpdatePostRequest, CreateCommentRequest, UpdateCommentRequest, PostFilter, PostListResponse, CommentListResponse, RecentPostsResponse, BoardStats, PostQuery, PostSummary, ThumbnailUrls, PostStatus, PostSummaryDb, AttachedFile, PostDetailResponse, PostSummaryResponse, CategoryResponse};
use ammonia::clean;
use std::str::FromStr;

// 권한 체크 유틸리티 함수들
fn can_list_board(board: &Board, user_role: Option<&str>) -> bool {
    let permission = &board.list_permission;
    
    match permission.as_str() {
        "guest" => true, // 모든 사용자 접근 가능
        "member" => user_role.is_some(), // 로그인한 사용자만
        "admin" => user_role == Some("admin"),
        _ => true,
    }
}

fn can_read_post(board: &Board, user_role: Option<&str>) -> bool {
    let permission = &board.read_permission;
    
    match permission.as_str() {
        "guest" => true,
        "member" => user_role.is_some(),
        "admin" => user_role == Some("admin"),
        _ => true,
    }
}

fn can_create_reply(board: &Board, user_role: Option<&str>) -> bool {
    // 답글 생성 권한은 게시글 작성 권한과 동일하게 설정
    let permission = &board.write_permission;
    
    match permission.as_str() {
        "guest" => true,
        "member" => user_role.is_some(),
        "admin" => user_role == Some("admin"),
        _ => true,
    }
}

fn can_write_post(board: &Board, user_role: Option<&str>) -> bool {
    let permission = &board.write_permission;
    
    // 익명 작성 허용 체크
    if board.allow_anonymous && permission == "guest" {
        return true;
    }
    
    match permission.as_str() {
        "guest" => true,
        "member" => user_role.is_some(),
        "admin" => user_role == Some("admin"),
        _ => user_role.is_some(),
    }
}

fn can_create_comment(board: &Board, user_role: Option<&str>) -> bool {
    let permission = &board.comment_permission;
    
    // 댓글 허용 체크
    if !board.allow_comments {
        return false;
    }
    
    match permission.as_str() {
        "guest" => true,
        "member" => user_role.is_some(),
        "admin" => user_role == Some("admin"),
        _ => user_role.is_some(),
    }
}

fn can_download_file(board: &Board, user_role: Option<&str>) -> bool {
    let permission = &board.download_permission;
    
    match permission.as_str() {
        "guest" => true,
        "member" => user_role.is_some(),
        "admin" => user_role == Some("admin"),
        _ => user_role.is_some(),
    }
}

// DB에서 가져온 raw Board 구조체
#[derive(Debug, sqlx::FromRow)]
struct BoardRaw {
    pub id: Uuid,
    pub slug: String,
    pub name: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub display_order: i32,
    pub is_public: bool,
    pub allow_anonymous: bool,
    pub allow_file_upload: bool,
    pub max_files: i32,
    pub max_file_size: i64,
    pub allowed_file_types: Option<String>, // DB에서는 문자열
    pub allow_rich_text: bool,
    pub require_category: bool,
    pub allow_comments: bool,
    pub allow_likes: bool,
    pub write_permission: String,
    pub list_permission: String,
    pub read_permission: String,
    pub reply_permission: String,
    pub comment_permission: String,
    pub download_permission: String,
    pub hide_list: bool,
    pub editor_type: String,
    pub allow_search: bool,
    pub allow_recommend: bool,
    pub allow_disrecommend: bool,
    pub show_author_name: bool,
    pub show_ip: bool,
    pub edit_comment_limit: i32,
    pub delete_comment_limit: i32,
    pub use_sns: bool,
    pub use_captcha: bool,
    pub title_length: i32,
    pub posts_per_page: i32,
    pub read_point: i32,
    pub write_point: i32,
    pub comment_point: i32,
    pub download_point: i32,
    pub allowed_iframe_domains: Option<String>, // DB에서는 문자열
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// 게시글 상세 정보 (쿼리용)
#[derive(Debug, sqlx::FromRow)]
struct PostDetailRaw {
    pub id: Uuid,
    pub title: String,
    pub content: String, // NOT NULL로 변경됨
    pub user_id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub parent_id: Option<Uuid>,
    pub depth: Option<i32>,
    pub reply_count: Option<i32>,
    pub is_notice: Option<bool>,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub dislikes: Option<i32>,
    pub status: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub attached_files: Option<Vec<String>>,
    pub thumbnail_urls: Option<serde_json::Value>,
    pub user_name: Option<String>,
    pub user_email: Option<String>,
    pub board_name: Option<String>,
    pub board_slug: Option<String>,
    pub category_name: Option<String>,
    pub comment_count: Option<i64>,
}

fn parse_csv_option(s: &Option<String>) -> Option<Vec<String>> {
    s.as_ref()
        .map(|raw| raw.split(',').map(|v| v.trim().to_string()).filter(|v| !v.is_empty()).collect())
}

fn convert_board_raw_to_board(raw: BoardRaw) -> Board {
    use crate::utils::uuid_compression::compress_uuid_to_base62;
    
    Board {
        id: raw.id,

        slug: raw.slug,
        name: raw.name,
        description: raw.description,
        category: raw.category,
        display_order: raw.display_order,
        is_public: raw.is_public,
        allow_anonymous: raw.allow_anonymous,
        allow_file_upload: raw.allow_file_upload,
        max_files: raw.max_files,
        max_file_size: raw.max_file_size,
        allowed_file_types: parse_csv_option(&raw.allowed_file_types),
        allow_rich_text: raw.allow_rich_text,
        require_category: raw.require_category,
        allow_comments: raw.allow_comments,
        allow_likes: raw.allow_likes,
        write_permission: raw.write_permission,
        list_permission: raw.list_permission,
        read_permission: raw.read_permission,
        reply_permission: raw.reply_permission,
        comment_permission: raw.comment_permission,
        download_permission: raw.download_permission,
        hide_list: raw.hide_list,
        editor_type: raw.editor_type,
        allow_search: raw.allow_search,
        allow_recommend: raw.allow_recommend,
        allow_disrecommend: raw.allow_disrecommend,
        show_author_name: raw.show_author_name,
        show_ip: raw.show_ip,
        edit_comment_limit: raw.edit_comment_limit,
        delete_comment_limit: raw.delete_comment_limit,
        use_sns: raw.use_sns,
        use_captcha: raw.use_captcha,
        title_length: raw.title_length,
        posts_per_page: raw.posts_per_page,
        read_point: raw.read_point,
        write_point: raw.write_point,
        comment_point: raw.comment_point,
        download_point: raw.download_point,
        allowed_iframe_domains: parse_csv_option(&raw.allowed_iframe_domains),
        created_at: raw.created_at,
        updated_at: raw.updated_at,
    }
}

// 게시판 목록 조회 (권한 체크 적용)
pub async fn get_boards(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
) -> Result<Json<ApiResponse<Vec<Board>>>, StatusCode> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    let boards = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT 
            id, slug, name, description, category, display_order, 
            COALESCE(is_public, true) as is_public, 
            COALESCE(allow_anonymous, false) as allow_anonymous,
            COALESCE(allow_file_upload, true) as allow_file_upload,
            COALESCE(max_files, 5) as max_files,
            COALESCE(max_file_size, 10485760) as max_file_size,
            allowed_file_types,
            COALESCE(allow_rich_text, true) as allow_rich_text,
            COALESCE(require_category, false) as require_category,
            COALESCE(allow_comments, true) as allow_comments,
            COALESCE(allow_likes, true) as allow_likes,
            COALESCE(write_permission, 'member') as write_permission,
            COALESCE(list_permission, 'guest') as list_permission,
            COALESCE(read_permission, 'guest') as read_permission,
            COALESCE(reply_permission, 'member') as reply_permission,
            COALESCE(comment_permission, 'member') as comment_permission,
            COALESCE(download_permission, 'member') as download_permission,
            COALESCE(hide_list, false) as hide_list,
            COALESCE(editor_type, 'rich') as editor_type,
            COALESCE(allow_search, true) as allow_search,
            COALESCE(allow_recommend, true) as allow_recommend,
            COALESCE(allow_disrecommend, false) as allow_disrecommend,
            COALESCE(show_author_name, true) as show_author_name,
            COALESCE(show_ip, false) as show_ip,
            COALESCE(edit_comment_limit, 0) as edit_comment_limit,
            COALESCE(delete_comment_limit, 0) as delete_comment_limit,
            COALESCE(use_sns, false) as use_sns,
            COALESCE(use_captcha, false) as use_captcha,
            COALESCE(title_length, 200) as title_length,
            COALESCE(posts_per_page, 20) as posts_per_page,
            COALESCE(read_point, 0) as read_point,
            COALESCE(write_point, 0) as write_point,
            COALESCE(comment_point, 0) as comment_point,
            COALESCE(download_point, 0) as download_point,
            allowed_iframe_domains,
            created_at, updated_at 
        FROM boards 
        WHERE COALESCE(is_public, true) = true 
        ORDER BY display_order, name
        "#
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching boards: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 권한 체크를 통과한 게시판만 필터링
    let filtered_boards: Vec<Board> = boards
        .into_iter()
        .map(convert_board_raw_to_board)
        .filter(|board| can_list_board(board, user_role))
        .collect();

    Ok(Json(ApiResponse {
        success: true,
        message: "게시판 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(filtered_boards),
        pagination: None,
    }))
}

// 게시판 상세 조회 (권한 체크 적용)
pub async fn get_board(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    Path(board_id): Path<Uuid>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT 
            id, slug, name, description, category, 
            COALESCE(display_order, 0) as display_order, 
            COALESCE(is_public, true) as is_public, 
            COALESCE(allow_anonymous, false) as allow_anonymous,
            COALESCE(allow_file_upload, true) as allow_file_upload,
            COALESCE(max_files, 5) as max_files,
            COALESCE(max_file_size, 10485760) as max_file_size,
            allowed_file_types,
            COALESCE(allow_rich_text, true) as allow_rich_text,
            COALESCE(require_category, false) as require_category,
            COALESCE(allow_comments, true) as allow_comments,
            COALESCE(allow_likes, true) as allow_likes,
            COALESCE(write_permission, 'member') as write_permission,
            COALESCE(list_permission, 'guest') as list_permission,
            COALESCE(read_permission, 'guest') as read_permission,
            COALESCE(reply_permission, 'member') as reply_permission,
            COALESCE(comment_permission, 'member') as comment_permission,
            COALESCE(download_permission, 'member') as download_permission,
            COALESCE(hide_list, false) as hide_list,
            COALESCE(editor_type, 'rich') as editor_type,
            COALESCE(allow_search, true) as allow_search,
            COALESCE(allow_recommend, true) as allow_recommend,
            COALESCE(allow_disrecommend, false) as allow_disrecommend,
            COALESCE(show_author_name, true) as show_author_name,
            COALESCE(show_ip, false) as show_ip,
            COALESCE(edit_comment_limit, 0) as edit_comment_limit,
            COALESCE(delete_comment_limit, 0) as delete_comment_limit,
            COALESCE(use_sns, false) as use_sns,
            COALESCE(use_captcha, false) as use_captcha,
            COALESCE(title_length, 200) as title_length,
            COALESCE(posts_per_page, 20) as posts_per_page,
            COALESCE(read_point, 0) as read_point,
            COALESCE(write_point, 0) as write_point,
            COALESCE(comment_point, 0) as comment_point,
            COALESCE(download_point, 0) as download_point,
            allowed_iframe_domains,
            created_at, updated_at
        FROM boards
        WHERE id = $1 AND COALESCE(is_public, true) = true
        "#
    )
    .bind(board_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiResponse::error("Failed to fetch board")),
        )
    })?
    .ok_or((
        StatusCode::NOT_FOUND,
        Json(ApiResponse::error("Board not found")),
    ))?;

    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크
    if !can_list_board(&board, user_role) {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ApiResponse::error("Access denied")),
        ));
    }

    Ok(Json(ApiResponse::success(board, "Board retrieved")))
}

// 카테고리 목록 조회 (게시판별)
pub async fn get_categories(
    Path(board_id): Path<Uuid>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Category>>>, StatusCode> {
    let categories_raw = sqlx::query_as::<_, Category>(
        "SELECT id, board_id, name, description, display_order, is_active, created_at, updated_at FROM categories WHERE board_id = $1 AND is_active = true ORDER BY display_order, name"
    )
    .bind(board_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 압축된 ID 추가
    let categories: Vec<Category> = categories_raw.into_iter().map(|mut category| {

        category
    }).collect();

    Ok(Json(ApiResponse {
        success: true,
        message: "카테고리 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(categories),
        pagination: None,
    }))
}

// 카테고리 목록 조회 (slug 기반)
pub async fn get_categories_by_slug(
    Path(slug): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Category>>>, StatusCode> {
    // 먼저 slug로 게시판 ID를 찾기
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT 
            id, slug, name, description, category, display_order, 
            COALESCE(is_public, true) as is_public, 
            COALESCE(allow_anonymous, false) as allow_anonymous,
            COALESCE(allow_file_upload, true) as allow_file_upload,
            COALESCE(max_files, 5) as max_files,
            COALESCE(max_file_size, 10485760) as max_file_size,
            allowed_file_types,
            COALESCE(allow_rich_text, true) as allow_rich_text,
            COALESCE(require_category, false) as require_category,
            COALESCE(allow_comments, true) as allow_comments,
            COALESCE(allow_likes, true) as allow_likes,
            COALESCE(write_permission, 'member') as write_permission,
            COALESCE(list_permission, 'guest') as list_permission,
            COALESCE(read_permission, 'guest') as read_permission,
            COALESCE(reply_permission, 'member') as reply_permission,
            COALESCE(comment_permission, 'member') as comment_permission,
            COALESCE(download_permission, 'member') as download_permission,
            COALESCE(hide_list, false) as hide_list,
            COALESCE(editor_type, 'rich') as editor_type,
            COALESCE(allow_search, true) as allow_search,
            COALESCE(allow_recommend, true) as allow_recommend,
            COALESCE(allow_disrecommend, false) as allow_disrecommend,
            COALESCE(show_author_name, true) as show_author_name,
            COALESCE(show_ip, false) as show_ip,
            COALESCE(edit_comment_limit, 0) as edit_comment_limit,
            COALESCE(delete_comment_limit, 0) as delete_comment_limit,
            COALESCE(use_sns, false) as use_sns,
            COALESCE(use_captcha, false) as use_captcha,
            COALESCE(title_length, 200) as title_length,
            COALESCE(posts_per_page, 20) as posts_per_page,
            COALESCE(read_point, 0) as read_point,
            COALESCE(write_point, 0) as write_point,
            COALESCE(comment_point, 0) as comment_point,
            COALESCE(download_point, 0) as download_point,
            allowed_iframe_domains,
            created_at, updated_at
        FROM boards 
        WHERE slug = $1 AND COALESCE(is_public, true) = true
        "#
    )
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board by slug: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or(StatusCode::NOT_FOUND)?;

    let board = convert_board_raw_to_board(board_raw);

    // 게시판 ID로 카테고리 조회
    let categories_raw = sqlx::query_as::<_, Category>(
        "SELECT id, board_id, name, description, display_order, is_active, created_at, updated_at FROM categories WHERE board_id = $1 AND is_active = true ORDER BY display_order, name"
    )
    .bind(board.id)
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching categories: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 압축된 ID 추가
    let categories: Vec<Category> = categories_raw.into_iter().map(|mut category| {

        category
    }).collect();

    Ok(Json(ApiResponse {
        success: true,
        message: "카테고리 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(categories),
        pagination: None,
    }))
}

// 게시글 목록 조회 (권한 체크 적용)
pub async fn get_posts(
    Query(query): Query<PostQuery>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
) -> Result<Json<ApiResponse<Vec<PostSummaryResponse>>>, StatusCode> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    // 게시판 권한 체크 (board_id가 있는 경우)
    if let Some(board_id) = query.board_id {
        let board_raw = sqlx::query_as::<_, BoardRaw>(
            r#"
            SELECT * FROM boards WHERE id = $1
            "#
        )
        .bind(board_id)
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Error fetching board: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
        let board = convert_board_raw_to_board(board_raw);

        // 권한 체크
        if !can_read_post(&board, user_role) {
            return Err(StatusCode::FORBIDDEN);
        }
    }

    // 기본값 설정
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(10).min(100); // 최대 100개로 제한
    let offset = (page - 1) * limit;
    
    // 정렬 조건 설정 (기본값: 최신순)
    let sort_order = match query.sort.as_deref() {
        Some("popular") => "p.likes DESC NULLS LAST, p.views DESC NULLS LAST",
        Some("comments") => "comment_count DESC NULLS LAST",
        Some("oldest") => "p.created_at ASC",
        _ => "p.created_at DESC"
    };

    // 검색어 처리
    let search = query.search.as_ref().map(|s| format!("%{}%", s));

    // 전체 개수 조회
    let total: i64 = if let Some(search) = &search {
        if let Some(board_id) = query.board_id {
            if let Some(category_id) = query.category_id {
                sqlx::query_scalar!(
                    r#"SELECT COUNT(*) as total FROM posts p
                        JOIN users u ON p.user_id = u.id
                        WHERE p.status IN ('active', 'published') AND p.board_id = $1 AND p.category_id = $2
                        AND (
                            p.title ILIKE $3 OR
                            p.content ILIKE $3 OR
                            u.name ILIKE $3 OR
                            EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $3)
                        )
                    "#,
                    board_id, category_id, search
                )
                .fetch_one(&state.pool)
                .await
                .map_err(|e| {
                    eprintln!("Count query error: {:?}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar!(
                    r#"SELECT COUNT(*) as total FROM posts p
                        JOIN users u ON p.user_id = u.id
                        WHERE p.status IN ('active', 'published') AND p.board_id = $1
                        AND (
                            p.title ILIKE $2 OR
                            p.content ILIKE $2 OR
                            u.name ILIKE $2 OR
                            EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $2)
                        )
                    "#,
                    board_id, search
                )
                .fetch_one(&state.pool)
                .await
                .map_err(|e| {
                    eprintln!("Count query error: {:?}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?
                .unwrap_or(0)
            }
        } else {
            sqlx::query_scalar!(
                r#"SELECT COUNT(*) as total FROM posts p
                    JOIN users u ON p.user_id = u.id
                    WHERE p.status IN ('active', 'published')
                    AND (
                        p.title ILIKE $1 OR
                        p.content ILIKE $1 OR
                        u.name ILIKE $1 OR
                        EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $1)
                    )
                "#,
                search
            )
            .fetch_one(&state.pool)
            .await
            .map_err(|e| {
                eprintln!("Count query error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?
            .unwrap_or(0)
        }
    } else {
        if let Some(board_id) = query.board_id {
            if let Some(category_id) = query.category_id {
                sqlx::query_scalar!(
                    "SELECT COUNT(*) as total FROM posts p WHERE p.status IN ('active', 'published') AND p.board_id = $1 AND p.category_id = $2",
                    board_id, category_id
                )
                .fetch_one(&state.pool)
                .await
                .map_err(|e| {
                    eprintln!("Count query error: {:?}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?
                .unwrap_or(0)
            } else {
                sqlx::query_scalar!(
                    "SELECT COUNT(*) as total FROM posts p WHERE p.status IN ('active', 'published') AND p.board_id = $1",
                    board_id
                )
                .fetch_one(&state.pool)
                .await
                .map_err(|e| {
                    eprintln!("Count query error: {:?}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?
                .unwrap_or(0)
            }
        } else {
            sqlx::query_scalar!(
                "SELECT COUNT(*) as total FROM posts p WHERE p.status IN ('active', 'published')"
            )
            .fetch_one(&state.pool)
            .await
            .map_err(|e| {
                eprintln!("Count query error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?
            .unwrap_or(0)
        }
    };

    // 게시글 목록 조회 (정렬은 기본값으로 고정)
    let posts = if let Some(search) = &search {
        if let Some(board_id) = query.board_id {
            if let Some(category_id) = query.category_id {
                sqlx::query_as!(
                    PostSummaryDb,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, b.slug as board_slug, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')), 0) as comment_count,
                           p.content, p.views, p.likes, p.is_notice,
                           COALESCE(c.name, NULL) as category_name,
                           p.parent_id, p.depth, p.reply_count, p.thumbnail_urls
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    LEFT JOIN categories c ON p.category_id = c.id
                    WHERE p.status IN ('active', 'published') AND p.board_id = $1 AND p.category_id = $2
                        AND (
                            p.title ILIKE $3 OR
                            p.content ILIKE $3 OR
                            u.name ILIKE $3 OR
                            EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $3)
                        )
                    ORDER BY p.is_notice DESC, p.created_at DESC
                    LIMIT $4 OFFSET $5
                    "#,
                    board_id, category_id, search, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            } else {
                sqlx::query_as!(
                    PostSummaryDb,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, b.slug as board_slug, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')), 0) as comment_count,
                           p.content, p.views, p.likes, p.is_notice,
                           COALESCE(c.name, NULL) as category_name,
                           p.parent_id, p.depth, p.reply_count, p.thumbnail_urls
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    LEFT JOIN categories c ON p.category_id = c.id
                    WHERE p.status IN ('active', 'published') AND p.board_id = $1
                        AND (
                            p.title ILIKE $2 OR
                            p.content ILIKE $2 OR
                            u.name ILIKE $2 OR
                            EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $2)
                        )
                    ORDER BY p.is_notice DESC, p.created_at DESC
                    LIMIT $3 OFFSET $4
                    "#,
                    board_id, search, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            }
        } else {
            sqlx::query_as!(
                PostSummaryDb,
                r#"
                SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, b.slug as board_slug, p.created_at,
                       COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')), 0) as comment_count,
                       p.content, p.views, p.likes, p.is_notice,
                       COALESCE(c.name, NULL) as category_name,
                       p.parent_id, p.depth, p.reply_count, p.thumbnail_urls
                FROM posts p
                JOIN users u ON p.user_id = u.id
                JOIN boards b ON p.board_id = b.id
                LEFT JOIN categories c ON p.category_id = c.id
                WHERE p.status IN ('active', 'published')
                    AND (
                        p.title ILIKE $1 OR
                        p.content ILIKE $1 OR
                        u.name ILIKE $1 OR
                        EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $1)
                    )
                ORDER BY p.is_notice DESC, p.created_at DESC
                LIMIT $2 OFFSET $3
                "#,
                search, limit, offset
            )
            .fetch_all(&state.pool)
            .await
        }
    } else {
        if let Some(board_id) = query.board_id {
            if let Some(category_id) = query.category_id {
                sqlx::query_as!(
                    PostSummaryDb,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, b.slug as board_slug, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')), 0) as comment_count,
                           p.content, p.views, p.likes, p.is_notice,
                           COALESCE(c.name, NULL) as category_name,
                           p.parent_id, p.depth, p.reply_count, p.thumbnail_urls
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    LEFT JOIN categories c ON p.category_id = c.id
                    WHERE p.status IN ('active', 'published') AND p.board_id = $1 AND p.category_id = $2
                    ORDER BY p.is_notice DESC, p.created_at DESC
                    LIMIT $3 OFFSET $4
                    "#,
                    board_id, category_id, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            } else {
                sqlx::query_as!(
                    PostSummaryDb,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, b.slug as board_slug, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')), 0) as comment_count,
                           p.content, p.views, p.likes, p.is_notice,
                           COALESCE(c.name, NULL) as category_name,
                           p.parent_id, p.depth, p.reply_count, p.thumbnail_urls
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    LEFT JOIN categories c ON p.category_id = c.id
                    WHERE p.status IN ('active', 'published') AND p.board_id = $1
                    ORDER BY p.is_notice DESC, p.created_at DESC
                    LIMIT $2 OFFSET $3
                    "#,
                    board_id, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            }
        } else {
            sqlx::query_as!(
                PostSummaryDb,
                r#"
                SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, b.slug as board_slug, p.created_at,
                       COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')), 0) as comment_count,
                       p.content, p.views, p.likes, p.is_notice,
                       COALESCE(c.name, NULL) as category_name,
                       p.parent_id, p.depth, p.reply_count, p.thumbnail_urls
                FROM posts p
                JOIN users u ON p.user_id = u.id
                JOIN boards b ON p.board_id = b.id
                LEFT JOIN categories c ON p.category_id = c.id
                WHERE p.status IN ('active', 'published')
                ORDER BY p.is_notice DESC, p.created_at DESC
                LIMIT $1 OFFSET $2
                "#,
                limit, offset
            )
            .fetch_all(&state.pool)
            .await
        }
    };
    let posts = posts.map_err(|e| {
        eprintln!("Posts query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 각 게시글의 첨부파일 정보 가져오기
    let mut posts_with_files = Vec::new();
    for post in posts {
        // 첨부파일 목록 조회
        let attached_files = sqlx::query_scalar!(
            r#"
            SELECT f.file_path
            FROM files f
            JOIN file_entities fe ON f.id = fe.file_id
            WHERE fe.entity_type = 'post' AND fe.entity_id = $1 AND f.status = 'published'
            ORDER BY fe.display_order, f.created_at
            "#,
            post.id
        )
        .fetch_all(&state.pool)
        .await
        .unwrap_or_default();

        let attached_files_option = if attached_files.is_empty() {
            None
        } else {
            Some(attached_files)
        };

        let thumbnail_urls = generate_thumbnail_urls(&attached_files_option).await;

        // URL ID 생성
        let url_id = generate_post_url_id(&state.pool, &post.id).await.ok();

        let post_with_files = PostSummary {
            id: post.id,


            title: post.title,
            board_id: post.board_id,
            user_name: post.user_name,
            board_name: post.board_name,
            board_slug: post.board_slug,
            category_name: post.category_name,
            created_at: post.created_at,
            comment_count: post.comment_count,
            content: post.content,
            views: post.views,
            likes: post.likes,
            is_notice: post.is_notice,
            attached_files: attached_files_option,
            thumbnail_urls,
            parent_id: post.parent_id,
            depth: post.depth,
            reply_count: post.reply_count,
        };
        
        posts_with_files.push(post_with_files);
    }

    // 정렬이 필요한 경우 메모리에서 정렬 (공지사항 우선 고정)
    let mut posts = posts_with_files;
    if let Some(ref sort) = query.sort {
        match sort.as_str() {
            "latest" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 최신순
                    b.is_notice.cmp(&a.is_notice).then(b.created_at.cmp(&a.created_at))
                });
            }
            "oldest" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 오래된순
                    b.is_notice.cmp(&a.is_notice).then(a.created_at.cmp(&b.created_at))
                });
            }
            "views" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 조회수순
                    b.is_notice.cmp(&a.is_notice).then(b.views.cmp(&a.views))
                });
            }
            "likes" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 좋아요순
                    b.is_notice.cmp(&a.is_notice).then(b.likes.cmp(&a.likes))
                });
            }
            _ => {
                posts.sort_by(|a, b| {
                    // 기본값: 공지사항 우선, 그 다음 최신순
                    b.is_notice.cmp(&a.is_notice).then(b.created_at.cmp(&a.created_at))
                });
            }
        }
    } else {
        // 정렬 옵션이 없어도 공지사항 우선 정렬
        posts.sort_by(|a, b| {
            b.is_notice.cmp(&a.is_notice).then(b.created_at.cmp(&a.created_at))
        });
    }

    // 페이지네이션 정보 계산
    let total_pages = (total + limit - 1) / limit;
    let pagination = Some(PaginationInfo {
        page: page as u32,
        limit: limit as u32,
        total: total as u64,
        total_pages: total_pages as u32,
    });

    // PostSummary를 PostSummaryResponse로 변환
    let posts_response: Vec<PostSummaryResponse> = posts.into_iter().map(|post| post.to_response()).collect();

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(posts_response),
        pagination,
    }))
}

// 게시글 상세 조회 (권한 체크 적용)
pub async fn get_post(
    Path(url_id): Path<String>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    // URL ID, 압축된 ID, 또는 UUID를 UUID로 변환
    let post_id = if url_id.contains('-') && url_id.len() < 20 {
        // URL ID 형태 (예: 1-Nu_EJg)
        match resolve_post_uuid(&state.pool, &url_id).await {
            Ok(uuid) => {
                println!("✅ URL ID 변환 성공: {} -> {}", url_id, uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 게시글 URL ID: {}", url_id);
                return Ok(Json(ApiResponse {
                    success: false,
                    message: "존재하지 않는 게시글입니다.".to_string(),
                    data: None,
                    pagination: None,
                }));
            }
        }
    } else if url_id.len() == 22 && url_id.chars().all(|c| c.is_alphanumeric()) {
        // Base62 압축된 ID 형태 (22자리)
        use crate::utils::uuid_compression::decompress_base62_to_uuid;
        match decompress_base62_to_uuid(&url_id) {
            Ok(uuid) => {
                println!("✅ 압축된 ID 변환 성공: {} -> {}", url_id, uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 압축된 ID: {}", url_id);
                return Ok(Json(ApiResponse {
                    success: false,
                    message: "잘못된 ID 형식입니다.".to_string(),
                    data: None,
                    pagination: None,
                }));
            }
        }
    } else {
        // 기존 UUID 형태 (하위 호환성)
        match uuid::Uuid::parse_str(&url_id) {
            Ok(uuid) => {
                println!("✅ UUID 직접 사용: {}", uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 ID 형식: {}", url_id);
                return Ok(Json(ApiResponse {
                    success: false,
                    message: "잘못된 ID 형식입니다.".to_string(),
                    data: None,
                    pagination: None,
                }));
            }
        }
    };
    
    // 먼저 기본 게시글 정보만 조회해서 테스트 (status를 text로 캐스팅)
    let post_basic = sqlx::query!(
        "SELECT id, board_id, category_id, user_id, parent_id, depth, reply_count, title, content, views, likes, dislikes, is_notice, status::text as status, created_at, updated_at FROM posts WHERE id = $1 AND status IN ('active', 'published')",
        post_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Basic post query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 게시판 정보 조회 (권한 체크용)
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE id = $1
        "#
    )
    .bind(post_basic.board_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크
    if !can_read_post(&board, user_role) {
        return Err(StatusCode::FORBIDDEN);
    }

    // 조회수 증가
    sqlx::query("UPDATE posts SET views = COALESCE(views, 0) + 1 WHERE id = $1")
        .bind(post_id)
        .execute(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Update views error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 사용자 정보 조회
    let user_info = sqlx::query!("SELECT name FROM users WHERE id = $1", post_basic.user_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("User query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 게시판 정보 조회
    let board_info = sqlx::query!("SELECT name, slug FROM boards WHERE id = $1", post_basic.board_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Board query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 카테고리 정보 조회 (optional)
    let category_name = if let Some(category_id) = post_basic.category_id {
        let category_info = sqlx::query!("SELECT name FROM categories WHERE id = $1", category_id)
            .fetch_optional(&state.pool)
            .await
            .map_err(|e| {
                eprintln!("Category query error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;
        category_info.map(|c| c.name)
    } else {
        None
    };

    // 댓글 수 조회
    let comment_count = sqlx::query!("SELECT COUNT(*) as count FROM comments WHERE post_id = $1 AND status IN ('active', 'published')", post_id)
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Comment count query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .count
        .unwrap_or(0);

    // 첨부 파일 조회
    let attached_files = sqlx::query!(
        r#"
        SELECT f.id, f.original_name, f.stored_name, f.file_path, f.file_size, f.mime_type, 
               fe.display_order
        FROM file_entities fe
        JOIN files f ON fe.file_id = f.id
        WHERE fe.entity_id = $1
        ORDER BY fe.display_order
        "#,
        post_id
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Attached files query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .into_iter()
    .map(|file| AttachedFile {
        id: file.id,
        original_name: file.original_name,
        file_path: format!("/uploads/{}", file.file_path.trim_start_matches("static/uploads/")),
        file_size: file.file_size,
        mime_type: file.mime_type,
        file_purpose: Some(FilePurpose::Attachment), // 기본값으로 설정
        display_order: Some(file.display_order.unwrap_or(0)),
    })
    .collect::<Vec<AttachedFile>>();

    // 현재 사용자의 좋아요 상태 확인
    let is_liked = if let Some(user_id) = claims.as_ref().map(|c| c.sub) {
        sqlx::query!("SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND entity_id = $2 AND entity_type = 'post') as is_liked", user_id, post_id)
            .fetch_one(&state.pool)
            .await
            .map(|row| row.is_liked.unwrap_or(false))
            .unwrap_or(false)
    } else {
        false
    };

    // URL ID 생성
    let url_id = generate_post_url_id(&state.pool, &post_basic.id).await.ok();

    let post = PostDetail {
        id: post_basic.id,


        board_id: post_basic.board_id,
        category_id: post_basic.category_id,
        user_id: post_basic.user_id,
        parent_id: post_basic.parent_id,
        depth: post_basic.depth,
        reply_count: post_basic.reply_count,
        title: post_basic.title,
        content: post_basic.content,
        views: post_basic.views,
        likes: post_basic.likes,
        dislikes: post_basic.dislikes,
        is_notice: post_basic.is_notice,
        status: post_basic.status.and_then(|s| s.parse::<PostStatus>().ok()),
        created_at: post_basic.created_at,
        updated_at: post_basic.updated_at,
        user_name: user_info.map(|u| u.name),
        user_email: None, // user_info에는 email 필드가 없음
        board_name: board_info.as_ref().map(|b| b.name.clone()),
        board_slug: board_info.map(|b| b.slug),
        category_name,
        comment_count: Some(comment_count),
        attached_files: Some(attached_files), // 첨부 파일 정보 포함
        thumbnail_urls: None, // 기본값
        is_liked: Some(is_liked), // 좋아요 상태 포함
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글을 성공적으로 조회했습니다.".to_string(),
        data: Some(post),
        pagination: None,
    }))
}

// 게시글 작성 (권한 체크 적용)
pub async fn create_post(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
    Json(payload): Json<CreatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 게시판 정보 조회 (권한 체크용)
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE id = $1
        "#
    )
    .bind(payload.board_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("create_post 게시판 조회 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크
    if !can_write_post(&board, Some(&claims.role)) {
        error!("create_post 권한 없음: role={}", claims.role);
        return Err(StatusCode::FORBIDDEN);
    }
    
    let sanitized_content = clean(&payload.content);
    
    // 먼저 게시글을 생성
    let post_result = sqlx::query!(
        "INSERT INTO posts (board_id, category_id, user_id, title, content, is_notice, status)
         VALUES ($1, $2, $3, $4, $5, $6, 'published')
         RETURNING id, board_id, category_id, user_id, parent_id, depth, reply_count, title, content, views, likes, dislikes, is_notice, status::text, created_at, updated_at",
        payload.board_id,
        payload.category_id,
        claims.sub,
        payload.title,
        sanitized_content,
        payload.is_notice.unwrap_or(false)
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("create_post DB INSERT 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    
    // 사용자 정보 조회
    let user_info = sqlx::query!("SELECT name, email FROM users WHERE id = $1", claims.sub)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            error!("User query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    // 게시판 정보 조회
    let board_info = sqlx::query!("SELECT name, slug FROM boards WHERE id = $1", post_result.board_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            error!("Board query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    // 카테고리 정보 조회
    let category_name = if let Some(category_id) = post_result.category_id {
        sqlx::query_scalar!("SELECT name FROM categories WHERE id = $1", category_id)
            .fetch_optional(&state.pool)
            .await
            .unwrap_or(None)
    } else {
        None
    };
    
    // 첨부파일에서 썸네일 URL 생성
    let thumbnail_urls = if let Some(ref attached_files) = payload.attached_files {
        generate_thumbnail_urls(&Some(attached_files.clone())).await
    } else {
        None
    };
    
    // 썸네일 URL을 posts 테이블에 저장
    if let Some(ref thumbnails) = thumbnail_urls {
        sqlx::query!(
            "UPDATE posts SET thumbnail_urls = $1 WHERE id = $2",
            serde_json::to_value(thumbnails).unwrap(),
            post_result.id
        )
        .execute(&state.pool)
        .await
        .map_err(|e| {
            error!("썸네일 URL 저장 실패: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    }
    
    // PostDetail 객체 생성
    // URL ID 생성
    let url_id = generate_post_url_id(&state.pool, &post_result.id).await.ok();

    let post = PostDetail {
        id: post_result.id,


        board_id: post_result.board_id,
        category_id: post_result.category_id,
        user_id: post_result.user_id,
        parent_id: post_result.parent_id,
        depth: post_result.depth,
        reply_count: post_result.reply_count,
        title: post_result.title,
        content: post_result.content,
        views: post_result.views,
        likes: post_result.likes,
        dislikes: post_result.dislikes,
        is_notice: post_result.is_notice,
        status: post_result.status.and_then(|s| s.parse::<PostStatus>().ok()),
        created_at: post_result.created_at,
        updated_at: post_result.updated_at,
        user_name: user_info.as_ref().map(|u| u.name.clone()),
        user_email: user_info.as_ref().map(|u| u.email.clone()),
        board_name: board_info.as_ref().map(|b| b.name.clone()),
        board_slug: board_info.as_ref().map(|b| b.slug.clone()),
        category_name,
        comment_count: Some(0),
        attached_files: None,
        thumbnail_urls,
        is_liked: None,
    };
    


    // 첨부된 파일들을 file_entities 테이블에 연결하고 상태를 published로 변경
    if let Some(attached_files) = payload.attached_files {
        for (index, file_url) in attached_files.iter().enumerate() {
            // file_url에서 파일명 추출 (전체 URL에서 파일명만 추출)
            let file_name = if file_url.contains("/uploads/") {
                // URL에서 파일명 부분만 추출
                let path_part = file_url.split("/uploads/").last().unwrap_or("");
                // 경로에서 파일명만 추출 (마지막 부분)
                let extracted_name = path_part.split('/').last().unwrap_or("");
                
                // 썸네일 파일명에서 _large 접미사 제거하여 원본 파일명 찾기
                if extracted_name.contains("_large.") {
                    // _large. 확장자 부분을 제거하고 원본 파일명으로 변환
                    extracted_name.replace("_large.", ".")
                } else {
                    extracted_name.to_string()
                }
            } else {
                file_url.to_string()
            };
            
            // files 테이블에서 해당 파일 조회 (stored_name으로 검색)
            // 먼저 파일이 존재하는지 확인 (상태 무관)
            let file_exists = sqlx::query!(
                "SELECT id, status::text FROM files WHERE stored_name = $1",
                file_name
            )
            .fetch_optional(&state.pool)
            .await;
            
            match file_exists {
                Ok(Some(file_info)) => {
                    let status = file_info.status.as_deref().unwrap_or("unknown");
                    if status == "draft" {
                        // draft 상태인 경우 처리
                        let file_id = file_info.id;
                        
                        // 파일 상태를 published로 변경
                        sqlx::query!(
                            "UPDATE files SET status = 'published' WHERE id = $1",
                            file_id
                        )
                        .execute(&state.pool)
                        .await
                        .map_err(|e| {
                            eprintln!("File status update error: {:?}", e);
                            StatusCode::INTERNAL_SERVER_ERROR
                        })?;

                        // file_entities 테이블에 연결 정보 저장
                        sqlx::query!(
                            "INSERT INTO file_entities (file_id, entity_type, entity_id, file_purpose, display_order)
                             VALUES ($1, $2, $3, $4, $5)",
                            file_id,
                            EntityType::Post as EntityType,  // entity_type을 Post로 설정
                            post.id,
                            FilePurpose::Attachment as FilePurpose,  // file_purpose를 Attachment로 설정
                            index as i32
                        )
                        .execute(&state.pool)
                        .await
                        .map_err(|e| {
                            eprintln!("File entity creation error: {:?}", e);
                            StatusCode::INTERNAL_SERVER_ERROR
                        })?;
                    }
                },
                Ok(None) => {
                    // 파일이 데이터베이스에 없는 경우 무시
                },
                Err(e) => {
                    eprintln!("Error querying file: {:?}", e);
                }
            }
        }
    }

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글이 성공적으로 작성되었습니다.".to_string(),
        data: Some(post),
        pagination: None,
    }))
}

// 게시글 수정
pub async fn update_post(
    Path(post_id_str): Path<String>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
    Json(payload): Json<UpdatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    
    // 압축된 ID 또는 UUID를 UUID로 변환
    let post_id = if post_id_str.len() == 22 && post_id_str.chars().all(|c| c.is_alphanumeric()) {
        // Base62 압축된 ID 형태 (22자리)
        use crate::utils::uuid_compression::decompress_base62_to_uuid;
        match decompress_base62_to_uuid(&post_id_str) {
            Ok(uuid) => {
                println!("✅ 압축된 ID 변환 성공: {} -> {}", post_id_str, uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 압축된 ID: {}", post_id_str);
                return Err(StatusCode::BAD_REQUEST);
            }
        }
    } else {
        // 기존 UUID 형태 (하위 호환성)
        match uuid::Uuid::parse_str(&post_id_str) {
            Ok(uuid) => {
                println!("✅ UUID 직접 사용: {}", uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 ID 형식: {}", post_id_str);
                return Err(StatusCode::BAD_REQUEST);
            }
        }
    };
    
    // 권한 확인
    let post = sqlx::query_as::<_, Post>(
        "SELECT * FROM posts WHERE id = $1 AND status = 'published'"
    )
    .bind(post_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to fetch post: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 게시글 작성자만 수정 가능
    if post.user_id != claims.sub {
        eprintln!("권한 없음: post_user_id={}, current_user_id={}", post.user_id, claims.sub);
        return Err(StatusCode::FORBIDDEN);
    }

    // 업데이트할 필드들
    let mut updates = Vec::new();
    let mut param_count = 0;

    if let Some(ref board_id) = payload.board_id {
        param_count += 1;
        updates.push(format!("board_id = ${}", param_count));
    }

    if let Some(ref category_id) = payload.category_id {
        param_count += 1;
        updates.push(format!("category_id = ${}", param_count));
    }

    if let Some(ref title) = payload.title {
        param_count += 1;
        updates.push(format!("title = ${}", param_count));
    }

    if let Some(ref content) = payload.content {
        param_count += 1;
        updates.push(format!("content = ${}", param_count));
    }

    if let Some(ref is_notice) = payload.is_notice {
        param_count += 1;
        updates.push(format!("is_notice = ${}", param_count));
    }

    if updates.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    updates.push("updated_at = NOW()".to_string());

    // 첨부파일에서 썸네일 URL 생성
    let thumbnail_urls = if let Some(ref attached_files) = payload.attached_files {
        generate_thumbnail_urls(&Some(attached_files.clone())).await
    } else {
        None
    };
    
    // 썸네일 URL을 posts 테이블에 저장
    if let Some(ref thumbnails) = thumbnail_urls {
        sqlx::query!(
            "UPDATE posts SET thumbnail_urls = $1 WHERE id = $2",
            serde_json::to_value(thumbnails).unwrap(),
            post_id
        )
        .execute(&state.pool)
        .await
        .map_err(|e| {
            error!("썸네일 URL 저장 실패: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    }

    param_count += 1;
    let sql = format!(
        "UPDATE posts SET {} WHERE id = ${} RETURNING id, board_id, category_id, user_id, title, content, views, likes, dislikes, is_notice, status, created_at, updated_at,
         (SELECT name FROM users WHERE id = user_id) as user_name,
         (SELECT name FROM boards WHERE id = board_id) as board_name,
         (SELECT slug FROM boards WHERE id = board_id) as board_slug,
         (SELECT name FROM categories WHERE id = category_id) as category_name,
         (SELECT COUNT(*)::bigint FROM comments WHERE post_id = posts.id AND status IN ('active', 'published')) as comment_count",
        updates.join(", "),
        param_count
    );

    let mut query_builder = sqlx::query_as::<_, PostDetail>(&sql);
    
    // 파라미터를 올바른 타입으로 바인딩
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

    let mut updated_post = query_builder
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            error!("Failed to update post: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    
    // 압축된 ID 추가


    // 첨부파일 처리 (기존 파일 연결 제거 후 새로 연결)
    if let Some(attached_files) = payload.attached_files {
        // 기존 파일 연결 제거
        sqlx::query!(
            "DELETE FROM file_entities WHERE entity_type = 'post' AND entity_id = $1",
            post_id
        )
        .execute(&state.pool)
        .await
        .map_err(|e| {
            error!("기존 파일 연결 제거 실패: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        // 새 파일 연결
        for (index, file_url) in attached_files.iter().enumerate() {
            // file_url에서 파일명 추출
            let file_name = if file_url.contains("/uploads/") {
                let path_part = file_url.split("/uploads/").last().unwrap_or("");
                let extracted_name = path_part.split('/').last().unwrap_or("");
                
                if extracted_name.contains("_large.") {
                    extracted_name.replace("_large.", ".")
                } else {
                    extracted_name.to_string()
                }
            } else {
                file_url.to_string()
            };
            
            // files 테이블에서 해당 파일 조회
            let file_exists = sqlx::query!(
                "SELECT id, status::text FROM files WHERE stored_name = $1",
                file_name
            )
            .fetch_optional(&state.pool)
            .await;
            
            match file_exists {
                Ok(Some(file_info)) => {
                    let status = file_info.status.as_deref().unwrap_or("unknown");
                    if status == "published" {
                        // file_entities 테이블에 연결 정보 저장
                        sqlx::query!(
                            "INSERT INTO file_entities (file_id, entity_type, entity_id, file_purpose, display_order)
                             VALUES ($1, $2, $3, $4, $5)",
                            file_info.id,
                            EntityType::Post as EntityType,
                            post_id,
                            FilePurpose::Attachment as FilePurpose,
                            index as i32
                        )
                        .execute(&state.pool)
                        .await
                        .map_err(|e| {
                            error!("파일 연결 실패: {:?}", e);
                            StatusCode::INTERNAL_SERVER_ERROR
                        })?;
                    }
                },
                _ => {
                    // 파일이 데이터베이스에 없는 경우 무시
                }
            }
        }
    }

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글이 성공적으로 수정되었습니다.".to_string(),
        data: Some(updated_post),
        pagination: None,
    }))
}

// 게시글 삭제
pub async fn delete_post(
    Path(post_id_str): Path<String>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    
    // 압축된 ID 또는 UUID를 UUID로 변환
    let post_id = if post_id_str.len() == 22 && post_id_str.chars().all(|c| c.is_alphanumeric()) {
        // Base62 압축된 ID 형태 (22자리)
        use crate::utils::uuid_compression::decompress_base62_to_uuid;
        match decompress_base62_to_uuid(&post_id_str) {
            Ok(uuid) => {
                println!("✅ 압축된 ID 변환 성공: {} -> {}", post_id_str, uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 압축된 ID: {}", post_id_str);
                return Err(StatusCode::BAD_REQUEST);
            }
        }
    } else {
        // 기존 UUID 형태 (하위 호환성)
        match uuid::Uuid::parse_str(&post_id_str) {
            Ok(uuid) => {
                println!("✅ UUID 직접 사용: {}", uuid);
                uuid
            },
            Err(_) => {
                println!("❌ 잘못된 ID 형식: {}", post_id_str);
                return Err(StatusCode::BAD_REQUEST);
            }
        }
    };
    
    // 권한 확인
    let post = sqlx::query_as::<_, Post>(
        "SELECT * FROM posts WHERE id = $1 AND status = 'published'"
    )
    .bind(post_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 게시글 작성자만 삭제 가능
    if post.user_id != claims.sub {
        eprintln!("삭제 권한 없음: post_user_id={}, current_user_id={}", post.user_id, claims.sub);
        return Err(StatusCode::FORBIDDEN);
    }

    // 소프트 삭제
    sqlx::query("UPDATE posts SET status = 'deleted' WHERE id = $1")
        .bind(post_id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글이 성공적으로 삭제되었습니다.".to_string(),
        data: Some(()),
        pagination: None,
    }))
}

// 댓글 목록 조회 (권한 체크 적용)
pub async fn get_comments(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
) -> Result<Json<ApiResponse<Vec<CommentDetail>>>, StatusCode> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    // 게시글 정보 조회 (게시판 ID 확인용)
    let post = sqlx::query!("SELECT board_id FROM posts WHERE id = $1 AND status IN ('active', 'published')", post_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            error!("Post query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or_else(|| {
            error!("Post not found: {}", post_id);
            StatusCode::NOT_FOUND
        })?;

    // 게시판 정보 조회 (권한 체크용)
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE id = $1
        "#
    )
    .bind(post.board_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("Error fetching board: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크 (댓글 보기는 게시글 읽기 권한과 동일)
    let can_read = can_read_post(&board, user_role);
    
    if !can_read {
        error!("권한 없음: user_role={:?}, read_permission={}", user_role, board.read_permission);
        return Err(StatusCode::FORBIDDEN);
    }

    // 댓글 목록 조회 (계층 구조 정렬 적용)
    let comments_raw = sqlx::query!(
        r#"
        WITH RECURSIVE comment_tree AS (
            -- 최상위 댓글들 (parent_id가 NULL인 것들)
            SELECT c.id, c.post_id, c.user_id, c.parent_id, c.content, c.likes, 
                   c.status::text as status, c.created_at, c.updated_at, c.depth, c.is_deleted,
                   u.name as user_name,
                   c.created_at::text as sort_path,
                   0 as level
            FROM comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.post_id = $1 AND c.parent_id IS NULL AND c.is_deleted = false
            
            UNION ALL
            
            -- 하위 댓글들 (재귀적으로)
            SELECT c.id, c.post_id, c.user_id, c.parent_id, c.content, c.likes,
                   c.status::text as status, c.created_at, c.updated_at, c.depth, c.is_deleted,
                   u.name as user_name,
                   ct.sort_path || ',' || c.created_at::text as sort_path,
                   ct.level + 1 as level
            FROM comments c
            JOIN users u ON c.user_id = u.id
            JOIN comment_tree ct ON c.parent_id = ct.id
            WHERE c.post_id = $1 AND c.is_deleted = false
        )
        SELECT id, post_id, user_id, parent_id, content, likes, status, 
               created_at, updated_at, depth, is_deleted, user_name
        FROM comment_tree
        ORDER BY sort_path
        "#,
        post_id
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        error!("댓글 조회 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 각 댓글에 대해 좋아요 상태 확인
    let mut comments = Vec::new();
    for comment_raw in comments_raw {
        let is_liked = if let Some(user_id) = claims.as_ref().map(|c| c.sub) {
            sqlx::query!("SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND entity_id = $2 AND entity_type = 'comment') as is_liked", user_id, comment_raw.id)
                .fetch_one(&state.pool)
                .await
                .map(|row| row.is_liked.unwrap_or(false))
                .unwrap_or(false)
        } else {
            false
        };

        let comment = CommentDetail {
            id: comment_raw.id.expect("Comment ID should not be null"),
            post_id: comment_raw.post_id.expect("Post ID should not be null"),
            user_id: comment_raw.user_id.expect("User ID should not be null"),
            parent_id: comment_raw.parent_id,
            content: comment_raw.content.expect("Content should not be null"),
            likes: comment_raw.likes,
            status: comment_raw.status.and_then(|s| s.parse::<PostStatus>().ok()),
            created_at: comment_raw.created_at,
            updated_at: comment_raw.updated_at,
            depth: comment_raw.depth,
            is_deleted: comment_raw.is_deleted,
            user_name: comment_raw.user_name.expect("User name should not be null"),
            is_liked: Some(is_liked),
        };
        comments.push(comment);
    }

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(comments),
        pagination: None,
    }))
}

// 댓글 작성 (권한 체크 적용)
pub async fn create_comment(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
    Json(payload): Json<CreateCommentRequest>,
) -> Result<Json<ApiResponse<CommentDetail>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 게시글 정보 조회 (게시판 ID 확인용)
    let post = sqlx::query!("SELECT board_id FROM posts WHERE id = $1 AND status IN ('active', 'published')", payload.post_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Post query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(StatusCode::NOT_FOUND)?;

    // 게시판 정보 조회 (권한 체크용)
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE id = $1
        "#
    )
    .bind(post.board_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크
    if !can_create_comment(&board, Some(&claims.role)) {
        return Err(StatusCode::FORBIDDEN);
    }

    // 대댓글 깊이 계산
    let depth = if let Some(parent_id) = payload.parent_id {
        // 부모 댓글의 깊이를 조회
        let parent_depth = sqlx::query!(
            "SELECT depth FROM comments WHERE id = $1",
            parent_id
        )
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Parent comment query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .map(|row| row.depth.unwrap_or(0))
        .unwrap_or(0);

        // 최대 깊이 제한 (예: 3단계까지만 허용)
        std::cmp::min(parent_depth + 1, 3)
    } else {
        0 // 최상위 댓글
    };

    let comment = sqlx::query_as::<_, Comment>(
        "INSERT INTO comments (post_id, user_id, parent_id, content, depth, is_deleted)
         VALUES ($1, $2, $3, $4, $5, false)
         RETURNING id, post_id, user_id, parent_id, content, likes, status, created_at, updated_at, depth, is_deleted"
    )
    .bind(payload.post_id)
    .bind(claims.sub)
    .bind(payload.parent_id)
    .bind(payload.content)
    .bind(depth)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Comment insert error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 사용자 정보 조회
    let user = sqlx::query!("SELECT name FROM users WHERE id = $1", claims.sub)
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("User query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let comment_detail = CommentDetail {
        id: comment.id,
        post_id: comment.post_id,
        user_id: comment.user_id,
        parent_id: comment.parent_id,
        content: comment.content,
        likes: comment.likes,
        status: comment.status,
        created_at: comment.created_at,
        updated_at: comment.updated_at,
        depth: comment.depth,
        is_deleted: comment.is_deleted,
        user_name: user.name,
        is_liked: Some(false), // 새로 생성된 댓글은 좋아요하지 않은 상태
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글이 성공적으로 작성되었습니다.".to_string(),
        data: Some(comment_detail),
        pagination: None,
    }))
}

// 댓글 수정
pub async fn update_comment(
    Path(comment_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
    Json(payload): Json<UpdateCommentRequest>,
) -> Result<Json<ApiResponse<CommentDetail>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 권한 확인
    let comment = sqlx::query_as::<_, Comment>(
        "SELECT * FROM comments WHERE id = $1 AND status IN ('active', 'published')"
    )
    .bind(comment_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if comment.user_id != claims.sub {
        // 관리자 권한 확인 (임시로 모든 인증된 사용자를 관리자로 처리)
        // 실제로는 데이터베이스에서 사용자 역할을 확인해야 함
    }

    // 댓글 수정
    let updated_comment_raw = sqlx::query!(
        "UPDATE comments SET content = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING id, post_id, user_id, parent_id, content, likes, status::text as status, created_at, updated_at, depth, is_deleted",
        payload.content,
        comment_id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 사용자 정보 조회
    let user = sqlx::query!("SELECT name FROM users WHERE id = $1", updated_comment_raw.user_id)
        .fetch_one(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let updated_comment = CommentDetail {
        id: updated_comment_raw.id,
        post_id: updated_comment_raw.post_id,
        user_id: updated_comment_raw.user_id,
        parent_id: updated_comment_raw.parent_id,
        content: updated_comment_raw.content,
        likes: updated_comment_raw.likes,
        status: updated_comment_raw.status.and_then(|s| s.parse::<PostStatus>().ok()),
        created_at: updated_comment_raw.created_at,
        updated_at: updated_comment_raw.updated_at,
        depth: updated_comment_raw.depth,
        is_deleted: updated_comment_raw.is_deleted,
        user_name: user.name,
        is_liked: None, // 수정 시에는 좋아요 상태를 확인하지 않음
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글이 성공적으로 수정되었습니다.".to_string(),
        data: Some(updated_comment),
        pagination: None,
    }))
}

// 댓글 삭제
pub async fn delete_comment(
    Path(comment_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 권한 확인
    let comment = sqlx::query_as::<_, Comment>(
        "SELECT * FROM comments WHERE id = $1 AND status IN ('active', 'published')"
    )
    .bind(comment_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if comment.user_id != claims.sub {
        // 관리자 권한 확인 (임시로 모든 인증된 사용자를 관리자로 처리)
        // 실제로는 데이터베이스에서 사용자 역할을 확인해야 함
    }

    // 소프트 삭제 (is_deleted = true로 설정)
    sqlx::query("UPDATE comments SET is_deleted = true, updated_at = NOW() WHERE id = $1")
        .bind(comment_id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글이 성공적으로 삭제되었습니다.".to_string(),
        data: Some(()),
        pagination: None,
    }))
}

// 게시판 통계 조회
pub async fn get_board_stats(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<BoardStats>>>, (StatusCode, Json<ApiResponse<()>>)> {
    let stats = sqlx::query_as!(
        BoardStats,
        r#"
        SELECT 
            b.id as board_id, b.name as board_name,
            COALESCE(p.post_count, 0) as post_count,
            COALESCE(c.comment_count, 0) as comment_count
        FROM boards b
        LEFT JOIN (
            SELECT board_id, COUNT(*) as post_count
            FROM posts 
            WHERE status IN ('active', 'published')
            GROUP BY board_id
        ) p ON b.id = p.board_id
        LEFT JOIN (
            SELECT p.board_id, COUNT(c.id) as comment_count
            FROM posts p
            LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'active'
            WHERE p.status IN ('active', 'published')
            GROUP BY p.board_id
        ) c ON b.id = c.board_id
        WHERE b.is_public = true
        ORDER BY b.display_order, b.name
        "#
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to fetch board stats")),
    ))?;

    Ok(Json(ApiResponse::success(stats, "Board stats retrieved")))
}

// 게시판 그룹별 최근 게시글 조회
pub async fn get_board_groups_recent_posts(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<BoardStats>>>, (StatusCode, Json<ApiResponse<()>>)> {
    let stats = sqlx::query_as!(
        BoardStats,
        r#"
        SELECT 
            b.id as board_id,
            b.name as board_name,
            COALESCE(p.post_count, 0) as post_count,
            COALESCE(c.comment_count, 0) as comment_count
        FROM boards b
        LEFT JOIN (
            SELECT board_id, COUNT(*) as post_count
            FROM posts 
            WHERE status IN ('active', 'published')
            GROUP BY board_id
        ) p ON b.id = p.board_id
        LEFT JOIN (
            SELECT p.board_id, COUNT(c.id) as comment_count
            FROM posts p
            LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'active'
            WHERE p.status IN ('active', 'published')
            GROUP BY p.board_id
        ) c ON b.id = c.board_id
        WHERE b.is_public = true
        ORDER BY b.display_order, b.name
        "#
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to fetch board stats")),
    ))?;

    Ok(Json(ApiResponse::success(stats, "Board stats retrieved")))
}

// 게시판 slug로 상세 조회 (권한 체크 적용)
pub async fn get_board_by_slug(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    Path(slug): Path<String>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE slug = $1
        "#
    )
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board by slug: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiResponse::error("Failed to fetch board by slug")),
        )
    })?
    .ok_or((
        StatusCode::NOT_FOUND,
        Json(ApiResponse::error("Board not found")),
    ))?;

    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크
    if !can_list_board(&board, user_role) {
        return Err((
            StatusCode::FORBIDDEN,
            Json(ApiResponse::error("Access denied")),
        ));
    }

    Ok(Json(ApiResponse::success(board, "Board retrieved by slug")))
}

// 게시판 slug로 게시글 목록 조회 (권한 체크 적용)
pub async fn get_posts_by_slug(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    Path(slug): Path<String>,
    Query(query): Query<PostQuery>,
) -> Result<Json<ApiResponse<Vec<PostSummaryResponse>>>, StatusCode> {
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    
    // slug로 board_id 조회
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE slug = $1
        "#
    )
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    let board = convert_board_raw_to_board(board_raw);

    // 권한 체크
    if !can_read_post(&board, user_role) {
        return Err(StatusCode::FORBIDDEN);
    }

    // board_id를 강제로 설정하고 직접 게시글 조회
    let mut query = query;
    query.board_id = Some(board.id);
    
    // 게시글 목록 조회 로직 직접 구현
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    // 전체 게시글 수 조회
    let mut count_sql = "SELECT COUNT(*) as total FROM posts p".to_string();
    let mut count_conditions = Vec::new();
    let mut count_param_count = 1;

    // 삭제된 게시글 제외
    count_conditions.push("p.status IN ('active', 'published')".to_string());

    if let Some(ref search) = query.search {
        count_conditions.push(format!("(p.title ILIKE ${} OR p.content ILIKE ${} OR EXISTS (SELECT 1 FROM users u WHERE u.id = p.user_id AND u.name ILIKE ${}))", 
            count_param_count, count_param_count, count_param_count));
        count_param_count += 1;
    }

    count_conditions.push(format!("p.board_id = ${}", count_param_count));
    count_param_count += 1;

    if !count_conditions.is_empty() {
        count_sql.push_str(&format!(" WHERE {}", count_conditions.join(" AND ")));
    }

    let mut count_query_builder = sqlx::query_scalar::<_, i64>(&count_sql);
    
    if let Some(ref search) = query.search {
        count_query_builder = count_query_builder.bind(format!("%{}%", search));
    }
    count_query_builder = count_query_builder.bind(board.id);

    let total = count_query_builder
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Error counting posts: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 게시글 목록 조회 (답글 포함)
    let mut sql = r#"
        SELECT 
            p.id, p.title, p.board_id, p.user_id, p.content, p.views, p.likes, p.is_notice, p.created_at,
            p.parent_id, p.depth, p.reply_count, p.thumbnail_urls,
            u.name as user_name,
            b.name as board_name,
            b.slug as board_slug,
            c.name as category_name,
            COALESCE(comment_count.count, 0) as comment_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN (
            SELECT post_id, COUNT(*) as count 
            FROM comments 
            WHERE status IN ('active', 'published') 
            GROUP BY post_id
        ) comment_count ON p.id = comment_count.post_id
    "#.to_string();
    
    let mut conditions = Vec::new();
    let mut param_count = 1;

    // 삭제된 게시글 제외
    conditions.push("p.status IN ('active', 'published')".to_string());

    if let Some(ref search) = query.search {
        conditions.push(format!("(p.title ILIKE ${} OR p.content ILIKE ${} OR u.name ILIKE ${})", 
            param_count, param_count, param_count));
        param_count += 1;
    }

    conditions.push(format!("p.board_id = ${}", param_count));
    param_count += 1;

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    // 공지사항을 먼저, 그 다음 일반 게시글 순으로 정렬 (답글은 부모 글 아래에 계층적 구조로)
    sql.push_str(&format!(" ORDER BY p.is_notice DESC, COALESCE(p.parent_id, p.id), p.depth, p.created_at DESC LIMIT ${} OFFSET ${}", param_count, param_count + 1));

    let mut query_builder = sqlx::query_as::<_, PostSummaryDb>(&sql);
    
    if let Some(ref search) = query.search {
        query_builder = query_builder.bind(format!("%{}%", search));
    }
    query_builder = query_builder.bind(board.id);
    query_builder = query_builder.bind(limit as i64);
    query_builder = query_builder.bind(offset as i64);

    let posts = query_builder
        .fetch_all(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Posts query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 각 게시글의 첨부파일 정보 가져오기
    let mut posts_with_files = Vec::new();
    for post in posts {
        // 첨부파일 목록 조회
        let attached_files = sqlx::query_scalar!(
            r#"
            SELECT f.file_path
            FROM files f
            JOIN file_entities fe ON f.id = fe.file_id
            WHERE fe.entity_type = 'post' AND fe.entity_id = $1 AND f.status = 'published'
            ORDER BY fe.display_order, f.created_at
            "#,
            post.id
        )
        .fetch_all(&state.pool)
        .await
        .unwrap_or_default();

        let attached_files_option = if attached_files.is_empty() {
            None
        } else {
            Some(attached_files)
        };

        let thumbnail_urls = generate_thumbnail_urls(&attached_files_option).await;

        // URL ID 생성
        let url_id = generate_post_url_id(&state.pool, &post.id).await.ok();

        let post_with_files = PostSummary {
            id: post.id,


            title: post.title,
            board_id: post.board_id,
            user_name: post.user_name,
            board_name: post.board_name,
            board_slug: post.board_slug,
            category_name: post.category_name,
            created_at: post.created_at,
            comment_count: post.comment_count,
            content: post.content,
            views: post.views,
            likes: post.likes,
            is_notice: post.is_notice,
            attached_files: attached_files_option,
            thumbnail_urls,
            parent_id: post.parent_id,
            depth: post.depth,
            reply_count: post.reply_count,
        };
        
        posts_with_files.push(post_with_files);
    }

    // 정렬이 필요한 경우 메모리에서 정렬 (공지사항 우선 고정)
    let mut posts = posts_with_files;
    if let Some(ref sort) = query.sort {
        match sort.as_str() {
            "latest" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 최신순
                    b.is_notice.cmp(&a.is_notice).then(b.created_at.cmp(&a.created_at))
                });
            }
            "oldest" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 오래된순
                    b.is_notice.cmp(&a.is_notice).then(a.created_at.cmp(&b.created_at))
                });
            }
            "views" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 조회수순
                    b.is_notice.cmp(&a.is_notice).then(b.views.cmp(&a.views))
                });
            }
            "likes" => {
                posts.sort_by(|a, b| {
                    // 공지사항 우선, 그 다음 좋아요순
                    b.is_notice.cmp(&a.is_notice).then(b.likes.cmp(&a.likes))
                });
            }
            _ => {
                posts.sort_by(|a, b| {
                    // 기본값: 공지사항 우선, 그 다음 최신순
                    b.is_notice.cmp(&a.is_notice).then(b.created_at.cmp(&a.created_at))
                });
            }
        }
    } else {
        // 정렬 옵션이 없어도 공지사항 우선 정렬
        posts.sort_by(|a, b| {
            b.is_notice.cmp(&a.is_notice).then(b.created_at.cmp(&a.created_at))
        });
    }

    // 페이지네이션 정보 계산
    let total_pages = (total + limit - 1) / limit;
    let pagination = crate::models::response::PaginationInfo {
        page: page as u32,
        limit: limit as u32,
        total: total as u64,
        total_pages: total_pages as u32,
    };

    // PostSummary를 PostSummaryResponse로 변환
    let posts_response: Vec<PostSummaryResponse> = posts.into_iter().map(|post| post.to_response()).collect();

    Ok(Json(ApiResponse {
        success: true,
        data: Some(posts_response),
        message: "게시글 목록을 성공적으로 조회했습니다.".to_string(),
        pagination: Some(pagination),
    }))
}

// 게시판 slug로 게시글 생성 (권한 체크 적용)
pub async fn create_post_by_slug(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
    Path(slug): Path<String>,
    Json(mut payload): Json<CreatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    eprintln!("📝 게시글 작성 시작: slug={}, user_id={}", slug, claims.sub);
    eprintln!("📝 요청 데이터: title={}, content_len={}", payload.title, payload.content.len());
    
    // slug로 board_id 조회
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE slug = $1
        "#
    )
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("❌ 게시판 조회 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or_else(|| {
        eprintln!("❌ 게시판을 찾을 수 없음: slug={}", slug);
        StatusCode::NOT_FOUND
    })?;

    let board = convert_board_raw_to_board(board_raw);
    eprintln!("📝 게시판 정보: id={}, name={}, slug={}", board.id, board.name, board.slug);

    // 권한 체크
    if !can_write_post(&board, Some(&claims.role)) {
        eprintln!("❌ 권한 없음: role={}", claims.role);
        return Err(StatusCode::FORBIDDEN);
    }
    eprintln!("✅ 권한 확인 완료: role={}", claims.role);

    let sanitized_content = clean(&payload.content);
    payload.content = sanitized_content;

    payload.board_id = Some(board.id);
    eprintln!("📝 create_post 호출 시작: board_id={}", board.id);
    
    // 기존 create_post 로직 재사용
    let result = create_post(State(state), Extension(Some(claims)), Json(payload)).await;
    match &result {
        Ok(_) => eprintln!("✅ create_post 성공"),
        Err(e) => eprintln!("❌ create_post 실패: {:?}", e),
    }
    result
}

// 답글 생성 (권한 체크 적용)
pub async fn create_reply_by_slug(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
    Path(slug): Path<String>,
    Json(payload): Json<CreateReplyRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 부모 게시글 조회 및 게시판 정보 확인
    let parent_post = sqlx::query_as::<_, PostDetailRaw>(
        r#"
        SELECT 
            p.id, p.board_id, p.category_id, p.user_id, p.parent_id, p.title, p.content,
            p.views, p.likes, p.dislikes, p.is_notice, p.status::text, p.created_at, p.updated_at,
            p.depth, p.reply_count, p.attached_files, p.thumbnail_urls,
            u.name as user_name, u.email as user_email,
            b.name as board_name, b.slug as board_slug,
            c.name as category_name,
            (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = false) as comment_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.id = $1 AND b.slug = $2 AND p.is_deleted = false
        "#
    )
    .bind(payload.parent_id)
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("부모 게시글 조회 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or_else(|| {
        error!("부모 게시글을 찾을 수 없음: parent_id={}, slug={}", payload.parent_id, slug);
        StatusCode::NOT_FOUND
    })?;

    // 게시판 정보 조회
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"SELECT * FROM boards WHERE slug = $1"#
    )
    .bind(&slug)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("게시판 조회 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let board = convert_board_raw_to_board(board_raw);

    // 답글 생성 권한 체크
    if !can_create_reply(&board, Some(&claims.role)) {
        error!("답글 생성 권한 없음: role={}", claims.role);
        return Err(StatusCode::FORBIDDEN);
    }

    let sanitized_content = clean(&payload.content);
    let parent_depth = parent_post.depth.unwrap_or(0);
    let reply_depth = parent_depth + 1;

    // 최대 답글 깊이 제한 (예: 5단계)
    if reply_depth > 5 {
        error!("답글 깊이 제한 초과: depth={}", reply_depth);
        return Err(StatusCode::BAD_REQUEST);
    }

    // 답글 생성
    let post_result = sqlx::query!(
        r#"
        INSERT INTO posts (board_id, category_id, user_id, parent_id, title, content, status, depth)
        VALUES ($1, $2, $3, $4, $5, $6, 'published', $7)
        RETURNING id
        "#,
        parent_post.board_id,
        parent_post.category_id,
        claims.sub,
        payload.parent_id,
        payload.title,
        sanitized_content,
        reply_depth
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("답글 생성 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let reply_id = post_result.id;

    // 첨부파일 처리 (필요한 경우)
    if let Some(attached_files) = &payload.attached_files {
        for file_path in attached_files {
            sqlx::query!(
                r#"
                INSERT INTO file_entities (file_id, entity_type, entity_id, file_purpose, display_order)
                SELECT f.id, $1, $2, 'attachment', 0
                FROM files f
                WHERE f.file_path = $3 AND f.status = 'published'
                AND NOT EXISTS (
                    SELECT 1 FROM file_entities fe 
                    WHERE fe.file_id = f.id AND fe.entity_type = $1 AND fe.entity_id = $2
                )
                "#,
                EntityType::Post as EntityType,
                reply_id,
                file_path
            )
            .execute(&state.pool)
            .await
            .map_err(|e| {
                error!("파일 연결 실패: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;
        }
    }

    // 첨부파일에서 썸네일 URL 생성
    let thumbnail_urls = if let Some(ref attached_files) = payload.attached_files {
        generate_thumbnail_urls(&Some(attached_files.clone())).await
    } else {
        None
    };
    
    // 썸네일 URL을 posts 테이블에 저장
    if let Some(ref thumbnails) = thumbnail_urls {
        sqlx::query!(
            "UPDATE posts SET thumbnail_urls = $1 WHERE id = $2",
            serde_json::to_value(thumbnails).unwrap(),
            reply_id
        )
        .execute(&state.pool)
        .await
        .map_err(|e| {
            error!("썸네일 URL 저장 실패: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    }
    
    // 부모 게시글의 답글 수 증가
    sqlx::query!(
        "UPDATE posts SET reply_count = reply_count + 1 WHERE id = $1",
        payload.parent_id
    )
    .execute(&state.pool)
    .await
    .map_err(|e| {
        error!("부모 게시글 답글 수 업데이트 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 생성된 답글 조회
    let reply = sqlx::query_as::<_, PostDetailRaw>(
        r#"
        SELECT 
            p.id, p.board_id, p.category_id, p.user_id, p.parent_id, p.title, p.content,
            p.views, p.likes, p.dislikes, p.is_notice, p.status::text, p.created_at, p.updated_at,
            p.depth, p.reply_count, p.attached_files, p.thumbnail_urls,
            u.name as user_name, u.email as user_email,
            b.name as board_name, b.slug as board_slug,
            c.name as category_name,
            (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND is_deleted = false) as comment_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.id = $1
        "#
    )
    .bind(reply_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("생성된 답글 조회 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // PostDetailRaw를 PostDetail로 변환
    // URL ID 생성
    let url_id = generate_post_url_id(&state.pool, &reply.id).await.ok();

    let reply_detail = PostDetail {
        id: reply.id,


        board_id: reply.board_id,
        category_id: reply.category_id,
        user_id: reply.user_id,
        parent_id: reply.parent_id,
        title: reply.title,
        content: reply.content,
        views: reply.views,
        likes: reply.likes,
        dislikes: reply.dislikes,
        is_notice: reply.is_notice,
        status: reply.status.and_then(|s| s.parse::<PostStatus>().ok()),
        created_at: reply.created_at,
        updated_at: reply.updated_at,
        depth: reply.depth,
        reply_count: reply.reply_count,
        user_name: reply.user_name,
        user_email: reply.user_email,
        board_name: reply.board_name,
        board_slug: reply.board_slug,
        category_name: reply.category_name,
        comment_count: reply.comment_count,
        attached_files: None, // 필요시 별도 로드
        thumbnail_urls: reply.thumbnail_urls.and_then(|v| serde_json::from_value(v).ok()),
        is_liked: None,
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "답글이 성공적으로 작성되었습니다.".to_string(),
        data: Some(reply_detail),
        pagination: None,
    }))
}

// 썸네일 URL 생성 함수 (누락된 썸네일 자동 생성 포함)
async fn generate_thumbnail_urls(attached_files: &Option<Vec<String>>) -> Option<ThumbnailUrls> {
    if let Some(files) = attached_files {
        for file_path in files {
            // 이미지 파일인지 확인
            if is_image_file_path(file_path) {
                let thumbnail_service = ThumbnailService::new();
                
                // 원본 파일 경로를 static/ 형태로 변환
                let original_path = if file_path.starts_with("/uploads") {
                    format!("static{}", file_path)
                } else {
                    file_path.clone()
                };

                // 병렬로 썸네일 생성/확인 처리
                let (thumb_result, card_result, large_result) = tokio::join!(
                    ensure_thumbnail_exists(&thumbnail_service, &original_path, "thumb"),
                    ensure_thumbnail_exists(&thumbnail_service, &original_path, "card"),
                    ensure_thumbnail_exists(&thumbnail_service, &original_path, "large")
                );
                
                return Some(ThumbnailUrls {
                    thumb: Some(thumb_result.unwrap_or_else(|| file_path.clone())),
                    card: Some(card_result.unwrap_or_else(|| file_path.clone())),
                    large: Some(large_result.unwrap_or_else(|| file_path.clone())),
                });
            }
        }
    }
    None
}

// 개별 썸네일 존재 확인 및 생성 함수
async fn ensure_thumbnail_exists(
    thumbnail_service: &ThumbnailService,
    original_path: &str,
    size_suffix: &str
) -> Option<String> {
    let thumbnail_url = thumbnail_service.get_thumbnail_url(original_path, size_suffix);
    
    // 썸네일이 이미 존재하는지 확인
    if thumbnail_service.thumbnail_exists(&thumbnail_url) {
        return Some(thumbnail_url.replace("static", ""));
    }
    
    // 썸네일이 없으면 생성 시도 (타임아웃 설정)
    let create_task = thumbnail_service.create_missing_thumbnail(original_path, size_suffix);
    
    // 2초 타임아웃 설정 (응답 속도 우선)
    match tokio::time::timeout(std::time::Duration::from_secs(2), create_task).await {
        Ok(Ok(Some(_))) => {
            // 생성 성공
            let new_url = thumbnail_service.get_thumbnail_url(original_path, size_suffix);
            Some(new_url.replace("static", ""))
        },
        _ => {
            // 생성 실패 또는 타임아웃 - 백그라운드에서 생성 스케줄링
            schedule_background_thumbnail_creation(original_path.to_string(), size_suffix.to_string());
            None // 원본 이미지를 사용하도록 None 반환
        }
    }
}

// 백그라운드 썸네일 생성 스케줄링 (실제 구현에서는 큐 시스템 사용)
fn schedule_background_thumbnail_creation(original_path: String, size_suffix: String) {
    tokio::spawn(async move {
        let thumbnail_service = ThumbnailService::new();
        if let Err(e) = thumbnail_service.create_missing_thumbnail(&original_path, &size_suffix).await {
            eprintln!("Background thumbnail creation failed for {}: {:?}", original_path, e);
        } else {
            println!("Background thumbnail created: {} ({})", original_path, size_suffix);
        }
    });
}

// 파일 경로가 이미지인지 확인
fn is_image_file_path(file_path: &str) -> bool {
    let extension = std::path::Path::new(file_path)
        .extension()
        .and_then(|s| s.to_str())
        .unwrap_or("")
        .to_lowercase();
    
    matches!(extension.as_str(), "jpg" | "jpeg" | "png" | "gif" | "webp" | "bmp")
}

// 좋아요 토글 (게시글)
pub async fn toggle_post_like(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 게시글 존재 확인
    let post = sqlx::query!("SELECT id, board_id, user_id FROM posts WHERE id = $1 AND status IN ('active', 'published')", post_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Post query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(StatusCode::NOT_FOUND)?;

    // 자신이 작성한 게시글에는 좋아요를 할 수 없음
    if post.user_id == claims.sub {
        return Err(StatusCode::FORBIDDEN);
    }

    // 게시판 정보 조회 (좋아요 허용 여부 확인)
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE id = $1
        "#
    )
    .bind(post.board_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    let board = convert_board_raw_to_board(board_raw);

    // 좋아요 기능이 비활성화된 경우
    if !board.allow_likes {
        return Err(StatusCode::FORBIDDEN);
    }

    // 기존 좋아요 확인
    let existing_like = sqlx::query!(
        "SELECT id FROM likes WHERE user_id = $1 AND entity_type = 'post' AND entity_id = $2",
        claims.sub,
        post_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Like query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let mut tx = state.pool.begin().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if let Some(like) = existing_like {
        // 좋아요 취소
        sqlx::query!("DELETE FROM likes WHERE id = $1", like.id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                eprintln!("Like delete error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        // 게시글 좋아요 수 감소
        sqlx::query!("UPDATE posts SET likes = GREATEST(likes - 1, 0) WHERE id = $1", post_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                eprintln!("Post likes update error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        Ok(Json(ApiResponse {
            success: true,
            message: "좋아요가 취소되었습니다.".to_string(),
            data: Some(serde_json::json!({
                "liked": false,
                "action": "unliked"
            })),
            pagination: None,
        }))
    } else {
        // 좋아요 추가
        sqlx::query!(
            "INSERT INTO likes (user_id, entity_type, entity_id) VALUES ($1, 'post', $2)",
            claims.sub,
            post_id
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            eprintln!("Like insert error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        // 게시글 좋아요 수 증가
        sqlx::query!("UPDATE posts SET likes = COALESCE(likes, 0) + 1 WHERE id = $1", post_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                eprintln!("Post likes update error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        Ok(Json(ApiResponse {
            success: true,
            message: "좋아요가 추가되었습니다.".to_string(),
            data: Some(serde_json::json!({
                "liked": true,
                "action": "liked"
            })),
            pagination: None,
        }))
    }
}

// 좋아요 토글 (댓글)
pub async fn toggle_comment_like(
    Path(comment_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    // 댓글 존재 확인
    let comment = sqlx::query!("SELECT id, post_id, user_id FROM comments WHERE id = $1 AND status IN ('active', 'published')", comment_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Comment query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .ok_or(StatusCode::NOT_FOUND)?;

    // 자신이 작성한 댓글에는 좋아요를 할 수 없음
    if comment.user_id == claims.sub {
        return Err(StatusCode::FORBIDDEN);
    }

    // 게시판 정보 조회 (좋아요 허용 여부 확인)
    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        SELECT * FROM boards WHERE id = $1
        "#
    )
    .bind(comment.post_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Error fetching board: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    let board = convert_board_raw_to_board(board_raw);

    // 좋아요 기능이 비활성화된 경우
    if !board.allow_likes {
        return Err(StatusCode::FORBIDDEN);
    }

    // 기존 좋아요 확인
    let existing_like = sqlx::query!(
        "SELECT id FROM likes WHERE user_id = $1 AND entity_type = 'comment' AND entity_id = $2",
        claims.sub,
        comment_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Like query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let mut tx = state.pool.begin().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if let Some(like) = existing_like {
        // 좋아요 취소
        sqlx::query!("DELETE FROM likes WHERE id = $1", like.id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                eprintln!("Like delete error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        // 댓글 좋아요 수 감소
        sqlx::query!("UPDATE comments SET likes = GREATEST(likes - 1, 0) WHERE id = $1", comment_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                eprintln!("Comment likes update error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        Ok(Json(ApiResponse {
            success: true,
            message: "좋아요가 취소되었습니다.".to_string(),
            data: Some(serde_json::json!({
                "liked": false,
                "action": "unliked"
            })),
            pagination: None,
        }))
    } else {
        // 좋아요 추가
        sqlx::query!(
            "INSERT INTO likes (user_id, entity_type, entity_id) VALUES ($1, 'comment', $2)",
            claims.sub,
            comment_id
        )
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            eprintln!("Like insert error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        // 댓글 좋아요 수 증가
        sqlx::query!("UPDATE comments SET likes = COALESCE(likes, 0) + 1 WHERE id = $1", comment_id)
            .execute(&mut *tx)
            .await
            .map_err(|e| {
                eprintln!("Comment likes update error: {:?}", e);
                StatusCode::INTERNAL_SERVER_ERROR
            })?;

        tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

        Ok(Json(ApiResponse {
            success: true,
            message: "좋아요가 추가되었습니다.".to_string(),
            data: Some(serde_json::json!({
                "liked": true,
                "action": "liked"
            })),
            pagination: None,
        }))
    }
}

// 좋아요 상태 확인 (게시글)
pub async fn get_post_like_status(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    let liked = sqlx::query!(
        "SELECT id FROM likes WHERE user_id = $1 AND entity_type = 'post' AND entity_id = $2",
        claims.sub,
        post_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Like status query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .is_some();

    Ok(Json(ApiResponse {
        success: true,
        message: "좋아요 상태를 조회했습니다.".to_string(),
        data: Some(serde_json::json!({
            "liked": liked
        })),
        pagination: None,
    }))
}

// 좋아요 상태 확인 (댓글)
pub async fn get_comment_like_status(
    Path(comment_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(claims): Extension<Option<crate::utils::auth::Claims>>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    // 인증 확인
    let claims = claims.ok_or(StatusCode::UNAUTHORIZED)?;
    let liked = sqlx::query!(
        "SELECT id FROM likes WHERE user_id = $1 AND entity_type = 'comment' AND entity_id = $2",
        claims.sub,
        comment_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Like status query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .is_some();

    Ok(Json(ApiResponse {
        success: true,
        message: "좋아요 상태를 조회했습니다.".to_string(),
        data: Some(serde_json::json!({
            "liked": liked
        })),
        pagination: None,
    }))
}

// 최근 게시글 조회 (홈페이지용)
#[derive(Debug, Deserialize)]
pub struct RecentPostsQuery {
    pub slugs: Option<String>, // 콤마로 구분된 slug 목록
    pub limit: Option<i64>,    // 조회할 게시글 수
}

pub async fn get_recent_posts(
    State(state): State<AppState>,
    Query(query): Query<RecentPostsQuery>,
) -> Result<Json<ApiResponse<Vec<PostDetail>>>, StatusCode> {
    let limit = query.limit.unwrap_or(3);
    let slugs = query.slugs.unwrap_or_else(|| "notice,volunteer-review,community".to_string());
    
    // slug 목록을 파싱
    let slug_list: Vec<&str> = slugs.split(',').map(|s| s.trim()).collect();
    
    let posts = sqlx::query_as::<_, PostDetailRaw>(
        r#"
        SELECT 
            p.id,
            p.title,
            p.content,
            p.user_id,
            p.board_id,
            p.category_id,
            NULL as parent_id,
            NULL as depth,
            NULL as reply_count,
            p.is_notice,
            p.views,
            p.likes,
            p.dislikes,
            p.status::text,
            p.created_at,
            p.updated_at,
            p.attached_files,
            p.thumbnail_urls,
            u.name as user_name,
            u.email as user_email,
            b.name as board_name,
            b.slug as board_slug,
            c.name as category_name,
            (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status IN ('active', 'published')) as comment_count
        FROM posts p
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE b.slug = ANY($1)
        AND p.status IN ('active', 'published')
        ORDER BY p.created_at DESC
        LIMIT $2
        "#
    )
    .bind(&slug_list)
    .bind(limit)
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Failed to fetch recent posts: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // PostDetailRaw를 PostDetail로 변환 (썸네일 URL 생성 포함)
    let mut posts_with_thumbnails = Vec::new();
    
    for post_raw in posts {
        let thumbnail_urls = if let Some(v) = post_raw.thumbnail_urls {
            serde_json::from_value(v).ok()
        } else {
            // 썸네일 URL이 없으면 첨부파일에서 생성
            generate_thumbnail_urls(&post_raw.attached_files).await
        };
        
        // URL ID 생성
        let url_id = generate_post_url_id(&state.pool, &post_raw.id).await.ok();

        let post_detail = PostDetail {
            id: post_raw.id,


            title: post_raw.title,
            content: post_raw.content,
            user_id: post_raw.user_id,
            board_id: post_raw.board_id,
            category_id: post_raw.category_id,
            parent_id: post_raw.parent_id,
            depth: post_raw.depth,
            reply_count: post_raw.reply_count,
            is_notice: post_raw.is_notice,
            views: post_raw.views,
            likes: post_raw.likes,
            dislikes: post_raw.dislikes,
            status: post_raw.status.and_then(|s| s.parse::<PostStatus>().ok()),
            created_at: post_raw.created_at,
            updated_at: post_raw.updated_at,
            attached_files: None, // 최근글에서는 첨부파일 상세 정보 불필요
            thumbnail_urls,
            user_name: post_raw.user_name,
            user_email: post_raw.user_email,
            board_name: post_raw.board_name,
            board_slug: post_raw.board_slug,
            category_name: post_raw.category_name,
            comment_count: post_raw.comment_count,
            is_liked: None, // 나중에 별도로 로드
        };
        
        posts_with_thumbnails.push(post_detail);
    }
    
    let posts = posts_with_thumbnails;

    Ok(Json(ApiResponse::success(posts, "최근 게시글을 성공적으로 조회했습니다.")))
}

// 모든 게시판과 카테고리 정보 조회 (관리자용)
pub async fn get_boards_with_categories(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
) -> Result<Json<ApiResponse<Vec<BoardWithCategoriesResponse>>>, StatusCode> {
    // 관리자 권한 확인
    let user_role = claims.as_ref().map(|c| c.role.as_str());
    if user_role != Some("admin") {
        return Ok(Json(ApiResponse {
            success: false,
            message: "관리자 권한이 필요합니다.".to_string(),
            data: None,
            pagination: None,
        }));
    }

    // 모든 게시판과 카테고리 조회
    let boards_raw = sqlx::query!(
        r#"
        SELECT 
            b.id as board_id,
            b.name as board_name,
            b.slug as board_slug,
            c.id as "category_id?",
            c.name as "category_name?"
        FROM boards b
        LEFT JOIN categories c ON b.id = c.board_id
        ORDER BY b.display_order, c.display_order
        "#
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        error!("Failed to fetch boards with categories: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 게시판별로 그룹핑
    let mut boards_map: HashMap<uuid::Uuid, BoardWithCategoriesResponse> = HashMap::new();
    
    for row in boards_raw {
        let board_entry = boards_map.entry(row.board_id).or_insert_with(|| {
            BoardWithCategoriesResponse {
                id: row.board_id,
                name: row.board_name.clone(),
                slug: row.board_slug.clone(),
                categories: Vec::new(),
            }
        });

        // 카테고리 정보가 있으면 추가 (LEFT JOIN이므로 null일 수 있음)
        if let (Some(category_id), Some(category_name)) = (row.category_id, row.category_name) {
            board_entry.categories.push(CategoryInfoResponse {
                id: category_id,
                name: category_name,
            });
        }
    }

    let boards: Vec<BoardWithCategoriesResponse> = boards_map.into_values().collect();

    Ok(Json(ApiResponse::success(boards, "게시판과 카테고리 목록을 성공적으로 조회했습니다.")))
}

#[derive(Debug, Serialize)]
pub struct BoardWithCategoriesResponse {
    pub id: uuid::Uuid,
    pub name: String,
    pub slug: String,
    pub categories: Vec<CategoryInfoResponse>,
}

#[derive(Debug, Serialize)]
pub struct CategoryInfoResponse {
    pub id: uuid::Uuid,
    pub name: String,
} 