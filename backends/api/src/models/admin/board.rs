use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Board {
    pub id: Uuid,
    pub name: String,
    pub slug: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub display_order: i32,
    pub is_public: bool,
    pub allow_anonymous: bool,
    // 파일 업로드 설정
    pub allow_file_upload: bool,
    pub max_files: i32,
    pub max_file_size: i64,
    pub allowed_file_types: Option<Vec<String>>,
    // 리치 텍스트 에디터 설정
    pub allow_rich_text: bool,
    // 기타 설정
    pub require_category: bool,
    pub allow_comments: bool,
    pub allow_likes: bool,
    // 새로운 설정 필드들
    // 권한 설정
    pub write_permission: String,
    pub list_permission: String,
    pub read_permission: String,
    pub reply_permission: String,
    pub comment_permission: String,
    pub download_permission: String,
    // 게시글 설정
    pub hide_list: bool,
    pub editor_type: String,
    pub allow_search: bool,
    // 추천/비추천 설정
    pub allow_recommend: bool,
    pub allow_disrecommend: bool,
    // 표시 설정
    pub show_author_name: bool,
    pub show_ip: bool,
    // 수정/삭제 제한
    pub edit_comment_limit: i32,
    pub delete_comment_limit: i32,
    // 추가 기능
    pub use_sns: bool,
    pub use_captcha: bool,
    // 제한 설정
    pub title_length: i32,
    pub posts_per_page: i32,
    // 포인트 설정
    pub read_point: i32,
    pub write_point: i32,
    pub comment_point: i32,
    pub download_point: i32,
    // iframe 도메인 설정
    pub allowed_iframe_domains: Option<Vec<String>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateBoardRequest {
    pub name: String,
    pub slug: String, // 다시 필수로 변경
    pub description: Option<String>,
    pub category: Option<String>,
    pub display_order: Option<i32>,
    pub is_public: Option<bool>,
    pub allow_anonymous: Option<bool>,
    pub allow_file_upload: Option<bool>,
    pub max_files: Option<i32>,
    pub max_file_size: Option<i64>,
    pub allowed_file_types: Option<Vec<String>>,
    pub allow_rich_text: Option<bool>,
    pub require_category: Option<bool>,
    pub allow_comments: Option<bool>,
    pub allow_likes: Option<bool>,
    pub write_permission: Option<String>,
    pub list_permission: Option<String>,
    pub read_permission: Option<String>,
    pub reply_permission: Option<String>,
    pub comment_permission: Option<String>,
    pub download_permission: Option<String>,
    pub hide_list: Option<bool>,
    pub editor_type: Option<String>,
    pub allow_search: Option<bool>,
    pub allow_recommend: Option<bool>,
    pub allow_disrecommend: Option<bool>,
    pub show_author_name: Option<bool>,
    pub show_ip: Option<bool>,
    pub edit_comment_limit: Option<i32>,
    pub delete_comment_limit: Option<i32>,
    pub use_sns: Option<bool>,
    pub use_captcha: Option<bool>,
    pub title_length: Option<i32>,
    pub posts_per_page: Option<i32>,
    pub read_point: Option<i32>,
    pub write_point: Option<i32>,
    pub comment_point: Option<i32>,
    pub download_point: Option<i32>,
    pub allowed_iframe_domains: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateBoardRequest {
    pub name: Option<String>,
    pub slug: Option<String>,
    pub description: Option<String>,
    pub category: Option<String>,
    pub display_order: Option<i32>,
    pub is_public: Option<bool>,
    pub allow_anonymous: Option<bool>,
    pub allow_file_upload: Option<bool>,
    pub max_files: Option<i32>,
    pub max_file_size: Option<i64>,
    pub allowed_file_types: Option<Vec<String>>,
    pub allow_rich_text: Option<bool>,
    pub require_category: Option<bool>,
    pub allow_comments: Option<bool>,
    pub allow_likes: Option<bool>,
    pub write_permission: Option<String>,
    pub list_permission: Option<String>,
    pub read_permission: Option<String>,
    pub reply_permission: Option<String>,
    pub comment_permission: Option<String>,
    pub download_permission: Option<String>,
    pub hide_list: Option<bool>,
    pub editor_type: Option<String>,
    pub allow_search: Option<bool>,
    pub allow_recommend: Option<bool>,
    pub allow_disrecommend: Option<bool>,
    pub show_author_name: Option<bool>,
    pub show_ip: Option<bool>,
    pub edit_comment_limit: Option<i32>,
    pub delete_comment_limit: Option<i32>,
    pub use_sns: Option<bool>,
    pub use_captcha: Option<bool>,
    pub title_length: Option<i32>,
    pub posts_per_page: Option<i32>,
    pub read_point: Option<i32>,
    pub write_point: Option<i32>,
    pub comment_point: Option<i32>,
    pub download_point: Option<i32>,
    pub allowed_iframe_domains: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Category {
    pub id: Uuid,
    pub board_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub display_order: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateCategoryRequest {
    pub name: String,
    pub description: Option<String>,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateCategoryRequest {
    pub name: Option<String>,
    pub description: Option<String>,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
}

// API 응답용 구조체들 (short_id 포함)
#[derive(Debug, Serialize, Deserialize)]
pub struct BoardResponse {
    pub id: Uuid,
    pub short_id: String, // Base62 압축된 ID
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
    pub allowed_file_types: Option<Vec<String>>,
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
    pub allowed_iframe_domains: Option<Vec<String>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CategoryResponse {
    pub id: Uuid,
    pub short_id: String, // Base62 압축된 ID
    pub board_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub display_order: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
} 