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
    let mut thumbnail_url = None;

    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    while let Some(mut field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            eprintln!("📁 파일 업로드 시작: original_name={}", original_name);
            
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

            // 파일 타입 검증
            if !is_allowed_file_type(&extension) {
                eprintln!("❌ 허용되지 않는 파일 타입: extension={}", extension);
                return Err(StatusCode::BAD_REQUEST);
            }
            
            eprintln!("✅ 파일 타입 검증 통과: extension={}", extension);

            // 파일 크기 제한 (50MB로 복원)
            const MAX_SIZE: u64 = 50 * 1024 * 1024;
            eprintln!("📁 파일 데이터 읽기 시작...");
            
            // 더 안전한 방법으로 파일 데이터 읽기 (매우 작은 청크로 처리)
            let mut file_data = Vec::new();
            let mut chunk_count = 0;
            
            // 메모리 예약 (성능 향상)
            file_data.reserve(MAX_SIZE as usize / 4);
            
            // 청크 크기 제한 (16KB로 매우 작게 제한)
            const CHUNK_SIZE_LIMIT: usize = 16 * 1024;
            
            loop {
                match field.chunk().await {
                    Ok(Some(chunk)) => {
                        chunk_count += 1;
                        eprintln!("📁 청크 {} 읽기: {} bytes (누적: {} bytes)", chunk_count, chunk.len(), file_data.len() + chunk.len());
                        
                        // 청크 크기 제한 확인
                        if chunk.len() > CHUNK_SIZE_LIMIT {
                            eprintln!("⚠️ 큰 청크 감지: 청크 {} 크기 {} bytes (제한: {} bytes)", chunk_count, chunk.len(), CHUNK_SIZE_LIMIT);
                            eprintln!("⚠️ 큰 청크로 인한 메모리 압박 가능성");
                        }
                        
                        // 누적 크기 확인
                        if file_data.len() + chunk.len() > MAX_SIZE as usize {
                            eprintln!("❌ 파일 크기 초과: {} bytes > {} bytes", file_data.len() + chunk.len(), MAX_SIZE);
                            return Err(StatusCode::PAYLOAD_TOO_LARGE);
                        }
                        
                        // 청크 데이터를 매우 작은 단위로 나누어 처리
                        let chunk_data = &chunk;
                        let mut offset = 0;
                        
                        while offset < chunk_data.len() {
                            let end = std::cmp::min(offset + CHUNK_SIZE_LIMIT, chunk_data.len());
                            let slice = &chunk_data[offset..end];
                            file_data.extend_from_slice(slice);
                            offset = end;
                            
                            // 메모리 압박을 줄이기 위해 잠시 대기
                            if offset < chunk_data.len() {
                                tokio::time::sleep(tokio::time::Duration::from_millis(10)).await;
                            }
                        }
                        
                        // 메모리 사용량 모니터링
                        if chunk_count % 2 == 0 {
                            eprintln!("📊 메모리 상태: 청크 {} 완료, 누적 크기: {} bytes", chunk_count, file_data.len());
                        }
                        
                        // 청크 5부터 특별 모니터링 (더 일찍 시작)
                        if chunk_count >= 5 {
                            eprintln!("🚨 청크 {} 처리 중 (위험 구간)", chunk_count);
                            // 메모리 압박을 줄이기 위해 더 긴 대기
                            tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
                        }
                    }
                    Ok(None) => {
                        eprintln!("📁 파일 데이터 읽기 완료: 총 {} 청크, {} bytes", chunk_count, file_data.len());
                        break;
                    }
                    Err(e) => {
                        eprintln!("❌ 파일 청크 읽기 실패 (청크 {}): {:?}", chunk_count + 1, e);
                        eprintln!("❌ 현재 누적 크기: {} bytes", file_data.len());
                        // 스트림 오류가 발생해도 일부 데이터가 있다면 계속 진행
                        if !file_data.is_empty() {
                            eprintln!("⚠️ 스트림 오류 발생했지만 {} bytes 데이터 수신됨, 계속 진행", file_data.len());
                            break;
                        } else {
                            return Err(StatusCode::BAD_REQUEST);
                        }
                    }
                }
            }
            
            eprintln!("✅ 파일 크기 검증 통과: {} bytes", file_data.len());

            // 파일명 생성 - UUID_timestamp_originalname.ext 형태
            let timestamp = Utc::now().timestamp();
            let uuid_part = Uuid::new_v4().to_string();
            let safe_original = sanitize_filename(&original_name);
            filename = format!("{}_{}_{}", uuid_part, timestamp, safe_original);
            
            // 저장 경로 결정
            let subfolder = if is_image_file(&extension) { "images" } else { "documents" };
            file_path = format!("static/uploads/posts/{}/{}", subfolder, filename);
            eprintln!("📁 저장 경로: {}", file_path);
            
            // 디렉토리 생성
            eprintln!("📁 디렉토리 생성 시작: static/uploads/posts/{}", subfolder);
            std::fs::create_dir_all(format!("static/uploads/posts/{}", subfolder))
                .map_err(|e| {
                    eprintln!("❌ 디렉토리 생성 실패: {:?}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;
            eprintln!("✅ 디렉토리 생성 완료");

            // 파일 저장
            eprintln!("📁 파일 저장 시작...");
            std::fs::write(&file_path, &file_data)
                .map_err(|e| {
                    eprintln!("❌ 파일 저장 실패: {:?}", e);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;
            eprintln!("✅ 파일 저장 완료: {}", file_path);

            size = file_data.len() as u64;
            mime_type = get_mime_type(&extension);

            // 이미지 파일인 경우 썸네일은 백그라운드에서 생성되므로 즉시 반환하지 않음
            if is_image_file(&extension) {
                thumbnail_url = None;
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
    
    // files 테이블에 저장 (이미지인 경우 처리 중 상태로 저장)
    let file_id = Uuid::new_v4();
    let processing_status = if is_image_file(&Path::new(&filename).extension().and_then(|ext| ext.to_str()).unwrap_or("")) {
        ProcessingStatus::Processing // 이미지인 경우 처리 중 상태로 저장
    } else {
        ProcessingStatus::Completed // 이미지가 아닌 경우 완료 상태로 저장
    };
    
    eprintln!("📁 DB 저장 시작: file_id={}, user_id={}", file_id, user_id);
    let file_record = sqlx::query!(
        r#"
        INSERT INTO files (id, user_id, original_name, stored_name, file_path, file_size, mime_type, file_type, processing_status)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id
        "#,
        file_id,
        user_id,
        original_name,
        filename,
        file_path,
        size as i64,
        mime_type,
        file_type as FileType,
        processing_status as ProcessingStatus
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("❌ DB 저장 실패: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    eprintln!("✅ DB 저장 완료: file_id={}", file_record.id);
    
    // 이미지 파일인 경우 백그라운드에서 썸네일 생성
    if is_image_file(&Path::new(&filename).extension().and_then(|ext| ext.to_str()).unwrap_or("")) {
        let state_clone = state.clone();
        let file_path_clone = file_path.clone();
        let file_id_clone = file_record.id;
        
        // 백그라운드 태스크로 썸네일 생성
        tokio::spawn(async move {
            eprintln!("🔄 백그라운드 썸네일 생성 시작: {}", file_path_clone);
            
            let thumbnail_service = ThumbnailService::new();
            match thumbnail_service.create_thumbnails(&file_path_clone).await {
                Ok(_) => {
                    eprintln!("✅ 백그라운드 썸네일 생성 완료: {}", file_path_clone);
                    
                    // DB 상태를 완료로 업데이트
                    let _ = sqlx::query!(
                        r#"
                        UPDATE files 
                        SET processing_status = $1 
                        WHERE id = $2
                        "#,
                        ProcessingStatus::Completed as ProcessingStatus,
                        file_id_clone
                    )
                    .execute(&state_clone.pool)
                    .await;
                    
                    eprintln!("✅ 파일 처리 상태 업데이트 완료: {}", file_id_clone);
                }
                Err(e) => {
                    eprintln!("❌ 백그라운드 썸네일 생성 실패: {:?}", e);
                    
                    // 실패해도 파일은 유지하되 상태 업데이트
                    let _ = sqlx::query!(
                        r#"
                        UPDATE files 
                        SET processing_status = $1 
                        WHERE id = $2
                        "#,
                        ProcessingStatus::Failed as ProcessingStatus,
                        file_id_clone
                    )
                    .execute(&state_clone.pool)
                    .await;
                }
            }
        });
        
        thumbnail_url = None; // 썸네일은 백그라운드에서 생성되므로 즉시 반환하지 않음
    }

    // 썸네일 URL은 위에서 이미 생성했으므로 그대로 사용

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

// 청크 업로드 엔드포인트 (실시간 합치기 방식)
pub async fn upload_post_file_chunk(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    mut multipart: Multipart,
) -> Result<Json<ApiResponse<UploadResponse>>, StatusCode> {
    let mut chunk_index = 0;
    let mut total_chunks = 0;
    let mut temp_file_id = String::new();
    let mut original_size = 0;
    let mut original_name = String::new();
    let mut chunk_data = Vec::new();

    // 인증 확인
    let user_id = claims
        .as_ref()
        .map(|c| c.sub.clone())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    while let Some(mut field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        match field_name.as_str() {
            "file" => {
                // 청크 데이터 읽기
                let mut data = Vec::new();
                while let Some(chunk) = field.chunk().await.map_err(|_| StatusCode::BAD_REQUEST)? {
                    data.extend_from_slice(&chunk);
                }
                chunk_data = data;
            }
            "chunkIndex" => {
                chunk_index = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?.parse::<usize>().map_err(|_| StatusCode::BAD_REQUEST)?;
            }
            "totalChunks" => {
                total_chunks = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?.parse::<usize>().map_err(|_| StatusCode::BAD_REQUEST)?;
            }
            "tempFileId" => {
                temp_file_id = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?;
            }
            "originalSize" => {
                original_size = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?.parse::<u64>().map_err(|_| StatusCode::BAD_REQUEST)?;
            }
            "originalName" => {
                original_name = field.text().await.map_err(|_| StatusCode::BAD_REQUEST)?;
            }
            _ => {}
        }
    }

    eprintln!("📁 청크 업로드: {}/{} ({} bytes)", chunk_index + 1, total_chunks, chunk_data.len());
    eprintln!("📁 임시 파일 ID: {}", temp_file_id);
    eprintln!("📁 원본 파일명: {}", original_name);
    eprintln!("📁 원본 크기: {} bytes", original_size);

    // 첫 번째 청크인 경우 파일 정보 초기화
    if chunk_index == 0 {
        // 파일명 생성
        let timestamp = Utc::now().timestamp();
        let uuid_part = Uuid::new_v4().to_string();
        let safe_original = sanitize_filename(&original_name);
        let filename = format!("{}_{}_{}", uuid_part, timestamp, safe_original);
        
        // 확장자 추출
        let extension = if let Some(dot_pos) = original_name.rfind('.') {
            let ext = &original_name[dot_pos + 1..];
            if ext.is_empty() { "bin".to_string() } else { ext.to_lowercase() }
        } else {
            "bin".to_string()
        };
        
        // 저장 경로 결정
        let subfolder = if is_image_file(&extension) { "images" } else { "documents" };
        let file_path = format!("static/uploads/posts/{}/{}", subfolder, filename);
        
        // 디렉토리 생성
        std::fs::create_dir_all(format!("static/uploads/posts/{}", subfolder))
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        // 파일 정보를 임시 디렉토리에 저장
        let temp_info_path = format!("static/uploads/temp/{}/file_info.json", temp_file_id);
        std::fs::create_dir_all(format!("static/uploads/temp/{}", temp_file_id))
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        let file_info = serde_json::json!({
            "filename": filename,
            "extension": extension,
            "subfolder": subfolder,
            "file_path": file_path,
            "original_name": original_name,
            "original_size": original_size,
            "user_id": user_id.to_string()
        });
        
        std::fs::write(&temp_info_path, serde_json::to_string(&file_info).unwrap())
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        eprintln!("📁 파일 정보 초기화 완료: {}", filename);
    }

    // 파일 정보 읽기
    let temp_info_path = format!("static/uploads/temp/{}/file_info.json", temp_file_id);
    let file_info_content = std::fs::read_to_string(&temp_info_path)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let file_info: serde_json::Value = serde_json::from_str(&file_info_content)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    let filename = file_info["filename"].as_str().unwrap().to_string();
    let file_path = file_info["file_path"].as_str().unwrap().to_string();
    let original_name = file_info["original_name"].as_str().unwrap().to_string();
    let extension = file_info["extension"].as_str().unwrap().to_string();
    let subfolder = file_info["subfolder"].as_str().unwrap().to_string();
    let user_id = Uuid::parse_str(file_info["user_id"].as_str().unwrap())
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 청크를 파일에 직접 추가 (append 모드)
    let file = std::fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&file_path)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    use std::io::Write;
    let mut writer = std::io::BufWriter::new(file);
    writer.write_all(&chunk_data).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    writer.flush().map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    
    eprintln!("📁 청크 {}/{} 파일에 추가 완료", chunk_index + 1, total_chunks);
    
    // 마지막 청크인 경우 최종 처리
    if chunk_index + 1 == total_chunks {
        eprintln!("📁 모든 청크 수신 완료, 최종 처리 시작");
        
        // 임시 파일 정보 삭제
        let _ = std::fs::remove_file(&temp_info_path);
        let _ = std::fs::remove_dir(format!("static/uploads/temp/{}", temp_file_id));
        
        let url = format!("/uploads/posts/{}/{}", subfolder, filename);
        let mime_type = get_mime_type(&extension);
        let file_type = determine_file_type(&mime_type);
        
        // 파일 크기 확인
        let file_size = std::fs::metadata(&file_path)
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
            .len();
        
        // DB에 저장 (썸네일 없이 먼저 저장)
        let file_id = Uuid::new_v4();
        let processing_status = if is_image_file(&extension) {
            ProcessingStatus::Processing // 이미지인 경우 처리 중 상태로 저장
        } else {
            ProcessingStatus::Completed // 이미지가 아닌 경우 완료 상태로 저장
        };
        
        let file_record = sqlx::query!(
            r#"
            INSERT INTO files (id, user_id, original_name, stored_name, file_path, file_size, mime_type, file_type, processing_status)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING id
            "#,
            file_id,
            user_id,
            original_name,
            filename,
            file_path,
            file_size as i64,
            mime_type,
            file_type as FileType,
            processing_status as ProcessingStatus
        )
        .fetch_one(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        let file_info = FileInfo {
            id: file_record.id,
            original_name: original_name.to_string(),
            file_path: url.clone(),
            file_size: file_size as i64,
            mime_type: mime_type.clone(),
            file_type,
            url: url.clone(),
        };
        
        // 이미지인 경우 백그라운드에서 썸네일 생성 (URL은 즉시 반환하지 않음)
        if is_image_file(&extension) {
            let state_clone = state.clone();
            let file_path_clone = file_path.clone();
            let file_id_clone = file_record.id;
            
            // 백그라운드 태스크로 썸네일 생성
            tokio::spawn(async move {
                eprintln!("🔄 백그라운드 썸네일 생성 시작: {}", file_path_clone);
                
                let thumbnail_service = ThumbnailService::new();
                match thumbnail_service.create_thumbnails(&file_path_clone).await {
                    Ok(_) => {
                        eprintln!("✅ 백그라운드 썸네일 생성 완료: {}", file_path_clone);
                        
                        // DB 상태를 완료로 업데이트
                        let _ = sqlx::query!(
                            r#"
                            UPDATE files 
                            SET processing_status = $1 
                            WHERE id = $2
                            "#,
                            ProcessingStatus::Completed as ProcessingStatus,
                            file_id_clone
                        )
                        .execute(&state_clone.pool)
                        .await;
                        
                        eprintln!("✅ 파일 처리 상태 업데이트 완료: {}", file_id_clone);
                    }
                    Err(e) => {
                        eprintln!("❌ 백그라운드 썸네일 생성 실패: {:?}", e);
                        
                        // 실패해도 파일은 유지하되 상태 업데이트
                        let _ = sqlx::query!(
                            r#"
                            UPDATE files 
                            SET processing_status = $1 
                            WHERE id = $2
                            "#,
                            ProcessingStatus::Failed as ProcessingStatus,
                            file_id_clone
                        )
                        .execute(&state_clone.pool)
                        .await;
                    }
                }
            });
        }
        
        eprintln!("📁 최종 파일 업로드 완료: {} ({} bytes)", url, file_size);
        Ok(Json(ApiResponse {
            success: true,
            message: "파일이 성공적으로 업로드되었습니다.".to_string(),
            data: Some(UploadResponse {
                filename: filename.to_string(),
                url: url.clone(),
                size: file_size,
                mime_type: mime_type.clone(),
                file_info,
                thumbnail_url: None, // 썸네일은 백그라운드에서 생성되므로 즉시 반환하지 않음
            }),
            pagination: None,
        }))
    } else {
        // 아직 모든 청크가 수신되지 않음
        eprintln!("📁 청크 {}/{} 완료, 다음 청크 대기 중...", chunk_index + 1, total_chunks);
        Ok(Json(ApiResponse {
            success: true,
            message: format!("청크 {}/{} 업로드 완료", chunk_index + 1, total_chunks),
            data: Some(UploadResponse {
                filename: String::new(),
                url: String::new(),
                size: 0,
                mime_type: String::new(),
                file_info: FileInfo {
                    id: Uuid::new_v4(),
                    original_name: String::new(),
                    file_path: String::new(),
                    file_size: 0,
                    mime_type: String::new(),
                    file_type: FileType::Image,
                    url: String::new(),
                },
                thumbnail_url: None,
            }),
            pagination: None,
        }))
    }
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

    while let Some(mut field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            eprintln!("📁 프로필 파일 업로드 시작: original_name={}", original_name);
            
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

            // 프로필 이미지만 허용
            if !is_image_file(&extension) {
                eprintln!("❌ 허용되지 않는 파일 타입: extension={}", extension);
                return Err(StatusCode::BAD_REQUEST);
            }
            
            eprintln!("✅ 프로필 파일 타입 검증 통과: extension={}", extension);

            // 파일 크기 제한 (10MB)
            const MAX_SIZE: u64 = 10 * 1024 * 1024;
            eprintln!("📁 프로필 파일 데이터 읽기 시작...");
            
            // 더 안전한 방법으로 파일 데이터 읽기
            let mut file_data = Vec::new();
            let mut chunk_count = 0;
            
            loop {
                match field.chunk().await {
                    Ok(Some(chunk)) => {
                        chunk_count += 1;
                        eprintln!("📁 프로필 청크 {} 읽기: {} bytes", chunk_count, chunk.len());
                        
                        // 누적 크기 확인
                        if file_data.len() + chunk.len() > MAX_SIZE as usize {
                            eprintln!("❌ 프로필 파일 크기 초과: {} bytes > {} bytes", file_data.len() + chunk.len(), MAX_SIZE);
                            return Err(StatusCode::PAYLOAD_TOO_LARGE);
                        }
                        
                        file_data.extend_from_slice(&chunk);
                    }
                    Ok(None) => {
                        eprintln!("📁 프로필 파일 데이터 읽기 완료: 총 {} 청크, {} bytes", chunk_count, file_data.len());
                        break;
                    }
                    Err(e) => {
                        eprintln!("❌ 프로필 파일 청크 읽기 실패: {:?}", e);
                        // 스트림 오류가 발생해도 일부 데이터가 있다면 계속 진행
                        if !file_data.is_empty() {
                            eprintln!("⚠️ 프로필 스트림 오류 발생했지만 {} bytes 데이터 수신됨, 계속 진행", file_data.len());
                            break;
                        } else {
                            return Err(StatusCode::BAD_REQUEST);
                        }
                    }
                }
            }
            
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

    while let Some(mut field) = multipart.next_field().await.map_err(|_| StatusCode::BAD_REQUEST)? {
        let field_name = field.name().unwrap_or("").to_string();
        
        if field_name == "file" {
            original_name = field.file_name().unwrap_or("unknown").to_string();
            eprintln!("📁 사이트 파일 업로드 시작: original_name={}", original_name);
            
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
            
            loop {
                match field.chunk().await {
                    Ok(Some(chunk)) => {
                        chunk_count += 1;
                        eprintln!("📁 사이트 청크 {} 읽기: {} bytes", chunk_count, chunk.len());
                        
                        // 누적 크기 확인
                        if file_data.len() + chunk.len() > MAX_SIZE as usize {
                            eprintln!("❌ 사이트 파일 크기 초과: {} bytes > {} bytes", file_data.len() + chunk.len(), MAX_SIZE);
                            return Err(StatusCode::PAYLOAD_TOO_LARGE);
                        }
                        
                        file_data.extend_from_slice(&chunk);
                    }
                    Ok(None) => {
                        eprintln!("📁 사이트 파일 데이터 읽기 완료: 총 {} 청크, {} bytes", chunk_count, file_data.len());
                        break;
                    }
                    Err(e) => {
                        eprintln!("❌ 사이트 파일 청크 읽기 실패: {:?}", e);
                        // 스트림 오류가 발생해도 일부 데이터가 있다면 계속 진행
                        if !file_data.is_empty() {
                            eprintln!("⚠️ 사이트 스트림 오류 발생했지만 {} bytes 데이터 수신됨, 계속 진행", file_data.len());
                            break;
                        } else {
                            return Err(StatusCode::BAD_REQUEST);
                        }
                    }
                }
            }
            
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

// 썸네일 상태 확인 엔드포인트
pub async fn check_thumbnail_status(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    AxumPath(file_id): AxumPath<Uuid>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    // 파일 정보 조회
    let file_record = sqlx::query!(
        r#"
        SELECT original_name, stored_name, file_path, mime_type
        FROM files 
        WHERE id = $1
        "#,
        file_id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    // 이미지가 아니면 썸네일 없음 (MIME 타입으로 확인)
    if !file_record.mime_type.starts_with("image/") {
        return Ok(Json(ApiResponse {
            success: true,
            message: "이미지 파일이 아닙니다.".to_string(),
            data: Some(serde_json::json!({
                "has_thumbnail": false,
                "thumbnail_url": null
            })),
            pagination: None,
        }));
    }

    // 썸네일이 생성되었는지 확인
    let thumbnail_service = ThumbnailService::new();
    let thumbnail_url = thumbnail_service.get_thumbnail_url(&file_record.file_path, "large");
    let thumbnail_path = thumbnail_service.build_thumbnail_path(&file_record.file_path, "large");
    let has_thumbnail = thumbnail_service.thumbnail_exists(&thumbnail_path);

    let thumbnail_url_value = if has_thumbnail { 
        serde_json::Value::String(thumbnail_url) 
    } else { 
        serde_json::Value::Null 
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "썸네일 상태 확인 완료".to_string(),
        data: Some(serde_json::json!({
            "has_thumbnail": has_thumbnail,
            "thumbnail_url": thumbnail_url_value
        })),
        pagination: None,
    }))
}

// 원본 파일 다운로드 엔드포인트
pub async fn download_original_file(
    State(state): State<AppState>,
    Extension(claims): Extension<Option<Claims>>,
    AxumPath(file_id): AxumPath<Uuid>,
) -> Result<axum::response::Response, StatusCode> {
    // 파일 정보 조회 (인증 없이도 접근 가능)
    let file_record = sqlx::query!(
        r#"
        SELECT original_name, stored_name, file_path, mime_type, user_id
        FROM files 
        WHERE id = $1
        "#,
        file_id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|_| StatusCode::NOT_FOUND)?;

    // 파일이 존재하는지 확인
    if !std::path::Path::new(&file_record.file_path).exists() {
        return Err(StatusCode::NOT_FOUND);
    }

    // 파일 내용 읽기
    let file_content = std::fs::read(&file_record.file_path)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 원본 파일명으로 다운로드되도록 헤더 설정
    let content_disposition = format!(
        "attachment; filename*=UTF-8''{}",
        urlencoding::encode(&file_record.original_name)
    );

    let response = axum::response::Response::builder()
        .status(200)
        .header("Content-Type", file_record.mime_type)
        .header("Content-Disposition", content_disposition)
        .header("Content-Length", file_content.len().to_string())
        .body(axum::body::Body::from(file_content))
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(response)
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
            // 공백과 탭은 언더스코어로 대체
            ' ' | '\t' => '_',
            // 한글과 특수문자는 영문/숫자로 변환하거나 제거
            c if c.is_ascii_control() => '_',
            // 그 외 문자는 그대로 유지 (한글 포함)
            _ => c,
        })
        .collect::<String>();
    
    // 연속된 언더스코어를 하나로 줄이기
    while safe_name.contains("__") {
        safe_name = safe_name.replace("__", "_");
    }
    
    // 앞뒤 언더스코어 제거
    safe_name = safe_name.trim_matches('_').to_string();
    
    // 빈 문자열이면 기본값 설정
    if safe_name.is_empty() {
        safe_name = "file".to_string();
    }
    
    // 파일명이 너무 길면 잘라내기 (확장자 제외하고 최대 50자)
    if let Some(dot_pos) = safe_name.rfind('.') {
        let (name_part, ext_part) = safe_name.split_at(dot_pos);
        if name_part.chars().count() > 50 {
            // UTF-8 문자 단위로 자르기
            let truncated_name: String = name_part.chars().take(50).collect();
            safe_name = format!("{}{}", truncated_name, ext_part);
        }
    } else if safe_name.chars().count() > 50 {
        // UTF-8 문자 단위로 자르기
        safe_name = safe_name.chars().take(50).collect();
    }
    
    safe_name
} 