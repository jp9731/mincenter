use sqlx::{PgPool, Executor};
use std::env;

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    // 환경 변수 로드
    dotenv::dotenv().ok();
    
    // 데이터베이스 연결
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    
    let pool = PgPool::connect(&database_url).await?;
    
    println!("데이터베이스에 연결되었습니다.");
    
    // 마이그레이션 실행
    println!("마이그레이션을 시작합니다...");
    
    // post_management_tables 마이그레이션 실행
    let migration_sql = include_str!("../../database/migrations/20250103000001_create_post_management_tables.sql");
    
    match pool.execute(migration_sql).await {
        Ok(_) => println!("✅ post_management_tables 마이그레이션이 성공적으로 실행되었습니다."),
        Err(e) => {
            if e.to_string().contains("already exists") {
                println!("ℹ️  post_management_tables가 이미 존재합니다.");
            } else {
                eprintln!("❌ post_management_tables 마이그레이션 실행 중 오류 발생: {}", e);
                return Err(e);
            }
        }
    }
    
    // URL ID 테이블 마이그레이션 실행
    let url_id_migration_sql = include_str!("../../database/migrations/20250104000002_create_url_id_tables.sql");
    
    match pool.execute(url_id_migration_sql).await {
        Ok(_) => println!("✅ URL ID 테이블 마이그레이션이 성공적으로 실행되었습니다."),
        Err(e) => {
            if e.to_string().contains("already exists") {
                println!("ℹ️  URL ID 테이블이 이미 존재합니다.");
            } else {
                eprintln!("❌ URL ID 테이블 마이그레이션 실행 중 오류 발생: {}", e);
                return Err(e);
            }
        }
    }
    
    println!("모든 마이그레이션이 완료되었습니다.");
    Ok(())
}
