use crate::{
    models::{community::*, response::*},
    AppState,
};
use axum::{
    extract::{Path, Query, State, Extension},
    http::StatusCode,
    Json,
};
use uuid::Uuid;
use sqlx::PgPool;
use crate::utils::auth::get_current_user;

// 게시판 목록 조회
pub async fn get_boards(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Board>>>, StatusCode> {
    let boards = sqlx::query_as::<_, Board>(
        "SELECT id, name, description, category, display_order, is_public, allow_anonymous, created_at, updated_at FROM boards WHERE is_public = true ORDER BY display_order, name"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "게시판 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(boards),
        pagination: None,
    }))
}

// 게시판 상세 조회
pub async fn get_board(
    State(state): State<AppState>,
    Path(board_id): Path<Uuid>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let board = sqlx::query_as!(
        Board,
        r#"
        SELECT id, name, description, category, COALESCE(display_order, 0) as display_order, COALESCE(is_public, true) as is_public, COALESCE(allow_anonymous, false) as allow_anonymous, created_at, updated_at
        FROM boards
        WHERE id = $1 AND is_public = true
        "#,
        board_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to fetch board")),
    ))?
    .ok_or((
        StatusCode::NOT_FOUND,
        Json(ApiResponse::error("Board not found")),
    ))?;

    Ok(Json(ApiResponse::success(board, "Board retrieved")))
}

// 카테고리 목록 조회 (게시판별)
pub async fn get_categories(
    Path(board_id): Path<Uuid>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Category>>>, StatusCode> {
    let categories = sqlx::query_as::<_, Category>(
        "SELECT id, board_id, name, description, display_order, is_active, created_at, updated_at FROM categories WHERE board_id = $1 AND is_active = true ORDER BY display_order, name"
    )
    .bind(board_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "카테고리 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(categories),
        pagination: None,
    }))
}

// 게시글 목록 조회
pub async fn get_posts(
    Query(_query): Query<PostQuery>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<crate::models::community::PostSummary>>>, StatusCode> {
    let posts = sqlx::query_as::<_, crate::models::community::PostSummary>(
        "SELECT p.id, p.title, u.name as user_name,p.board_id, b.name as board_name, p.created_at
         FROM posts p
         JOIN users u ON p.user_id = u.id
         JOIN boards b ON p.board_id = b.id
         WHERE p.status = 'active'
         ORDER BY p.created_at DESC
         LIMIT 10"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Database error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(posts),
        pagination: None,
    }))
}

// 게시글 상세 조회
pub async fn get_post(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 조회수 증가
    sqlx::query("UPDATE posts SET views = COALESCE(views, 0) + 1 WHERE id = $1")
        .bind(post_id)
        .execute(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Update views error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        // 먼저 기본 게시글 정보만 조회해서 테스트 (status를 text로 캐스팅)
    let post_basic = sqlx::query!(
        "SELECT id, board_id, category_id, user_id, title, content, views, likes, is_notice, status::text as status, created_at, updated_at FROM posts WHERE id = $1",
        post_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Basic post query error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 사용자 정보 조회
    let user_info = sqlx::query!("SELECT name FROM users WHERE id = $1", post_basic.user_id)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("User query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 게시판 정보 조회
    let board_info = sqlx::query!("SELECT name FROM boards WHERE id = $1", post_basic.board_id)
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
    let comment_count = sqlx::query!("SELECT COUNT(*) as count FROM comments WHERE post_id = $1 AND status = 'active'", post_id)
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Comment count query error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?
        .count
        .unwrap_or(0);

    let post = PostDetail {
        id: post_basic.id,
        board_id: post_basic.board_id,
        category_id: post_basic.category_id,
        user_id: post_basic.user_id,
        title: post_basic.title,
        content: post_basic.content,
        views: post_basic.views,
        likes: post_basic.likes,
        is_notice: post_basic.is_notice,
        status: post_basic.status,
        created_at: post_basic.created_at,
        updated_at: post_basic.updated_at,
        user_name: user_info.map(|u| u.name),
        board_name: board_info.map(|b| b.name),
        category_name,
        comment_count: Some(comment_count),
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글을 성공적으로 조회했습니다.".to_string(),
        data: Some(post),
        pagination: None,
    }))
}

// 게시글 작성
pub async fn create_post(
    State(state): State<AppState>,
    Extension(user): Extension<crate::models::user::User>,
    Json(payload): Json<CreatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    let post = sqlx::query_as::<_, PostDetail>(
        "INSERT INTO posts (board_id, category_id, user_id, title, content, is_notice)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, board_id, category_id, user_id, title, content, views, likes, is_notice, status, created_at, updated_at,
         (SELECT name FROM users WHERE id = $3) as user_name,
         (SELECT name FROM boards WHERE id = $1) as board_name,
         (SELECT name FROM categories WHERE id = $2) as category_name,
         0 as comment_count"
    )
    .bind(payload.board_id)
    .bind(payload.category_id)
    .bind(user.id)
    .bind(payload.title)
    .bind(payload.content)
    .bind(payload.is_notice.unwrap_or(false))
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글이 성공적으로 작성되었습니다.".to_string(),
        data: Some(post),
        pagination: None,
    }))
}

