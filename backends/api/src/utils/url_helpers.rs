use uuid::Uuid;
use crate::utils::uuid_compression::{compress_uuid_to_base62, decompress_base62_to_uuid};

/// URL에서 사용할 수 있는 압축된 ID 생성
pub fn create_short_id(uuid: &Uuid) -> String {
    compress_uuid_to_base62(uuid)
}

/// 압축된 ID를 원래 UUID로 복원
pub fn parse_short_id(short_id: &str) -> Result<Uuid, String> {
    decompress_base62_to_uuid(short_id)
}

/// URL 경로에서 UUID를 압축된 형태로 변환
pub fn compress_url_path(path: &str) -> String {
    // UUID 패턴 매칭 (8-4-4-4-12 형태)
    let uuid_pattern = regex::Regex::new(r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
        .expect("UUID regex pattern should be valid");
    
    uuid_pattern.replace_all(path, |caps: &regex::Captures| {
        if let Ok(uuid) = Uuid::parse_str(&caps[0]) {
            create_short_id(&uuid)
        } else {
            caps[0].to_string()
        }
    }).to_string()
}

/// 압축된 URL 경로를 원래 UUID 형태로 복원
pub fn decompress_url_path(path: &str) -> String {
    // Base62 패턴 매칭 (22자리)
    let base62_pattern = regex::Regex::new(r"[0-9a-zA-Z]{22}")
        .expect("Base62 regex pattern should be valid");
    
    base62_pattern.replace_all(path, |caps: &regex::Captures| {
        if let Ok(uuid) = parse_short_id(&caps[0]) {
            uuid.to_string()
        } else {
            caps[0].to_string()
        }
    }).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_url_compression() {
        let uuid = Uuid::new_v4();
        let original_path = format!("/api/boards/{}/posts/{}", uuid, uuid);
        
        println!("원본 경로: {}", original_path);
        
        let compressed_path = compress_url_path(&original_path);
        println!("압축된 경로: {}", compressed_path);
        
        let decompressed_path = decompress_url_path(&compressed_path);
        println!("복원된 경로: {}", decompressed_path);
        
        assert_eq!(original_path, decompressed_path);
    }
}
