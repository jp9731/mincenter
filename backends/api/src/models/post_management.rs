use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

// 새로 생성한 테이블들의 모델
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PostMoveHistory {
    pub id: i32,
    pub post_id: Uuid,
    pub original_board_id: Uuid,
    pub original_category_id: Option<Uuid>,
    pub moved_board_id: Uuid,
    pub moved_category_id: Option<Uuid>,
    pub move_reason: Option<String>,
    pub moved_by: Uuid,
    pub moved_at: DateTime<Utc>,
    pub move_location: String, // 'site' 또는 'admin'
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePostMoveHistory {
    pub post_id: Uuid,
    pub original_board_id: Uuid,
    pub original_category_id: Option<Uuid>,
    pub moved_board_id: Uuid,
    pub moved_category_id: Option<Uuid>,
    pub move_reason: Option<String>,
    pub move_location: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PostHideHistory {
    pub id: i32,
    pub post_id: Uuid,
    pub hide_reason: Option<String>,
    pub hide_category: String, // 'inappropriate', 'spam', 'duplicate', 'violation', 'other', 'quick_hide'
    pub hide_tags: Option<Vec<String>>,
    pub hidden_by: Uuid,
    pub hidden_at: DateTime<Utc>,
    pub hide_location: String, // 'site' 또는 'admin'
    pub is_hidden: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePostHideHistory {
    pub post_id: Uuid,
    pub hide_reason: Option<String>,
    pub hide_category: String,
    pub hide_tags: Option<Vec<String>>,
    pub hide_location: String,
}

// 기존 모델들 (하위 호환성을 위해 유지)
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PostMove {
    pub id: Uuid,
    pub post_id: Uuid,
    pub from_board_id: Uuid,
    pub to_board_id: Uuid,
    pub from_category_id: Option<Uuid>,
    pub to_category_id: Option<Uuid>,
    pub moved_by: Uuid,
    pub move_reason: Option<String>,
    pub moved_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePostMove {
    pub post_id: Uuid,
    pub to_board_id: Uuid,
    pub to_category_id: Option<Uuid>,
    pub move_reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct PostHide {
    pub id: Uuid,
    pub post_id: Uuid,
    pub hidden_by: Uuid,
    pub hide_reason: String,
    pub hidden_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreatePostHide {
    pub post_id: Uuid,
    pub hide_reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct CommentHide {
    pub id: Uuid,
    pub comment_id: Uuid,
    pub hidden_by: Uuid,
    pub hide_reason: String,
    pub hidden_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateCommentHide {
    pub comment_id: Uuid,
    pub hide_reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BoardWithCategories {
    pub board: Board,
    pub categories: Vec<BoardCategory>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Board {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub is_active: bool,
    pub display_order: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BoardCategory {
    pub id: Uuid,
    pub board_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub display_order: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// 열거형 타입들
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MoveLocation {
    Site,
    Admin,
}

impl From<MoveLocation> for String {
    fn from(location: MoveLocation) -> String {
        match location {
            MoveLocation::Site => "site".to_string(),
            MoveLocation::Admin => "admin".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum HideCategory {
    Inappropriate,
    Spam,
    Duplicate,
    Violation,
    Other,
    QuickHide,
}

impl From<HideCategory> for String {
    fn from(category: HideCategory) -> String {
        match category {
            HideCategory::Inappropriate => "inappropriate".to_string(),
            HideCategory::Spam => "spam".to_string(),
            HideCategory::Duplicate => "duplicate".to_string(),
            HideCategory::Violation => "violation".to_string(),
            HideCategory::Other => "other".to_string(),
            HideCategory::QuickHide => "quick_hide".to_string(),
        }
    }
}
