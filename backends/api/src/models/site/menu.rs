use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

// 메뉴 타입
#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone)]
#[sqlx(type_name = "menu_type", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum MenuType {
    Page,    // 안내페이지
    Board,   // 게시판
    Calendar, // 일정
    Url,     // 외부링크
}

// 1단 메뉴
#[derive(Debug, Serialize, Deserialize, FromRow, Clone)]
pub struct Menu {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub menu_type: MenuType,
    pub target_id: Option<Uuid>, // 페이지 ID 또는 게시판 ID
    pub url: Option<String>,     // 외부 링크 URL
    pub display_order: i32,
    pub is_active: bool,
    pub parent_id: Option<Uuid>, // 2단 메뉴인 경우 1단 메뉴 ID
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// 메뉴 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreateMenuRequest {
    pub name: String,
    pub description: Option<String>,
    pub menu_type: MenuType,
    pub target_id: Option<Uuid>,
    pub url: Option<String>,
    pub display_order: i32,
    pub is_active: bool,
    pub parent_id: Option<Uuid>,
}

// 메뉴 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdateMenuRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub menu_type: Option<MenuType>,
    pub target_id: Option<Uuid>,
    pub url: Option<String>,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
    pub parent_id: Option<Uuid>,
}

// 메뉴 트리 구조 (1단 + 2단 메뉴)
#[derive(Debug, Serialize, Deserialize)]
pub struct MenuTree {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub menu_type: MenuType,
    pub target_id: Option<Uuid>,
    pub slug: Option<String>, // 게시판이나 페이지의 slug
    pub url: Option<String>,
    pub display_order: i32,
    pub is_active: bool,
    pub children: Vec<MenuTree>,
}

// 사이트 헤더용 메뉴 응답
#[derive(Debug, Serialize, Deserialize)]
pub struct SiteMenuResponse {
    pub menus: Vec<MenuTree>,
    pub cached_at: DateTime<Utc>,
} 