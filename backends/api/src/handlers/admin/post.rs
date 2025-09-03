use axum::{
    extract::{Path, Query, State, Extension},
    http::StatusCode,
    Json,
};
use uuid::Uuid;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use sqlx::PgPool;
use tracing::{info, error, warn};
use std::str::FromStr;

use crate::{
    models::{
        response::ApiResponse,
        site::community::{Post, PostDetail, PostStatus, UpdatePostRequest},
    },
    utils::auth::Claims,
    AppState,
};
use crate::utils::url_id::generate_post_url_id;

// 게시글 목록 조회
pub async fn get_posts(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Query(query): Query<PostListQuery>,
) -> Result<Json<ApiResponse<PostListResponse>>, StatusCode> {
    info!("게시글 목록 조회 요청: user_id={}", claims.sub);

    let mut query_builder = sqlx::QueryBuilder::new(
        r#"
        SELECT 
            p.id,
            p.board_id,
            p.category_id,
            p.user_id,
            p.parent_id,
            p.title,
            p.content,
            p.views,
            p.likes,
            p.is_notice,
            p.status,
            p.created_at,
            p.updated_at,
            p.depth,
            p.reply_count,
            b.name as board_name,
            c.name as category_name,
            u.name as user_name,
            COALESCE(comment_count.count, 0) as comment_count
        FROM posts p
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN (
            SELECT post_id, COUNT(*) as count 
            FROM comments 
            WHERE status = 'active' 
            GROUP BY post_id
        ) comment_count ON p.id = comment_count.post_id
        WHERE 1=1
        "#
    );

    let mut count_query_builder = sqlx::QueryBuilder::new(
        "SELECT COUNT(*) FROM posts p WHERE 1=1"
    );

    // 검색 조건
    if let Some(ref search) = query.search {
        if let Ok(uuid) = Uuid::parse_str(search) {
            query_builder.push(" AND p.id = ");
            query_builder.push_bind(uuid);

            count_query_builder.push(" AND p.id = ");
            count_query_builder.push_bind(uuid);
        } else {
            query_builder.push(" AND (p.title ILIKE ");
            query_builder.push_bind(format!("%{}%", search));

            query_builder.push(" OR p.content ILIKE ");
            query_builder.push_bind(format!("%{}%", search));
            query_builder.push(")");

            count_query_builder.push(" AND (p.title ILIKE ");
            count_query_builder.push_bind(format!("%{}%", search));

            count_query_builder.push(" OR p.content ILIKE ");
            count_query_builder.push_bind(format!("%{}%", search));
            count_query_builder.push(")");
        }
    }

    // 상태 필터
    if let Some(ref status) = query.status {
        query_builder.push(" AND p.status = ");
        query_builder.push_bind(status);

        count_query_builder.push(" AND p.status = ");
        count_query_builder.push_bind(status);
    }

    // 정렬
    query_builder.push(" ORDER BY p.created_at DESC");

    // 페이지네이션
    let limit = query.limit.unwrap_or(20);
    let offset = (query.page.unwrap_or(1) - 1) * limit;

    query_builder.push(" LIMIT ");
    query_builder.push_bind(limit);

    query_builder.push(" OFFSET ");
    query_builder.push_bind(offset);

    // 총 개수 조회
    let total_count: i64 = count_query_builder
        .build_query_scalar()
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            error!("게시글 총 개수 조회 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 게시글 목록 조회
    let posts_raw = query_builder
        .build_query_as::<PostListRaw>()
        .fetch_all(&state.pool)
        .await
        .map_err(|e| {
            error!("게시글 목록 조회 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let mut posts: Vec<PostDetail> = Vec::new();
    for post_raw in posts_raw {
        let post = PostDetail {
            id: post_raw.id,
            board_id: post_raw.board_id,
            category_id: post_raw.category_id,
            user_id: post_raw.user_id,
            parent_id: post_raw.parent_id,
            title: post_raw.title,
            content: post_raw.content,
            views: post_raw.views,
            likes: post_raw.likes,
            dislikes: None,
            is_notice: post_raw.is_notice,
            status: Some(post_raw.status),
            created_at: post_raw.created_at,
            updated_at: post_raw.updated_at,
            depth: post_raw.depth,
            reply_count: post_raw.reply_count,
            user_name: post_raw.user_name,
            user_email: None,
            board_name: post_raw.board_name,
            board_slug: None,
            category_name: post_raw.category_name,
            comment_count: post_raw.comment_count,
            attached_files: None,
            thumbnail_urls: None,
            is_liked: None,
        };
        posts.push(post);
    }

    let response = PostListResponse {
        posts,
        total_count,
        page: query.page.unwrap_or(1),
        limit,
        total_pages: (total_count as f64 / limit as f64).ceil() as i32,
    };

    Ok(Json(ApiResponse::success(response, "게시글 목록을 성공적으로 조회했습니다.")))
}

// 게시글 상세 조회
pub async fn get_post(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(post_id): Path<Uuid>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    info!("게시글 상세 조회 요청: post_id={}, user_id={}", post_id, claims.sub);

    let post_raw = sqlx::query_as::<_, PostDetailRaw>(
        r#"
        SELECT 
            p.id,
            p.board_id,
            p.category_id,
            p.user_id,
            p.parent_id,
            p.title,
            p.content,
            p.views,
            p.likes,
            p.is_notice,
            p.status,
            p.created_at,
            p.updated_at,
            p.depth,
            p.reply_count,
            b.name as board_name,
            c.name as category_name,
            u.name as user_name,
            COALESCE(comment_count.count, 0) as comment_count
        FROM posts p
        LEFT JOIN boards b ON p.board_id = b.id
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN users u ON p.user_id = u.id
        LEFT JOIN (
            SELECT post_id, COUNT(*) as count 
            FROM comments 
            WHERE status = 'active' 
            GROUP BY post_id
        ) comment_count ON p.id = comment_count.post_id
        WHERE p.id = $1
        "#
    )
    .bind(&post_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        error!("게시글 상세 조회 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let post_raw = match post_raw {
        Some(post) => post,
        None => {
            warn!("존재하지 않는 게시글 조회 시도: {}", post_id);
            return Err(StatusCode::NOT_FOUND);
        }
    };

    let url_id = generate_post_url_id(&state.pool, &post_raw.id).await.ok();

    let post = PostDetail {
        id: post_raw.id,
        board_id: post_raw.board_id,
        category_id: post_raw.category_id,
        user_id: post_raw.user_id,
        parent_id: post_raw.parent_id,
        title: post_raw.title,
        content: post_raw.content,
        views: post_raw.views,
        likes: post_raw.likes,
        dislikes: None,
        is_notice: post_raw.is_notice,
        status: Some(post_raw.status),
        created_at: post_raw.created_at,
        updated_at: post_raw.updated_at,
        depth: post_raw.depth,
        reply_count: post_raw.reply_count,
        user_name: post_raw.user_name,
        user_email: None,
        board_name: post_raw.board_name,
        board_slug: None,
        category_name: post_raw.category_name,
        comment_count: post_raw.comment_count,
        attached_files: None,
        thumbnail_urls: None,
        is_liked: None,
    };

    Ok(Json(ApiResponse::success(post, "게시글을 성공적으로 조회했습니다.")))
}

// 게시글 생성
pub async fn create_post(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(request): Json<CreatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    info!("게시글 생성 요청: user_id={}, title={}", claims.sub, request.title);

    // 게시글 생성
    let post_result = sqlx::query_as::<_, PostDetailRaw>(
        r#"
        INSERT INTO posts (board_id, category_id, user_id, title, content, is_notice, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING 
            id,
            board_id,
            category_id,
            user_id,
            parent_id,
            title,
            content,
            views,
            likes,
            is_notice,
            status,
            created_at,
            updated_at,
            depth,
            reply_count,
            (SELECT name FROM boards WHERE id = board_id) as board_name,
            (SELECT name FROM categories WHERE id = category_id) as category_name,
            (SELECT name FROM users WHERE id = user_id) as user_name,
            0 as comment_count
        "#
    )
    .bind(&request.board_id)
    .bind(&request.category_id)
    .bind(&claims.sub)
    .bind(&request.title)
    .bind(&request.content)
    .bind(&request.is_notice.unwrap_or(false))
    .bind(&request.created_at.unwrap_or_else(|| Utc::now()))
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("게시글 생성 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let url_id = generate_post_url_id(&state.pool, &post_result.id).await.ok();

    let post = PostDetail {
        id: post_result.id,
        board_id: post_result.board_id,
        category_id: post_result.category_id,
        user_id: post_result.user_id,
        parent_id: post_result.parent_id,
        title: post_result.title,
        content: post_result.content,
        views: post_result.views,
        likes: post_result.likes,
        dislikes: None, // 기본값
        is_notice: post_result.is_notice,
        status: Some(post_result.status),
        created_at: post_result.created_at,
        updated_at: post_result.updated_at,
        depth: post_result.depth,
        reply_count: post_result.reply_count,
        user_name: post_result.user_name,
        user_email: None,
        board_name: post_result.board_name,
        board_slug: None,
        category_name: post_result.category_name,
        comment_count: post_result.comment_count,
        attached_files: None,
        thumbnail_urls: None,
        is_liked: None,
    };

    Ok(Json(ApiResponse::success(post, "게시글이 성공적으로 생성되었습니다.")))
}

// 게시글 수정
pub async fn update_post(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(post_id): Path<Uuid>,
    Json(request): Json<UpdatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    info!("게시글 수정 요청: post_id={}, user_id={}", post_id, claims.sub);

    // 게시글 존재 여부 확인
    let post_exists = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM posts WHERE id = $1)"
    )
    .bind(&post_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("게시글 존재 확인 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if !post_exists {
        warn!("존재하지 않는 게시글 수정 시도: {}", post_id);
        return Err(StatusCode::NOT_FOUND);
    }

    // 게시글 수정
    let updated_post_raw = sqlx::query_as::<_, PostDetailRaw>(
        r#"
        UPDATE posts 
        SET 
            board_id = COALESCE($2, board_id),
            category_id = COALESCE($3, category_id),
            title = COALESCE($4, title),
            content = COALESCE($5, content),
            is_notice = COALESCE($6, is_notice),
            updated_at = NOW()
        WHERE id = $1
        RETURNING 
            id,
            board_id,
            category_id,
            user_id,
            parent_id,
            title,
            content,
            views,
            likes,
            is_notice,
            status,
            created_at,
            updated_at,
            depth,
            reply_count,
            (SELECT name FROM boards WHERE id = board_id) as board_name,
            (SELECT name FROM categories WHERE id = category_id) as category_name,
            (SELECT name FROM users WHERE id = user_id) as user_name,
            (SELECT COUNT(*) FROM comments WHERE post_id = posts.id AND status = 'active') as comment_count
        "#
    )
    .bind(&post_id)
    .bind(&request.board_id)
    .bind(&request.category_id)
    .bind(&request.title)
    .bind(&request.content)
    .bind(&request.is_notice)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("게시글 수정 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let url_id = generate_post_url_id(&state.pool, &updated_post_raw.id).await.ok();

    let updated_post = PostDetail {
        id: updated_post_raw.id,
        board_id: updated_post_raw.board_id,
        category_id: updated_post_raw.category_id,
        user_id: updated_post_raw.user_id,
        parent_id: updated_post_raw.parent_id,
        title: updated_post_raw.title,
        content: updated_post_raw.content,
        views: updated_post_raw.views,
        likes: updated_post_raw.likes,
        dislikes: None, // 기본값
        is_notice: updated_post_raw.is_notice,
        status: Some(updated_post_raw.status),
        created_at: updated_post_raw.created_at,
        updated_at: updated_post_raw.updated_at,
        depth: updated_post_raw.depth,
        reply_count: updated_post_raw.reply_count,
        user_name: updated_post_raw.user_name,
        user_email: None,
        board_name: updated_post_raw.board_name,
        board_slug: None,
        category_name: updated_post_raw.category_name,
        comment_count: updated_post_raw.comment_count,
        attached_files: None,
        thumbnail_urls: None,
        is_liked: None,
    };

    Ok(Json(ApiResponse::success(updated_post, "게시글이 성공적으로 수정되었습니다.")))
}

// 게시글 삭제
pub async fn delete_post(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(post_id): Path<Uuid>,
) -> Result<Json<ApiResponse<String>>, StatusCode> {
    info!("게시글 삭제 요청: post_id={}, user_id={}", post_id, claims.sub);

    // 게시글 존재 여부 확인
    let post_exists = sqlx::query_scalar::<_, bool>(
        "SELECT EXISTS(SELECT 1 FROM posts WHERE id = $1)"
    )
    .bind(&post_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("게시글 존재 확인 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if !post_exists {
        warn!("존재하지 않는 게시글 삭제 시도: {}", post_id);
        return Err(StatusCode::NOT_FOUND);
    }

    // 게시글 삭제 (실제로는 status를 'deleted'로 변경)
    sqlx::query(
        r#"
        UPDATE posts 
        SET status = 'deleted', updated_at = NOW()
        WHERE id = $1
        "#
    )
    .bind(&post_id)
    .execute(&state.pool)
    .await
    .map_err(|e| {
        error!("게시글 삭제 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    info!("게시글 삭제 완료: {}", post_id);
    Ok(Json(ApiResponse::success("success".to_string(), "게시글이 성공적으로 삭제되었습니다.")))
}

// 게시글 목록 조회 쿼리 파라미터
#[derive(Debug, Deserialize)]
pub struct PostListQuery {
    pub page: Option<i32>,
    pub limit: Option<i32>,
    pub search: Option<String>,
    pub status: Option<PostStatus>,
}

// 게시글 목록 응답
#[derive(Debug, Serialize)]
pub struct PostListResponse {
    pub posts: Vec<PostDetail>,
    pub total_count: i64,
    pub page: i32,
    pub limit: i32,
    pub total_pages: i32,
}

// 게시글 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreatePostRequest {
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub title: String,
    pub content: String,
    pub is_notice: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub attached_files: Option<Vec<String>>,
}

// 게시글 상세 조회용 Raw 구조체
#[derive(Debug, sqlx::FromRow)]
struct PostDetailRaw {
    pub id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub title: String,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: PostStatus,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>,
    pub reply_count: Option<i32>,
    pub board_name: Option<String>,
    pub category_name: Option<String>,
    pub user_name: Option<String>,
    pub comment_count: Option<i64>,
}

// 게시글 목록 조회용 Raw 구조체
#[derive(Debug, sqlx::FromRow)]
struct PostListRaw {
    pub id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub title: String,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: PostStatus,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>,
    pub reply_count: Option<i32>,
    pub board_name: Option<String>,
    pub category_name: Option<String>,
    pub user_name: Option<String>,
    pub comment_count: Option<i64>,
}