// 게시글 수정
pub async fn update_post(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(user): Extension<crate::models::user::User>,
    Json(payload): Json<UpdatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // 권한 확인
    let post = sqlx::query_as::<_, Post>(
        "SELECT * FROM posts WHERE id = $1 AND status = 'active'"
    )
    .bind(post_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if post.user_id != user.id && user.role.as_deref() != Some("admin") {
        return Err(StatusCode::FORBIDDEN);
    }

    // 업데이트할 필드들
    let mut updates = Vec::new();
    let mut params: Vec<String> = Vec::new();
    let mut param_count = 0;

    if let Some(board_id) = payload.board_id {
        param_count += 1;
        updates.push(format!("board_id = ${}", param_count));
        params.push(board_id.to_string());
    }

    if let Some(category_id) = payload.category_id {
        param_count += 1;
        updates.push(format!("category_id = ${}", param_count));
        params.push(category_id.to_string());
    }

    if let Some(title) = payload.title {
        param_count += 1;
        updates.push(format!("title = ${}", param_count));
        params.push(title);
    }

    if let Some(content) = payload.content {
        param_count += 1;
        updates.push(format!("content = ${}", param_count));
        params.push(content);
    }

    if let Some(is_notice) = payload.is_notice {
        param_count += 1;
        updates.push(format!("is_notice = ${}", param_count));
        params.push(is_notice.to_string());
    }

    if updates.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    updates.push("updated_at = NOW()".to_string());

    param_count += 1;
    let sql = format!(
        "UPDATE posts SET {} WHERE id = ${} RETURNING id, board_id, category_id, user_id, title, content, views, likes, is_notice, status, created_at::text, updated_at::text,
         (SELECT name FROM users WHERE id = user_id) as user_name,
         (SELECT name FROM boards WHERE id = board_id) as board_name,
         (SELECT name FROM categories WHERE id = category_id) as category_name,
         (SELECT COUNT(*) FROM comments WHERE post_id = posts.id AND status = 'active') as comment_count",
        updates.join(", "),
        param_count
    );

    params.push(post_id.to_string());

    let mut query_builder = sqlx::query_as::<_, PostDetail>(&sql);
    for param in params {
        query_builder = query_builder.bind(param);
    }

    let updated_post = query_builder
        .fetch_one(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글이 성공적으로 수정되었습니다.".to_string(),
        data: Some(updated_post),
        pagination: None,
    }))
}

// 게시글 삭제
pub async fn delete_post(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(user): Extension<crate::models::user::User>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 권한 확인
    let post = sqlx::query_as::<_, Post>(
        "SELECT * FROM posts WHERE id = $1 AND status = 'active'"
    )
    .bind(post_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if post.user_id != user.id && user.role.as_deref() != Some("admin") {
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

// 댓글 목록 조회
pub async fn get_comments(
    Path(post_id): Path<Uuid>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<CommentDetail>>>, StatusCode> {
    let comments = sqlx::query_as::<_, CommentDetail>(
        "SELECT c.*, u.name as user_name
         FROM comments c
         JOIN users u ON c.user_id = u.id
         WHERE c.post_id = $1 AND c.status = 'active'
         ORDER BY c.created_at"
    )
    .bind(post_id)
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(comments),
        pagination: None,
    }))
}

// 댓글 작성
pub async fn create_comment(
    State(state): State<AppState>,
    Extension(user): Extension<crate::models::user::User>,
    Json(payload): Json<CreateCommentRequest>,
) -> Result<Json<ApiResponse<CommentDetail>>, StatusCode> {
    let comment = sqlx::query_as::<_, CommentDetail>(
        "INSERT INTO comments (post_id, user_id, parent_id, content)
         VALUES ($1, $2, $3, $4)
         RETURNING c.*, u.name as user_name
         FROM comments c
         JOIN users u ON c.user_id = u.id
         WHERE c.id = LASTVAL()"
    )
    .bind(payload.post_id)
    .bind(user.id)
    .bind(payload.parent_id)
    .bind(payload.content)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글이 성공적으로 작성되었습니다.".to_string(),
        data: Some(comment),
        pagination: None,
    }))
}

