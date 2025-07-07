use axum::{
    extract::{Multipart, State, Extension, Path as AxumPath},
    http::StatusCode,
    response::Json,
};
use std::path::Path;
use uuid::Uuid;
use chrono::Utc;
use crate::{
    AppState,
    models::response::ApiResponse,
    models::file::{File, FileType, FileStatus, ProcessingStatus, FileEntity, EntityType, FilePurpose, FileInfo},
    utils::auth::Claims,
    services::thumbnail::ThumbnailService,
};

// 파일 업로드 응답
#[derive(Debug, serde::Serialize)]
pub struct UploadResponse {
    pub filename: String,
    pub url: String,
    pub size: u64,
    pub mime_type: String,
    pub file_info: FileInfo,
    pub thumbnail_url: Option<String>,  // 썸네일 URL (이미지인 경우)
}

// 게시글 파일 업로드
pub async fn upload_post_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();
    let mut original_name = String::new();

    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    while let Some(field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            let extension = Path::new(&original_name)
                .extension()
                .and_then(|ext| ext.to_str())
                .unwrap_or("bin");

            // 파일 타입 검증
            if !is_allowed_file_type(&extension) {
                return Err(StatusCode::BAD_REQUEST);
            }

            // 파일 크기 제한 (10MB)
            const MAX_SIZE: u64 = 10 * 1024 * 1024;
            let file_data = field.bytes().await.map_err(|_| StatusCode::BAD_REQUEST)?;
            if file_data.len() as u64 > MAX_SIZE {
                return Err(StatusCode::PAYLOAD_TOO_LARGE);
            }

            // 파일명 생성 - UUID_timestamp_originalname.ext 형태
            let timestamp = Utc::now().timestamp();
            let uuid_part = Uuid::new_v4().to_string();
            let safe_original = sanitize_filename(&original_name);
            filename = format!("{}_{}_{}", uuid_part, timestamp, safe_original);
            
            // 저장 경로 결정
            let subfolder = if is_image_file(&extension) { "images" } else { "documents" };
            file_path = format!("static/uploads/posts/{}/{}", subfolder, filename);
            
            // 디렉토리 생성
            std::fs::create_dir_all(format!("static/uploads/posts/{}", subfolder))
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            // 파일 저장
            std::fs::write(&file_path, &file_data)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            size = file_data.len() as u64;
            mime_type = get_mime_type(&extension);

            // 이미지 파일인 경우 썸네일 생성
            if is_image_file(&extension) {
                let thumbnail_service = ThumbnailService::new();
                if let Err(e) = thumbnail_service.create_thumbnails(&file_path).await {
                    eprintln!("Failed to create thumbnails: {:?}", e);
                    // 썸네일 생성 실패는 치명적이지 않으므로 계속 진행
                }
            }
        }
    }

    if filename.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let url = format!("/uploads/posts/{}/{}", 
        if is_image_file(&Path::new(&filename).extension().and_then(|ext| ext.to_str()).unwrap_or("")) { "images" } else { "documents" },
        filename
    );

    // 파일 타입 결정
    let file_type = determine_file_type(&mime_type);
    
    // files 테이블에 저장 (상태를 draft로 설정)
    let file_id = Uuid::new_v4();
    let file_record = sqlx::query!(
        r#"
        INSERT INTO files (id, user_id, original_name, stored_name, file_path, file_size, mime_type, processing_status)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id
        "#,
        file_id,
        user_id,
        original_name,
        filename,
        file_path,
        size as i64,
        mime_type,
        ProcessingStatus::Completed as ProcessingStatus
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 이미지 파일인 경우 썸네일 URL 생성
    let thumbnail_url = if is_image_file(&Path::new(&filename).extension().and_then(|ext| ext.to_str()).unwrap_or("")) {
        let thumbnail_service = ThumbnailService::new();
        let large_thumbnail_url = thumbnail_service.get_thumbnail_url(&file_path, "large");
        Some(large_thumbnail_url)
    } else {
        None
    };

    let file_info = FileInfo {
        id: file_record.id,
        original_name: original_name.clone(),
        file_path: url.clone(),
        file_size: size as i64,
        mime_type: mime_type.clone(),
        file_type,
        url: url.clone(),
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "파일이 성공적으로 업로드되었습니다.".to_string(),
        data: Some(UploadResponse {
            filename,
            url: url.clone(),
            size,
            mime_type: mime_type.clone(),
            file_info,
            thumbnail_url,
        }),
        pagination: None,
    }))
}

