use crate::{
    errors::ApiError,
    models::admin::board::{Board, Category, CreateBoardRequest, UpdateBoardRequest, CreateCategoryRequest, UpdateCategoryRequest},
    models::response::ApiResponse,
};
use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
    routing::{delete, get, post, put},
    Router,
};
use serde::{Deserialize, Serialize};
use crate::AppState;
use uuid::Uuid;
use chrono::{DateTime, Utc};

// DB에서 가져온 raw Board 구조체
#[derive(Debug, sqlx::FromRow)]
struct BoardRaw {
    pub id: Uuid,
    pub name: String,
    pub slug: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub display_order: i32,
    pub is_public: bool,
    pub allow_anonymous: bool,
    pub allow_file_upload: bool,
    pub max_files: i32,
    pub max_file_size: i64,
    pub allowed_file_types: Option<String>, // 다시 문자열로 변경
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
    pub allowed_iframe_domains: Option<String>, // 다시 문자열로 변경
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

fn parse_csv_option(s: &Option<String>) -> Option<Vec<String>> {
    s.as_ref()
        .map(|raw| raw.split(',').map(|v| v.trim().to_string()).filter(|v| !v.is_empty()).collect())
}

fn convert_board_raw_to_board(raw: BoardRaw) -> Board {
    Board {
        id: raw.id,
        name: raw.name,
        slug: raw.slug,
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

#[derive(Debug, Deserialize)]
pub struct BoardListQuery {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub search: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct BoardListResponse {
    pub boards: Vec<Board>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
}

pub fn board_routes() -> Router<AppState> {
    Router::new()
        .route("/", get(list_boards))
        .route("/", post(create_board))
        .route("/:id", get(get_board))
        .route("/:id", put(update_board))
        .route("/:id", delete(delete_board))
        .route("/:id/categories", get(list_categories))
        .route("/:id/categories", post(create_category))
        .route("/:id/categories/:category_id", put(update_category))
        .route("/:id/categories/:category_id", delete(delete_category))
}

// 게시판 목록 조회
pub async fn list_boards(
    State(state): State<AppState>,
    Query(query): Query<BoardListQuery>,
) -> Result<Json<ApiResponse<BoardListResponse>>, ApiError> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(20);
    let offset = (page - 1) * limit;

    let mut sql = "SELECT * FROM boards".to_string();
    let mut count_sql = "SELECT COUNT(*) FROM boards".to_string();
    let mut params: Vec<String> = Vec::new();

    if let Some(search) = query.search {
        sql.push_str(" WHERE name ILIKE $1 OR description ILIKE $1");
        count_sql.push_str(" WHERE name ILIKE $1 OR description ILIKE $1");
        params.push(format!("%{}%", search));
    }

    sql.push_str(" ORDER BY display_order ASC, created_at DESC LIMIT $");
    sql.push_str(&(params.len() + 1).to_string());
    sql.push_str(" OFFSET $");
    sql.push_str(&(params.len() + 2).to_string());

    let mut query_builder = sqlx::query_as::<_, BoardRaw>(&sql);
    for param in &params {
        query_builder = query_builder.bind(param);
    }
    query_builder = query_builder.bind(limit).bind(offset);

    let boards: Vec<BoardRaw> = query_builder.fetch_all(&state.pool).await?;

    let converted_boards: Vec<Board> = boards.into_iter().map(convert_board_raw_to_board).collect();

    let mut count_query_builder = sqlx::query_scalar::<_, i64>(&count_sql);
    for param in &params {
        count_query_builder = count_query_builder.bind(param);
    }
    let total = count_query_builder.fetch_one(&state.pool).await?;

    let response = BoardListResponse {
        boards: converted_boards,
        total,
        page,
        limit,
    };

    Ok(Json(ApiResponse::success(response, "게시판 목록을 성공적으로 조회했습니다.")))
}

// 게시판 생성
pub async fn create_board(
    State(state): State<AppState>,
    Json(board_data): Json<CreateBoardRequest>,
) -> Result<Json<ApiResponse<Board>>, ApiError> {
    // 배열을 콤마 문자열로 변환
    let allowed_file_types_str = board_data.allowed_file_types
        .as_ref()
        .map(|arr| arr.join(","));
    let allowed_iframe_domains_str = board_data.allowed_iframe_domains
        .as_ref()
        .map(|arr| arr.join(","));

    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        INSERT INTO boards (
            name, slug, description, category, display_order, is_public, allow_anonymous,
            allow_file_upload, max_files, max_file_size, allowed_file_types, allow_rich_text,
            require_category, allow_comments, allow_likes, created_at, updated_at,
            write_permission, list_permission, read_permission, reply_permission, comment_permission, download_permission,
            hide_list, editor_type, allow_search, allow_recommend, allow_disrecommend,
            show_author_name, show_ip, edit_comment_limit, delete_comment_limit,
            use_sns, use_captcha, title_length, posts_per_page, read_point, write_point,
            comment_point, download_point, allowed_iframe_domains
        )
        VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW(), NOW(),
            $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30,
            $31, $32, $33, $34, $35, $36, $37, $38, $39
        )
        RETURNING *
        "#,
    )
    .bind(&board_data.name)
    .bind(&board_data.slug)
    .bind(&board_data.description)
    .bind(&board_data.category)
    .bind(board_data.display_order.unwrap_or(0))
    .bind(board_data.is_public.unwrap_or(true))
    .bind(board_data.allow_anonymous.unwrap_or(false))
    .bind(board_data.allow_file_upload.unwrap_or(true))
    .bind(board_data.max_files.unwrap_or(5))
    .bind(board_data.max_file_size.unwrap_or(10485760))
    .bind(allowed_file_types_str.as_deref())
    .bind(board_data.allow_rich_text.unwrap_or(true))
    .bind(board_data.require_category.unwrap_or(false))
    .bind(board_data.allow_comments.unwrap_or(true))
    .bind(board_data.allow_likes.unwrap_or(true))
    .bind(board_data.write_permission.as_deref().unwrap_or("member"))
    .bind(board_data.list_permission.as_deref().unwrap_or("guest"))
    .bind(board_data.read_permission.as_deref().unwrap_or("guest"))
    .bind(board_data.reply_permission.as_deref().unwrap_or("member"))
    .bind(board_data.comment_permission.as_deref().unwrap_or("member"))
    .bind(board_data.download_permission.as_deref().unwrap_or("member"))
    .bind(board_data.hide_list.unwrap_or(false))
    .bind(board_data.editor_type.as_deref().unwrap_or("rich"))
    .bind(board_data.allow_search.unwrap_or(true))
    .bind(board_data.allow_recommend.unwrap_or(true))
    .bind(board_data.allow_disrecommend.unwrap_or(false))
    .bind(board_data.show_author_name.unwrap_or(true))
    .bind(board_data.show_ip.unwrap_or(false))
    .bind(board_data.edit_comment_limit.unwrap_or(0))
    .bind(board_data.delete_comment_limit.unwrap_or(0))
    .bind(board_data.use_sns.unwrap_or(false))
    .bind(board_data.use_captcha.unwrap_or(false))
    .bind(board_data.title_length.unwrap_or(200))
    .bind(board_data.posts_per_page.unwrap_or(20))
    .bind(board_data.read_point.unwrap_or(0))
    .bind(board_data.write_point.unwrap_or(0))
    .bind(board_data.comment_point.unwrap_or(0))
    .bind(board_data.download_point.unwrap_or(0))
    .bind(allowed_iframe_domains_str.as_deref())
    .fetch_one(&state.pool)
    .await?;

    let board = convert_board_raw_to_board(board_raw);

    Ok(Json(ApiResponse::success(board, "게시판이 성공적으로 생성되었습니다.")))
}

// 게시판 조회
pub async fn get_board(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<Board>>, ApiError> {
    let board_raw = sqlx::query_as::<_, BoardRaw>("SELECT * FROM boards WHERE id = $1")
        .bind(id)
        .fetch_one(&state.pool)
        .await?;

    let board = convert_board_raw_to_board(board_raw);

    Ok(Json(ApiResponse::success(board, "게시판을 성공적으로 조회했습니다.")))
}

// 게시판 수정
pub async fn update_board(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
    Json(board_data): Json<UpdateBoardRequest>,
) -> Result<Json<ApiResponse<Board>>, ApiError> {
    // 배열을 콤마 문자열로 변환
    let allowed_file_types_str = board_data.allowed_file_types
        .as_ref()
        .map(|arr| arr.join(","));
    let allowed_iframe_domains_str = board_data.allowed_iframe_domains
        .as_ref()
        .map(|arr| arr.join(","));

    let board_raw = sqlx::query_as::<_, BoardRaw>(
        r#"
        UPDATE boards SET
            name = COALESCE($1, name),
            slug = COALESCE($2, slug),
            description = COALESCE($3, description),
            category = COALESCE($4, category),
            display_order = COALESCE($5, display_order),
            is_public = COALESCE($6, is_public),
            allow_anonymous = COALESCE($7, allow_anonymous),
            allow_file_upload = COALESCE($8, allow_file_upload),
            max_files = COALESCE($9, max_files),
            max_file_size = COALESCE($10, max_file_size),
            allowed_file_types = COALESCE($11, allowed_file_types),
            allow_rich_text = COALESCE($12, allow_rich_text),
            require_category = COALESCE($13, require_category),
            allow_comments = COALESCE($14, allow_comments),
            allow_likes = COALESCE($15, allow_likes),
            write_permission = COALESCE($16, write_permission),
            list_permission = COALESCE($17, list_permission),
            read_permission = COALESCE($18, read_permission),
            reply_permission = COALESCE($19, reply_permission),
            comment_permission = COALESCE($20, comment_permission),
            download_permission = COALESCE($21, download_permission),
            hide_list = COALESCE($22, hide_list),
            editor_type = COALESCE($23, editor_type),
            allow_search = COALESCE($24, allow_search),
            allow_recommend = COALESCE($25, allow_recommend),
            allow_disrecommend = COALESCE($26, allow_disrecommend),
            show_author_name = COALESCE($27, show_author_name),
            show_ip = COALESCE($28, show_ip),
            edit_comment_limit = COALESCE($29, edit_comment_limit),
            delete_comment_limit = COALESCE($30, delete_comment_limit),
            use_sns = COALESCE($31, use_sns),
            use_captcha = COALESCE($32, use_captcha),
            title_length = COALESCE($33, title_length),
            posts_per_page = COALESCE($34, posts_per_page),
            read_point = COALESCE($35, read_point),
            write_point = COALESCE($36, write_point),
            comment_point = COALESCE($37, comment_point),
            download_point = COALESCE($38, download_point),
            allowed_iframe_domains = COALESCE($39, allowed_iframe_domains),
            updated_at = NOW()
        WHERE id = $40
        RETURNING *
        "#,
    )
    .bind(board_data.name.as_deref())
    .bind(board_data.slug.as_deref())
    .bind(board_data.description.as_deref())
    .bind(board_data.category.as_deref())
    .bind(board_data.display_order)
    .bind(board_data.is_public)
    .bind(board_data.allow_anonymous)
    .bind(board_data.allow_file_upload)
    .bind(board_data.max_files)
    .bind(board_data.max_file_size)
    .bind(allowed_file_types_str.as_deref())
    .bind(board_data.allow_rich_text)
    .bind(board_data.require_category)
    .bind(board_data.allow_comments)
    .bind(board_data.allow_likes)
    .bind(board_data.write_permission.as_deref())
    .bind(board_data.list_permission.as_deref())
    .bind(board_data.read_permission.as_deref())
    .bind(board_data.reply_permission.as_deref())
    .bind(board_data.comment_permission.as_deref())
    .bind(board_data.download_permission.as_deref())
    .bind(board_data.hide_list)
    .bind(board_data.editor_type.as_deref())
    .bind(board_data.allow_search)
    .bind(board_data.allow_recommend)
    .bind(board_data.allow_disrecommend)
    .bind(board_data.show_author_name)
    .bind(board_data.show_ip)
    .bind(board_data.edit_comment_limit)
    .bind(board_data.delete_comment_limit)
    .bind(board_data.use_sns)
    .bind(board_data.use_captcha)
    .bind(board_data.title_length)
    .bind(board_data.posts_per_page)
    .bind(board_data.read_point)
    .bind(board_data.write_point)
    .bind(board_data.comment_point)
    .bind(board_data.download_point)
    .bind(allowed_iframe_domains_str.as_deref())
    .bind(id)
    .fetch_one(&state.pool)
    .await?;

    let board = convert_board_raw_to_board(board_raw);

    Ok(Json(ApiResponse::success(board, "게시판이 성공적으로 수정되었습니다.")))
}

// 게시판 삭제
pub async fn delete_board(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<ApiResponse<()>>, ApiError> {
    let result = sqlx::query("DELETE FROM boards WHERE id = $1")
        .bind(id)
        .execute(&state.pool)
        .await?;

    if result.rows_affected() == 0 {
        return Err(ApiError::NotFound("Board not found".to_string()));
    }

    Ok(Json(ApiResponse::success((), "게시판이 성공적으로 삭제되었습니다.")))
}

// 카테고리 목록 조회
pub async fn list_categories(
    State(state): State<AppState>,
    Path(board_id): Path<Uuid>,
) -> Result<Json<ApiResponse<Vec<Category>>>, ApiError> {
    let categories = sqlx::query_as::<_, Category>(
        "SELECT * FROM categories WHERE board_id = $1 ORDER BY display_order ASC, created_at ASC"
    )
    .bind(board_id)
    .fetch_all(&state.pool)
    .await?;

    Ok(Json(ApiResponse::success(categories, "카테고리 목록을 성공적으로 조회했습니다.")))
}

// 카테고리 생성
pub async fn create_category(
    State(state): State<AppState>,
    Path(board_id): Path<Uuid>,
    Json(category_data): Json<CreateCategoryRequest>,
) -> Result<Json<ApiResponse<Category>>, ApiError> {
    let category = sqlx::query_as::<_, Category>(
        r#"
        INSERT INTO categories (board_id, name, description, display_order, is_active)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
        "#,
    )
    .bind(board_id)
    .bind(&category_data.name)
    .bind(&category_data.description)
    .bind(category_data.display_order.unwrap_or(0))
    .bind(category_data.is_active.unwrap_or(true))
    .fetch_one(&state.pool)
    .await?;

    Ok(Json(ApiResponse::success(category, "카테고리가 성공적으로 생성되었습니다.")))
}

// 카테고리 수정
pub async fn update_category(
    State(state): State<AppState>,
    Path((board_id, category_id)): Path<(Uuid, Uuid)>,
    Json(category_data): Json<UpdateCategoryRequest>,
) -> Result<Json<ApiResponse<Category>>, ApiError> {
    let mut query = "UPDATE categories SET ".to_string();
    let mut params: Vec<String> = Vec::new();
    let mut param_count = 1;

    if let Some(name) = &category_data.name {
        if !params.is_empty() {
            query.push_str(", ");
        }
        query.push_str(&format!("name = ${}", param_count));
        params.push(name.clone());
        param_count += 1;
    }

    if let Some(description) = &category_data.description {
        if !params.is_empty() {
            query.push_str(", ");
        }
        query.push_str(&format!("description = ${}", param_count));
        params.push(description.clone());
        param_count += 1;
    }

    if let Some(display_order) = category_data.display_order {
        if !params.is_empty() {
            query.push_str(", ");
        }
        query.push_str(&format!("display_order = ${}", param_count));
        params.push(display_order.to_string());
        param_count += 1;
    }

    if let Some(is_active) = category_data.is_active {
        if !params.is_empty() {
            query.push_str(", ");
        }
        query.push_str(&format!("is_active = ${}", param_count));
        params.push(is_active.to_string());
        param_count += 1;
    }

    if params.is_empty() {
        return Err(ApiError::BadRequest("No fields to update".to_string()));
    }

    query.push_str(&format!(" WHERE id = ${} AND board_id = ${}", param_count, param_count + 1));
    params.push(category_id.to_string());
    params.push(board_id.to_string());

    let mut query_builder = sqlx::query(&query);
    for param in &params {
        query_builder = query_builder.bind(param);
    }

    let result = query_builder.execute(&state.pool).await?;

    if result.rows_affected() == 0 {
        return Err(ApiError::NotFound("Category not found".to_string()));
    }

    let category = sqlx::query_as::<_, Category>("SELECT * FROM categories WHERE id = $1")
        .bind(category_id)
        .fetch_one(&state.pool)
        .await?;

    Ok(Json(ApiResponse::success(category, "카테고리가 성공적으로 수정되었습니다.")))
}

// 카테고리 삭제
pub async fn delete_category(
    State(state): State<AppState>,
    Path((board_id, category_id)): Path<(Uuid, Uuid)>,
) -> Result<Json<ApiResponse<()>>, ApiError> {
    let result = sqlx::query("DELETE FROM categories WHERE id = $1 AND board_id = $2")
        .bind(category_id)
        .bind(board_id)
        .execute(&state.pool)
        .await?;

    if result.rows_affected() == 0 {
        return Err(ApiError::NotFound("Category not found".to_string()));
    }

    Ok(Json(ApiResponse::success((), "카테고리가 성공적으로 삭제되었습니다.")))
}

