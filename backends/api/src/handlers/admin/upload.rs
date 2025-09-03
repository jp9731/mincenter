use axum::{
    extract::{Multipart, State},
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

// 관리자용 사이트 파일 업로드
pub async fn upload_site_file(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut filename = String::new();
    let mut file_path = String::new();
    let mut size = 0u64;
    let mut mime_type = String::new();
    let mut file_type = String::new();
    let mut original_name = String::new();

    while let Some(mut field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            eprintln!("📁 관리자 사이트 파일 업로드 시작: original_name={}", original_name);
            
            // 파일명에서 확장자 추출 (더 안전한 방법)
            let extension = if let Some(dot_pos) = original_name.rfind('.') {
                let ext = &original_name[dot_pos + 1..];
                if ext.is_empty() {
                    "bin".to_string()
                } else {
                    ext.to_lowercase()
                }
            } else {
                "bin".to_string()
            };
            
            eprintln!("📁 확장자 추출: extension={}", extension);

            // 이미지 파일만 허용
            if !is_image_file(&extension) {
                eprintln!("❌ 허용되지 않는 파일 타입: extension={}", extension);
                return Err(StatusCode::BAD_REQUEST);
            }
            
            eprintln!("✅ 사이트 파일 타입 검증 통과: extension={}", extension);

            // 파일 크기 제한 (10MB)
            const MAX_SIZE: u64 = 10 * 1024 * 1024;
            eprintln!("📁 사이트 파일 데이터 읽기 시작...");
            
            // 더 안전한 방법으로 파일 데이터 읽기
            let mut file_data = Vec::new();
            let mut chunk_count = 0;
            
            // 메모리 예약 (성능 향상)
            file_data.reserve(1024 * 1024); // 1MB 예약
            
            while let Some(chunk) = field.chunk().await.map_err(|_| StatusCode::BAD_REQUEST)? {
                chunk_count += 1;
                eprintln!("📁 청크 {} 읽기 완료: {} bytes", chunk_count, chunk.len());
                
                file_data.extend_from_slice(&chunk);
                
                // 파일 크기 검사
                if file_data.len() as u64 > MAX_SIZE {
                    eprintln!("❌ 파일 크기 초과: {} bytes > {} bytes", file_data.len(), MAX_SIZE);
                    return Err(StatusCode::PAYLOAD_TOO_LARGE);
                }
            }

            eprintln!("📁 파일 데이터 읽기 완료: {} bytes, {} 청크", file_data.len(), chunk_count);

            // 파일 크기 검사
            if file_data.len() as u64 > MAX_SIZE {
                eprintln!("❌ 파일 크기 초과: {} bytes > {} bytes", file_data.len(), MAX_SIZE);
                return Err(StatusCode::PAYLOAD_TOO_LARGE);
            }

            // 파일 타입 결정 (hero, background, logo, banner)
            file_type = "logo".to_string(); // 로고 업로드용

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

// 이미지 파일인지 확인
fn is_image_file(extension: &str) -> bool {
    matches!(extension, "jpg" | "jpeg" | "png" | "gif" | "webp" | "svg" | "bmp" | "ico")
}

// MIME 타입 반환
fn get_mime_type(extension: &str) -> String {
    match extension {
        "jpg" | "jpeg" => "image/jpeg".to_string(),
        "png" => "image/png".to_string(),
        "gif" => "image/gif".to_string(),
        "webp" => "image/webp".to_string(),
        "svg" => "image/svg+xml".to_string(),
        "bmp" => "image/bmp".to_string(),
        "ico" => "image/x-icon".to_string(),
        _ => "application/octet-stream".to_string(),
    }
}
