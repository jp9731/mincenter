use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use redis::AsyncCommands;
use crate::{
    AppState,
    models::response::ApiResponse,
    models::site::menu::{Menu, MenuTree, SiteMenuResponse, MenuType},
};
use tracing::error;
use tracing::info;

// 사이트 헤더용 메뉴 조회 (Redis 캐시 사용)
pub async fn get_site_menus(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<SiteMenuResponse>>, StatusCode> {
    // Redis에서 캐시된 메뉴 조회 (실패해도 계속 진행)
    if let Ok(mut redis_conn) = state.redis.get_async_connection().await {
        let cached_menus: Result<String, redis::RedisError> = redis_conn.get("site_menus").await;
        
        if let Ok(cached_data) = cached_menus {
            if let Ok(site_response) = serde_json::from_str::<SiteMenuResponse>(&cached_data) {
                return Ok(Json(ApiResponse::success(site_response, "캐시된 메뉴 데이터")));
            }
        }
    }

    // 캐시가 없으면 DB에서 조회하고 캐시에 저장
    let menus = build_menu_tree(&state.pool).await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let site_response = SiteMenuResponse {
        menus,
        cached_at: chrono::Utc::now(),
    };

    // Redis에 캐시 저장 (1시간) - 실패해도 계속 진행
    if let Ok(mut redis_conn) = state.redis.get_async_connection().await {
        let _: Result<(), redis::RedisError> = redis_conn
            .set_ex("site_menus", serde_json::to_string(&site_response).unwrap(), 3600)
            .await;
    }

    Ok(Json(ApiResponse::success(site_response, "메뉴 데이터")))
}

// 메뉴 트리 구조 생성
async fn build_menu_tree(pool: &sqlx::PgPool) -> Result<Vec<MenuTree>, sqlx::Error> {
    // 모든 활성 메뉴 조회
    let all_menus = sqlx::query_as::<_, Menu>(
        "SELECT * FROM menus WHERE is_active = true ORDER BY display_order ASC, created_at ASC"
    )
    .fetch_all(pool)
    .await?;

    // 1단 메뉴만 필터링
    let root_menus: Vec<Menu> = all_menus.iter()
        .filter(|menu| menu.parent_id.is_none())
        .cloned()
        .collect();

    // 각 1단 메뉴에 하위 메뉴 추가
    let mut menu_trees = Vec::new();
    for root_menu in root_menus {
        let mut children = Vec::new();
        for menu in &all_menus {
            if menu.parent_id == Some(root_menu.id) {
                let slug = get_slug_for_menu(pool, &menu.menu_type, menu.target_id).await;
                children.push(MenuTree {
                    id: menu.id,
                    name: menu.name.clone(),
                    description: menu.description.clone(),
                    menu_type: menu.menu_type.clone(),
                    target_id: menu.target_id,
                    slug,
                    url: menu.url.clone(),
                    display_order: menu.display_order,
                    is_active: menu.is_active,
                    children: Vec::new(),
                });
            }
        }

        let slug = get_slug_for_menu(pool, &root_menu.menu_type, root_menu.target_id).await;
        let menu_tree = MenuTree {
            id: root_menu.id,
            name: root_menu.name,
            description: root_menu.description,
            menu_type: root_menu.menu_type,
            target_id: root_menu.target_id,
            slug,
            url: root_menu.url,
            display_order: root_menu.display_order,
            is_active: root_menu.is_active,
            children,
        };

        menu_trees.push(menu_tree);
    }

    Ok(menu_trees)
}

// 메뉴 타입과 target_id에 따라 slug 조회
async fn get_slug_for_menu(pool: &sqlx::PgPool, menu_type: &MenuType, target_id: Option<Uuid>) -> Option<String> {
    if let Some(id) = target_id {
        match menu_type {
            MenuType::Board => {
                // 게시판에서 slug 조회
                sqlx::query_scalar::<_, String>("SELECT slug FROM boards WHERE id = $1")
                    .bind(id)
                    .fetch_optional(pool)
                    .await
                    .unwrap_or(None)
            },
            MenuType::Page => {
                // 페이지에서 slug 조회
                sqlx::query_scalar::<_, String>("SELECT slug FROM pages WHERE id = $1")
                    .bind(id)
                    .fetch_optional(pool)
                    .await
                    .unwrap_or(None)
            },
            MenuType::Calendar => None, // 일정 타입은 slug가 필요 없음
            MenuType::Url => None, // URL 타입은 slug가 필요 없음
        }
    } else {
        None
    }
}

 