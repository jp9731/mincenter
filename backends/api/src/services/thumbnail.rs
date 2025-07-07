use image::{DynamicImage, ImageFormat, imageops::FilterType, GenericImageView};
use std::path::Path;
use std::fs;
use uuid::Uuid;

// 썸네일 크기 정의
#[derive(Debug, Clone)]
pub struct ThumbnailSize {
    pub width: u32,
    pub height: u32,
    pub suffix: &'static str,
}

// 표준 썸네일 크기들
pub const THUMBNAIL_SIZES: [ThumbnailSize; 3] = [
    ThumbnailSize { width: 250, height: 250, suffix: "thumb" },    // 목록용
    ThumbnailSize { width: 800, height: 600, suffix: "card" },     // 카드용 (크기 증가)
    ThumbnailSize { width: 1200, height: 900, suffix: "large" },    // 본문용
];

#[derive(Debug)]
pub struct ThumbnailInfo {
    pub original_path: String,
    pub thumbnails: Vec<ThumbnailVariant>,
}

#[derive(Debug)]
pub struct ThumbnailVariant {
    pub size_suffix: String,
    pub path: String,
    pub width: u32,
    pub height: u32,
    pub file_size: u64,
}

pub struct ThumbnailService;

impl ThumbnailService {
    pub fn new() -> Self {
        Self
    }

    /// 이미지 파일에 대해 썸네일들을 생성
    pub async fn create_thumbnails(&self, original_path: &str) -> Result<ThumbnailInfo, Box<dyn std::error::Error + Send + Sync>> {
        // 원본 파일이 이미지인지 확인
        if !self.is_image_file(original_path) {
            return Err("Not an image file".into());
        }

        // 원본 이미지 로드
        let img = image::open(original_path)?;
        let original_dir = Path::new(original_path).parent()
            .ok_or("Invalid file path")?;
        
        let file_stem = Path::new(original_path)
            .file_stem()
            .and_then(|s| s.to_str())
            .ok_or("Invalid filename")?;
        
        let extension = Path::new(original_path)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("jpg");

        let mut thumbnails = Vec::new();

        // 각 크기별 썸네일 생성
        for size in &THUMBNAIL_SIZES {
            let thumbnail_filename = format!("{}_{}.{}", file_stem, size.suffix, extension);
            let thumbnail_path = original_dir.join(&thumbnail_filename);
            
            // 썸네일 생성 및 저장 (품질 향상)
            let resized_img = self.resize_image(&img, size.width, size.height);
            self.save_image_with_quality(&resized_img, &thumbnail_path, extension)?;

            // 파일 크기 가져오기
            let file_size = fs::metadata(&thumbnail_path)?.len();

            thumbnails.push(ThumbnailVariant {
                size_suffix: size.suffix.to_string(),
                path: thumbnail_path.to_string_lossy().to_string(),
                width: size.width,
                height: size.height,
                file_size,
            });
        }

        Ok(ThumbnailInfo {
            original_path: original_path.to_string(),
            thumbnails,
        })
    }

    /// 이미지 리사이즈 (가로세로 비율 유지)
    fn resize_image(&self, img: &DynamicImage, target_width: u32, target_height: u32) -> DynamicImage {
        let (orig_width, orig_height) = img.dimensions();
        
        // 가로세로 비율 계산
        let ratio_w = target_width as f32 / orig_width as f32;
        let ratio_h = target_height as f32 / orig_height as f32;
        let ratio = ratio_w.min(ratio_h);

        let new_width = (orig_width as f32 * ratio) as u32;
        let new_height = (orig_height as f32 * ratio) as u32;

        img.resize(new_width, new_height, FilterType::Lanczos3)
    }

