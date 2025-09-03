use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use uuid::Uuid;
use crate::{
    AppState,
    models::response::ApiResponse,
    utils::url_helpers::{create_short_id, parse_short_id},
};

/// 압축된 ID로 게시판 조회
pub async fn get_board_by_short_id(
    State(state): State<AppState>,
    Path(short_id): Path<String>,
) -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    // 압축된 ID를 UUID로 변환
    let board_id = match parse_short_id(&short_id) {
        Ok(uuid) => uuid,
        Err(_) => {
            return Err(StatusCode::BAD_REQUEST);
        }
    };

    // 실제 게시판 조회 로직 (예시)
    let board = sqlx::query!(
        "SELECT id, name, description FROM boards WHERE id = $1",
        board_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    match board {
        Some(board) => {
            let response = serde_json::json!({
                "id": board.id,
                "short_id": create_short_id(&board.id), // 압축된 ID도 함께 반환
                "name": board.name,
                "description": board.description
            });
            
            Ok(Json(ApiResponse::success(response, "게시판 조회 성공")))
        }
        None => Err(StatusCode::NOT_FOUND),
    }
}

/// 게시판 목록 조회 (압축된 ID 포함)
pub async fn get_boards_with_short_ids(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<Vec<serde_json::Value>>>, StatusCode> {
    let boards = sqlx::query!(
        "SELECT id, name, description FROM boards ORDER BY created_at DESC LIMIT 10"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let boards_with_short_ids: Vec<serde_json::Value> = boards
        .into_iter()
        .map(|board| {
            serde_json::json!({
                "id": board.id,
                "short_id": create_short_id(&board.id),
                "name": board.name,
                "description": board.description
            })
        })
        .collect();

    Ok(Json(ApiResponse::success(boards_with_short_ids, "게시판 목록 조회 성공")))
}

/// URL 압축 예시
pub async fn compress_url_example() -> Result<Json<ApiResponse<serde_json::Value>>, StatusCode> {
    let uuid = Uuid::new_v4();
    let original_url = format!("/api/boards/{}/posts/{}", uuid, uuid);
    
    let compressed_url = crate::utils::url_helpers::compress_url_path(&original_url);
    let decompressed_url = crate::utils::url_helpers::decompress_url_path(&compressed_url);
    
    let response = serde_json::json!({
        "original_url": original_url,
        "compressed_url": compressed_url,
        "decompressed_url": decompressed_url,
        "compression_ratio": format!("{:.1}%", 
            (1.0 - compressed_url.len() as f64 / original_url.len() as f64) * 100.0)
    });
    
    Ok(Json(ApiResponse::success(response, "URL 압축 예시")))
}
