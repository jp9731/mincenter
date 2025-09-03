use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use crate::{
    models::response::ApiResponse,
    models::site::settings::SiteInfo,
    AppState,
};

// 사이트 정보 조회 (공개)
pub async fn get_site_info(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<SiteInfo>>, StatusCode> {
    // 사이트 정보 조회
    let site_info = sqlx::query_as::<_, SiteInfo>(
        "SELECT * FROM site_info ORDER BY created_at DESC LIMIT 1"
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("사이트 정보 조회 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    // 기본 사이트 정보가 없으면 생성
    let site_info = if let Some(info) = site_info {
        info
    } else {
        let default_info = sqlx::query_as::<_, SiteInfo>(
            r#"
            INSERT INTO site_info (
                site_name, site_description, site_keywords, site_author, 
                site_url, site_logo, site_favicon, contact_email, 
                contact_phone, contact_fax, contact_address, business_number,
                social_facebook, social_twitter, social_instagram, social_youtube
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
            RETURNING *
            "#
        )
        .bind("민들레장애인자립생활센터")
        .bind("함께 만들어가는 따뜻한 세상")
        .bind("장애인자립생활센터, 민들레, 봉사, 복지")
        .bind("박길연")
        .bind("https://mincenter.org")
        .bind("")
        .bind("")
        .bind("mincenter08@daum.net")
        .bind("032-542-9294")
        .bind("032-232-0739")
        .bind("인천광역시 계양구 계산새로71 A동 201~202호 (계산동, 하이베라스)")
        .bind("131-80-12554")
        .bind("")
        .bind("")
        .bind("https://www.instagram.com/mincenter08?igsh=bTZyM2Qxa2t4ajJv")
        .bind("")
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            tracing::error!("기본 사이트 정보 생성 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
        
        default_info
    };

    Ok(Json(ApiResponse::success(site_info, "사이트 정보를 성공적으로 조회했습니다.")))
}
