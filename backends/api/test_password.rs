use bcrypt::{verify, hash, DEFAULT_COST};

fn main() {
    let password = "admin123";
    let hash = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e";
    
    println!("Testing password verification...");
    println!("Password: {}", password);
    println!("Hash: {}", hash);
    
    match verify(password, hash) {
        Ok(is_valid) => {
            println!("Verification result: {}", is_valid);
            if is_valid {
                println!("✅ Password is correct!");
            } else {
                println!("❌ Password is incorrect!");
            }
        }
        Err(e) => {
            println!("❌ Verification error: {}", e);
        }
    }
    
    // 새로운 해시 생성 테스트
    println!("\nTesting new hash generation...");
    match hash(password, DEFAULT_COST) {
        Ok(new_hash) => {
            println!("New hash: {}", new_hash);
            match verify(password, &new_hash) {
                Ok(is_valid) => println!("New hash verification: {}", is_valid),
                Err(e) => println!("New hash verification error: {}", e),
            }
        }
        Err(e) => println!("Hash generation error: {}", e),
    }
} 