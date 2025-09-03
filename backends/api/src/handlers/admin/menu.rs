use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use redis::AsyncCommands;
use crate::{
    AppState,
    models::response::ApiResponse,
    models::site::menu::{Menu, CreateMenuRequest, UpdateMenuRequest, MenuType},
};
use tracing::error;
use tracing::info;
use tracing::warn;

// 메뉴 목록 조회 (관리자용)
#[derive(Deserialize)]
pub struct MenuQuery {
    pub page: Option<i64>,
    pub limit: Option<i64>,
    pub parent_id: Option<Uuid>,
    pub is_active: Option<bool>,
}

pub async fn get_menus(
    State(state): State<AppState>,
    Query(query): Query<MenuQuery>,
) -> Result<Json<ApiResponse<Vec<Menu>>>, StatusCode> {
    let page = query.page.unwrap_or(1);
    let limit = query.limit.unwrap_or(50);
    let offset = (page - 1) * limit;

    let mut sql = "SELECT * FROM menus".to_string();
    let mut conditions = Vec::new();

    if let Some(parent_id) = query.parent_id {
        conditions.push(format!("parent_id = '{}'", parent_id));
    } else {
        conditions.push("parent_id IS NULL".to_string()); // 1단 메뉴만 조회
    }

    if let Some(is_active) = query.is_active {
        conditions.push(format!("is_active = {}", is_active));
    }

    if !conditions.is_empty() {
        sql.push_str(&format!(" WHERE {}", conditions.join(" AND ")));
    }

    sql.push_str(&format!(" ORDER BY display_order ASC, created_at ASC LIMIT {} OFFSET {}", limit, offset));

    let menus = sqlx::query_as::<_, Menu>(&sql)
        .fetch_all(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse::success(menus, "메뉴 목록")))
}

