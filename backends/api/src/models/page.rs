use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Page {
    pub id: Uuid,
    pub slug: String,
    pub title: String,
    pub content: String,
    pub excerpt: Option<String>,
    pub meta_title: Option<String>,
    pub meta_description: Option<String>,
    pub status: String,
    pub is_published: bool,
    pub published_at: Option<DateTime<Utc>>,
    pub created_by: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub updated_by: Option<Uuid>,
    pub view_count: i32,
    pub sort_order: i32,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePageRequest {
    pub slug: String,
    pub title: String,
    pub content: String,
    pub excerpt: Option<String>,
    pub meta_title: Option<String>,
    pub meta_description: Option<String>,
    pub status: String,
    pub is_published: bool,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdatePageRequest {
    pub slug: Option<String>,
    pub title: Option<String>,
    pub content: Option<String>,
    pub excerpt: Option<String>,
    pub meta_title: Option<String>,
    pub meta_description: Option<String>,
    pub status: Option<String>,
    pub is_published: Option<bool>,
    pub sort_order: Option<i32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PageListResponse {
    pub pages: Vec<Page>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
    pub total_pages: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PageStatusUpdate {
    pub status: String,
    pub is_published: bool,
} 