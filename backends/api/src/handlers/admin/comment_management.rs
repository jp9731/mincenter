use axum::{
    extract::{Path, State, Extension},
    http::StatusCode,
    Json,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    errors::ApiError,
    models::{ApiResponse, site::community::Comment},
    utils::auth::Claims,
    AppState,
};

#[derive(Debug, Deserialize)]
pub struct CommentHideRequest {
    pub hide_category: String,      // 숨김 카테고리 ('광고', '음란물', '욕설비방', '기타 정책위반')
    pub hide_reason: Option<String>, // 상세 사유
    pub hide_tags: Option<Vec<String>>, // 태그 (사용하지 않지만 일관성을 위해 유지)
}

#[derive(Debug, Serialize)]
pub struct CommentHideResponse {
    pub comment_id: i32,
    pub hidden_by: Uuid,
    pub hide_reason: String,
    pub hidden_at: chrono::DateTime<chrono::Utc>,
}

/// 댓글 숨김 (관리자 전용)
pub async fn hide_comment(
    Path(comment_id): Path<i32>,
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>, // 관리자 권한은 미들웨어에서 체크됨
    Json(payload): Json<CommentHideRequest>,
) -> Result<Json<ApiResponse<CommentHideResponse>>, ApiError> {
    println!("🔒 댓글 숨김 요청: comment_id={}, admin_id={}", comment_id, claims.sub);

    // 댓글 존재 확인
    let comment = sqlx::query_as::<_, Comment>(
        "SELECT * FROM comments WHERE id = $1 AND is_deleted = false"
    )
    .bind(comment_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        println!("❌ 댓글 조회 실패: {:?}", e);
        e
    })
    .map_err(ApiError::from)?;
    
    let comment = match comment {
        Some(c) => c,
        None => {
            println!("❌ 댓글을 찾을 수 없음: comment_id={}", comment_id);
            return Err(ApiError::NotFound("댓글을 찾을 수 없습니다.".to_string()));
        }
    };

    println!("✅ 댓글 확인: content={}", &comment.content[..comment.content.len().min(50)]);

    // 숨김 사유 생성 (카테고리 + 상세 사유)
    let full_reason = match payload.hide_reason.as_ref() {
        Some(reason) if !reason.trim().is_empty() => {
            format!("[{}] {}", payload.hide_category, reason.trim())
        }
        _ => format!("[{}]", payload.hide_category)
    };

    // 댓글 숨김 이력 기록 (comment_hide_history 테이블 사용)
    let hide_record = sqlx::query!(
        r#"
        INSERT INTO comment_hide_history (
            comment_id, 
            hide_reason, 
            hide_category, 
            hide_tags, 
            hidden_by, 
            hide_location,
            is_hidden
        ) VALUES ($1, $2, $3, $4, $5, $6, $7) 
        RETURNING id, hidden_at
        "#,
        comment_id,
        payload.hide_reason.as_deref(),
        payload.hide_category,
        payload.hide_tags.as_deref().unwrap_or(&Vec::new()) as &[String],
        claims.sub,
        "admin",
        true
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        println!("❌ 댓글 숨김 이력 저장 실패: {:?}", e);
        e
    })
    .map_err(ApiError::from)?;

    // 댓글을 삭제 상태로 변경 (소프트 삭제)
    sqlx::query("UPDATE comments SET is_deleted = true, updated_at = NOW() WHERE id = $1")
        .bind(comment_id)
        .execute(&state.pool)
        .await
        .map_err(|e| {
            println!("❌ 댓글 삭제 상태 변경 실패: {:?}", e);
            e
        })
        .map_err(ApiError::from)?;

    println!("✅ 댓글 숨김 완료: comment_id={}", comment_id);

    let response = CommentHideResponse {
        comment_id,
        hidden_by: claims.sub,
        hide_reason: full_reason,
        hidden_at: hide_record.hidden_at.unwrap(),
    };

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글이 성공적으로 숨겨졌습니다.".to_string(),
        data: Some(response),
        pagination: None,
    }))
}

/// 댓글 숨김 해제 (관리자 전용)
pub async fn unhide_comment(
    Path(comment_id): Path<i32>,
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>, // 관리자 권한은 미들웨어에서 체크됨
) -> Result<Json<ApiResponse<()>>, ApiError> {
    println!("🔓 댓글 숨김 해제 요청: comment_id={}, admin_id={}", comment_id, claims.sub);

    // 댓글 존재 확인 (숨겨진 댓글 포함)
    let comment = sqlx::query_as::<_, Comment>(
        "SELECT * FROM comments WHERE id = $1"
    )
    .bind(comment_id)
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        println!("❌ 댓글 조회 실패: {:?}", e);
        e
    })
    .map_err(ApiError::from)?;
    
    let comment = match comment {
        Some(c) => c,
        None => {
            println!("❌ 댓글을 찾을 수 없음: comment_id={}", comment_id);
            return Err(ApiError::NotFound("댓글을 찾을 수 없습니다.".to_string()));
        }
    };

    // 댓글 숨김 해제 이력 기록
    sqlx::query!(
        r#"
        INSERT INTO comment_hide_history (
            comment_id, 
            hide_reason, 
            hide_category, 
            hidden_by, 
            hide_location,
            is_hidden
        ) VALUES ($1, $2, $3, $4, $5, $6) 
        "#,
        comment_id,
        "관리자에 의한 숨김 해제",
        "해제",
        claims.sub,
        "admin",
        false
    )
    .execute(&state.pool)
    .await
    .map_err(|e| {
        println!("❌ 댓글 숨김 해제 이력 저장 실패: {:?}", e);
        e
    })
    .map_err(ApiError::from)?;

    // 댓글 숨김 해제 (소프트 삭제 해제)
    sqlx::query("UPDATE comments SET is_deleted = false, updated_at = NOW() WHERE id = $1")
        .bind(comment_id)
        .execute(&state.pool)
        .await
        .map_err(|e| {
            println!("❌ 댓글 숨김 해제 실패: {:?}", e);
            e
        })
        .map_err(ApiError::from)?;

    println!("✅ 댓글 숨김 해제 완료: comment_id={}", comment_id);

    Ok(Json(ApiResponse {
        success: true,
        message: "댓글 숨김이 해제되었습니다.".to_string(),
        data: Some(()),
        pagination: None,
    }))
}
