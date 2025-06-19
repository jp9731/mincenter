pub mod response;
pub mod user;
pub mod community;

use sqlx::PgPool;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}