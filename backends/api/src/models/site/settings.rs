use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};

// 사이트 기본 정보
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct SiteInfo {
    pub id: Uuid,
    pub site_name: String,
    pub site_description: Option<String>,
    pub site_keywords: Option<String>,
    pub site_author: Option<String>,
    pub site_url: Option<String>,
    pub site_logo: Option<String>,
    pub site_favicon: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub contact_fax: Option<String>,
    pub contact_address: Option<String>,
    pub business_number: Option<String>,
    pub social_facebook: Option<String>,
    pub social_twitter: Option<String>,
    pub social_instagram: Option<String>,
    pub social_youtube: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// SNS 링크
#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct SnsLink {
    pub id: Uuid,
    pub name: String,
    pub url: String,
    pub icon: String,
    pub icon_type: String, // 'svg' | 'emoji'
    pub display_order: i32,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// 사이트 설정 전체 응답
#[derive(Debug, Serialize, Deserialize)]
pub struct SiteSettings {
    pub site_info: SiteInfo,
    pub sns_links: Vec<SnsLink>,
}

// 사이트 정보 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdateSiteInfoRequest {
    pub site_name: Option<String>,
    pub site_description: Option<String>,
    pub site_keywords: Option<String>,
    pub site_author: Option<String>,
    pub site_url: Option<String>,
    pub site_logo: Option<String>,
    pub site_favicon: Option<String>,
    pub contact_email: Option<String>,
    pub contact_phone: Option<String>,
    pub contact_fax: Option<String>,
    pub contact_address: Option<String>,
    pub business_number: Option<String>,
    pub social_facebook: Option<String>,
    pub social_twitter: Option<String>,
    pub social_instagram: Option<String>,
    pub social_youtube: Option<String>,
}

// SNS 링크 생성 요청
#[derive(Debug, Deserialize)]
pub struct CreateSnsLinkRequest {
    pub name: String,
    pub url: String,
    pub icon: String,
    pub icon_type: String,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
}

// SNS 링크 수정 요청
#[derive(Debug, Deserialize)]
pub struct UpdateSnsLinkRequest {
    pub name: Option<String>,
    pub url: Option<String>,
    pub icon: Option<String>,
    pub icon_type: Option<String>,
    pub display_order: Option<i32>,
    pub is_active: Option<bool>,
}

// 사이트 설정 저장 요청
#[derive(Debug, Deserialize)]
pub struct SaveSiteSettingsRequest {
    pub siteInfo: UpdateSiteInfoRequest,
    pub snsLinks: Vec<CreateSnsLinkRequest>,
} 