// 댓글 수정
pub async fn update_comment(
    Path(comment_id): Path<Uuid>,
    State(state): State<AppState>,
    Extension(user): Extension<crate::models::user::User>,
    Json(payload): Json<UpdateCommentRequest>,
) -> Result<Json<ApiResponse<CommentDetail>>, StatusCode> {
    // 권한 확인
    let comment = sqlx::query_as::<_, Comment>(
        "SELECT * FROM comments WHERE id = $1 AND status = 'active'"
    )
    .bind(comment_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if comment.user_id != user.id && user.role.as_deref() != Some("admin") {
        return Err(StatusCode::FORBIDDEN);
    }

    let updated_comment = sqlx::query_as::<_, CommentDetail>(
        "UPDATE comments SET content = $1, updated_at = NOW()
         WHERE id = $2
         RETURNING c.*, u.name as user_name
         FROM comments c
         JOIN users u ON c.user_id = u.id
         WHERE c.id = $2"
    )
    .bind(payload.content)
    .bind(comment_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

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
    Extension(user): Extension<crate::models::user::User>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 권한 확인
    let comment = sqlx::query_as::<_, Comment>(
        "SELECT * FROM comments WHERE id = $1 AND status = 'active'"
    )
    .bind(comment_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if comment.user_id != user.id && user.role.as_deref() != Some("admin") {
        return Err(StatusCode::FORBIDDEN);
    }

    // 소프트 삭제
    sqlx::query("UPDATE comments SET status = 'deleted' WHERE id = $1")
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
            WHERE status = 'active'
            GROUP BY board_id
        ) p ON b.id = p.board_id
        LEFT JOIN (
            SELECT p.board_id, COUNT(c.id) as comment_count
            FROM posts p
            LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'active'
            WHERE p.status = 'active'
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
            WHERE status = 'active'
            GROUP BY board_id
        ) p ON b.id = p.board_id
        LEFT JOIN (
            SELECT p.board_id, COUNT(c.id) as comment_count
            FROM posts p
            LEFT JOIN comments c ON p.id = c.post_id AND c.status = 'active'
            WHERE p.status = 'active'
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

// 게시판 생성
pub async fn create_board(
    State(state): State<AppState>,
    Json(request): Json<Board>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let board = sqlx::query_as!(
        Board,
        r#"
        INSERT INTO boards (name, description, category, display_order, is_public, allow_anonymous)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING id, name, description, category, COALESCE(display_order, 0) as display_order, COALESCE(is_public, true) as is_public, COALESCE(allow_anonymous, false) as allow_anonymous, created_at, updated_at
        "#,
        request.name,
        request.description,
        request.category,
        request.display_order,
        request.is_public,
        request.allow_anonymous
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to create board")),
    ))?;

    Ok(Json(ApiResponse::success(board, "Board created")))
}

// 게시판 수정
pub async fn update_board(
    State(state): State<AppState>,
    Path(board_id): Path<Uuid>,
    Json(request): Json<Board>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let board = sqlx::query_as!(
        Board,
        r#"
        UPDATE boards 
        SET name = $1, description = $2, category = $3, display_order = $4, is_public = $5, allow_anonymous = $6, updated_at = NOW()
        WHERE id = $7
        RETURNING id, name, description, category, COALESCE(display_order, 0) as display_order, COALESCE(is_public, true) as is_public, COALESCE(allow_anonymous, false) as allow_anonymous, created_at, updated_at
        "#,
        request.name,
        request.description,
        request.category,
        request.display_order,
        request.is_public,
        request.allow_anonymous,
        board_id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to update board")),
    ))?;

    Ok(Json(ApiResponse::success(board, "Board updated")))
}

// 게시판 삭제
pub async fn delete_board(
    State(state): State<AppState>,
    Path(board_id): Path<Uuid>,
) -> Result<Json<ApiResponse<()>>, (StatusCode, Json<ApiResponse<()>>)> {
    sqlx::query!("DELETE FROM boards WHERE id = $1", board_id)
        .execute(&state.pool)
        .await
        .map_err(|_| (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiResponse::error("Failed to delete board")),
        ))?;

    Ok(Json(ApiResponse::success((), "Board deleted")))
} 