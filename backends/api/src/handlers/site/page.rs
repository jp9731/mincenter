use crate::{
    database::get_database,
    errors::ApiError,
    models::site::page::{Page, CreatePageRequest, UpdatePageRequest, PageListResponse, PageStatusUpdate},
    models::response::ApiResponse,
};
use axum::{
    extract::{Path, Query, Extension},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use uuid::Uuid;
use chrono::Utc;
use std::collections::HashMap;

// 페이지 목록 조회
pub async fn get_pages(
    Extension(claims): Extension<crate::utils::auth::Claims>,
    Query(query): Query<HashMap<String, String>>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    let page = query.get("page").and_then(|p| p.parse::<i64>().ok()).unwrap_or(1);
    let limit = query.get("limit").and_then(|l| l.parse::<i64>().ok()).unwrap_or(10);
    let search = query.get("search").cloned();
    let status = query.get("status").cloned();

    let offset = (page - 1) * limit;

    // 기본 쿼리
    let mut sql = String::from(
        "SELECT p.*, 
                u1.name as created_by_name, 
                u2.name as updated_by_name
         FROM pages p 
         LEFT JOIN users u1 ON p.created_by = u1.id 
         LEFT JOIN users u2 ON p.updated_by = u2.id 
         WHERE 1=1"
    );
    let mut count_sql = String::from("SELECT COUNT(*) FROM pages WHERE 1=1");
    let mut params: Vec<String> = vec![];

    // 검색 조건 추가
    if let Some(search_term) = search {
        let search_condition = " AND (p.title ILIKE $1 OR p.content ILIKE $1 OR p.slug ILIKE $1)";
        sql.push_str(search_condition);
        count_sql.push_str(search_condition);
        params.push(format!("%{}%", search_term));
    }

    // 상태 필터 추가
    if let Some(status_filter) = status {
        let param_index = params.len() + 1;
        let status_condition = format!(" AND p.status = ${}", param_index);
        sql.push_str(&status_condition);
        count_sql.push_str(&status_condition);
        params.push(status_filter);
    }

    // 정렬 및 페이징
    let limit_param = params.len() + 1;
    let offset_param = params.len() + 2;
    sql.push_str(&format!(" ORDER BY p.sort_order ASC, p.created_at DESC LIMIT ${} OFFSET ${}", limit_param, offset_param));

    // 총 개수 조회
    let mut count_query = sqlx::query_scalar::<_, i64>(&count_sql);
    for param in params.iter() {
        count_query = count_query.bind(param);
    }
    let total = count_query.fetch_one(&db).await?;

    // 페이지 목록 조회
    let mut query_builder = sqlx::query_as::<_, Page>(&sql);
    for param in &params {
        query_builder = query_builder.bind(param);
    }
    query_builder = query_builder.bind(limit).bind(offset);

    let pages = query_builder.fetch_all(&db).await?;

    let total_pages = (total + limit - 1) / limit;

    let response = PageListResponse {
        pages,
        total,
        page,
        limit,
        total_pages,
    };

    Ok((
        StatusCode::OK,
        Json(ApiResponse {
            success: true,
            message: "페이지 목록을 성공적으로 조회했습니다.".to_string(),
            data: Some(response),
            pagination: None,
        })
    ))
}

// 단일 페이지 조회
pub async fn get_page(
    Extension(_claims): Extension<crate::utils::auth::Claims>,
    Path(page_id): Path<Uuid>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    let page = sqlx::query_as::<_, Page>(
        "SELECT p.*, 
                u1.name as created_by_name, 
                u2.name as updated_by_name
         FROM pages p 
         LEFT JOIN users u1 ON p.created_by = u1.id 
         LEFT JOIN users u2 ON p.updated_by = u2.id 
         WHERE p.id = $1"
    )
    .bind(page_id)
    .fetch_optional(&db)
    .await?;

    match page {
        Some(page) => Ok((
            StatusCode::OK,
            Json(ApiResponse {
                success: true,
                message: "페이지를 성공적으로 조회했습니다.".to_string(),
                data: Some(page),
                pagination: None,
            })
        )),
        None => Err(ApiError::NotFound("페이지를 찾을 수 없습니다.".to_string())),
    }
}

// 슬러그로 페이지 조회
pub async fn get_page_by_slug(
    Path(slug): Path<String>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    let page = sqlx::query_as::<_, Page>(
        "SELECT p.*, 
                u1.name as created_by_name, 
                u2.name as updated_by_name
         FROM pages p 
         LEFT JOIN users u1 ON p.created_by = u1.id 
         LEFT JOIN users u2 ON p.updated_by = u2.id 
         WHERE p.slug = $1 AND p.is_published = true"
    )
    .bind(slug)
    .fetch_optional(&db)
    .await?;

    match page {
        Some(page) => {
            // 조회수 증가
            let _ = sqlx::query("SELECT increment_page_view_count($1)")
                .bind(page.id)
                .execute(&db)
                .await;

            Ok((
                StatusCode::OK,
                Json(ApiResponse {
                    success: true,
                    message: "페이지를 성공적으로 조회했습니다.".to_string(),
                    data: Some(page),
                    pagination: None,
                })
            ))
        },
        None => Err(ApiError::NotFound("페이지를 찾을 수 없습니다.".to_string())),
    }
}

// 페이지 생성
pub async fn create_page(
    Extension(claims): Extension<crate::utils::auth::Claims>,
    Json(page_data): Json<CreatePageRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    // 슬러그 중복 확인
    let existing = sqlx::query("SELECT id FROM pages WHERE slug = $1")
        .bind(&page_data.slug)
        .fetch_optional(&db)
        .await?;

    if existing.is_some() {
        return Err(ApiError::BadRequest("이미 존재하는 슬러그입니다.".to_string()));
    }

    let published_at = if page_data.is_published {
        Some(Utc::now())
    } else {
        None
    };

    let page = sqlx::query_as::<_, Page>(
        "INSERT INTO pages (
            slug, title, content, excerpt, meta_title, meta_description, 
            status, is_published, published_at, created_by, sort_order
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING *"
    )
    .bind(&page_data.slug)
    .bind(&page_data.title)
    .bind(&page_data.content)
    .bind(&page_data.excerpt)
    .bind(&page_data.meta_title)
    .bind(&page_data.meta_description)
    .bind(&page_data.status)
    .bind(page_data.is_published)
    .bind(published_at)
    .bind(claims.sub)
    .bind(page_data.sort_order.unwrap_or(0))
    .fetch_one(&db)
    .await?;

    Ok((
        StatusCode::CREATED,
        Json(ApiResponse {
            success: true,
            message: "페이지가 성공적으로 생성되었습니다.".to_string(),
            data: Some(page),
            pagination: None,
        })
    ))
}

// 페이지 수정
pub async fn update_page(
    Extension(claims): Extension<crate::utils::auth::Claims>,
    Path(page_id): Path<Uuid>,
    Json(page_data): Json<UpdatePageRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    // 기존 페이지 확인
    let existing = sqlx::query_as::<_, Page>("SELECT * FROM pages WHERE id = $1")
        .bind(page_id)
        .fetch_optional(&db)
        .await?;

    if existing.is_none() {
        return Err(ApiError::NotFound("페이지를 찾을 수 없습니다.".to_string()));
    }

    // 슬러그 중복 확인 (자신 제외)
    if let Some(ref new_slug) = page_data.slug {
        let slug_exists = sqlx::query("SELECT id FROM pages WHERE slug = $1 AND id != $2")
            .bind(new_slug)
            .bind(page_id)
            .fetch_optional(&db)
            .await?;

        if slug_exists.is_some() {
            return Err(ApiError::BadRequest("이미 존재하는 슬러그입니다.".to_string()));
        }
    }

    // 개별 필드 업데이트를 통한 타입 안전성 확보
    let mut query = sqlx::query_as::<_, Page>("SELECT * FROM pages WHERE id = $1")
        .bind(page_id);
    
    let mut update_sql = "UPDATE pages SET ".to_string();
    let mut updates = Vec::new();
    let mut param_count = 1;

    // 동적으로 쿼리 구성
    if page_data.slug.is_some() || page_data.title.is_some() || page_data.content.is_some() || 
       page_data.excerpt.is_some() || page_data.meta_title.is_some() || page_data.meta_description.is_some() ||
       page_data.status.is_some() || page_data.is_published.is_some() || page_data.sort_order.is_some() {
        
        if let Some(ref slug) = page_data.slug {
            updates.push(format!("slug = ${}", param_count));
            param_count += 1;
        }
        
        if let Some(ref title) = page_data.title {
            updates.push(format!("title = ${}", param_count));
            param_count += 1;
        }
        
        if let Some(ref content) = page_data.content {
            // JSON 유효성 검사
            if let Err(e) = serde_json::from_str::<serde_json::Value>(content) {
                eprintln!("Invalid JSON content: {:?}", e);
                return Err(ApiError::BadRequest("유효하지 않은 JSON 형식입니다.".to_string()));
            }
            
            // 컨텐츠 크기 제한 (2MB)
            if content.len() > 2 * 1024 * 1024 {
                return Err(ApiError::BadRequest("컨텐츠 크기가 너무 큽니다. (최대 2MB)".to_string()));
            }
            
            updates.push(format!("content = ${}", param_count));
            param_count += 1;
        }
        
        if let Some(ref excerpt) = page_data.excerpt {
            updates.push(format!("excerpt = ${}", param_count));
            param_count += 1;
        }
        
        if let Some(ref meta_title) = page_data.meta_title {
            updates.push(format!("meta_title = ${}", param_count));
            param_count += 1;
        }
        
        if let Some(ref meta_description) = page_data.meta_description {
            updates.push(format!("meta_description = ${}", param_count));
            param_count += 1;
        }
        
        if let Some(ref status) = page_data.status {
            updates.push(format!("status = ${}", param_count));
            param_count += 1;
        }
        
        if page_data.is_published.is_some() {
            updates.push(format!("is_published = ${}", param_count));
            param_count += 1;
            
            // 발행 상태가 true인 경우 published_at도 업데이트
            if page_data.is_published == Some(true) {
                updates.push(format!("published_at = ${}", param_count));
                param_count += 1;
            }
        }
        
        if page_data.sort_order.is_some() {
            updates.push(format!("sort_order = ${}", param_count));
            param_count += 1;
        }
        
        // updated_by 추가
        updates.push(format!("updated_by = ${}", param_count));
        param_count += 1;
    } else {
        return Err(ApiError::BadRequest("업데이트할 내용이 없습니다.".to_string()));
    }

    update_sql.push_str(&updates.join(", "));
    update_sql.push_str(&format!(" WHERE id = ${} RETURNING *", param_count));

    let mut query_builder = sqlx::query_as::<_, Page>(&update_sql);
    
    // 순서대로 바인딩
    if let Some(ref slug) = page_data.slug {
        query_builder = query_builder.bind(slug);
    }
    if let Some(ref title) = page_data.title {
        query_builder = query_builder.bind(title);
    }
    if let Some(ref content) = page_data.content {
        query_builder = query_builder.bind(content);
    }
    if let Some(ref excerpt) = page_data.excerpt {
        query_builder = query_builder.bind(excerpt);
    }
    if let Some(ref meta_title) = page_data.meta_title {
        query_builder = query_builder.bind(meta_title);
    }
    if let Some(ref meta_description) = page_data.meta_description {
        query_builder = query_builder.bind(meta_description);
    }
    if let Some(ref status) = page_data.status {
        query_builder = query_builder.bind(status);
    }
    if let Some(is_published) = page_data.is_published {
        query_builder = query_builder.bind(is_published);
        if is_published {
            query_builder = query_builder.bind(Utc::now());
        }
    }
    if let Some(sort_order) = page_data.sort_order {
        query_builder = query_builder.bind(sort_order);
    }
    
    // updated_by와 page_id 바인딩
    query_builder = query_builder.bind(claims.sub);
    query_builder = query_builder.bind(page_id);

    let updated_page = query_builder.fetch_one(&db).await.map_err(|e| {
        eprintln!("Database error updating page {}: {:?}", page_id, e);
        eprintln!("Update SQL: {}", update_sql);
        eprintln!("Param count: {}", param_count);
        if let Some(content) = &page_data.content {
            eprintln!("Content length: {}", content.len());
        }
        ApiError::Internal("페이지 업데이트 중 오류가 발생했습니다.".to_string())
    })?;

    Ok((
        StatusCode::OK,
        Json(ApiResponse {
            success: true,
            message: "페이지가 성공적으로 수정되었습니다.".to_string(),
            data: Some(updated_page),
            pagination: None,
        })
    ))
}

// 페이지 상태 업데이트
pub async fn update_page_status(
    Extension(claims): Extension<crate::utils::auth::Claims>,
    Path(page_id): Path<Uuid>,
    Json(status_data): Json<PageStatusUpdate>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    let published_at = if status_data.is_published {
        Some(Utc::now())
    } else {
        None
    };

    let page = sqlx::query_as::<_, Page>(
        "UPDATE pages 
         SET status = $1, is_published = $2, published_at = $3, updated_by = $4 
         WHERE id = $5 
         RETURNING *"
    )
    .bind(&status_data.status)
    .bind(status_data.is_published)
    .bind(published_at)
    .bind(claims.sub)
    .bind(page_id)
    .fetch_one(&db)
    .await?;

    Ok((
        StatusCode::OK,
        Json(ApiResponse {
            success: true,
            message: "페이지 상태가 성공적으로 업데이트되었습니다.".to_string(),
            data: Some(page),
            pagination: None,
        })
    ))
}

// 페이지 삭제
pub async fn delete_page(
    Extension(_claims): Extension<crate::utils::auth::Claims>,
    Path(page_id): Path<Uuid>,
) -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    let result = sqlx::query("DELETE FROM pages WHERE id = $1")
        .bind(page_id)
        .execute(&db)
        .await?;

    if result.rows_affected() == 0 {
        return Err(ApiError::NotFound("페이지를 찾을 수 없습니다.".to_string()));
    }

    Ok((
        StatusCode::OK,
        Json(ApiResponse::<()> {
            success: true,
            message: "페이지가 성공적으로 삭제되었습니다.".to_string(),
            data: None,
            pagination: None,
        })
    ))
}

// 발행된 페이지 목록 조회 (공개용)
pub async fn get_published_pages() -> Result<impl IntoResponse, ApiError> {
    let db = get_database().await?;

    let pages = sqlx::query_as::<_, Page>(
        "SELECT p.*, 
                u1.name as created_by_name, 
                u2.name as updated_by_name
         FROM pages p 
         LEFT JOIN users u1 ON p.created_by = u1.id 
         LEFT JOIN users u2 ON p.updated_by = u2.id 
         WHERE p.is_published = true AND p.status = 'published'
         ORDER BY p.sort_order ASC, p.created_at DESC"
    )
    .fetch_all(&db)
    .await?;

    Ok((
        StatusCode::OK,
        Json(ApiResponse {
            success: true,
            message: "발행된 페이지 목록을 성공적으로 조회했습니다.".to_string(),
            data: Some(pages),
            pagination: None,
        })
    ))
} 