use axum::{
    extract::State,
    http::StatusCode,
    Json,
};
use crate::{
    models::response::ApiResponse,
    models::site::settings::{
        SiteInfo, SnsLink, SiteSettings, UpdateSiteInfoRequest, 
        CreateSnsLinkRequest, SaveSiteSettingsRequest
    },
    AppState,
};
use uuid::Uuid;
use chrono::Utc;

// 사이트 설정 조회
pub async fn get_site_settings(
    State(state): State<AppState>,
) -> Result<Json<ApiResponse<SiteSettings>>, StatusCode> {
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
            INSERT INTO site_info (site_name)
            VALUES ($1)
            RETURNING *
            "#
        )
        .bind("민센터 봉사단체")
        .fetch_one(&state.pool)
        .await
        .map_err(|e| {
            tracing::error!("기본 사이트 정보 생성 실패: {}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;
        
        default_info
    };

    // SNS 링크 조회
    let sns_links = sqlx::query_as::<_, SnsLink>(
        "SELECT * FROM sns_links WHERE is_active = true ORDER BY display_order, created_at"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("SNS 링크 조회 실패: {}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let settings = SiteSettings {
        site_info,
        sns_links,
    };

    Ok(Json(ApiResponse::success(settings, "사이트 설정을 성공적으로 조회했습니다.")))
}

// 사이트 설정 저장
pub async fn save_site_settings(
    State(state): State<AppState>,
    Json(payload): Json<SaveSiteSettingsRequest>,
) -> Result<Json<ApiResponse<SiteSettings>>, StatusCode> {
    // 트랜잭션 시작
    let mut tx = state.pool.begin().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 사이트 정보 업데이트
    let site_info = sqlx::query_as::<_, SiteInfo>(
        r#"
        UPDATE site_info SET
            site_name = COALESCE($1, site_name),
            site_description = COALESCE($2, site_description),
            site_keywords = COALESCE($3, site_keywords),
            site_author = COALESCE($4, site_author),
            site_url = COALESCE($5, site_url),
            site_logo = COALESCE($6, site_logo),
            site_favicon = COALESCE($7, site_favicon),
            contact_email = COALESCE($8, contact_email),
            contact_phone = COALESCE($9, contact_phone),
            contact_fax = COALESCE($10, contact_fax),
            contact_address = COALESCE($11, contact_address),
            business_number = COALESCE($12, business_number),
            social_facebook = COALESCE($13, social_facebook),
            social_twitter = COALESCE($14, social_twitter),
            social_instagram = COALESCE($15, social_instagram),
            social_youtube = COALESCE($16, social_youtube),
            updated_at = NOW()
        WHERE id = (SELECT id FROM site_info ORDER BY created_at DESC LIMIT 1)
        RETURNING *
        "#
    )
    .bind(&payload.siteInfo.site_name)
    .bind(&payload.siteInfo.site_description)
    .bind(&payload.siteInfo.site_keywords)
    .bind(&payload.siteInfo.site_author)
    .bind(&payload.siteInfo.site_url)
    .bind(&payload.siteInfo.site_logo)
    .bind(&payload.siteInfo.site_favicon)
    .bind(&payload.siteInfo.contact_email)
    .bind(&payload.siteInfo.contact_phone)
    .bind(&payload.siteInfo.contact_fax)
    .bind(&payload.siteInfo.contact_address)
    .bind(&payload.siteInfo.business_number)
    .bind(&payload.siteInfo.social_facebook)
    .bind(&payload.siteInfo.social_twitter)
    .bind(&payload.siteInfo.social_instagram)
    .bind(&payload.siteInfo.social_youtube)
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 기존 SNS 링크 비활성화
    sqlx::query("UPDATE sns_links SET is_active = false")
        .execute(&mut *tx)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 새로운 SNS 링크 저장
    let mut sns_links = Vec::new();
    for (index, link) in payload.snsLinks.iter().enumerate() {
        let sns_link = sqlx::query_as::<_, SnsLink>(
            r#"
            INSERT INTO sns_links (name, url, icon, icon_type, display_order, is_active)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
            "#
        )
        .bind(&link.name)
        .bind(&link.url)
        .bind(&link.icon)
        .bind(&link.icon_type)
        .bind(link.display_order.unwrap_or((index + 1) as i32))
        .bind(link.is_active.unwrap_or(true))
        .fetch_one(&mut *tx)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        sns_links.push(sns_link);
    }

    // 트랜잭션 커밋
    tx.commit().await.map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let settings = SiteSettings {
        site_info,
        sns_links,
    };

    Ok(Json(ApiResponse::success(settings, "사이트 설정이 성공적으로 저장되었습니다.")))
} 