// 프로필 파일 업로드
pub async fn upload_profile_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();
    let mut original_name = String::new();

    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    while let Some(field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            let extension = Path::new(&original_name)
                .extension()
                .and_then(|ext| ext.to_str())
                .unwrap_or("bin");

            // 프로필 이미지만 허용
            if !is_image_file(&extension) {
                return Err(StatusCode::BAD_REQUEST);
            }

            // 파일 크기 제한 (5MB)
            const MAX_SIZE: u64 = 5 * 1024 * 1024;
            let file_data = field.bytes().await.map_err(|_| StatusCode::BAD_REQUEST)?;
            if file_data.len() as u64 > MAX_SIZE {
                return Err(StatusCode::PAYLOAD_TOO_LARGE);
            }

            // 파일명 생성 - UUID_timestamp_originalname.ext 형태
            let timestamp = Utc::now().timestamp();
            let uuid_part = Uuid::new_v4().to_string();
            let safe_original = sanitize_filename(&original_name);
            filename = format!("{}_{}_{}", uuid_part, timestamp, safe_original);
            file_path = format!("static/uploads/profiles/avatars/{}", filename);
            
            // 디렉토리 생성
            std::fs::create_dir_all("static/uploads/profiles/avatars")
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            // 파일 저장
            std::fs::write(&file_path, &file_data)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            size = file_data.len() as u64;
            mime_type = get_mime_type(&extension);
        }
    }

    if filename.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let url = format!("/uploads/profiles/avatars/{}", filename);

    Ok(Json(ApiResponse {
        success: true,
        message: "프로필 이미지가 성공적으로 업로드되었습니다.".to_string(),
        data: Some(UploadResponse {
            filename,
            url: url.clone(),
            size,
            mime_type: mime_type.clone(),
            file_info: FileInfo {
                id: Uuid::new_v4(),
                original_name: original_name.clone(),
                file_path: url.clone(),
                file_size: size as i64,
                mime_type: mime_type.clone(),
                file_type: determine_file_type(&mime_type),
                url: url.clone(),
            },
            thumbnail_url: None,  // 프로필 이미지는 썸네일 불필요
        }),
        pagination: None,
    }))
}

// 사이트 파일 업로드
pub async fn upload_site_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();
    let mut file_type = String::new();
    let mut original_name = String::new();

    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    while let Some(field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            let extension = Path::new(&original_name)
                .extension()
                .and_then(|ext| ext.to_str())
                .unwrap_or("bin");

            // 이미지 파일만 허용
            if !is_image_file(&extension) {
                return Err(StatusCode::BAD_REQUEST);
            }

            // 파일 크기 제한 (10MB)
            const MAX_SIZE: u64 = 10 * 1024 * 1024;
            let file_data = field.bytes().await.map_err(|_| StatusCode::BAD_REQUEST)?;
            if file_data.len() as u64 > MAX_SIZE {
                return Err(StatusCode::PAYLOAD_TOO_LARGE);
            }

            // 파일 타입 결정 (hero, background, logo, banner)
            file_type = "hero".to_string(); // 기본값, 실제로는 요청에서 받아야 함

            // 파일명 생성
            let timestamp = Utc::now().timestamp();
            filename = format!("{}_{}.{}", file_type, timestamp, extension);
            file_path = format!("static/uploads/site/{}/{}", file_type, filename);
            
            // 디렉토리 생성
            std::fs::create_dir_all(format!("static/uploads/site/{}", file_type))
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            // 파일 저장
            std::fs::write(&file_path, &file_data)
                .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

            size = file_data.len() as u64;
            mime_type = get_mime_type(&extension);
        }
    }

    if filename.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let url = format!("/uploads/site/{}/{}", file_type, filename);

    Ok(Json(ApiResponse {
        success: true,
        message: "사이트 파일이 성공적으로 업로드되었습니다.".to_string(),
        data: Some(UploadResponse {
            filename,
            url: url.clone(),
            size,
            mime_type: mime_type.clone(),
            file_info: FileInfo {
                id: Uuid::new_v4(),
                original_name: original_name.clone(),
                file_path: url.clone(),
                file_size: size as i64,
                mime_type: mime_type.clone(),
                file_type: FileType::Image,
                url: url.clone(),
            },
            thumbnail_url: None,  // 사이트 이미지는 썸네일 불필요
        }),
        pagination: None,
    }))
}

