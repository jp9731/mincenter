use axum::{extract::{Path, State, Json, Extension}, http::StatusCode, response::IntoResponse};
use crate::{AppState, models::calendar::CalendarEvent, models::response::ApiResponse, errors::ApiError, utils::auth::Claims};
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDateTime};
use serde::{Deserialize, Serialize};

#[derive(serde::Deserialize)]
pub struct CalendarEventRequest {
    pub title: String,
    pub description: Option<String>,
    pub start_at: String, // ISO 8601 문자열로 받음
    pub end_at: Option<String>, // ISO 8601 문자열로 받음
    pub all_day: Option<bool>,
    pub color: Option<String>,
    pub is_public: Option<bool>, // 공개 여부
}

// 일정 목록 조회 (기간 필터는 추후 추가)
pub async fn get_events(State(state): State<AppState>) -> Result<Json<ApiResponse<Vec<CalendarEvent>>>, StatusCode> {
    let events = sqlx::query_as::<_, CalendarEvent>(
        "SELECT ce.id, ce.title, ce.description, ce.start_at, ce.end_at, ce.all_day, ce.color, ce.user_id, ce.is_public, ce.created_at, ce.updated_at, u.name as user_name 
         FROM calendar_events ce 
         LEFT JOIN users u ON ce.user_id = u.id 
         ORDER BY ce.start_at DESC"
    )
        .fetch_all(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Database error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    Ok(Json(ApiResponse::success(events, "일정 목록")))
}

// 공개 일정 목록 조회 (사이트용)
pub async fn get_public_events(State(state): State<AppState>) -> Result<Json<ApiResponse<Vec<CalendarEvent>>>, StatusCode> {
    let events = sqlx::query_as::<_, CalendarEvent>(
        "SELECT ce.id, ce.title, ce.description, ce.start_at, ce.end_at, ce.all_day, ce.color, ce.user_id, ce.is_public, ce.created_at, ce.updated_at, u.name as user_name 
         FROM calendar_events ce 
         LEFT JOIN users u ON ce.user_id = u.id 
         WHERE ce.is_public = TRUE
         ORDER BY ce.start_at DESC"
    )
        .fetch_all(&state.pool)
        .await
        .map_err(|e| {
            eprintln!("Database error: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
    Ok(Json(ApiResponse::success(events, "공개 일정 목록")))
}

// 일정 추가
pub async fn create_event(
    State(state): State<AppState>, 
    Extension(claims): Extension<Claims>,
    Json(data): Json<CalendarEventRequest>
) -> Result<Json<ApiResponse<CalendarEvent>>, StatusCode> {
    // 날짜 파싱
    let start_at = DateTime::parse_from_rfc3339(&data.start_at)
        .map_err(|_| StatusCode::BAD_REQUEST)?
        .with_timezone(&Utc);
    
    let end_at = if let Some(end_str) = data.end_at {
        Some(DateTime::parse_from_rfc3339(&end_str)
            .map_err(|_| StatusCode::BAD_REQUEST)?
            .with_timezone(&Utc))
    } else {
        None
    };

    let event = sqlx::query_as::<_, CalendarEvent>(
        "INSERT INTO calendar_events (title, description, start_at, end_at, all_day, color, user_id, is_public, created_at, updated_at) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW(), NOW()) 
         RETURNING id, title, description, start_at, end_at, all_day, color, user_id, is_public, created_at, updated_at, NULL as user_name"
    )
    .bind(&data.title)
    .bind(&data.description)
    .bind(start_at)
    .bind(end_at)
    .bind(data.all_day.unwrap_or(false))
    .bind(&data.color)
    .bind(claims.sub)
    .bind(data.is_public.unwrap_or(true))
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Database error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    Ok(Json(ApiResponse::success(event, "일정 추가 완료")))
}

// 일정 수정
pub async fn update_event(
    State(state): State<AppState>, 
    Path(id): Path<Uuid>, 
    Json(data): Json<CalendarEventRequest>
) -> Result<Json<ApiResponse<CalendarEvent>>, StatusCode> {
    // 날짜 파싱
    let start_at = DateTime::parse_from_rfc3339(&data.start_at)
        .map_err(|_| StatusCode::BAD_REQUEST)?
        .with_timezone(&Utc);
    
    let end_at = if let Some(end_str) = data.end_at {
        Some(DateTime::parse_from_rfc3339(&end_str)
            .map_err(|_| StatusCode::BAD_REQUEST)?
            .with_timezone(&Utc))
    } else {
        None
    };

    let event = sqlx::query_as::<_, CalendarEvent>(
        "UPDATE calendar_events SET title=$1, description=$2, start_at=$3, end_at=$4, all_day=$5, color=$6, is_public=$7, updated_at=NOW() 
         WHERE id=$8 
         RETURNING id, title, description, start_at, end_at, all_day, color, user_id, is_public, created_at, updated_at, NULL as user_name"
    )
    .bind(&data.title)
    .bind(&data.description)
    .bind(start_at)
    .bind(end_at)
    .bind(data.all_day.unwrap_or(false))
    .bind(&data.color)
    .bind(data.is_public.unwrap_or(true))
    .bind(id)
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        eprintln!("Database error: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;
    Ok(Json(ApiResponse::success(event, "일정 수정 완료")))
}

// 일정 삭제
pub async fn delete_event(State(state): State<AppState>, Path(id): Path<Uuid>) -> Result<Json<ApiResponse<()>>, StatusCode> {
    let _ = sqlx::query("DELETE FROM calendar_events WHERE id = $1")
        .bind(id)
        .execute(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(Json(ApiResponse::success((), "일정 삭제 완료")))
} 