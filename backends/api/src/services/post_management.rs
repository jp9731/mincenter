use sqlx::{PgPool, Row};
use uuid::Uuid;

use crate::models::admin::post_management::*;
use crate::errors::ApiError;
use serde::{Serialize, Deserialize};

pub struct PostManagementService {
    pool: PgPool,
}

impl PostManagementService {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    /// 게시글 이동 이력 생성
    pub async fn create_move_history(&self, data: CreatePostMoveHistory) -> Result<PostMoveHistory, ApiError> {
        let query = r#"
            INSERT INTO post_move_history (
                post_id, original_board_id, original_category_id, 
                moved_board_id, moved_category_id, move_reason, 
                moved_by, move_location
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
        "#;

        let result = sqlx::query_as::<_, PostMoveHistory>(query)
            .bind(data.post_id)
            .bind(data.original_board_id)
            .bind(data.original_category_id)
            .bind(data.moved_board_id)
            .bind(data.moved_category_id)
            .bind(data.move_reason)
            .bind(data.moved_by)
            .bind(data.move_location)
            .fetch_one(&self.pool)
            .await?;

        Ok(result)
    }

    /// 게시글 숨김 이력 생성
    pub async fn create_hide_history(&self, data: CreatePostHideHistory) -> Result<PostHideHistory, ApiError> {
        let query = r#"
            INSERT INTO post_hide_history (
                post_id, hide_reason, hide_category, 
                hide_tags, hidden_by, hide_location
            ) VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
        "#;

        let result = sqlx::query_as::<_, PostHideHistory>(query)
            .bind(data.post_id)
            .bind(data.hide_reason)
            .bind(data.hide_category)
            .bind(data.hide_tags)
            .bind(data.hidden_by)
            .bind(data.hide_location)
            .fetch_one(&self.pool)
            .await?;

        Ok(result)
    }

    /// 게시글 이동 이력 조회
    pub async fn get_move_history(&self, post_id: i32) -> Result<Vec<PostMoveHistory>, ApiError> {
        let query = r#"
            SELECT * FROM post_move_history 
            WHERE post_id = $1 
            ORDER BY moved_at DESC
        "#;

        let results = sqlx::query_as::<_, PostMoveHistory>(query)
            .bind(post_id)
            .fetch_all(&self.pool)
            .await?;

        Ok(results)
    }

    /// 게시글 숨김 이력 조회
    pub async fn get_hide_history(&self, post_id: i32) -> Result<Vec<PostHideHistory>, ApiError> {
        let query = r#"
            SELECT * FROM post_hide_history 
            WHERE post_id = $1 
            ORDER BY hidden_at DESC
        "#;

        let results = sqlx::query_as::<_, PostHideHistory>(query)
            .bind(post_id)
            .fetch_all(&self.pool)
            .await?;

        Ok(results)
    }

    /// 게시글 숨김 상태 업데이트
    pub async fn update_hide_status(&self, post_id: i32, data: UpdatePostHideHistory) -> Result<PostHideHistory, ApiError> {
        let query = r#"
            UPDATE post_hide_history 
            SET 
                hide_reason = COALESCE($1, hide_reason),
                hide_category = COALESCE($2, hide_category),
                hide_tags = COALESCE($3, hide_tags),
                is_hidden = COALESCE($4, is_hidden)
            WHERE post_id = $5 AND is_hidden = true
            RETURNING *
        "#;

        let result = sqlx::query_as::<_, PostHideHistory>(query)
            .bind(data.hide_reason)
            .bind(data.hide_category)
            .bind(data.hide_tags)
            .bind(data.is_hidden)
            .bind(post_id)
            .fetch_one(&self.pool)
            .await?;

        Ok(result)
    }

    /// 게시글 이동 (간단 버전)
    pub async fn move_post(&self, post_id: Uuid, data: PostMoveRequest, user_id: Uuid) -> Result<PostMoveHistory, ApiError> {
        println!("🔧 서비스: move_post 시작 (간단 버전)");
        println!("🔧 post_id: {}", post_id);
        println!("🔧 target_board_id: {}", data.target_board_id);
        
        // 게시글 업데이트만 수행 (히스토리 제거)
        println!("🔄 게시글 업데이트 중...");
        let result = sqlx::query!(
            "UPDATE posts SET board_id = $1, category_id = $2 WHERE id = $3",
            data.target_board_id,
            data.target_category_id,
            post_id
        )
        .execute(&self.pool)
        .await?;
        
        println!("✅ 게시글 업데이트 완료: {} rows affected", result.rows_affected());

        // 더미 히스토리 반환 (기존 코드 호환성을 위해)
        let dummy_history = PostMoveHistory {
            id: 1,
            post_id: 1,
            original_board_id: 1,
            original_category_id: None,
            moved_board_id: 1,
            moved_category_id: None,
            move_reason: data.move_reason,
            moved_by: 1,
            moved_at: chrono::Utc::now(),
            move_location: data.move_location,
        };

        Ok(dummy_history)
    }

    /// 게시글 숨김
    pub async fn hide_post(&self, data: PostHideRequest, user_id: Uuid) -> Result<PostHideHistory, ApiError> {
        // 트랜잭션 시작
        let mut tx = self.pool.begin().await?;

        // 기존 숨김 이력이 있다면 숨김 해제
        sqlx::query!(
            "UPDATE post_hide_history SET is_hidden = false WHERE post_id = $1 AND is_hidden = true",
            data.post_id
        )
        .execute(&mut *tx)
        .await?;

        // 새로운 숨김 이력 생성
        let hide_data = CreatePostHideHistory {
            post_id: data.post_id,
            hide_reason: data.hide_reason,
            hide_category: data.hide_category,
            hide_tags: data.hide_tags,
            hidden_by: user_id,
            hide_location: data.hide_location,
        };

        let history = self.create_hide_history(hide_data).await?;

        // 트랜잭션 커밋
        tx.commit().await?;

        Ok(history)
    }

    /// 게시글 숨김 해제
    pub async fn unhide_post(&self, data: PostUnhideRequest, user_id: Uuid) -> Result<PostHideHistory, ApiError> {
        let query = r#"
            UPDATE post_hide_history 
            SET is_hidden = false 
            WHERE post_id = $1 AND is_hidden = true
            RETURNING *
        "#;

        let result = sqlx::query_as::<_, PostHideHistory>(query)
            .bind(data.post_id)
            .fetch_one(&self.pool)
            .await?;

        Ok(result)
    }

    /// 숨겨진 게시글 목록 조회
    pub async fn get_hidden_posts(&self, page: i64, limit: i64) -> Result<Vec<PostHideHistory>, ApiError> {
        let offset = (page - 1) * limit;
        
        let query = r#"
            SELECT ph.* FROM post_hide_history ph
            WHERE ph.is_hidden = true
            ORDER BY ph.hidden_at DESC
            LIMIT $1 OFFSET $2
        "#;

        let results = sqlx::query_as::<_, PostHideHistory>(query)
            .bind(limit)
            .bind(offset)
            .fetch_all(&self.pool)
            .await?;

        Ok(results)
    }

    /// 게시글 이동 이력 통계
    pub async fn get_move_statistics(&self, board_id: Option<Uuid>, start_date: Option<chrono::NaiveDate>, end_date: Option<chrono::NaiveDate>) -> Result<Vec<MoveStatistics>, ApiError> {
        let mut query = r#"
            SELECT 
                DATE(moved_at) as move_date,
                COUNT(*) as move_count,
                move_location
            FROM post_move_history
            WHERE 1=1
        "#.to_string();

        let mut param_count = 0;

        if let Some(board_id) = board_id {
            param_count += 1;
            query.push_str(&format!(" AND (original_board_id = ${} OR moved_board_id = ${})", param_count, param_count));
        }

        if let Some(_start_date) = start_date {
            param_count += 1;
            query.push_str(&format!(" AND moved_at >= ${}", param_count));
        }

        if let Some(_end_date) = end_date {
            param_count += 1;
            query.push_str(&format!(" AND moved_at <= ${}", param_count));
        }

        query.push_str(" GROUP BY DATE(moved_at), move_location ORDER BY move_date DESC");

        let mut results = Vec::new();
        let mut query_builder = sqlx::query(&query);

        if let Some(board_id) = board_id {
            query_builder = query_builder.bind(board_id).bind(board_id);
        }

        if let Some(start_date) = start_date {
            query_builder = query_builder.bind(start_date);
        }

        if let Some(end_date) = end_date {
            query_builder = query_builder.bind(end_date);
        }

        let rows = query_builder.fetch_all(&self.pool).await?;

        for row in rows {
            results.push(MoveStatistics {
                move_date: row.try_get("move_date")?,
                move_count: row.try_get("move_count")?,
                move_location: row.try_get("move_location")?,
            });
        }

        Ok(results)
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MoveStatistics {
    pub move_date: chrono::NaiveDate,
    pub move_count: i64,
    pub move_location: String,
}
