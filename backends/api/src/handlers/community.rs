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
            created_at, updated_at 
        FROM boards 
        WHERE COALESCE(is_public, true) = true 
        ORDER BY display_order, name
        "#
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
            created_at, updated_at
        FROM boards
        WHERE id = $1 AND COALESCE(is_public, true) = true
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

// 카테고리 목록 조회 (slug 기반)
pub async fn get_categories_by_slug(
    Path(slug): Path<String>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<Category>>>, StatusCode> {
    // 먼저 slug로 게시판 ID를 찾기
    let board = sqlx::query_as::<_, Board>(
        "SELECT id, slug, name, description, category, display_order, is_public, allow_anonymous, allow_file_upload, max_files, max_file_size, allowed_file_types, allow_rich_text, require_category, allow_comments, allow_likes, created_at, updated_at FROM boards WHERE slug = $1 AND COALESCE(is_public, true) = true"
    )
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 게시판 ID로 카테고리 조회
    let categories = sqlx::query_as::<_, Category>(
        "SELECT id, board_id, name, description, display_order, is_active, created_at, updated_at FROM categories WHERE board_id = $1 AND is_active = true ORDER BY display_order, name"
    )
    .bind(board.id)
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
    Query(query): Query<PostQuery>,
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<crate::models::community::PostSummary>>>, StatusCode> {
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
                        WHERE p.status = 'active' AND p.board_id = $1 AND p.category_id = $2
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
                        WHERE p.status = 'active' AND p.board_id = $1
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
                    WHERE p.status = 'active'
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
                    "SELECT COUNT(*) as total FROM posts p WHERE p.status = 'active' AND p.board_id = $1 AND p.category_id = $2",
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
                    "SELECT COUNT(*) as total FROM posts p WHERE p.status = 'active' AND p.board_id = $1",
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
                "SELECT COUNT(*) as total FROM posts p WHERE p.status = 'active'"
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
                    crate::models::community::PostSummary,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'active'), 0) as comment_count
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    WHERE p.status = 'active' AND p.board_id = $1 AND p.category_id = $2
                        AND (
                            p.title ILIKE $3 OR
                            p.content ILIKE $3 OR
                            u.name ILIKE $3 OR
                            EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $3)
                        )
                    ORDER BY p.created_at DESC
                    LIMIT $4 OFFSET $5
                    "#,
                    board_id, category_id, search, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            } else {
                sqlx::query_as!(
                    crate::models::community::PostSummary,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'active'), 0) as comment_count
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    WHERE p.status = 'active' AND p.board_id = $1
                        AND (
                            p.title ILIKE $2 OR
                            p.content ILIKE $2 OR
                            u.name ILIKE $2 OR
                            EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $2)
                        )
                    ORDER BY p.created_at DESC
                    LIMIT $3 OFFSET $4
                    "#,
                    board_id, search, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            }
        } else {
            sqlx::query_as!(
                crate::models::community::PostSummary,
                r#"
                SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, p.created_at,
                       COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'active'), 0) as comment_count
                FROM posts p
                JOIN users u ON p.user_id = u.id
                JOIN boards b ON p.board_id = b.id
                WHERE p.status = 'active'
                    AND (
                        p.title ILIKE $1 OR
                        p.content ILIKE $1 OR
                        u.name ILIKE $1 OR
                        EXISTS (SELECT 1 FROM comments c WHERE c.post_id = p.id AND c.content ILIKE $1)
                    )
                ORDER BY p.created_at DESC
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
                    crate::models::community::PostSummary,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'active'), 0) as comment_count
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    WHERE p.status = 'active' AND p.board_id = $1 AND p.category_id = $2
                    ORDER BY p.created_at DESC
                    LIMIT $3 OFFSET $4
                    "#,
                    board_id, category_id, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            } else {
                sqlx::query_as!(
                    crate::models::community::PostSummary,
                    r#"
                    SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, p.created_at,
                           COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'active'), 0) as comment_count
                    FROM posts p
                    JOIN users u ON p.user_id = u.id
                    JOIN boards b ON p.board_id = b.id
                    WHERE p.status = 'active' AND p.board_id = $1
                    ORDER BY p.created_at DESC
                    LIMIT $2 OFFSET $3
                    "#,
                    board_id, limit, offset
                )
                .fetch_all(&state.pool)
                .await
            }
        } else {
            sqlx::query_as!(
                crate::models::community::PostSummary,
                r#"
                SELECT p.id, p.title, u.name as user_name, p.board_id, b.name as board_name, p.created_at,
                       COALESCE((SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'active'), 0) as comment_count
                FROM posts p
                JOIN users u ON p.user_id = u.id
                JOIN boards b ON p.board_id = b.id
                WHERE p.status = 'active'
                ORDER BY p.created_at DESC
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

    // 정렬이 필요한 경우 메모리에서 정렬
    let mut posts = posts;
    match query.sort.as_deref() {
        Some("popular") => {
            posts.sort_by(|a, b| {
                b.created_at.cmp(&a.created_at)
            });
        }
        Some("comments") => {
            posts.sort_by(|a, b| {
                b.comment_count.unwrap_or(0).cmp(&a.comment_count.unwrap_or(0))
            });
        }
        Some("oldest") => {
            posts.sort_by(|a, b| {
                a.created_at.cmp(&b.created_at)
            });
        }
        _ => {} // 기본값 (최신순)은 이미 SQL에서 처리됨
    }

    // 페이징 정보 계산
    let total_pages = (total + limit - 1) / limit;
    let pagination = Some(PaginationInfo {
        page: page as u32,
        limit: limit as u32,
        total: total as u64,
        total_pages: total_pages as u32,
    });

    Ok(Json(ApiResponse {
        success: true,
        message: "게시글 목록을 성공적으로 조회했습니다.".to_string(),
        data: Some(posts),
        pagination,
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
    Extension(claims): Extension<crate::utils::auth::Claims>,
    Json(payload): Json<CreatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    println!("[DEBUG] Creating post with payload: {:?}", payload);
    println!("[DEBUG] User ID from claims: {:?}", claims.sub);
    
    let post = sqlx::query_as::<_, PostDetail>(
        "INSERT INTO posts (board_id, category_id, user_id, title, content, is_notice)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, board_id, category_id, user_id, title, content, views, likes, is_notice, status::text, created_at, updated_at,
         (SELECT name FROM users WHERE id = $3) as user_name,
         (SELECT name FROM boards WHERE id = $1) as board_name,
         (SELECT name FROM categories WHERE id = $2) as category_name,
         0::bigint as comment_count"
    )
    .bind(payload.board_id)
    .bind(payload.category_id)
    .bind(claims.sub)
    .bind(payload.title)
    .bind(payload.content)
    .bind(payload.is_notice.unwrap_or(false))
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Create post error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    println!("[DEBUG] Post created successfully: {:?}", post.id);

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
    Extension(claims): Extension<crate::utils::auth::Claims>,
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

    if post.user_id != claims.sub {
        // 관리자 권한 확인 (임시로 모든 인증된 사용자를 관리자로 처리)
        // 실제로는 데이터베이스에서 사용자 역할을 확인해야 함
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
        "UPDATE posts SET {} WHERE id = ${} RETURNING id, board_id, category_id, user_id, title, content, views, likes, is_notice, status::text, created_at::text, updated_at::text,
         (SELECT name FROM users WHERE id = user_id) as user_name,
         (SELECT name FROM boards WHERE id = board_id) as board_name,
         (SELECT name FROM categories WHERE id = category_id) as category_name,
         (SELECT COUNT(*)::bigint FROM comments WHERE post_id = posts.id AND status = 'active') as comment_count",
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
    Extension(claims): Extension<crate::utils::auth::Claims>,
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

    if post.user_id != claims.sub {
        // 관리자 권한 확인 (임시로 모든 인증된 사용자를 관리자로 처리)
        // 실제로는 데이터베이스에서 사용자 역할을 확인해야 함
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
    Extension(claims): Extension<crate::utils::auth::Claims>,
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
    .bind(claims.sub)
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
    Extension(claims): Extension<crate::utils::auth::Claims>,
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

    if comment.user_id != claims.sub {
        // 관리자 권한 확인 (임시로 모든 인증된 사용자를 관리자로 처리)
        // 실제로는 데이터베이스에서 사용자 역할을 확인해야 함
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
    Extension(claims): Extension<crate::utils::auth::Claims>,
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

    if comment.user_id != claims.sub {
        // 관리자 권한 확인 (임시로 모든 인증된 사용자를 관리자로 처리)
        // 실제로는 데이터베이스에서 사용자 역할을 확인해야 함
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
    Json(request): Json<CreateBoardRequest>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let board = sqlx::query_as!(
        Board,
        r#"
        INSERT INTO boards (
            name, slug, description, category, display_order, is_public, allow_anonymous,
            allow_file_upload, max_files, max_file_size, allowed_file_types,
            allow_rich_text, require_category, allow_comments, allow_likes
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
        )
        RETURNING 
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
            created_at, updated_at
        "#,
        request.name,
        request.slug,
        request.description,
        request.category,
        request.display_order,
        request.is_public,
        request.allow_anonymous,
        request.allow_file_upload,
        request.max_files,
        request.max_file_size,
        request.allowed_file_types.as_deref(),
        request.allow_rich_text,
        request.require_category,
        request.allow_comments,
        request.allow_likes
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Failed to create board: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiResponse::error("Failed to create board")),
        )
    })?;

    Ok(Json(ApiResponse::success(board, "Board created successfully")))
}

// 게시판 수정
pub async fn update_board(
    State(state): State<AppState>,
    Path(board_id): Path<Uuid>,
    Json(request): Json<UpdateBoardRequest>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    // 기존 게시판 조회
    let existing_board = sqlx::query_as!(
        Board,
        "SELECT id, slug, name, description, category, display_order, is_public, allow_anonymous, allow_file_upload, max_files, max_file_size, allowed_file_types, allow_rich_text, require_category, allow_comments, allow_likes, created_at, updated_at FROM boards WHERE id = $1",
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

    // 업데이트할 값들 (기존 값과 새 값 병합)
    let name = request.name.unwrap_or(existing_board.name);
    let description = request.description.or(existing_board.description);
    let category = request.category.or(existing_board.category);
    let display_order = request.display_order.or(existing_board.display_order);
    let is_public = request.is_public.or(existing_board.is_public);
    let allow_anonymous = request.allow_anonymous.or(existing_board.allow_anonymous);
    let allow_file_upload = request.allow_file_upload.or(existing_board.allow_file_upload);
    let max_files = request.max_files.or(existing_board.max_files);
    let max_file_size = request.max_file_size.or(existing_board.max_file_size);
    let allowed_file_types = request.allowed_file_types.or(existing_board.allowed_file_types);
    let allow_rich_text = request.allow_rich_text.or(existing_board.allow_rich_text);
    let require_category = request.require_category.or(existing_board.require_category);
    let allow_comments = request.allow_comments.or(existing_board.allow_comments);
    let allow_likes = request.allow_likes.or(existing_board.allow_likes);

    let board = sqlx::query_as!(
        Board,
        r#"
        UPDATE boards SET 
            name = $1, description = $2, category = $3, display_order = $4,
            is_public = $5, allow_anonymous = $6, allow_file_upload = $7,
            max_files = $8, max_file_size = $9, allowed_file_types = $10,
            allow_rich_text = $11, require_category = $12, allow_comments = $13,
            allow_likes = $14, updated_at = NOW()
        WHERE id = $15
        RETURNING 
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
            created_at, updated_at
        "#,
        name, description, category, display_order, is_public, allow_anonymous,
        allow_file_upload, max_files, max_file_size, allowed_file_types.as_deref(),
        allow_rich_text, require_category, allow_comments, allow_likes, board_id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Failed to update board: {:?}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ApiResponse::error("Failed to update board")),
        )
    })?;

    Ok(Json(ApiResponse::success(board, "Board updated successfully")))
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

// 게시판 slug로 상세 조회
pub async fn get_board_by_slug(
    State(state): State<AppState>,
    Path(slug): Path<String>,
) -> Result<Json<ApiResponse<Board>>, (StatusCode, Json<ApiResponse<()>>)> {
    let board = sqlx::query_as::<_, Board>(
        "SELECT * FROM boards WHERE slug = $1"
    )
    .bind(&slug)
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(ApiResponse::error("Failed to fetch board by slug")),
    ))?
    .ok_or((
        StatusCode::NOT_FOUND,
        Json(ApiResponse::error("Board not found")),
    ))?;
    Ok(Json(ApiResponse::success(board, "Board retrieved by slug")))
}

// 게시판 slug로 게시글 목록 조회
pub async fn get_posts_by_slug(
    State(state): State<AppState>,
    Path(slug): Path<String>,
    Query(query): Query<PostQuery>,
) -> Result<Json<ApiResponse<Vec<crate::models::community::PostSummary>>>, StatusCode> {
    // slug로 board_id 조회
    let board = sqlx::query_as::<_, Board>("SELECT * FROM boards WHERE slug = $1")
        .bind(&slug)
        .fetch_optional(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    // 기존 get_posts 로직 재사용 (board_id만 강제)
    let mut query = query;
    query.board_id = Some(board.id);
    // get_posts 내부 로직 복사 또는 별도 함수로 분리 가능
    // (여기서는 간단히 get_posts 함수 본문을 복사해서 사용)
    // ... (get_posts 본문 복사) ...
    // 실제 구현에서는 get_posts 내부 로직을 별도 함수로 분리하는 것이 좋음
    // (여기서는 간단히 board_id만 세팅해서 기존 get_posts 호출)
    super::community::get_posts(Query(query), State(state)).await
}

// 게시판 slug로 게시글 생성
pub async fn create_post_by_slug(
    State(state): State<AppState>,
    Extension(claims): Extension<crate::utils::auth::Claims>,
    Path(slug): Path<String>,
    Json(mut payload): Json<CreatePostRequest>,
) -> Result<Json<ApiResponse<PostDetail>>, StatusCode> {
    // slug로 board_id 조회
    let board = sqlx::query_as::<_, Board>("SELECT * FROM boards WHERE slug = $1")
        .bind(&slug)
        .fetch_optional(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;
    payload.board_id = Some(board.id);
    // 기존 create_post 로직 재사용
    super::community::create_post(State(state), Extension(claims), Json(payload)).await
} 