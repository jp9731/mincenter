-- 민들레장애인자립생활센터 데이터베이스 시드 데이터
-- PostgreSQL 시드 스크립트

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 역할(Role) 데이터
INSERT INTO roles (id, name, description, is_active, created_at, updated_at) VALUES
('8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'super_admin', '시스템 전체 관리자 - 모든 권한을 가짐', true, NOW(), NOW()),
('7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'admin', '일반 관리자 - 대부분의 관리 기능 사용 가능', true, NOW(), NOW()),
('950fce82-5b3a-4b1b-b2f1-8f67557ed209', 'moderator', '중재자 - 게시글과 댓글 관리', true, NOW(), NOW()),
('4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', 'editor', '편집자 - 콘텐츠 작성 및 편집', true, NOW(), NOW()),
('3ae58427-d64c-417e-903c-fee48fd5b5e5', 'viewer', '조회자 - 읽기 전용 권한', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 2. 권한(Permission) 데이터
INSERT INTO permissions (id, name, description, resource, action, is_active, created_at, updated_at) VALUES
-- 사용자 관리 권한
('ec04bc0b-5eec-4989-ab20-a6d455cb80ba', 'users.read', '사용자 목록 조회', 'users', 'read', true, NOW(), NOW()),
('6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2', 'users.create', '사용자 생성', 'users', 'create', true, NOW(), NOW()),
('e2af9343-75e3-42db-a678-c24cc1eb9dda', 'users.update', '사용자 정보 수정', 'users', 'update', true, NOW(), NOW()),
('5cc786f4-510e-4e28-ab4d-f979ad2e90ab', 'users.delete', '사용자 삭제', 'users', 'delete', true, NOW(), NOW()),
('05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05', 'users.roles', '사용자 역할 관리', 'users', 'roles', true, NOW(), NOW()),

-- 게시판 관리 권한
('188c9d63-b2a5-4f3a-88d3-4bf690ad715b', 'boards.read', '게시판 목록 조회', 'boards', 'read', true, NOW(), NOW()),
('fc591480-ce7e-494a-abb1-f05da3b43c00', 'boards.create', '게시판 생성', 'boards', 'create', true, NOW(), NOW()),
('c3f4db40-9e81-450e-884f-68f05a1b29ee', 'boards.update', '게시판 수정', 'boards', 'update', true, NOW(), NOW()),
('05c8baa1-c491-4ad2-a35b-28028214048b', 'boards.delete', '게시판 삭제', 'boards', 'delete', true, NOW(), NOW()),

-- 게시글 관리 권한
('dd955dd2-e944-4751-92b2-e9f4930d2171', 'posts.read', '게시글 목록 조회', 'posts', 'read', true, NOW(), NOW()),
('7ee6b121-79d5-451a-882a-e10e4b65c7b2', 'posts.create', '게시글 작성', 'posts', 'create', true, NOW(), NOW()),
('08e17652-fc1c-477f-874e-327ca6175930', 'posts.update', '게시글 수정', 'posts', 'update', true, NOW(), NOW()),
('240e0131-8cae-4bd6-90ac-c8f17c8daced', 'posts.delete', '게시글 삭제', 'posts', 'delete', true, NOW(), NOW()),
('9eb4c166-f549-448f-9288-c1203f57f013', 'posts.moderate', '게시글 중재', 'posts', 'moderate', true, NOW(), NOW()),

-- 댓글 관리 권한
('0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6', 'comments.read', '댓글 목록 조회', 'comments', 'read', true, NOW(), NOW()),
('1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a', 'comments.create', '댓글 작성', 'comments', 'create', true, NOW(), NOW()),
('10d069a2-3995-45ff-a240-050f1fee0a7c', 'comments.update', '댓글 수정', 'comments', 'update', true, NOW(), NOW()),
('586759ab-70e4-4909-81bc-cc9dbe76d64e', 'comments.delete', '댓글 삭제', 'comments', 'delete', true, NOW(), NOW()),
('5447679d-6216-4454-b8fa-f0bd7d8bb5f9', 'comments.moderate', '댓글 중재', 'comments', 'moderate', true, NOW(), NOW()),

-- 설정 관리 권한
('38b38386-5b6a-4b4c-a774-dafb71663a9e', 'settings.read', '사이트 설정 조회', 'settings', 'read', true, NOW(), NOW()),
('420d1ca8-24a1-4091-91ea-21e8fd898d36', 'settings.update', '사이트 설정 수정', 'settings', 'update', true, NOW(), NOW()),

-- 메뉴 관리 권한
('53c54c43-725a-4ff2-96af-05b1f4a42600', 'menus.read', '메뉴 목록 조회', 'menus', 'read', true, NOW(), NOW()),
('7ae0adf5-6894-4f27-b5e3-9a1252b64d48', 'menus.create', '메뉴 생성', 'menus', 'create', true, NOW(), NOW()),
('c47f6b36-4cc9-43d9-bd58-6767eea06026', 'menus.update', '메뉴 수정', 'menus', 'update', true, NOW(), NOW()),
('18329519-90f5-4c46-bae3-fe8a96440dcf', 'menus.delete', '메뉴 삭제', 'menus', 'delete', true, NOW(), NOW()),

-- 페이지 관리 권한
('baf16a50-fe29-4664-ac57-aea87f27a8e1', 'pages.read', '페이지 목록 조회', 'pages', 'read', true, NOW(), NOW()),
('53faa02c-0729-4db5-a672-47a689310388', 'pages.create', '페이지 생성', 'pages', 'create', true, NOW(), NOW()),
('5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae', 'pages.update', '페이지 수정', 'pages', 'update', true, NOW(), NOW()),
('f3115d94-6574-4dcd-a693-cded458f6ec2', 'pages.delete', '페이지 삭제', 'pages', 'delete', true, NOW(), NOW()),

-- 일정 관리 권한
('d5fd800d-84e7-40d4-bb38-f802cbee49b3', 'calendar.read', '일정 목록 조회', 'calendar', 'read', true, NOW(), NOW()),
('61a2391f-ed6a-47f7-a87e-e45087740bd3', 'calendar.create', '일정 생성', 'calendar', 'create', true, NOW(), NOW()),
('c2083b31-4fa5-42dd-a264-679af6db51b2', 'calendar.update', '일정 수정', 'calendar', 'update', true, NOW(), NOW()),
('90e15cca-f259-459b-a06d-ae7589882259', 'calendar.delete', '일정 삭제', 'calendar', 'delete', true, NOW(), NOW()),

-- 역할 및 권한 관리
('b819e4cd-d8f7-42b4-9adb-aeb96832dffd', 'roles.read', '역할 목록 조회', 'roles', 'read', true, NOW(), NOW()),
('a71eebce-7bd1-4e1b-ba19-a87eefe1298a', 'roles.create', '역할 생성', 'roles', 'create', true, NOW(), NOW()),
('06e77098-960c-4d8a-86a5-2919a5a463de', 'roles.update', '역할 수정', 'roles', 'update', true, NOW(), NOW()),
('c87367bc-5722-47b9-a8d1-29664d67328a', 'roles.delete', '역할 삭제', 'roles', 'delete', true, NOW(), NOW()),
('ba2168d1-a06b-491e-b73d-85f692a74fdb', 'permissions.read', '권한 목록 조회', 'permissions', 'read', true, NOW(), NOW()),
('4ed5fa1f-bbb9-45fe-9e3c-95334b083c68', 'permissions.assign', '권한 할당', 'permissions', 'assign', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 3. 역할-권한 매핑 (super_admin - 모든 권한)
INSERT INTO role_permissions (role_id, permission_id, created_at) 
SELECT '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', id, NOW() 
FROM permissions 
WHERE is_active = true
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 4. 역할-권한 매핑 (admin - super_admin 제외 대부분 권한)
INSERT INTO role_permissions (role_id, permission_id, created_at) 
SELECT '7f188600-b0ed-4dc6-bcdb-74c9916989ed', id, NOW() 
FROM permissions 
WHERE is_active = true 
  AND name NOT IN ('roles.delete', 'permissions.assign')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 5. 역할-권한 매핑 (moderator - 게시글/댓글 관리)
INSERT INTO role_permissions (role_id, permission_id, created_at) 
SELECT '950fce82-5b3a-4b1b-b2f1-8f67557ed209', id, NOW() 
FROM permissions 
WHERE resource IN ('boards', 'posts', 'comments') 
  AND action IN ('read', 'create', 'update', 'delete', 'moderate')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 6. 역할-권한 매핑 (editor - 콘텐츠 작성/편집)
INSERT INTO role_permissions (role_id, permission_id, created_at) 
SELECT '4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', id, NOW() 
FROM permissions 
WHERE (resource IN ('posts', 'comments') AND action IN ('create', 'update'))
   OR (resource = 'pages' AND action IN ('read', 'create', 'update'))
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 7. 역할-권한 매핑 (viewer - 읽기 전용)
INSERT INTO role_permissions (role_id, permission_id, created_at) 
SELECT '3ae58427-d64c-417e-903c-fee48fd5b5e5', id, NOW() 
FROM permissions 
WHERE action = 'read'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- 8. 사이트 정보 데이터
INSERT INTO site_info (id, site_name, catchphrase, address, phone, email, homepage, fax, representative_name, business_number, created_at, updated_at) VALUES
('7486aeef-6900-41cc-954a-2d7eb82c449d', '민들레장애인자립생활센터', '함께 만들어가는 따뜻한 세상', '인천광역시 계양구 계산새로71 A동 201~202호(계산동, 하이베라스)', '032-542-9294', 'mincenter08@daum.net', 'https://mincenter.kr', '032-232-0739', '박길연', '131-80-12554', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 9. 관리자 계정 생성
INSERT INTO users (email, password_hash, name, role, status, email_verified, points, created_at, updated_at) VALUES
('admin@mincenter.kr', '$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG', '시스템 관리자', 'admin', 'active', true, 0, NOW(), NOW()),
('manager@mincenter.kr', '$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG', '센터 관리자', 'admin', 'active', true, 0, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- 10. 사용자 역할 할당 (관리자에게 super_admin 역할 부여)
INSERT INTO user_roles (user_id, role_id, created_at) 
SELECT u.id, '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', NOW()
FROM users u 
WHERE u.email = 'admin@mincenter.kr'
ON CONFLICT (user_id, role_id) DO NOTHING;

INSERT INTO user_roles (user_id, role_id, created_at) 
SELECT u.id, '7f188600-b0ed-4dc6-bcdb-74c9916989ed', NOW()
FROM users u 
WHERE u.email = 'manager@mincenter.kr'
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 11. 기본 게시판 데이터
INSERT INTO boards (id, name, slug, description, category, display_order, is_public, allow_anonymous, allow_file_upload, max_files, created_at, updated_at) VALUES
('b1b1b1b1-1111-1111-1111-111111111111', '공지사항', 'notice', '센터의 공지사항을 확인하세요', 'official', 1, true, false, true, 5, NOW(), NOW()),
('b2b2b2b2-2222-2222-2222-222222222222', '자유게시판', 'free', '자유롭게 소통하는 공간입니다', 'community', 2, true, false, true, 3, NOW(), NOW()),
('b3b3b3b3-3333-3333-3333-333333333333', '자료실', 'resource', '유용한 자료를 공유하세요', 'resource', 3, true, false, true, 10, NOW(), NOW()),
('b4b4b4b4-4444-4444-4444-444444444444', '갤러리', 'gallery', '사진과 이미지를 공유하는 공간', 'media', 4, true, false, true, 20, NOW(), NOW())
ON CONFLICT (slug) DO NOTHING;

-- 12. 카테고리 데이터
INSERT INTO categories (id, board_id, name, slug, description, display_order, is_active, created_at, updated_at) VALUES
(uuid_generate_v4(), 'b2b2b2b2-2222-2222-2222-222222222222', '일반', 'general', '일반 게시글', 1, true, NOW(), NOW()),
(uuid_generate_v4(), 'b3b3b3b3-3333-3333-3333-333333333333', '양식', 'forms', '각종 양식 자료', 1, true, NOW(), NOW()),
(uuid_generate_v4(), 'b3b3b3b3-3333-3333-3333-333333333333', '안내서', 'guides', '이용 안내서', 2, true, NOW(), NOW())
ON CONFLICT (board_id, slug) DO NOTHING;

-- 13. 메뉴 데이터
INSERT INTO menus (id, name, url, target, icon, display_order, parent_id, is_active, menu_type, created_at, updated_at) VALUES
('m1m1m1m1-1111-1111-1111-111111111111', '홈', '/', '_self', 'home', 1, null, true, 'page', NOW(), NOW()),
('m2m2m2m2-2222-2222-2222-222222222222', '센터소개', '/about', '_self', 'info', 2, null, true, 'page', NOW(), NOW()),
('m3m3m3m3-3333-3333-3333-333333333333', '서비스', '/services', '_self', 'service', 3, null, true, 'page', NOW(), NOW()),
('m4m4m4m4-4444-4444-4444-444444444444', '커뮤니티', '/community', '_self', 'community', 4, null, true, 'board', NOW(), NOW()),
('m5m5m5m5-5555-5555-5555-555555555555', '일정', '/calendar', '_self', 'calendar', 5, null, true, 'calendar', NOW(), NOW()),
('m6m6m6m6-6666-6666-6666-666666666666', '후원', '/donation', '_self', 'heart', 6, null, true, 'page', NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- 14. 사이트 설정 데이터
INSERT INTO site_settings (id, setting_key, setting_value, description, is_public, created_at, updated_at) VALUES
(uuid_generate_v4(), 'site_title', '민들레장애인자립생활센터', '사이트 제목', true, NOW(), NOW()),
(uuid_generate_v4(), 'site_description', '함께 만들어가는 따뜻한 세상', '사이트 설명', true, NOW(), NOW()),
(uuid_generate_v4(), 'contact_email', 'mincenter08@daum.net', '연락처 이메일', true, NOW(), NOW()),
(uuid_generate_v4(), 'contact_phone', '032-542-9294', '연락처 전화번호', true, NOW(), NOW()),
(uuid_generate_v4(), 'facebook_url', '', '페이스북 URL', true, NOW(), NOW()),
(uuid_generate_v4(), 'instagram_url', '', '인스타그램 URL', true, NOW(), NOW()),
(uuid_generate_v4(), 'youtube_url', '', '유튜브 URL', true, NOW(), NOW()),
(uuid_generate_v4(), 'registration_enabled', 'true', '회원가입 허용 여부', false, NOW(), NOW()),
(uuid_generate_v4(), 'comment_approval_required', 'false', '댓글 승인 필요 여부', false, NOW(), NOW()),
(uuid_generate_v4(), 'max_file_size', '10485760', '최대 파일 크기 (바이트)', false, NOW(), NOW())
ON CONFLICT (setting_key) DO NOTHING;

-- 15. FAQ 데이터
INSERT INTO faqs (id, question, answer, category, display_order, is_active, created_at, updated_at) VALUES
(uuid_generate_v4(), '센터 이용 시간은 어떻게 되나요?', '평일 오전 9시부터 오후 6시까지 이용 가능합니다. 공휴일은 휴무입니다.', 'general', 1, true, NOW(), NOW()),
(uuid_generate_v4(), '서비스 신청은 어떻게 하나요?', '전화 또는 방문을 통해 상담 후 서비스 신청이 가능합니다.', 'service', 2, true, NOW(), NOW()),
(uuid_generate_v4(), '후원 방법이 궁금합니다.', '정기후원과 일시후원이 가능하며, 계좌이체 또는 온라인 결제를 통해 후원하실 수 있습니다.', 'donation', 3, true, NOW(), NOW())
ON CONFLICT (question) DO NOTHING;