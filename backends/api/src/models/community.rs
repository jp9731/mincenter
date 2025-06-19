use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use chrono::{DateTime, Utc};
use uuid::Uuid;

// 게시판 모델
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct Board {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub display_order: Option<i32>,
    pub is_public: Option<bool>,
    pub allow_anonymous: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
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
    pub title: String,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

// 게시글 상세 정보 (사용자 정보 포함)
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostDetail {
    pub id: Uuid,
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub user_id: Uuid,
    pub title: String,
    pub content: String,
    pub views: Option<i32>,
    pub likes: Option<i32>,
    pub is_notice: Option<bool>,
    pub status: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub user_name: Option<String>,
    pub board_name: Option<String>,
    pub category_name: Option<String>,
    pub comment_count: Option<i64>,
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
    pub status: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
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
    pub status: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub user_name: String,
}

// 게시글 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreatePostRequest {
    pub board_id: Uuid,
    pub category_id: Option<Uuid>,
    pub title: String,
    pub content: String,
    pub is_notice: Option<bool>,
}

// 게시글 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdatePostRequest {
    pub board_id: Option<Uuid>,
    pub category_id: Option<Uuid>,
    pub title: Option<String>,
    pub content: Option<String>,
    pub is_notice: Option<bool>,
}

// 댓글 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreateCommentRequest {
    pub post_id: Uuid,
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

// 게시판 목록 응답
#[derive(Debug, Serialize)]
pub struct BoardListResponse {
    pub boards: Vec<Board>,
    pub total: i64,
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

// 게시글 간단 요약 (테스트용)
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct PostSummary {
    pub id: Uuid,
    pub title: String,
    pub board_id: Option<Uuid>,
    pub user_name: Option<String>,
    pub board_name: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
} 