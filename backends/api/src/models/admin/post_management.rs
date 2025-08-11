use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostMoveHistory {
    pub id: i32,
    pub post_id: i32,
    pub original_board_id: i32,
    pub original_category_id: Option<i32>,
    pub moved_board_id: i32,
    pub moved_category_id: Option<i32>,
    pub move_reason: Option<String>,
    pub moved_by: i32,
    pub moved_at: DateTime<Utc>,
    pub move_location: String,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostHideHistory {
    pub id: i32,
    pub post_id: Uuid,
    pub hide_reason: Option<String>,
    pub hide_category: String,
    pub hide_tags: Option<Vec<String>>,
    pub hidden_by: Uuid,
    pub hidden_at: DateTime<Utc>,
    pub hide_location: String,
    pub is_hidden: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePostMoveHistory {
    pub post_id: i32,
    pub original_board_id: i32,
    pub original_category_id: Option<i32>,
    pub moved_board_id: i32,
    pub moved_category_id: Option<i32>,
    pub move_reason: Option<String>,
    pub moved_by: i32,
    pub move_location: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePostHideHistory {
    pub post_id: Uuid,
    pub hide_reason: Option<String>,
    pub hide_category: String,
    pub hide_tags: Option<Vec<String>>,
    pub hidden_by: Uuid,
    pub hide_location: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdatePostHideHistory {
    pub hide_reason: Option<String>,
    pub hide_category: Option<String>,
    pub hide_tags: Option<Vec<String>>,
    pub is_hidden: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostMoveRequest {
    pub target_board_id: Uuid,
    pub target_category_id: Option<Uuid>,
    pub move_reason: Option<String>,
    pub move_location: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostHideRequest {
    pub post_id: Uuid,
    pub hide_reason: Option<String>,
    pub hide_category: String,
    pub hide_tags: Option<Vec<String>>,
    pub hide_location: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostUnhideRequest {
    pub post_id: Uuid,
    pub unhide_reason: Option<String>,
    pub unhide_location: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BoardWithCategories {
    pub id: i32,
    pub name: String,
    pub slug: String,
    pub categories: Vec<Category>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Category {
    pub id: i32,
    pub name: String,
    pub slug: String,
}