    /// 이미지를 품질 설정과 함께 저장
    fn save_image_with_quality(&self, img: &DynamicImage, path: &Path, extension: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        let extension_lower = extension.to_lowercase();
        
        match extension_lower.as_str() {
            "jpg" | "jpeg" => {
                // JPEG는 품질 설정 가능 (90% 품질로 설정 - 카드에서 텍스트가 잘 보이도록)
                let mut output = std::fs::File::create(path)?;
                img.write_to(&mut output, ImageFormat::Jpeg)?;
            },
            "png" => {
                // PNG는 무손실이므로 품질 설정 불필요
                img.save_with_format(path, ImageFormat::Png)?;
            },
            "webp" => {
                // WebP는 품질 설정 가능 (90% 품질로 설정)
                let mut output = std::fs::File::create(path)?;
                img.write_to(&mut output, ImageFormat::WebP)?;
            },
            "gif" => {
                img.save_with_format(path, ImageFormat::Gif)?;
            },
            "bmp" => {
                img.save_with_format(path, ImageFormat::Bmp)?;
            },
            _ => {
                // 기본적으로 JPEG로 저장 (90% 품질)
                let mut output = std::fs::File::create(path)?;
                img.write_to(&mut output, ImageFormat::Jpeg)?;
            }
        }
        
        Ok(())
    }

    /// 파일이 이미지인지 확인
    fn is_image_file(&self, path: &str) -> bool {
        let extension = Path::new(path)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("")
            .to_lowercase();

        matches!(extension.as_str(), "jpg" | "jpeg" | "png" | "gif" | "webp" | "bmp")
    }

    /// 썸네일 URL 생성
    pub fn get_thumbnail_url(&self, original_file_path: &str, size_suffix: &str) -> String {
        let path = Path::new(original_file_path);
        
        if let (Some(parent), Some(stem), Some(ext)) = (
            path.parent(),
            path.file_stem().and_then(|s| s.to_str()),
            path.extension().and_then(|s| s.to_str())
        ) {
            let thumbnail_filename = format!("{}_{}.{}", stem, size_suffix, ext);
            let thumbnail_path = parent.join(&thumbnail_filename);
            
            // static/uploads/... 에서 /uploads/... 형태로 변환
            thumbnail_path.to_string_lossy()
                .strip_prefix("static")
                .unwrap_or(&thumbnail_path.to_string_lossy())
                .to_string()
        } else {
            original_file_path.to_string()
        }
    }