// 메뉴 생성
pub async fn create_menu(
    State(state): State<AppState>,
    Json(data): Json<CreateMenuRequest>,
) -> Result<Json<ApiResponse<Menu>>, StatusCode> {
    info!("메뉴 생성 요청: {:?}", data);
    let menu = sqlx::query_as::<_, Menu>(
        r#"
        INSERT INTO menus (id, name, description, menu_type, target_id, url, display_order, is_active, parent_id)
        VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
        "#
    )
    .bind(&data.name)
    .bind(&data.description)
    .bind(&data.menu_type)
    .bind(&data.target_id)
    .bind(&data.url)
    .bind(&data.display_order)
    .bind(&data.is_active)
    .bind(&data.parent_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        error!("메뉴 생성 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // Redis 캐시 무효화
    let mut redis_conn = state.redis.get_async_connection().await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let _: Result<(), redis::RedisError> = redis_conn.del("site_menus").await;

    Ok(Json(ApiResponse::success(menu, "메뉴가 생성되었습니다.")))
}

// 전체 메뉴 배열 업데이트
#[derive(Deserialize)]
pub struct UpdateMenusRequest {
    pub menus: Vec<Menu>,
}

// 프론트엔드에서 보내는 메뉴 데이터 구조
#[derive(Deserialize)]
pub struct FrontendMenu {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub menu_type: String,
    pub target_id: Option<String>,
    pub url: Option<String>,
    pub display_order: i32,
    pub is_active: bool,
    pub parent_id: Option<String>,
}

pub async fn update_menus(
    State(state): State<AppState>,
    Json(data): Json<Vec<FrontendMenu>>,
) -> Result<Json<ApiResponse<Vec<Menu>>>, StatusCode> {
    info!("메뉴 업데이트 요청: {}개 메뉴", data.len());
    
    // 트랜잭션 시작
    let mut tx = state.pool.begin().await
        .map_err(|e| {
            error!("트랜잭션 시작 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 기존 메뉴 모두 삭제
    sqlx::query!("DELETE FROM menus")
        .execute(&mut *tx)
        .await
        .map_err(|e| {
            error!("기존 메뉴 삭제 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // 새 메뉴들 삽입
    let mut updated_menus = Vec::new();
    for (index, menu_data) in data.iter().enumerate() {
        info!("메뉴 {} 처리 중: {}", index + 1, menu_data.name);
        
        // menu_type 문자열을 MenuType enum으로 변환
        let menu_type = match menu_data.menu_type.to_lowercase().as_str() {
            "page" => MenuType::Page,
            "board" => MenuType::Board,
            "calendar" => MenuType::Calendar,
            "url" => MenuType::Url,
            _ => {
                error!("잘못된 menu_type: {}", menu_data.menu_type);
                return Err(StatusCode::BAD_REQUEST);
            }
        };

        // UUID 변환
        let id = match Uuid::parse_str(&menu_data.id) {
            Ok(uuid) => uuid,
            Err(e) => {
                error!("잘못된 ID 형식: {} - {}", menu_data.id, e);
                return Err(StatusCode::BAD_REQUEST);
            }
        };
        
        let target_id = if let Some(target_id_str) = &menu_data.target_id {
            if !target_id_str.is_empty() {
                match Uuid::parse_str(target_id_str) {
                    Ok(uuid) => Some(uuid),
                    Err(e) => {
                        error!("잘못된 target_id 형식: {} - {}", target_id_str, e);
                        return Err(StatusCode::BAD_REQUEST);
                    }
                }
            } else {
                None
            }
        } else {
            None
        };

        let parent_id = if let Some(parent_id_str) = &menu_data.parent_id {
            if !parent_id_str.is_empty() {
                match Uuid::parse_str(parent_id_str) {
                    Ok(uuid) => Some(uuid),
                    Err(e) => {
                        error!("잘못된 parent_id 형식: {} - {}", parent_id_str, e);
                        return Err(StatusCode::BAD_REQUEST);
                    }
                }
            } else {
                None
            }
        } else {
            None
        };

        let new_menu = sqlx::query_as::<_, Menu>(
            r#"
            INSERT INTO menus (id, name, description, menu_type, target_id, url, display_order, is_active, parent_id)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
            "#,
        )
        .bind(id)
        .bind(&menu_data.name)
        .bind(&menu_data.description)
        .bind(menu_type)
        .bind(target_id)
        .bind(&menu_data.url)
        .bind(menu_data.display_order)
        .bind(menu_data.is_active)
        .bind(parent_id)
        .fetch_one(&mut *tx)
        .await
        .map_err(|e| {
            error!("메뉴 삽입 실패: {} - {}", menu_data.name, e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

        updated_menus.push(new_menu);
        info!("메뉴 {} 삽입 완료: {}", index + 1, menu_data.name);
    }

    // 트랜잭션 커밋
    tx.commit().await
        .map_err(|e| {
            error!("트랜잭션 커밋 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // Redis 캐시 무효화 (실패해도 계속 진행)
    if let Ok(mut redis_conn) = state.redis.get_async_connection().await {
        let _: Result<(), redis::RedisError> = redis_conn.del("site_menus").await;
    }

    info!("메뉴 업데이트 완료: {}개 메뉴", updated_menus.len());
    Ok(Json(ApiResponse::success(updated_menus, "메뉴가 성공적으로 업데이트되었습니다.")))
}

// 메뉴 수정
pub async fn update_menu(
    State(state): State<AppState>,
    Path(menu_id): Path<Uuid>,
    Json(data): Json<UpdateMenuRequest>,
) -> Result<Json<ApiResponse<Menu>>, StatusCode> {
    // 단순한 업데이트 쿼리로 변경
    let menu = sqlx::query_as::<_, Menu>(
        r#"
        UPDATE menus 
        SET name = COALESCE($1, name),
            description = COALESCE($2, description),
            menu_type = COALESCE($3, menu_type),
            target_id = $4,
            url = $5,
            display_order = COALESCE($6, display_order),
            is_active = COALESCE($7, is_active),
            parent_id = $8,
            updated_at = NOW()
        WHERE id = $9
        RETURNING *
        "#
    )
    .bind(&data.name)
    .bind(&data.description)
    .bind(&data.menu_type)
    .bind(&data.target_id)
    .bind(&data.url)
    .bind(&data.display_order)
    .bind(&data.is_active)
    .bind(&data.parent_id)
    .bind(&menu_id)
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // Redis 캐시 무효화 (실패해도 계속 진행)
    if let Ok(mut redis_conn) = state.redis.get_async_connection().await {
        let _: Result<(), redis::RedisError> = redis_conn.del("site_menus").await;
    }

    Ok(Json(ApiResponse::success(menu, "메뉴가 수정되었습니다.")))
}

// 메뉴 삭제
pub async fn delete_menu(
    State(state): State<AppState>,
    Path(menu_id): Path<Uuid>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 하위 메뉴가 있는지 확인
    let has_children = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM menus WHERE parent_id = $1",
        menu_id
    )
    .fetch_one(&state.pool)
    .await
    .unwrap_or(Some(0))
    .unwrap_or(0) > 0;

    if has_children {
        return Ok(Json(ApiResponse::<()>::error("하위 메뉴가 있는 메뉴는 삭제할 수 없습니다.")));
    }

    sqlx::query!("DELETE FROM menus WHERE id = $1", menu_id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // Redis 캐시 무효화 (실패해도 계속 진행)
    if let Ok(mut redis_conn) = state.redis.get_async_connection().await {
        let _: Result<(), redis::RedisError> = redis_conn.del("site_menus").await;
    }

    Ok(Json(ApiResponse::success((), "메뉴가 삭제되었습니다.")))
}

// 메뉴 순서 변경
#[derive(Deserialize)]
pub struct ReorderMenuRequest {
    pub menu_orders: Vec<MenuOrder>,
}

#[derive(Deserialize)]
pub struct MenuOrder {
    pub id: Uuid,
    pub display_order: i32,
}

pub async fn reorder_menus(
    State(state): State<AppState>,
    Json(data): Json<ReorderMenuRequest>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    for menu_order in data.menu_orders {
        sqlx::query!(
            "UPDATE menus SET display_order = $1 WHERE id = $2",
            menu_order.display_order,
            menu_order.id
        )
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    }

    // Redis 캐시 무효화 (실패해도 계속 진행)
    if let Ok(mut redis_conn) = state.redis.get_async_connection().await {
        let _: Result<(), redis::RedisError> = redis_conn.del("site_menus").await;
    }

    Ok(Json(ApiResponse::success((), "메뉴 순서가 변경되었습니다.")))
}
