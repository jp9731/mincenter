use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::env;

pub async fn connect() -> Result<PgPool, sqlx::Error> {
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");

    PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
}

pub async fn get_database() -> Result<PgPool, sqlx::Error> {
    connect().await
}