// 파일 삭제
pub async fn delete_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    AxumPath(file_id): AxumPath<Uuid>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // 파일 정보 조회
    let file = sqlx::query!(
        "SELECT id, user_id, original_name, stored_name, file_path, file_size, mime_type, created_at FROM files WHERE id = $1",
        file_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    // 권한 확인 (파일 소유자만 삭제 가능)
    if file.user_id != user_id {
        return Err(StatusCode::FORBIDDEN);
    }

    // 파일이 게시글에 연결되어 있는지 확인
    let file_entity = sqlx::query!(
        "SELECT file_id, entity_id FROM file_entities WHERE file_id = $1",
        file_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 게시글에 연결된 파일은 삭제 불가 (게시글 수정에서 처리)
    if file_entity.is_some() {
        return Err(StatusCode::BAD_REQUEST);
    }

    // 파일 시스템에서 실제 파일 삭제
    if let Err(e) = std::fs::remove_file(&file.file_path) {
        eprintln!("Failed to delete file from filesystem: {:?}", e);
        // 파일 시스템 삭제 실패는 무시하고 DB에서만 삭제
    }

    // 썸네일 파일들도 삭제 (이미지인 경우)
    if file.mime_type.starts_with("image/") {
        let thumbnail_service = ThumbnailService::new();
        if let Err(e) = thumbnail_service.delete_thumbnails(&file.file_path).await {
            eprintln!("Failed to delete thumbnails: {:?}", e);
        }
    }

    // DB에서 파일 삭제
    sqlx::query!("DELETE FROM files WHERE id = $1", file_id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(ApiResponse {
        success: true,
        message: "파일이 성공적으로 삭제되었습니다.".to_string(),
        data: Some(()),
        pagination: None,
    }))
}

// 게시글 첨부파일 삭제 (게시글 수정 시)
pub async fn delete_post_attachment(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    AxumPath((post_id, file_id)): AxumPath<(Uuid, Uuid)>,
) -> Result<Json<ApiResponse<()>>, StatusCode> {
    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // 게시글 소유자 확인
    let post = sqlx::query!(
        "SELECT user_id FROM posts WHERE id = $1",
        post_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    if post.user_id != user_id {
        return Err(StatusCode::FORBIDDEN);
    }

    // file_entities에서 연결 제거
    sqlx::query!(
        "DELETE FROM file_entities WHERE file_id = $1 AND entity_id = $2",
        file_id,
        post_id
    )
    .execute(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 파일이 다른 곳에 연결되어 있는지 확인
    let remaining_connections = sqlx::query!(
        "SELECT COUNT(*) as count FROM file_entities WHERE file_id = $1",
        file_id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 다른 곳에 연결되어 있지 않으면 파일도 삭제
    if remaining_connections.count == Some(0) {
        let file = sqlx::query!(
            "SELECT id, user_id, original_name, stored_name, file_path, file_size, mime_type, created_at FROM files WHERE id = $1",
            file_id
        )
        .fetch_optional(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;

        // 파일 시스템에서 실제 파일 삭제
        if let Err(e) = std::fs::remove_file(&file.file_path) {
            eprintln!("Failed to delete file from filesystem: {:?}", e);
        }

        // 썸네일 파일들도 삭제 (이미지인 경우)
        if file.mime_type.starts_with("image/") {
            let thumbnail_service = ThumbnailService::new();
            if let Err(e) = thumbnail_service.delete_thumbnails(&file.file_path).await {
                eprintln!("Failed to delete thumbnails: {:?}", e);
            }
        }

        // DB에서 파일 삭제
        sqlx::query!("DELETE FROM files WHERE id = $1", file_id)
            .execute(&state.pool)
            .await
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    }

    Ok(Json(ApiResponse {
        success: true,
        message: "첨부파일이 성공적으로 삭제되었습니다.".to_string(),
        data: Some(()),
        pagination: None,
    }))
}

// 유틸리티 함수들
fn is_allowed_file_type(extension: &str) -> bool {
    let allowed_extensions = [
        // 이미지
        "jpg", "jpeg", "png", "gif", "webp", "svg",
        // 문서
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt",
        // 비디오 (선택적)
        "mp4", "avi", "mov", "wmv",
    ];
    
    allowed_extensions.contains(&extension.to_lowercase().as_str())
}

fn is_image_file(extension: &str) -> bool {
    let image_extensions = ["jpg", "jpeg", "png", "gif", "webp", "svg"];
    image_extensions.contains(&extension.to_lowercase().as_str())
}

fn get_mime_type(extension: &str) -> String {
    match extension.to_lowercase().as_str() {
        "jpg" | "jpeg" => "image/jpeg".to_string(),
        "png" => "image/png".to_string(),
        "gif" => "image/gif".to_string(),
        "webp" => "image/webp".to_string(),
        "svg" => "image/svg+xml".to_string(),
        "pdf" => "application/pdf".to_string(),
        "doc" => "application/msword".to_string(),
        "docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document".to_string(),
        "xls" => "application/vnd.ms-excel".to_string(),
        "xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".to_string(),
        "ppt" => "application/vnd.ms-powerpoint".to_string(),
        "pptx" => "application/vnd.openxmlformats-officedocument.presentationml.presentation".to_string(),
        "txt" => "text/plain".to_string(),
        "mp4" => "video/mp4".to_string(),
        "avi" => "video/x-msvideo".to_string(),
        "mov" => "video/quicktime".to_string(),
        "wmv" => "video/x-ms-wmv".to_string(),
        _ => "application/octet-stream".to_string(),
    }
}

fn determine_file_type(mime_type: &str) -> FileType {
    match mime_type {
        mime if mime.starts_with("image/") => FileType::Image,
        mime if mime.starts_with("video/") => FileType::Video,
        mime if mime.starts_with("audio/") => FileType::Audio,
        mime if mime.starts_with("application/pdf") || 
                mime.starts_with("application/msword") || 
                mime.starts_with("application/vnd.openxmlformats") ||
                mime.starts_with("text/") => FileType::Document,
        mime if mime.contains("zip") || mime.contains("rar") || mime.contains("tar") => FileType::Archive,
        _ => FileType::Other,
    }
}

fn sanitize_filename(filename: &str) -> String {
    // 파일명에서 안전하지 않은 문자들을 제거하거나 대체
    let mut safe_name = filename
        .chars()
        .map(|c| match c {
            // 파일시스템에서 금지된 문자들을 언더스코어로 대체
            '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
            // 공백은 언더스코어로 대체
            ' ' => '_',
            // 그 외 문자는 그대로 유지
            _ => c,
        })
        .collect::<String>();
    
    // 파일명이 너무 길면 잘라내기 (확장자 제외하고 최대 100자)
    if let Some(dot_pos) = safe_name.rfind('.') {
        let (name_part, ext_part) = safe_name.split_at(dot_pos);
        if name_part.chars().count() > 100 {
            // UTF-8 문자 단위로 자르기
            let truncated_name: String = name_part.chars().take(100).collect();
            safe_name = format!("{}{}", truncated_name, ext_part);
        }
    } else if safe_name.chars().count() > 100 {
        // UTF-8 문자 단위로 자르기
        safe_name = safe_name.chars().take(100).collect();
    }
    
    safe_name
} 