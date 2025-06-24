use axum::{
    extract::{Multipart, State, Extension},
    http::StatusCode,
    response::Json,
};
use std::path::Path;
use uuid::Uuid;
use chrono::Utc;
use crate::{
    AppState,
    models::response::ApiResponse,
    utils::auth::Claims,
};

// 파일 업로드 응답
#[derive(Debug, serde::Serialize)]
pub struct UploadResponse {
    pub filename: String,
    pub url: String,
    pub size: u64,
    pub mime_type: String,
}

// 게시글 파일 업로드
pub async fn upload_post_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();

    while let Some(field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            let original_filename = field.file_name().unwrap_or("unknown").to_string();
            let extension = Path::new(&original_filename)
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

            // 파일명 생성
            let timestamp = Utc::now().timestamp();
            let random_id = Uuid::new_v4().to_string()[..8].to_string();
            filename = format!("{}_{}_{}.{}", claims.sub, timestamp, random_id, extension);
            
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
        }
    }

    if filename.is_empty() {
        return Err(StatusCode::BAD_REQUEST);
    }

    let url = format!("/uploads/posts/{}/{}", 
        if is_image_file(&Path::new(&filename).extension().and_then(|ext| ext.to_str()).unwrap_or("")) { "images" } else { "documents" },
        filename
    );

    Ok(Json(ApiResponse {
        success: true,
        message: "파일이 성공적으로 업로드되었습니다.".to_string(),
        data: Some(UploadResponse {
            filename,
            url,
            size,
            mime_type,
        }),
        pagination: None,
    }))
}

// 프로필 파일 업로드
pub async fn upload_profile_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();

    while let Some(field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            let original_filename = field.file_name().unwrap_or("unknown").to_string();
            let extension = Path::new(&original_filename)
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

            // 파일명 생성
            let timestamp = Utc::now().timestamp();
            filename = format!("{}_{}.{}", claims.sub, timestamp, extension);
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
            url,
            size,
            mime_type,
        }),
        pagination: None,
    }))
}

// 사이트 파일 업로드
pub async fn upload_site_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();
    let mut file_type = String::new();

    while let Some(field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            let original_filename = field.file_name().unwrap_or("unknown").to_string();
            let extension = Path::new(&original_filename)
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
            url,
            size,
            mime_type,
        }),
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