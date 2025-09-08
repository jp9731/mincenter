use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::{DateTime, Utc};
use uuid::Uuid;
use std::str::FromStr;
use crate::models::file::FilePurpose;

// 게시글 상태 enum
#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "post_status", rename_all = "lowercase")]
pub enum PostStatus {
    Active,
    Hidden,
    Deleted,
    Published,
}

impl FromStr for PostStatus {
    type Err = ();
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "active" => Ok(PostStatus::Active),
            "hidden" => Ok(PostStatus::Hidden),
            "deleted" => Ok(PostStatus::Deleted),
            "published" => Ok(PostStatus::Published),
            _ => Err(()),
        }
    }
}

// 카테고리 모델
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Category {
    pub id: Uuid,
    pub board_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// 게시글 모델
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Post {
    pub id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>, // 답글의 경우 부모 게시글 ID
    pub title: String,
    pub content: String, // NOT NULL로 변경됨
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: Option<PostStatus>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>, // 답글 깊이
    pub reply_count: Option<i32>, // 답글 수
}

// 첨부 파일 정보
#[derive(Debug, Serialize, Deserialize)]
pub struct AttachedFile {
    pub id: Uuid,
    pub original_name: String,
    pub file_path: String,
    pub file_size: i64,
    pub mime_type: String, // NOT NULL로 변경됨
    pub file_purpose: Option<FilePurpose>,
    pub display_order: Option<i32>,
}

// 게시글 상세 정보 (사용자 정보 포함)
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostDetail {
    pub id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>, // 답글의 경우 부모 게시글 ID
    pub title: String,
    pub content: String, // NOT NULL로 변경됨
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub dislikes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: Option<PostStatus>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>, // 답글 깊이
    pub reply_count: Option<i32>, // 답글 수
    pub user_name: Option<String>,
    pub user_email: Option<String>,
    pub board_name: Option<String>,
    pub board_slug: Option<String>,
    pub category_name: Option<String>,
    pub comment_count: Option<i64>,
    #[sqlx(skip)]
    pub attached_files: Option<Vec<AttachedFile>>,
    #[sqlx(skip)]
    pub thumbnail_urls: Option<ThumbnailUrls>,
    #[sqlx(skip)]
    pub is_liked: Option<bool>,
}

// 댓글 모델
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Comment {
    pub id: Uuid,
    pub post_id: Uuid,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub content: String,
    pub likes: Option<i32>,
    pub status: Option<PostStatus>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>, // 대댓글 깊이
    pub is_deleted: Option<bool>, // 댓글 삭제 여부
}

// 댓글 상세 정보 (사용자 정보 포함)
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct CommentDetail {
    pub id: Uuid,
    pub post_id: Uuid,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub content: String,
    pub likes: Option<i32>,
    pub status: Option<PostStatus>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>, // 대댓글 깊이
    pub is_deleted: Option<bool>, // 댓글 삭제 여부
    pub user_name: String,
    #[sqlx(skip)]
    pub is_liked: Option<bool>,
}

// 게시글 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreatePostRequest {
    pub board_id: Option<Uuid>,
    pub category_id: Option<Uuid>,
    pub title: String,
    pub content: String,
    pub is_notice: Option<bool>,
    pub attached_files: Option<Vec<String>>,
}

// 답글 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreateReplyRequest {
    pub parent_id: Uuid, // 부모 게시글 ID
    pub title: String,
    pub content: String,
    pub attached_files: Option<Vec<String>>,
}

// 게시글 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdatePostRequest {
    pub board_id: Option<Uuid>,
    pub category_id: Option<Uuid>,
    pub title: Option<String>,
    pub content: Option<String>,
    pub is_notice: Option<bool>,
    pub attached_files: Option<Vec<String>>,
}

// 댓글 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreateCommentRequest {
    pub post_id: String, // 압축된 ID 지원을 위해 String으로 변경
    pub parent_id: Option<Uuid>,
    pub content: String,
}

// 댓글 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdateCommentRequest {
    pub content: String,
}

// 게시글 목록 조회 필터
#[derive(Debug, Deserialize)]
pub struct PostFilter {
    pub board_id: Option<Uuid>,
    pub user_id: Option<Uuid>,
    pub status: Option<String>,
    pub search: Option<String>,
    pub sort: Option<String>,
    pub page: Option<i32>,
    pub limit: Option<i32>,
}

// 게시글 목록 응답
#[derive(Debug, Serialize)]
pub struct PostListResponse {
    pub posts: Vec<PostDetail>,
    pub total: i64,
    pub page: i64,
    pub limit: i64,
    pub total_pages: i64,
}

// 댓글 목록 응답
#[derive(Debug, Serialize)]
pub struct CommentListResponse {
    pub comments: Vec<CommentDetail>,
    pub total: i64,
}

// 최근 게시글 응답
#[derive(Debug, Serialize)]
pub struct RecentPostsResponse {
    pub posts: Vec<PostDetail>,
}

// 게시판 통계
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct BoardStats {
    pub board_id: Uuid,
    pub board_name: String,
    pub post_count: Option<i64>,
    pub comment_count: Option<i64>,
}

// 게시글 조회 쿼리
#[derive(Debug, Serialize, Deserialize)]
pub struct PostQuery {
    pub search: Option<String>,
    pub board_id: Option<Uuid>,
    pub category_id: Option<Uuid>,
    pub sort: Option<String>,
    pub page: Option<i64>,
    pub limit: Option<i64>,
}

