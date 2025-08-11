use uuid::Uuid;
use std::collections::HashMap;
use base64::{engine::general_purpose, Engine as _};
use sha2::{Sha256, Digest};
use sqlx::PgPool;
use crate::errors::ApiError;

/// URL ID 생성을 위한 유틸리티
/// 
/// URL ID 형태: {순차번호}-{6자리해시}
/// 예: 1234-a1b2c3 (1234번째 게시글, 해시 a1b2c3)
pub struct UrlIdGenerator {
    pool: PgPool,
}

impl UrlIdGenerator {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// UUID로부터 URL ID 생성
    pub async fn generate_url_id(&self, table: &str, uuid: &Uuid) -> Result<String, ApiError> {
        // 1. 해당 테이블에서 순차 번호 가져오기
        let sequence_num = self.get_or_create_sequence_number(table, uuid).await?;
        
        // 2. UUID에서 짧은 해시 생성 (6자리)
        let hash = self.generate_short_hash(uuid);
        
        // 3. 순차번호-해시 형태로 결합
        Ok(format!("{}-{}", sequence_num, hash))
    }

    /// URL ID에서 UUID 복원
    pub async fn resolve_uuid(&self, table: &str, url_id: &str) -> Result<Uuid, ApiError> {
        // URL ID 파싱 (숫자-해시 형태)
        let parts: Vec<&str> = url_id.split('-').collect();
        if parts.len() != 2 {
            return Err(ApiError::BadRequest("잘못된 URL ID 형식".to_string()));
        }

        let sequence_num: i32 = parts[0].parse()
            .map_err(|_| ApiError::BadRequest("잘못된 순차번호".to_string()))?;
        let hash = parts[1];

        // 데이터베이스에서 UUID 조회
        self.get_uuid_by_sequence_and_hash(table, sequence_num, hash).await
    }

    /// UUID에서 6자리 해시 생성
    fn generate_short_hash(&self, uuid: &Uuid) -> String {
        let mut hasher = Sha256::new();
        hasher.update(uuid.as_bytes());
        let result = hasher.finalize();
        
        // Base64 인코딩 후 앞 6자리만 사용 (URL 안전 문자)
        let base64 = general_purpose::URL_SAFE_NO_PAD.encode(&result[..4]);
        base64.chars().take(6).collect()
    }

    /// 순차 번호 가져오기 또는 생성
    async fn get_or_create_sequence_number(&self, table: &str, uuid: &Uuid) -> Result<i32, ApiError> {
        let url_id_table = format!("{}_url_ids", table);
        
        // 이미 존재하는지 확인
        let query_str = format!("SELECT sequence_num FROM {} WHERE uuid = $1", url_id_table);
        let existing = sqlx::query_scalar::<_, i32>(&query_str)
            .bind(uuid)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| {
                println!("❌ 기존 URL ID 조회 실패: {}", e);
                ApiError::Database(e)
            })?;

        if let Some(sequence_num) = existing {
            return Ok(sequence_num);
        }

        // 새로운 순차 번호 생성 (가장 큰 번호 + 1)
        let next_num_query = format!("SELECT COALESCE(MAX(sequence_num), 0) + 1 as next_num FROM {}", url_id_table);
        let next_num = sqlx::query_scalar::<_, i32>(&next_num_query)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| {
                println!("❌ 다음 순차번호 조회 실패: {}", e);
                ApiError::Database(e)
            })?;

        // URL ID 매핑 테이블에 저장
        let hash = self.generate_short_hash(uuid);
        let insert_query = format!("INSERT INTO {} (uuid, sequence_num, hash) VALUES ($1, $2, $3)", url_id_table);
        sqlx::query(&insert_query)
            .bind(uuid)
            .bind(next_num)
            .bind(&hash)
            .execute(&self.pool)
            .await
            .map_err(|e| {
                println!("❌ URL ID 저장 실패: {}", e);
                ApiError::Database(e)
            })?;

        println!("✅ 새 URL ID 생성: {} -> {}-{}", uuid, next_num, hash);
        Ok(next_num)
    }

    /// 순차번호와 해시로 UUID 조회
    async fn get_uuid_by_sequence_and_hash(&self, table: &str, sequence_num: i32, hash: &str) -> Result<Uuid, ApiError> {
        let url_id_table = format!("{}_url_ids", table);
        
        let query_str = format!("SELECT uuid FROM {} WHERE sequence_num = $1 AND hash = $2", url_id_table);
        let uuid = sqlx::query_scalar::<_, Uuid>(&query_str)
            .bind(sequence_num)
            .bind(hash)
            .fetch_optional(&self.pool)
            .await
            .map_err(|e| {
                println!("❌ UUID 조회 실패: {}", e);
                ApiError::Database(e)
            })?;

        match uuid {
            Some(uuid) => {
                println!("✅ URL ID 해석 성공: {}-{} -> {}", sequence_num, hash, uuid);
                Ok(uuid)
            },
            None => {
                println!("❌ URL ID를 찾을 수 없음: {}-{}", sequence_num, hash);
                Err(ApiError::NotFound("해당 URL ID를 찾을 수 없습니다.".to_string()))
            }
        }
    }
}

/// 편의 함수들
pub async fn generate_post_url_id(pool: &PgPool, uuid: &Uuid) -> Result<String, ApiError> {
    let generator = UrlIdGenerator::new(pool.clone());
    generator.generate_url_id("posts", uuid).await
}

pub async fn resolve_post_uuid(pool: &PgPool, url_id: &str) -> Result<Uuid, ApiError> {
    let generator = UrlIdGenerator::new(pool.clone());
    generator.resolve_uuid("posts", url_id).await
}

pub async fn generate_comment_url_id(pool: &PgPool, uuid: &Uuid) -> Result<String, ApiError> {
    let generator = UrlIdGenerator::new(pool.clone());
    generator.generate_url_id("comments", uuid).await
}

pub async fn resolve_comment_uuid(pool: &PgPool, url_id: &str) -> Result<Uuid, ApiError> {
    let generator = UrlIdGenerator::new(pool.clone());
    generator.resolve_uuid("comments", url_id).await
}

pub async fn generate_user_url_id(pool: &PgPool, uuid: &Uuid) -> Result<String, ApiError> {
    let generator = UrlIdGenerator::new(pool.clone());
    generator.generate_url_id("users", uuid).await
}

pub async fn resolve_user_uuid(pool: &PgPool, url_id: &str) -> Result<Uuid, ApiError> {
    let generator = UrlIdGenerator::new(pool.clone());
    generator.resolve_uuid("users", url_id).await
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_url_id_format() {
        let url_id = "1234-a1b2c3";
        let parts: Vec<&str> = url_id.split('-').collect();
        
        assert_eq!(parts.len(), 2);
        assert_eq!(parts[0], "1234");
        assert_eq!(parts[1], "a1b2c3");
    }
}
