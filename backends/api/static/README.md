# 파일 저장 구조

## 폴더 구조

```
static/
├── uploads/                    # 업로드된 파일들
│   ├── posts/                  # 게시글 관련 파일
│   │   ├── images/            # 게시글 이미지 (jpg, png, gif, webp)
│   │   └── documents/         # 게시글 첨부 문서 (pdf, doc, xls, ppt, txt)
│   ├── profiles/              # 프로필 관련 파일
│   │   ├── avatars/           # 프로필 이미지 (jpg, png)
│   │   └── documents/         # 프로필 관련 문서
│   └── site/                  # 사이트 설정 관련 파일
│       ├── hero/              # 히어로 섹션 배경 이미지
│       ├── backgrounds/       # 사이트 배경 이미지
│       ├── logos/             # 로고 이미지
│       └── banners/           # 배너 이미지
└── temp/                      # 임시 파일 (업로드 중, 처리 중)
```

## 파일 타입별 허용 확장자

### 이미지 파일
- **허용 확장자**: jpg, jpeg, png, gif, webp, svg
- **최대 크기**: 10MB
- **저장 위치**: 
  - 게시글: `uploads/posts/images/`
  - 프로필: `uploads/profiles/avatars/`
  - 사이트: `uploads/site/{hero,backgrounds,logos,banners}/`

### 문서 파일
- **허용 확장자**: pdf, doc, docx, xls, xlsx, ppt, pptx, txt
- **최대 크기**: 50MB
- **저장 위치**: 
  - 게시글: `uploads/posts/documents/`
  - 프로필: `uploads/profiles/documents/`

### 비디오 파일 (선택적)
- **허용 확장자**: mp4, avi, mov, wmv
- **최대 크기**: 100MB
- **저장 위치**: `uploads/posts/videos/`

## 파일 명명 규칙

### 게시글 파일
```
posts/images/{post_id}_{timestamp}_{random}.{ext}
posts/documents/{post_id}_{timestamp}_{random}.{ext}
```

### 프로필 파일
```
profiles/avatars/{user_id}_{timestamp}.{ext}
profiles/documents/{user_id}_{timestamp}_{random}.{ext}
```

### 사이트 파일
```
site/hero/{type}_{timestamp}.{ext}
site/backgrounds/{page}_{timestamp}.{ext}
site/logos/{type}_{timestamp}.{ext}
site/banners/{location}_{timestamp}.{ext}
```

## 권한 설정

### 폴더 권한
```bash
# 업로드 폴더 권한 설정
chmod 755 static/uploads
chmod 755 static/uploads/posts
chmod 755 static/uploads/profiles
chmod 755 static/uploads/site

# 임시 폴더 권한 설정
chmod 777 static/temp
```

### 웹 서버 설정
- Nginx/Apache에서 `static/uploads/` 폴더를 정적 파일 서빙으로 설정
- URL 경로: `/uploads/` → `static/uploads/`

## 보안 고려사항

1. **파일 타입 검증**: MIME 타입과 확장자 모두 검증
2. **파일 크기 제한**: 서버 설정과 애플리케이션 레벨에서 제한
3. **악성 파일 검사**: 업로드된 파일의 바이러스 검사
4. **접근 권한**: 인증된 사용자만 파일 업로드 가능
5. **파일 정리**: 주기적으로 사용되지 않는 파일 정리

## API 엔드포인트

### 파일 업로드
```
POST /api/upload/posts
POST /api/upload/profiles
POST /api/upload/site
```

### 파일 조회
```
GET /uploads/posts/{filename}
GET /uploads/profiles/{filename}
GET /uploads/site/{filename}
```

### 파일 삭제
```
DELETE /api/upload/{type}/{filename}
``` 