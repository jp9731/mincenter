-- 민들레센터 데이터베이스 시드 데이터
-- PostgreSQL 13 호환 버전
-- 생성일: 2025-01-08

-- 게시판 데이터
INSERT INTO public.boards (id, name, slug, description, category, display_order, is_public, allow_anonymous, allow_file_upload, max_files, max_file_size, allowed_file_types, allow_rich_text, require_category, allow_comments, allow_likes, write_permission, list_permission, read_permission, reply_permission, comment_permission, download_permission, hide_list, editor_type, allow_search, allow_recommend, allow_disrecommend, show_author_name, show_ip, edit_comment_limit, delete_comment_limit, use_sns, use_captcha, title_length, posts_per_page, read_point, write_point, comment_point, download_point, created_at, updated_at, allowed_iframe_domains) VALUES
('30368058-a9be-49b5-a169-2c42e436e9b9', '공지사항', 'notice', '봉사단체의 공지사항을 전달합니다', 'notice', 1, true, false, true, 5, 10485760, NULL, true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-07 21:16:34.041214+00', '2025-07-07 21:16:34.041214+00', NULL),
('9dadb78e-a011-4ff0-8b5b-62b18e8cd443', '봉사활동 후기', 'volunteer-review', '봉사활동 참여 후기를 공유해주세요', 'review', 2, true, false, true, 5, 10485760, NULL, true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-07 21:16:34.041214+00', '2025-07-07 21:16:34.041214+00', NULL),
('0defeac6-ed18-40e1-b2e0-487781d4a4ac', '자유게시판', 'free', '자유롭게 소통하는 공간입니다', 'free', 3, true, false, true, 5, 10485760, NULL, true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-07 21:16:34.041214+00', '2025-07-07 21:16:34.041214+00', NULL),
('f632656c-fb87-4735-ab77-2e93ddb23f34', '질문과 답변', 'qna', '궁금한 것들을 질문해주세요', 'qna', 4, true, false, true, 5, 10485760, NULL, true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-07 21:16:34.041214+00', '2025-07-07 21:16:34.041214+00', NULL),
('b3b3b3b3-3333-3333-3333-333333333333', '자료실', 'resource', '유용한 자료를 공유하세요', 'resource', 3, true, false, true, 10, 10485760, NULL, true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-07 21:16:34.098662+00', '2025-07-07 21:16:34.098662+00', NULL),
('b4b4b4b4-4444-4444-4444-444444444444', '갤러리', 'gallery', '사진과 이미지를 공유하는 공간', 'media', 4, true, false, true, 20, 10485760, NULL, true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-07 21:16:34.098662+00', '2025-07-07 21:16:34.098662+00', NULL),
('8ec7b0bc-0b36-4865-8816-b476b1f390ca', '익명게시판', 'abbs', '', NULL, 0, true, false, true, 5, 10485760, 'image/*', true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-08 20:37:46.167403+00', '2025-07-08 20:37:46.167403+00', NULL),
('8800b948-9a32-4577-b2e9-b51429bd471a', '센터소식', 'news', '', NULL, 0, true, false, true, 5, 10485760, 'image/*', true, false, true, true, 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, '2025-07-08 20:39:21.551239+00', '2025-07-08 20:39:21.551239+00', NULL);

-- 사용자 데이터
INSERT INTO public.users (id, email, password_hash, name, phone, profile_image, points, role, status, email_verified, email_verified_at, last_login_at, created_at, updated_at) VALUES
('e7e9319f-6c49-4b9c-9bbf-b86b5c2b6598', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e', '관리자', NULL, NULL, 0, 'admin', 'active', true, NULL, NULL, '2025-07-07 21:16:34.043445+00', '2025-07-07 21:16:34.043445+00'),
('16f15cc1-479e-4dc4-9acc-f874a0ac4f1a', 'manager@mincenter.kr', '$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG', '센터 관리자', NULL, NULL, 0, 'admin', 'active', true, NULL, NULL, '2025-07-07 21:16:34.097526+00', '2025-07-07 21:16:34.097526+00'),
('81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'jp9731kr@gmail.com', '$2b$12$sTEOv0xC8zobJqNE0aW3lOa/oxWQZoxVyDxpzrXFwk5U8ghJR71EK', '임종필', NULL, NULL, 0, 'user', 'active', false, NULL, NULL, '2025-07-07 21:48:51.62173+00', '2025-07-07 21:48:51.62173+00'),
('0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5', 'admin@mincenter.kr', '$2b$12$zeKomcjdMt/y17Gp1mFMNuWZDWeSdsSVtJJEyfXgkl.0A6MhFg0mW', '시스템 관리자', NULL, NULL, 0, 'admin', 'active', true, NULL, NULL, '2025-07-07 21:16:34.097526+00', '2025-07-08 04:36:29.785397+00');

-- 카테고리 데이터
INSERT INTO public.categories (id, board_id, name, description, display_order, is_active, created_at, updated_at) VALUES
('cf4dea4f-ae65-479f-bafd-771eae9109a2', '8800b948-9a32-4577-b2e9-b51429bd471a', '소식지', '', 0, true, '2025-07-08 20:39:47.621147+00', '2025-07-08 20:39:47.621147+00');

-- 게시글 데이터
INSERT INTO public.posts (id, board_id, category_id, user_id, title, content, views, likes, is_notice, status, created_at, updated_at, dislikes, meta_title, meta_description, meta_keywords, is_deleted, reading_time, comment_count, attached_files, thumbnail_urls) VALUES
('ea128cd1-e857-44f1-90bd-8fe4b3508918', '30368058-a9be-49b5-a169-2c42e436e9b9', NULL, '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'ㅅㄷㄴㅅ', '<p>ㅁㅁㅁㅁ</p>', 3, 0, false, 'active', '2025-07-08 05:20:38.320629+00', '2025-07-08 05:28:05.781185+00', 0, NULL, NULL, NULL, false, NULL, 0, NULL, NULL),
('6cf46c4a-f972-4a9a-932a-b8fd063691d8', '30368058-a9be-49b5-a169-2c42e436e9b9', NULL, '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'test', '<p>aaaa</p>', 0, 0, false, 'active', '2025-07-08 05:44:21.820352+00', '2025-07-08 05:44:21.820352+00', 0, NULL, NULL, NULL, false, NULL, 0, NULL, NULL),
('41c1d208-be71-4b1b-ab57-b39855404258', '30368058-a9be-49b5-a169-2c42e436e9b9', NULL, '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'ㅁㅁㅁ', '<p>ㅁㅁㅁㅁ</p>', 0, 0, false, 'active', '2025-07-08 05:49:56.518586+00', '2025-07-08 05:49:56.518586+00', 0, NULL, NULL, NULL, false, NULL, 0, NULL, NULL),
('a70fa13d-1df7-43db-a7b7-1a2e24185e6b', '30368058-a9be-49b5-a169-2c42e436e9b9', NULL, '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'ㄱㄱㄱㄱㄱ', '<p>ㄱㄱㄱㄱㄱㄱ</p>', 0, 0, false, 'active', '2025-07-08 05:55:38.195796+00', '2025-07-08 05:55:38.195796+00', 0, NULL, NULL, NULL, false, NULL, 0, NULL, NULL),
('aa919d94-b3a9-45fe-b36a-b6b147ee5031', '30368058-a9be-49b5-a169-2c42e436e9b9', NULL, '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'ㄱㄱㄱㄱㄱ', '<p>ㄱㄱㄱㄱㄱㄱ</p>', 0, 0, false, 'active', '2025-07-08 05:59:11.772751+00', '2025-07-08 05:59:11.772751+00', 0, NULL, NULL, NULL, false, NULL, 0, NULL, NULL),
('1b564544-2ea1-4305-a496-56ae7c9893c3', '30368058-a9be-49b5-a169-2c42e436e9b9', NULL, '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', '글쓰기 테스트', '<p>ㅁㅁㅁㅁ</p>', 2, 0, false, 'active', '2025-07-08 06:02:25.259406+00', '2025-07-08 06:03:10.399075+00', 0, NULL, NULL, NULL, false, NULL, 0, NULL, NULL);

-- FAQ 데이터
INSERT INTO public.faqs (id, question, answer, category, display_order, is_active, created_at, updated_at) VALUES
('cde9c413-5b1a-4bb1-8dd8-b84eaba5428d', '봉사활동에 참여하려면 어떻게 해야 하나요?', '회원가입 후 원하는 봉사활동을 신청하시면 됩니다.', 'general', 1, true, '2025-07-07 21:16:34.042603+00', '2025-07-07 21:16:34.042603+00'),
('281e027d-6db7-47ed-89fa-ed70d596e1b4', '봉사활동 참여 시 준비물이 있나요?', '활동별로 다르며, 각 활동 상세페이지에서 확인할 수 있습니다.', 'general', 2, true, '2025-07-07 21:16:34.042603+00', '2025-07-07 21:16:34.042603+00'),
('653a1717-d933-4e22-9c5a-43a6151c7fc0', '포인트는 어떻게 사용하나요?', '포인트는 기부하거나 봉사활동 용품과 교환할 수 있습니다.', 'point', 3, true, '2025-07-07 21:16:34.042603+00', '2025-07-07 21:16:34.042603+00');

-- 메뉴 데이터
INSERT INTO public.menus (id, name, description, menu_type, target_id, url, display_order, is_active, parent_id, created_at, updated_at) VALUES
('3f909e4d-b3e1-42d4-a939-041117449164', '민들레는요', '단체 소개', 'url', NULL, '/about', 1, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00'),
('56213843-2ef9-40b3-9e32-1f0c67f15cbc', '사업안내', '봉사활동 안내', 'url', NULL, '/services', 2, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00'),
('9d0c8ea9-d2c9-46b7-ae59-850423bda0e5', '공지사항', '회원 커뮤니티', 'board', '30368058-a9be-49b5-a169-2c42e436e9b9', '', 3, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00'),
('103202de-8d5f-482d-94d9-df9892a080c0', '센터일정', '', 'calendar', NULL, '/calendar', 4, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00'),
('7b3181bc-802f-48be-b2b3-4dbc59b0aaba', '후원안내', '후원 안내', 'url', NULL, '/donation', 7, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00'),
('0c7bfe17-c05a-4b48-b2b5-8e00b20ac847', '센터소식', '', 'board', '8800b948-9a32-4577-b2e9-b51429bd471a', '', 5, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00'),
('33a96986-e5c8-40e7-9792-b26bf2c8afbe', '정보마당', '', 'board', '0defeac6-ed18-40e1-b2e0-487781d4a4ac', '', 6, true, NULL, '2025-07-08 20:46:38.420224+00', '2025-07-08 20:46:38.420224+00');

-- 조직 정보 데이터
INSERT INTO public.organization_info (id, name, description, address, phone, email, website, logo_url, established_year, created_at, updated_at) VALUES
('69260a1e-e09f-42a4-822b-03f537837e2d', '따뜻한 마음 봉사단', '장애인을 위한 다양한 봉사활동을 펼치는 단체입니다.', '서울특별시 강남구 테헤란로 123', '02-1234-5678', 'info@warmheart.org', NULL, NULL, NULL, '2025-07-07 21:16:34.04232+00', '2025-07-07 21:16:34.04232+00');

-- 권한 데이터
INSERT INTO public.permissions (id, name, description, resource, action, is_active, created_at, updated_at) VALUES
('ec04bc0b-5eec-4989-ab20-a6d455cb80ba', 'users.read', '사용자 목록 조회', 'users', 'read', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2', 'users.create', '사용자 생성', 'users', 'create', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('e2af9343-75e3-42db-a678-c24cc1eb9dda', 'users.update', '사용자 정보 수정', 'users', 'update', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('f8b9c0d1-e2f3-4g5h-6i7j-8k9l0m1n2o3p', 'users.delete', '사용자 삭제', 'users', 'delete', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('q4r5s6t7-u8v9-w0x1-y2z3-a4b5c6d7e8f9', 'boards.read', '게시판 목록 조회', 'boards', 'read', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('g0h1i2j3-k4l5-m6n7-o8p9-q0r1s2t3u4v5', 'boards.create', '게시판 생성', 'boards', 'create', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('w6x7y8z9-a0b1-c2d3-e4f5-g6h7i8j9k0l1', 'boards.update', '게시판 수정', 'boards', 'update', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('m2n3o4p5-q6r7-s8t9-u0v1-w2x3y4z5a6b7', 'boards.delete', '게시판 삭제', 'boards', 'delete', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('c8d9e0f1-g2h3-i4j5-k6l7-m8n9o0p1q2r3', 'posts.read', '게시글 조회', 'posts', 'read', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('s4t5u6v7-w8x9-y0z1-a2b3-c4d5e6f7g8h9', 'posts.create', '게시글 작성', 'posts', 'create', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('i0j1k2l3-m4n5-o6p7-q8r9-s0t1u2v3w4x5', 'posts.update', '게시글 수정', 'posts', 'update', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('y6z7a8b9-c0d1-e2f3-g4h5-i6j7k8l9m0n1', 'posts.delete', '게시글 삭제', 'posts', 'delete', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00');

-- 역할 데이터
INSERT INTO public.roles (id, name, description, is_active, created_at, updated_at) VALUES
('admin-role-id-1', '관리자', '시스템 전체 관리 권한', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00'),
('user-role-id-1', '일반사용자', '기본 사용자 권한', true, '2025-07-07 21:16:34.091278+00', '2025-07-07 21:16:34.091278+00');

-- 사용자 역할 연결
INSERT INTO public.user_roles (id, user_id, role_id, created_at) VALUES
('ur-1', 'e7e9319f-6c49-4b9c-9bbf-b86b5c2b6598', 'admin-role-id-1', '2025-07-07 21:16:34.091278+00'),
('ur-2', '16f15cc1-479e-4dc4-9acc-f874a0ac4f1a', 'admin-role-id-1', '2025-07-07 21:16:34.091278+00'),
('ur-3', '0ab0419e-76d1-4e0b-b745-de1e8e4cc8d5', 'admin-role-id-1', '2025-07-07 21:16:34.091278+00'),
('ur-4', '81fe86cf-ca4e-4c79-80b7-81dc0e03d78d', 'user-role-id-1', '2025-07-07 21:16:34.091278+00');

-- 관리자 역할에 모든 권한 부여
INSERT INTO public.role_permissions (id, role_id, permission_id, created_at) VALUES
('rp-1', 'admin-role-id-1', 'ec04bc0b-5eec-4989-ab20-a6d455cb80ba', '2025-07-07 21:16:34.091278+00'),
('rp-2', 'admin-role-id-1', '6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2', '2025-07-07 21:16:34.091278+00'),
('rp-3', 'admin-role-id-1', 'e2af9343-75e3-42db-a678-c24cc1eb9dda', '2025-07-07 21:16:34.091278+00'),
('rp-4', 'admin-role-id-1', 'f8b9c0d1-e2f3-4g5h-6i7j-8k9l0m1n2o3p', '2025-07-07 21:16:34.091278+00'),
('rp-5', 'admin-role-id-1', 'q4r5s6t7-u8v9-w0x1-y2z3-a4b5c6d7e8f9', '2025-07-07 21:16:34.091278+00'),
('rp-6', 'admin-role-id-1', 'g0h1i2j3-k4l5-m6n7-o8p9-q0r1s2t3u4v5', '2025-07-07 21:16:34.091278+00'),
('rp-7', 'admin-role-id-1', 'w6x7y8z9-a0b1-c2d3-e4f5-g6h7i8j9k0l1', '2025-07-07 21:16:34.091278+00'),
('rp-8', 'admin-role-id-1', 'm2n3o4p5-q6r7-s8t9-u0v1-w2x3y4z5a6b7', '2025-07-07 21:16:34.091278+00'),
('rp-9', 'admin-role-id-1', 'c8d9e0f1-g2h3-i4j5-k6l7-m8n9o0p1q2r3', '2025-07-07 21:16:34.091278+00'),
('rp-10', 'admin-role-id-1', 's4t5u6v7-w8x9-y0z1-a2b3-c4d5e6f7g8h9', '2025-07-07 21:16:34.091278+00'),
('rp-11', 'admin-role-id-1', 'i0j1k2l3-m4n5-o6p7-q8r9-s0t1u2v3w4x5', '2025-07-07 21:16:34.091278+00'),
('rp-12', 'admin-role-id-1', 'y6z7a8b9-c0d1-e2f3-g4h5-i6j7k8l9m0n1', '2025-07-07 21:16:34.091278+00');

-- 일반사용자 역할에 기본 권한 부여
INSERT INTO public.role_permissions (id, role_id, permission_id, created_at) VALUES
('rp-13', 'user-role-id-1', 'q4r5s6t7-u8v9-w0x1-y2z3-a4b5c6d7e8f9', '2025-07-07 21:16:34.091278+00'),
('rp-14', 'user-role-id-1', 'c8d9e0f1-g2h3-i4j5-k6l7-m8n9o0p1q2r3', '2025-07-07 21:16:34.091278+00'),
('rp-15', 'user-role-id-1', 's4t5u6v7-w8x9-y0z1-a2b3-c4d5e6f7g8h9', '2025-07-07 21:16:34.091278+00'),
('rp-16', 'user-role-id-1', 'i0j1k2l3-m4n5-o6p7-q8r9-s0t1u2v3w4x5', '2025-07-07 21:16:34.091278+00'); 