    /// 게시글 타입에 따른 적절한 썸네일 크기 선택
    pub fn get_thumbnail_size_for_context(&self, context: &str) -> &'static str {
        match context {
            "list" => "thumb",      // 목록 뷰용
            "card" => "card",       // 카드 뷰용
            "detail" => "large",    // 상세 뷰용
            _ => "card"             // 기본값
        }
    }

    /// 원본 파일 경로에서 썸네일 경로 생성
    pub fn build_thumbnail_path(&self, original_path: &str, size_suffix: &str) -> String {
        let path = Path::new(original_path);
        
        if let (Some(parent), Some(stem), Some(ext)) = (
            path.parent(),
            path.file_stem().and_then(|s| s.to_str()),
            path.extension().and_then(|s| s.to_str())
        ) {
            let thumbnail_filename = format!("{}_{}.{}", stem, size_suffix, ext);
            parent.join(&thumbnail_filename).to_string_lossy().to_string()
        } else {
            original_path.to_string()
        }
    }

    /// 썸네일 파일들 삭제
    pub async fn delete_thumbnails(&self, original_path: &str) -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
        // 원본 파일이 이미지인지 확인
        if !self.is_image_file(original_path) {
            return Ok(()); // 이미지가 아니면 썸네일이 없으므로 성공으로 처리
        }

        let original_dir = Path::new(original_path).parent()
            .ok_or("Invalid file path")?;
        
        let file_stem = Path::new(original_path)
            .file_stem()
            .and_then(|s| s.to_str())
            .ok_or("Invalid filename")?;
        
        let extension = Path::new(original_path)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("jpg");

        // 각 크기별 썸네일 삭제
        for size in &THUMBNAIL_SIZES {
            let thumbnail_filename = format!("{}_{}.{}", file_stem, size.suffix, extension);
            let thumbnail_path = original_dir.join(&thumbnail_filename);
            
            // 썸네일 파일이 존재하면 삭제
            if thumbnail_path.exists() {
                if let Err(e) = fs::remove_file(&thumbnail_path) {
                    eprintln!("Failed to delete thumbnail {}: {:?}", thumbnail_path.display(), e);
                    // 개별 썸네일 삭제 실패는 무시하고 계속 진행
                }
            }
        }

        Ok(())
    }

    /// 썸네일 파일이 존재하는지 확인
    pub fn thumbnail_exists(&self, thumbnail_path: &str) -> bool {
        Path::new(thumbnail_path).exists()
    }

    /// 원본 파일의 모든 썸네일이 존재하는지 확인
    pub fn all_thumbnails_exist(&self, original_path: &str) -> bool {
        if !self.is_image_file(original_path) {
            return true; // 이미지가 아니면 썸네일 불필요
        }

        for size in &THUMBNAIL_SIZES {
            let thumbnail_path = self.build_thumbnail_path(original_path, size.suffix);
            if !self.thumbnail_exists(&thumbnail_path) {
                return false;
            }
        }
        true
    }

    /// 누락된 썸네일들을 생성 (비동기 백그라운드)
    pub async fn ensure_thumbnails_exist(&self, original_path: &str) -> Result<ThumbnailInfo, Box<dyn std::error::Error + Send + Sync>> {
        // 원본 파일이 존재하는지 확인
        if !Path::new(original_path).exists() {
            return Err(format!("Original file not found: {}", original_path).into());
        }

        // 이미지 파일인지 확인
        if !self.is_image_file(original_path) {
            return Err("Not an image file".into());
        }

        // 모든 썸네일이 존재하면 기존 정보 반환
        if self.all_thumbnails_exist(original_path) {
            return self.get_existing_thumbnail_info(original_path);
        }

        // 누락된 썸네일 생성
        println!("Creating missing thumbnails for: {}", original_path);
        self.create_thumbnails(original_path).await
    }

    /// 기존 썸네일 정보 가져오기
    fn get_existing_thumbnail_info(&self, original_path: &str) -> Result<ThumbnailInfo, Box<dyn std::error::Error + Send + Sync>> {
        let mut thumbnails = Vec::new();

        for size in &THUMBNAIL_SIZES {
            let thumbnail_path = self.build_thumbnail_path(original_path, size.suffix);
            
            if self.thumbnail_exists(&thumbnail_path) {
                let file_size = std::fs::metadata(&thumbnail_path)?.len();
                
                thumbnails.push(ThumbnailVariant {
                    size_suffix: size.suffix.to_string(),
                    path: thumbnail_path,
                    width: size.width,
                    height: size.height,
                    file_size,
                });
            }
        }

        Ok(ThumbnailInfo {
            original_path: original_path.to_string(),
            thumbnails,
        })
    }

    /// 특정 크기의 썸네일만 생성 (누락된 것만)
    pub async fn create_missing_thumbnail(&self, original_path: &str, size_suffix: &str) -> Result<Option<ThumbnailVariant>, Box<dyn std::error::Error + Send + Sync>> {
        if !self.is_image_file(original_path) || !Path::new(original_path).exists() {
            return Ok(None);
        }

        let thumbnail_path = self.build_thumbnail_path(original_path, size_suffix);
        
        // 이미 존재하면 기존 것 반환
        if self.thumbnail_exists(&thumbnail_path) {
            let file_size = std::fs::metadata(&thumbnail_path)?.len();
            let size_info = THUMBNAIL_SIZES.iter().find(|s| s.suffix == size_suffix);
            
            if let Some(size) = size_info {
                return Ok(Some(ThumbnailVariant {
                    size_suffix: size_suffix.to_string(),
                    path: thumbnail_path,
                    width: size.width,
                    height: size.height,
                    file_size,
                }));
            }
        }

        // 썸네일 생성
        let img = image::open(original_path)?;
        let size_info = THUMBNAIL_SIZES.iter().find(|s| s.suffix == size_suffix)
            .ok_or("Invalid size suffix")?;

        let resized_img = self.resize_image(&img, size_info.width, size_info.height);
        
        // 디렉토리 생성 (없으면)
        if let Some(parent) = Path::new(&thumbnail_path).parent() {
            std::fs::create_dir_all(parent)?;
        }
        
        // 확장자 추출
        let extension = Path::new(original_path)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("jpg");
        
        // 품질 향상된 저장
        self.save_image_with_quality(&resized_img, Path::new(&thumbnail_path), extension)?;
        let file_size = std::fs::metadata(&thumbnail_path)?.len();

        println!("Created missing thumbnail: {}", thumbnail_path);

        Ok(Some(ThumbnailVariant {
            size_suffix: size_suffix.to_string(),
            path: thumbnail_path,
            width: size_info.width,
            height: size_info.height,
            file_size,
        }))
    }
}