// 게시글 간단 요약 (쿼리용 - attached_files 제외)
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostSummaryDb {
    pub id: Uuid,
    pub title: String,
    pub board_id: Option<Uuid>,
    pub user_name: Option<String>,
    pub board_name: Option<String>,
    pub board_slug: Option<String>,
    pub category_name: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub comment_count: Option<i64>,
    pub content: String, // NOT NULL로 변경됨
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub parent_id: Option<Uuid>, // 답글의 경우 부모 게시글 ID
    pub depth: Option<i32>, // 답글 깊이
    pub reply_count: Option<i32>, // 답글 수
    pub thumbnail_urls: Option<serde_json::Value>, // jsonb로 변경됨
}

// 게시글 간단 요약 (API 응답용)
#[derive(Debug, Serialize, Deserialize)]
pub struct PostSummary {
    pub id: Uuid,
    pub title: String,
    pub board_id: Option<Uuid>,
    pub user_name: Option<String>,
    pub board_name: Option<String>,
    pub board_slug: Option<String>,
    pub category_name: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub comment_count: Option<i64>,
    pub content: String, // NOT NULL로 변경됨
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub attached_files: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub thumbnail_urls: Option<ThumbnailUrls>,
    pub parent_id: Option<Uuid>, // 답글의 경우 부모 게시글 ID
    pub depth: Option<i32>, // 답글 깊이
    pub reply_count: Option<i32>, // 답글 수
}

// 썸네일 URL들
#[derive(Debug, Serialize, Deserialize)]
pub struct ThumbnailUrls {
    pub thumb: Option<String>,   // 목록용 (150x150)
    pub card: Option<String>,    // 카드용 (300x200)  
    pub large: Option<String>,   // 본문용 (800x600)
}

// API 응답용 구조체들 (short_id 포함)
#[derive(Debug, Serialize, Deserialize)]
pub struct PostDetailResponse {
    pub id: Uuid,
    pub short_id: String, // Base62 압축된 ID
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub parent_id: Option<Uuid>,
    pub title: String,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub dislikes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: Option<PostStatus>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub depth: Option<i32>,
    pub reply_count: Option<i32>,
    pub user_name: Option<String>,
    pub user_email: Option<String>,
    pub board_name: Option<String>,
    pub board_slug: Option<String>,
    pub category_name: Option<String>,
    pub comment_count: Option<i64>,
    pub attached_files: Option<Vec<AttachedFile>>,
    pub thumbnail_urls: Option<ThumbnailUrls>,
    pub is_liked: Option<bool>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostSummaryResponse {
    pub id: Uuid,
    pub short_id: String, // Base62 압축된 ID
    pub title: String,
    pub board_id: Option<Uuid>,
    pub user_name: Option<String>,
    pub board_name: Option<String>,
    pub board_slug: Option<String>,
    pub category_name: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub comment_count: Option<i64>,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub attached_files: Option<Vec<String>>,
    pub thumbnail_urls: Option<ThumbnailUrls>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CategoryResponse {
    pub id: Uuid,
    pub short_id: String, // Base62 압축된 ID
    pub board_id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// 변환 함수들
impl PostSummary {
    pub fn to_response(self) -> PostSummaryResponse {
        use crate::utils::uuid_compression::compress_uuid_to_base62;
        
        PostSummaryResponse {
            id: self.id,
            short_id: compress_uuid_to_base62(&self.id),
            title: self.title,
            board_id: self.board_id,
            user_name: self.user_name,
            board_name: self.board_name,
            board_slug: self.board_slug,
            category_name: self.category_name,
            created_at: self.created_at,
            comment_count: self.comment_count,
            content: self.content,
            views: self.views,
            likes: self.likes,
            is_notice: self.is_notice,
            attached_files: self.attached_files,
            thumbnail_urls: self.thumbnail_urls,
        }
    }
}

impl PostDetail {
    pub fn to_response(self) -> PostDetailResponse {
        use crate::utils::uuid_compression::compress_uuid_to_base62;
        
        PostDetailResponse {
            id: self.id,
            short_id: compress_uuid_to_base62(&self.id),
            board_id: self.board_id,
            category_id: self.category_id,
            user_id: self.user_id,
            parent_id: self.parent_id,
            title: self.title,
            content: self.content,
            views: self.views,
            likes: self.likes,
            dislikes: self.dislikes,
            is_notice: self.is_notice,
            status: self.status,
            created_at: self.created_at,
            updated_at: self.updated_at,
            depth: self.depth,
            reply_count: self.reply_count,
            user_name: self.user_name,
            user_email: self.user_email,
            board_name: self.board_name,
            board_slug: self.board_slug,
            category_name: self.category_name,
            comment_count: self.comment_count,
            attached_files: self.attached_files,
            thumbnail_urls: self.thumbnail_urls,
            is_liked: self.is_liked,
        }
    }
}

impl Category {
    pub fn to_response(self) -> CategoryResponse {
        use crate::utils::uuid_compression::compress_uuid_to_base62;
        
        CategoryResponse {
            id: self.id,
            short_id: compress_uuid_to_base62(&self.id),
            board_id: self.board_id,
            name: self.name,
            description: self.description,
            display_order: self.display_order,
            is_active: self.is_active,
            created_at: self.created_at,
            updated_at: self.updated_at,
        }
    }
}