use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use std::str::FromStr;

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct File {
    pub id: Uuid,
    pub user_id: Uuid,
    pub original_name: String,
    pub stored_name: String,
    pub file_path: String,
    pub file_size: i64,
    pub original_size: Option<i64>,
    pub mime_type: String, // NOT NULL로 변경됨
    pub file_type: FileType,
    pub status: FileStatus,
    pub compression_ratio: Option<f64>,
    pub has_thumbnails: bool,
    pub processing_status: ProcessingStatus,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type, Clone, Copy)]
#[sqlx(type_name = "file_type", rename_all = "lowercase")]
pub enum FileType {
    Image,
    Video,
    Audio,
    Document,
    Archive,
    Other,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "file_status", rename_all = "lowercase")]
pub enum FileStatus {
    Draft,
    Published,
    Orphaned,
    Processing,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "processing_status", rename_all = "lowercase")]
pub enum ProcessingStatus {
    Pending,
    Processing,
    Completed,
    Failed,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct FileEntity {
    pub id: Uuid,
    pub file_id: Uuid,
    pub entity_type: EntityType,
    pub entity_id: Uuid,
    pub file_purpose: FilePurpose,
    pub display_order: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "entity_type", rename_all = "lowercase")]
pub enum EntityType {
    Post,
    Gallery,
    UserProfile,
    Comment,
    Draft,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "file_purpose", rename_all = "lowercase")]
pub enum FilePurpose {
    Attachment,
    Thumbnail,
    Content,
    Avatar,
    EditorImage,
}

impl FromStr for FilePurpose {
    type Err = ();
    
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "attachment" => Ok(FilePurpose::Attachment),
            "thumbnail" => Ok(FilePurpose::Thumbnail),
            "content" => Ok(FilePurpose::Content),
            "avatar" => Ok(FilePurpose::Avatar),
            "editorimage" => Ok(FilePurpose::EditorImage),
            _ => Err(()),
        }
    }
}

// 파일 업로드 요청
#[derive(Debug, Deserialize)]
pub struct FileUploadRequest {
    pub entity_type: EntityType,
    pub entity_id: Uuid,
    pub file_purpose: Option<FilePurpose>,
}

// 파일 정보 응답
#[derive(Debug, Serialize)]
pub struct FileInfo {
    pub id: Uuid,
    pub original_name: String,
    pub file_path: String,
    pub file_size: i64,
    pub mime_type: String, // NOT NULL로 변경됨
    pub file_type: FileType,
    pub url: String,
} 