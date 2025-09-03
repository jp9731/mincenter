use uuid::Uuid;
use base64::{Engine as _, engine::general_purpose};

/// UUID를 Base64로 압축 (36자리 → 24자리)
pub fn compress_uuid_to_base64(uuid: &Uuid) -> String {
    let bytes = uuid.as_bytes();
    general_purpose::URL_SAFE_NO_PAD.encode(bytes)
}

/// Base64 압축된 UUID를 원래 UUID로 복원
pub fn decompress_base64_to_uuid(compressed: &str) -> Result<Uuid, String> {
    let bytes = general_purpose::URL_SAFE_NO_PAD
        .decode(compressed)
        .map_err(|e| format!("Base64 디코딩 실패: {}", e))?;
    
    if bytes.len() != 16 {
        return Err("잘못된 UUID 길이".to_string());
    }
    
    let mut uuid_bytes = [0u8; 16];
    uuid_bytes.copy_from_slice(&bytes);
    
    Ok(Uuid::from_bytes(uuid_bytes))
}

/// UUID를 Base62로 압축 (36자리 → 약 22자리)
pub fn compress_uuid_to_base62(uuid: &Uuid) -> String {
    let bytes = uuid.as_bytes();
    let mut num = 0u128;
    
    // UUID를 128비트 숫자로 변환
    for &byte in bytes {
        num = (num << 8) | byte as u128;
    }
    
    // Base62 인코딩
    base62_encode(num)
}

/// Base62 압축된 UUID를 원래 UUID로 복원
pub fn decompress_base62_to_uuid(compressed: &str) -> Result<Uuid, String> {
    let num = base62_decode(compressed)?;
    
    // 128비트 숫자를 UUID 바이트로 변환
    let mut bytes = [0u8; 16];
    for i in 0..16 {
        bytes[15 - i] = ((num >> (i * 8)) & 0xFF) as u8;
    }
    
    Ok(Uuid::from_bytes(bytes))
}

/// Base62 인코딩 (0-9, a-z, A-Z)
const BASE62_CHARS: &[u8] = b"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

fn base62_encode(mut num: u128) -> String {
    if num == 0 {
        return "0".to_string();
    }
    
    let mut result = String::new();
    while num > 0 {
        result.push(BASE62_CHARS[(num % 62) as usize] as char);
        num /= 62;
    }
    
    result.chars().rev().collect()
}

fn base62_decode(s: &str) -> Result<u128, String> {
    let mut result = 0u128;
    
    for ch in s.chars() {
        let digit = match ch {
            '0'..='9' => ch as u128 - '0' as u128,
            'a'..='z' => ch as u128 - 'a' as u128 + 10,
            'A'..='Z' => ch as u128 - 'A' as u128 + 36,
            _ => return Err(format!("잘못된 Base62 문자: {}", ch)),
        };
        
        result = result * 62 + digit;
    }
    
    Ok(result)
}

/// 더 짧은 랜덤 ID 생성 (NanoID 스타일)
pub fn generate_short_id(length: usize) -> String {
    use rand::Rng;
    
    let mut rng = rand::thread_rng();
    let chars: Vec<char> = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".chars().collect();
    
    (0..length)
        .map(|_| chars[rng.gen_range(0..chars.len())])
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_uuid_compression() {
        let uuid = Uuid::new_v4();
        println!("원본 UUID: {}", uuid);
        
        // Base64 압축 테스트
        let compressed_base64 = compress_uuid_to_base64(&uuid);
        println!("Base64 압축: {} (길이: {})", compressed_base64, compressed_base64.len());
        
        let decompressed_base64 = decompress_base64_to_uuid(&compressed_base64).unwrap();
        assert_eq!(uuid, decompressed_base64);
        
        // Base62 압축 테스트
        let compressed_base62 = compress_uuid_to_base62(&uuid);
        println!("Base62 압축: {} (길이: {})", compressed_base62, compressed_base62.len());
        
        let decompressed_base62 = decompress_base62_to_uuid(&compressed_base62).unwrap();
        assert_eq!(uuid, decompressed_base62);
        
        // 짧은 ID 생성 테스트
        let short_id = generate_short_id(12);
        println!("짧은 ID: {} (길이: {})", short_id, short_id.len());
    }
}
