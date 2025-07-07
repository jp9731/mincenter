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
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // 기본 사이트 정보가 없으면 생성
    let site_info = if let Some(info) = site_info {
        info
    } else {
        let default_info = sqlx::query_as::<_, SiteInfo>(
            r#"
            INSERT INTO site_info (site_name, catchphrase, address, phone, email, homepage, fax, representative_name, business_number, logo_image_url)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *
            "#
        )
        .bind("민센터 봉사단체")
        .bind("함께 만들어가는 따뜻한 세상")
        .bind("서울특별시 강남구 테헤란로 123")
        .bind("02-1234-5678")
        .bind("info@mincenter.org")
        .bind("https://example.com")
        .bind("")
        .bind("")
        .bind("")
        .bind("")
        .fetch_one(&state.pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        default_info
    };

    // SNS 링크 조회
    let sns_links = sqlx::query_as::<_, SnsLink>(
        "SELECT * FROM sns_links WHERE is_active = true ORDER BY display_order, created_at"
    )
    .fetch_all(&state.pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

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
            catchphrase = $2,
            address = $3,
            phone = $4,
            email = $5,
            homepage = $6,
            fax = $7,
            representative_name = $8,
            business_number = $9,
            logo_image_url = $10,
            updated_at = NOW()
        WHERE id = (SELECT id FROM site_info ORDER BY created_at DESC LIMIT 1)
        RETURNING *
        "#
    )
    .bind(&payload.siteInfo.site_name)
    .bind(&payload.siteInfo.catchphrase)
    .bind(&payload.siteInfo.address)
    .bind(&payload.siteInfo.phone)
    .bind(&payload.siteInfo.email)
    .bind(&payload.siteInfo.homepage)
    .bind(&payload.siteInfo.fax)
    .bind(&payload.siteInfo.representative_name)
    .bind(&payload.siteInfo.business_number)
    .bind(&payload.siteInfo.logo_image_url)
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