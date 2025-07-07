--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13 (Debian 15.13-1.pgdg120+1)
-- Dumped by pg_dump version 15.13 (Debian 15.13-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: _sqlx_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public._sqlx_migrations VALUES (20250626085720, 'extend boards table', '2025-06-26 08:57:55.117442+00', true, '\xb64b2b68c2062fe98a78adec465738604d320d091f2ec1987292c16ac16d420cd7576bb62f4dea9b53cf61e0a892fcae', 5072959);
INSERT INTO public._sqlx_migrations VALUES (20250705143316, 'create likes table', '2025-07-05 14:33:44.598419+00', true, '\x5ddf632dbcf59127a0486f20f0972b2419caa0b9e67546f3c616d555bdf69b44cb59a15ce759139810ab65efc5aeca27', 7533833);
INSERT INTO public._sqlx_migrations VALUES (20250706003410, 'create site settings tables', '2025-07-06 00:34:32.735633+00', true, '\x93d663dff22264d85fcb63eb5d3f5f8ccc1c62f60070ecd769bd8dc0d566e9902889c55da27e1bfbf6b25a42f34cd0ad', 17795500);
INSERT INTO public._sqlx_migrations VALUES (20250706003934, 'add additional site info fields', '2025-07-06 00:41:47.260803+00', true, '\xc4b4bb8ac7fd5ee7f2707b8adec20dd438775acfda9ae138d3e380599597a20c813a749291857435012b9347c7c4d991', 5264542);
INSERT INTO public._sqlx_migrations VALUES (20250706010154, 'create rbac tables', '2025-07-06 01:04:07.727488+00', true, '\xae9870bc65f3603d7d3680f25047489ad1dd24c3a03718c3831b6ae4d378e5834a65833c29eb37a6eb843174e114b6d1', 30370958);
INSERT INTO public._sqlx_migrations VALUES (20250707015959, 'add published to post status', '2025-07-07 01:53:01.755611+00', true, '\x531994c20e6f70ab2e66f9d09708eb6c0640e0f168d70b903a149fb25430b9943be4d8bd33a9926c098576f04832b97f', 2292042);
INSERT INTO public._sqlx_migrations VALUES (20250707020000, 'extend posts table', '2025-07-07 01:53:01.75896+00', true, '\x4ab075cb4b20350d1c776c1ff3762329c36afaaf9b841f226fe247936445b6314c05396c62b61615706540ef20afead6', 13490209);
INSERT INTO public._sqlx_migrations VALUES (20250705223357, 'add allowed iframe domains to boards', '2025-07-07 05:09:22.625315+00', true, '\x70578c12aeb18ffb5e05568aead0a48fae4434d403c404608c05c7aa4649de10a16c52217167433ce4ecc445d9e60813', 2658042);


--
-- Data for Name: boards; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.boards VALUES ('afa91103-ad7d-4142-a15c-f804f3d0e3bc', '봉사활동 후기', 'volunteer-review', '봉사활동 참여 후기를 공유해주세요', 'review', 2, true, false, true, 5, 10485760, NULL, true, false, true, true, '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00', 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, NULL);
INSERT INTO public.boards VALUES ('315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '공지사항', 'notice', '봉사단체의 공지사항을 전달합니다', 'notice', 1, true, false, true, 5, 10485760, 'image/*,application/pdf', true, true, true, true, '2025-06-25 14:55:57.619579+00', '2025-07-07 00:51:05.943682+00', 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, 'youtube.com,youtu.be,vimeo.com');
INSERT INTO public.boards VALUES ('38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', '자유게시판', 'free', '자유롭게 소통하는 공간입니다', 'free', 3, true, true, true, 5, 10485760, NULL, true, false, true, true, '2025-06-25 14:55:57.619579+00', '2025-07-07 00:51:49.840199+00', 'member', 'guest', 'guest', 'member', 'member', 'member', false, 'rich', true, true, false, true, false, 0, 0, false, false, 200, 20, 0, 0, 0, 0, NULL);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users VALUES ('f0bd148f-7ca9-43fb-bbea-affb264b461d', 'user1@example.com', '$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG', '김봉사', NULL, NULL, 35, 'user', 'active', true, NULL, NULL, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.users VALUES ('a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'user2@example.com', '$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG', '이도움', NULL, NULL, 25, 'user', 'active', true, NULL, NULL, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.users VALUES ('020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'user3@example.com', '$2b$12$GqE3.Nr9GwxQV3VCveevPeYNQM4B9yu1wlAuevumr0tAJfBEL0foG', '박나눔', NULL, NULL, 20, 'user', 'active', true, NULL, NULL, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.users VALUES ('26b43586-7447-4f58-a2a9-6b2ddea56c57', 'jp9731kr@gmail.com', '$2b$12$yDTlThNP74SAuCh.OCzRH.2Iqe1HoMklnMxNkNqYgV.CD7j5rq4NK', '임종필', NULL, NULL, 0, 'user', 'active', false, NULL, NULL, '2025-06-25 15:02:27.759152+00', '2025-06-25 15:02:27.759152+00');
INSERT INTO public.users VALUES ('de166ef3-1f14-4f14-ace8-1752517be700', 'admin@example.com', '$2b$12$yDTlThNP74SAuCh.OCzRH.2Iqe1HoMklnMxNkNqYgV.CD7j5rq4NK', '관리자', NULL, NULL, 0, 'admin', 'active', true, NULL, NULL, '2025-06-25 14:55:57.619579+00', '2025-06-25 18:39:03.559664+00');


--
-- Data for Name: calendar_events; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.calendar_events VALUES ('2fa3748a-78cd-45a2-83a6-c87e9249cf83', '청소', 'ㅁㅁㅁ', '2025-06-27 00:00:00+00', '2025-06-28 00:00:00+00', true, NULL, true, 'de166ef3-1f14-4f14-ace8-1752517be700', '2025-06-26 08:04:39.102033+00', '2025-06-26 08:04:39.102033+00');


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categories VALUES ('b894d840-99af-4147-96f6-38f4466b8554', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '일반공지', '일반적인 공지사항', 1, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('342c1b55-eb42-4a1f-bdbf-7708bf2b8ba7', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '긴급공지', '긴급한 공지사항', 2, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('e7f5bfae-da5c-4c4f-be30-e13c4e94ad49', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '행사안내', '다가오는 행사 안내', 3, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('19afc16d-78d7-45ca-92fe-f3eddaee2884', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', '복지관봉사', '복지관 관련 봉사활동 후기', 1, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('3fd31bd9-2750-49a4-8f29-05066b4440d0', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', '교육봉사', '교육 관련 봉사활동 후기', 2, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('f48661a4-dbd4-434a-a672-ac1b6961a402', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', '행사봉사', '행사 지원 봉사활동 후기', 3, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('caba02cf-f47c-4de1-bd63-eb4dea96e8f3', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', '기타봉사', '기타 봉사활동 후기', 4, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('d4a76efd-a066-4320-8797-e8fb41640ee3', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', '일반', '일반적인 이야기', 1, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('d0b8b795-1eac-4d2a-bbf6-bc122b96a3ff', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', '정보공유', '유용한 정보 공유', 2, true, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.categories VALUES ('5f560789-b780-4678-bb44-118150410bcb', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', '봉사', '', 5, true, '2025-06-26 09:37:15.63986+00', '2025-06-26 09:37:15.63986+00');


--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.posts VALUES ('8ba55245-1518-4fc2-93f6-5ac7c8603738', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '이미지등록', '<p>ㅁㅁㅁㅁㅁㄴㅇㄹㅎㅎㅎㅎ</p>', 39, 0, false, 'active', '2025-07-07 04:11:01.887583+00', '2025-07-07 05:15:38.830954+00', 'http://localhost:8080/uploads/posts/images/1566e58f-2e8d-430b-b0d4-0b37fba6e7dc_1751861457_mosa2yuMWk_large_card.png', false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('5abd7733-c33c-4a1c-89de-6150dcf864c3', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'test', '', 2, 0, false, 'active', '2025-07-03 16:31:23.067858+00', '2025-07-05 08:05:43.290761+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('457143cd-0a02-4fca-9d70-a44cd1b37c78', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', NULL, 'f0bd148f-7ca9-43fb-bbea-affb264b461d', '장애인 복지관 청소 봉사 후기', '오늘 처음으로 장애인 복지관 청소 봉사에 참여했습니다.

생각보다 많은 일들이 있었지만, 함께 참여한 봉사자들과 협력해서 깨끗하게 정리할 수 있었어요. 
특히 복지관을 이용하시는 분들이 고마워하시는 모습을 보니 정말 뿌듯했습니다.

다음에도 꼭 참여하고 싶어요! 😊', 45, 1, false, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('2d71edf5-ae14-47f1-8d98-2cfe7e9ef22a', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', NULL, 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', '시각장애인 도서 낭독 봉사 경험담', '매주 토요일 시각장애인을 위한 도서 낭독 봉사를 하고 있습니다.

처음에는 어떻게 읽어야 할지 몰라서 많이 긴장했는데, 
이제는 자연스럽게 감정을 담아서 읽을 수 있게 되었어요.

이용자분들이 책 내용에 대해 함께 이야기하실 때가 가장 보람찹니다.
작은 나눔이지만 서로에게 의미있는 시간이 되고 있습니다.', 67, 2, false, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('60e89ffd-f783-49a0-914b-6367245c0827', 'afa91103-ad7d-4142-a15c-f804f3d0e3bc', NULL, '020a4cdc-2efb-447d-aafc-e4fe3a80d792', '휠체어 이용자와 함께한 나들이', '휠체어를 이용하시는 분들과 함께 공원 나들이를 다녀왔습니다.

평소에 생각하지 못했던 불편함들을 많이 느꼈어요.
턱이 있는 곳, 경사가 있는 길, 좁은 통로 등...

하지만 함께 웃고 이야기하며 즐거운 시간을 보낼 수 있어서 좋았습니다.
앞으로도 이런 활동에 더 적극적으로 참여하고 싶어요.', 34, 1, false, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('5811f59a-fda2-4ccd-9574-232294bfd793', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', NULL, 'f0bd148f-7ca9-43fb-bbea-affb264b461d', '봉사활동 동기들과 점심 모임 후기', '지난주에 함께 봉사활동을 했던 분들과 점심을 먹었어요.

봉사활동 이야기도 하고, 서로의 근황도 나누면서 
정말 즐거운 시간을 보냈습니다.

이렇게 좋은 사람들을 만날 수 있어서 봉사활동이 더욱 의미있게 느껴져요.', 23, 0, false, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('82dd1e74-3e43-41a7-8b03-c5a99157e959', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', NULL, 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', '여러분의 봉사활동 동기는 무엇인가요?', '안녕하세요! 봉사활동을 시작한지 3개월 정도 되었는데요.

처음에는 단순히 도움이 되고 싶다는 마음으로 시작했지만,
지금은 오히려 제가 더 많은 것을 배우고 받는 것 같아요.

여러분들은 어떤 계기로 봉사활동을 시작하셨나요?
궁금해서 질문드립니다! 😊', 41, 0, false, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('6ab10755-55be-42eb-ab0e-8e64fceb42a4', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'test', '<p>ㅁㅁㅎㅎㅎㅎㅎㅎ</p>', 117, 0, false, 'active', '2025-07-04 16:15:22.440298+00', '2025-07-07 03:07:40.776265+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('69d61465-54bd-4bc2-9b33-c68d66d1a1ed', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '파일 업로드 테스트', '<p>파일업로드&nbsp;테스트</p>', 3, 0, false, 'active', '2025-07-03 17:41:17.97022+00', '2025-07-03 17:45:24.407579+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('563ddf2e-4c42-43eb-a54d-9c7c98fb08bf', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '자유게시판 글쓰기 테스트', '<p>ㅁㅁㅁ</p>', 0, 0, false, 'active', '2025-07-07 03:47:06.516099+00', '2025-07-07 03:47:06.516099+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('3942cfc5-0f34-4451-a862-02c0e561248c', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '자유게시판 글쓰기 테스트', '<p>ㅁㅁㅁ</p>', 0, 0, false, 'active', '2025-07-07 03:52:28.632721+00', '2025-07-07 03:52:28.632721+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('22265d42-8ed4-4165-9969-b4a6bf35efde', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㅁㅁ', '<p>ㅁㅁㅁ</p>', 2, 0, false, 'active', '2025-07-07 04:07:16.963352+00', '2025-07-07 04:08:55.748124+00', 'http://localhost:8080/uploads/posts/images/865607f5-4135-42d6-a35b-1668cd4bc5d3_1751861231_mosa2yuMWk_large_card.png', false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('b12a145c-ff4c-470a-bee6-054bc480a1a9', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㅁㅁㅇㅇㅇ', '<p>ㅇㅇㅇ</p>', 3, 0, false, 'deleted', '2025-07-03 18:06:24.271308+00', '2025-07-04 14:10:40.447799+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('baf3011d-ce7c-479f-9404-4e68569103a4', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㅁㅁ', '<p>ㅁㅁㅁ</p>', 3, 0, false, 'deleted', '2025-07-03 17:52:09.00469+00', '2025-07-04 14:23:56.86847+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('6e62b126-799a-4aa3-9a0f-1729e6471acc', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '342c1b55-eb42-4a1f-bdbf-7708bf2b8ba7', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '카테고리 표시테스트', 'ㅁㅁㅁ', 9, 0, false, 'active', '2025-07-03 11:47:24.478417+00', '2025-07-03 14:04:22.138004+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('50a91c2a-3046-400b-bdff-3f761f0f54a5', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅅㅅㅅ', '<p>ㅁㅁㅁㅁ</p>', 24, 0, false, 'deleted', '2025-07-03 18:36:09.42692+00', '2025-07-07 04:34:36.573538+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('618ea67b-b7c6-4c6a-bd49-fe8b3217d5e4', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '에디터 테스트', '<p></p><p></p><p></p><p></p><h1></h1><h1><strong>ㅁㄴㅇㄹㅁ</strong></h1><p></p><p>ㅁㄴㅇㄹ</p><p>ㅁㄴㅇ</p><p>ㄹ</p><p>ㅁㄴㅇ</p><p></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p>', 4, 0, false, 'active', '2025-07-03 15:05:05.108094+00', '2025-07-03 15:12:19.25703+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('51f0cd83-16fd-45be-8054-e94d193b88ff', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'test', '<p><strong>aaa</strong></p><p></p><p><em>aaavasdf</em></p><p></p><p>asdfasdf</p><p></p>', 1, 0, false, 'active', '2025-07-03 15:26:40.447332+00', '2025-07-03 15:26:40.489322+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('b3d290ed-fde1-4761-9768-dc9a450513f1', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'test', '<p>asdfasdf</p>', 1, 0, false, 'active', '2025-07-03 16:03:39.464118+00', '2025-07-03 16:03:39.496574+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('3f2692a0-29cb-4fc6-beb8-3065a6792022', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '파일 업로드 테스트', '<p>ㅁㅁㅁ</p>', 2, 0, false, 'active', '2025-07-03 17:48:04.759442+00', '2025-07-05 16:28:38.754997+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('ebe5550f-980d-4d2d-9f11-c91de949b41b', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, 'de166ef3-1f14-4f14-ace8-1752517be700', '봉사활동 참여 시 주의사항', '봉사활동 참여 전 반드시 확인해주세요.

1. 활동 30분 전까지 도착
2. 편안한 복장 착용
3. 개인 물병 지참
4. 안전교육 필수 이수

안전한 봉사활동을 위해 협조 부탁드립니다.', 148, 1, true, 'active', '2025-06-25 15:01:27.803809+00', '2025-07-05 16:40:50.002376+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('34b42ceb-343a-4f98-9345-b199881eb88b', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '이미지 썸네일 테스트', 'ㅁㅁㅁ', 7, 0, false, 'active', '2025-07-03 11:08:20.079903+00', '2025-07-06 00:07:20.092767+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('4cde2867-8afd-4d9f-9859-9aeb6075ab0c', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅅㄷㄴㅅ', '<p><img src="http://localhost:8080/uploads/posts/images/6611edaa-cabf-48d4-b745-58a0afd972f4_1751563563_mosanvHTPb.jpeg"></p>', 7, 0, false, 'active', '2025-07-03 17:26:18.735952+00', '2025-07-06 00:07:26.264431+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('f564bd02-873d-4829-bac2-508f396016d9', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㄹㄹ', '<p>ㄹㅁㅁ</p>', 2, 0, false, 'active', '2025-07-07 04:09:32.017436+00', '2025-07-07 05:13:14.743889+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('ce4e47da-6b96-42c5-8c09-936b4a9fc1d1', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'asdf', '', 1, 0, false, 'active', '2025-07-03 16:32:17.840692+00', '2025-07-03 16:32:17.880478+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('2f09d4b0-b1cc-4e03-81e2-a49314a11b99', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '이미지 등록 테스트', '<p>ㅁㅁㅁ</p>', 4, 0, false, 'deleted', '2025-07-03 18:26:49.612235+00', '2025-07-07 01:27:56.73411+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('c6c3ed72-355d-4ad9-8fc1-c5fa59587a50', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅅㄷㄴㅅ', '<p>ㅁㅁㅁ</p>', 51, 0, false, 'active', '2025-07-03 17:50:36.139504+00', '2025-07-07 01:43:36.377419+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('c14f811e-4d0e-43bf-a0f1-16b73f268ef4', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '342c1b55-eb42-4a1f-bdbf-7708bf2b8ba7', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '에디터 이미지 등록 테스트', '<p>에디터에&nbsp;이미지를&nbsp;넣기</p><p><img src="http://localhost:8080/uploads/posts/images/96f19416-d9fa-495e-b6bc-3843470410a2_1751563728_mosanvHTPb.jpeg"></p><p></p><p>다른&nbsp;이미지&nbsp;추가</p><p><img src="http://localhost:8080/uploads/posts/images/da5e4b4c-2f7a-4092-ac87-1a4e4362723a_1751563745_mosay1e0g0.jpeg"></p><p></p><p>다른&nbsp;이미지</p><p><img src="http://localhost:8080/uploads/posts/images/01b093aa-60ad-4f3e-b362-6233ba5893a5_1751563794_mosaZqVyO2_large.jpeg"></p><p></p>', 6, 0, false, 'active', '2025-07-03 17:30:07.396103+00', '2025-07-07 01:43:44.496576+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('09c42ab4-ddbf-46d9-8de1-bc04e1cee52c', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '글쓰기 테스트', '<p>ㅁㅁㅁ</p>', 1, 0, false, 'active', '2025-07-07 04:00:33.449954+00', '2025-07-07 04:04:50.156762+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('4ca367cf-7d67-40ec-9b19-ca875f364e29', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '글쓰기2', '<p>ㅅㄷㄴㅅ</p>', 0, 0, false, 'active', '2025-07-07 04:05:11.935326+00', '2025-07-07 04:05:11.935326+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('b637c2b0-773a-44fe-999a-31ef94d36e06', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '에디터 테스트', '<p></p><p></p><p></p><p></p><h1></h1><h1><strong>ㅁㄴㅇㄹㅁ</strong></h1><p></p><p>ㅁㄴㅇㄹ</p><p>ㅁㄴㅇ</p><p>ㄹ</p><p>ㅁㄴㅇ</p><p></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p><p></p>', 0, 0, false, 'active', '2025-07-03 15:02:45.277647+00', '2025-07-03 15:02:45.277647+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('06496333-b12e-4461-8629-d02c93ae3c72', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '에디터 이미지 등록 테스트', '<p>글쓰기&nbsp;내용넣고</p><p>이미지&nbsp;넣고</p><p>ㅁ</p>', 1, 0, false, 'active', '2025-07-03 15:25:31.97971+00', '2025-07-03 15:25:32.127983+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('41ef5430-13df-4562-a1b9-78d1c16451c5', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '공지사항 테스트 파일올리기', 'ㅁㅁㅁ', 1, 0, false, 'active', '2025-06-30 03:35:59.113179+00', '2025-06-30 03:35:59.150075+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('18398622-a20f-4ab0-94cf-6eeee5a232f0', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '첨부파일 테스트', '<p>ㅁㅁㅁㅁ</p>', 5, 0, false, 'active', '2025-07-03 17:42:44.070163+00', '2025-07-03 17:45:29.569529+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('c410071d-fa5d-4373-a1a5-9faa87c308ff', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'edit test1', '<p>aaaasd</p><p></p><p></p>', 1, 0, false, 'active', '2025-07-03 15:33:26.000712+00', '2025-07-03 15:33:26.096861+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('7250bebd-0d93-47bc-96d7-2c3fc73d664c', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'te', '', 1, 0, false, 'active', '2025-07-03 15:37:10.224595+00', '2025-07-03 15:37:10.265302+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('384a7794-7b74-467c-9875-16ed0f0bb62a', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '파일올리기2', 'ㅁㅁ', 3, 0, false, 'deleted', '2025-06-30 03:37:30.764704+00', '2025-06-30 03:39:17.069322+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('62f2e637-ae28-4ab1-a8e9-2570b6d3051f', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', 'd4a76efd-a066-4320-8797-e8fb41640ee3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '테스트', '<p>ㅁㅁ</p>', 1, 0, false, 'active', '2025-07-07 04:10:41.768518+00', '2025-07-07 04:10:41.790606+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('7561be0b-6d2f-4d7f-a857-3f945b01fecf', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '테스트2', '공지사항 테스트', 2, 0, false, 'deleted', '2025-06-30 03:35:32.703753+00', '2025-06-30 03:39:24.821392+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('09982180-f32c-417d-9970-b3b7dc18370e', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, 'de166ef3-1f14-4f14-ace8-1752517be700', 'testttt', 'aaa', 9, 0, false, 'active', '2025-06-26 08:07:07.897618+00', '2025-06-30 03:39:28.82783+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('17b9502d-4eb2-416f-9290-02f5939d7bd4', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'test', '<p><s>ㅁㄴㅇㄹㅁㄴ</s></p><p></p><p></p><p><a href="https://naver.com" rel="noopener noreferrer">ㅁㄴㅇㄹ</a></p><p></p><p><img></p><p></p><p>asdfasdf<img></p><p></p><a href="https://www.youtube.com/embed/l7p_eUfFhzc?showinfo=0" rel="noopener noreferrer">https://www.youtube.com/embed/l7p_eUfFhzc?showinfo=0</a><p></p>', 27, 0, false, 'active', '2025-07-03 16:12:50.97846+00', '2025-07-05 08:38:50.057881+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('2a3c7e83-075a-428e-b9f5-efd96b4106d8', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', 'b894d840-99af-4147-96f6-38f4466b8554', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㅁㅁ', '<p>ㅁㅁㅁ</p>', 28, 0, false, 'deleted', '2025-07-03 18:46:04.4485+00', '2025-07-07 04:16:12.658546+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('c1eb1d8a-4462-4176-a6e7-2df5a15334dd', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '파일올리기 테스트', 'ㅅㄷ', 2, 0, false, 'active', '2025-06-30 03:40:21.421086+00', '2025-06-30 03:42:27.556333+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('88f689db-7967-4ac7-94bc-5c6d04dcbc50', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', '파일 업로드 테스트3', 'ㅁㅁㅁ', 5, 0, false, 'active', '2025-06-30 04:05:50.93173+00', '2025-07-06 00:07:22.05573+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('cc942cab-1be7-46e8-ba84-ff06d474dad6', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅅㄷㄴㅅ', 'ㅁㅁㅁ', 13, 0, false, 'active', '2025-06-30 04:28:22.066825+00', '2025-07-06 00:07:24.285795+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('20b709e8-90fc-42f1-b0a7-35a4773a2108', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㅁㅁ', 'ㅁㅁㅁㅁ', 20, 0, false, 'active', '2025-06-30 04:34:53.865936+00', '2025-07-06 00:07:24.664138+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('b034a77b-2dd9-4876-ab26-8ab7941a99f5', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅅㄷㄴㅅ', 'ㅁㅁㅁㅁ', 11, 0, false, 'active', '2025-07-03 11:34:00.082849+00', '2025-07-06 00:07:25.044706+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('3da3e28a-e084-48d2-81f5-cf36953382f9', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, 'de166ef3-1f14-4f14-ace8-1752517be700', '[중요] 2024년 하반기 봉사활동 계획 안내', '안녕하세요. 따뜻한 마음 봉사단입니다.

2024년 하반기 봉사활동 계획을 안내드립니다.

## 주요 일정
- 7월: 여름 장애인 캠프 (7/15-7/17)
- 8월: 장애인 체육대회 지원 (8/20)
- 9월: 추석 나눔 행사 (9/15)
- 10월: 장애인 일자리 박람회 (10/12)
- 11월: 김장 나눔 봉사 (11/20)
- 12월: 연말 감사 행사 (12/22)

많은 참여 부탁드립니다.', 175, 0, true, 'active', '2025-06-25 15:01:27.803809+00', '2025-07-07 04:36:26.836706+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);
INSERT INTO public.posts VALUES ('9a2c07d3-d964-4afc-aee5-b7e96aa75135', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', NULL, '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ㅁㅁㅁㄹㄹㄹ', '<p>ㄹㄹㄹㄹ</p>', 15, 0, false, 'deleted', '2025-07-03 18:00:39.196984+00', '2025-07-04 14:23:27.327911+00', NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 'approved', NULL, NULL, 0, 0, 1, NULL, 0, 0);


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.comments VALUES ('ec3b6b4c-bac3-408e-a4d2-eb04304d87eb', '457143cd-0a02-4fca-9d70-a44cd1b37c78', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', NULL, '정말 수고하셨어요! 저도 다음번에 참여해보고 싶네요.', 0, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.comments VALUES ('19c1bc8a-bcc4-41da-a129-3918fd2cba10', '457143cd-0a02-4fca-9d70-a44cd1b37c78', 'de166ef3-1f14-4f14-ace8-1752517be700', NULL, '첫 봉사활동 참여해주셔서 감사합니다. 앞으로도 많은 참여 부탁드려요!', 0, 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.comments VALUES ('947d93d9-b85e-4741-adf4-46c98e71c228', '6ab10755-55be-42eb-ab0e-8e64fceb42a4', '26b43586-7447-4f58-a2a9-6b2ddea56c57', NULL, 'ㅅㄷㄴㅅ', 0, 'active', '2025-07-05 12:31:26.997135+00', '2025-07-05 12:31:26.997135+00');
INSERT INTO public.comments VALUES ('73d49819-0078-47aa-adde-7346ba8a2daf', 'ebe5550f-980d-4d2d-9f11-c91de949b41b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', NULL, 'ㅁㅁㅁ', 0, 'active', '2025-07-05 12:33:40.349674+00', '2025-07-05 12:33:40.349674+00');
INSERT INTO public.comments VALUES ('bcfeda46-0bd2-4e43-a9b4-5abc4f839544', 'ebe5550f-980d-4d2d-9f11-c91de949b41b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', NULL, 'ㅍㅍㄹㅁㄴㅇㄹ', 0, 'active', '2025-07-05 12:33:52.385553+00', '2025-07-05 12:33:52.385553+00');
INSERT INTO public.comments VALUES ('ef196ffa-1b25-4bb5-afce-7371e42c24e3', 'ebe5550f-980d-4d2d-9f11-c91de949b41b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', NULL, 'ㅠㅠㅠㅠ', 0, 'active', '2025-07-05 14:31:18.437715+00', '2025-07-05 14:31:18.437715+00');
INSERT INTO public.comments VALUES ('5b85189c-f021-4e6f-8f1a-a5197aa4b3a1', 'ebe5550f-980d-4d2d-9f11-c91de949b41b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', NULL, 'ㅁㅁㅁ', 0, 'active', '2025-07-05 14:31:22.688487+00', '2025-07-05 14:31:22.688487+00');
INSERT INTO public.comments VALUES ('23856a52-08ce-4d9c-bfb5-b11bbf5d14ca', 'ebe5550f-980d-4d2d-9f11-c91de949b41b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', NULL, 'ㅅㄷㄴㅅ', 1, 'active', '2025-07-05 12:32:36.17856+00', '2025-07-05 14:35:54.202032+00');


--
-- Data for Name: drafts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.drafts VALUES ('6a7081d8-0fd4-4e47-8c37-f2f5a3b882f3', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', NULL, '작성 중인 글 제목', '이것은 임시저장된 글 내용입니다...', 3, '2025-07-02 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');


--
-- Data for Name: faqs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.faqs VALUES ('41e6c44c-017c-477d-bf52-71b4a2c80820', '봉사활동에 참여하려면 어떻게 해야 하나요?', '회원가입 후 원하는 봉사활동을 신청하시면 됩니다.', 'general', 1, true, '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.faqs VALUES ('2edab382-0fb8-4fbc-8cb2-615f0b2c10ac', '봉사활동 참여 시 준비물이 있나요?', '활동별로 다르며, 각 활동 상세페이지에서 확인할 수 있습니다.', 'general', 2, true, '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.faqs VALUES ('936cd2df-0241-4a30-9282-f7502e74f8b0', '포인트는 어떻게 사용하나요?', '포인트는 기부하거나 봉사활동 용품과 교환할 수 있습니다.', 'point', 3, true, '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.faqs VALUES ('e035c11b-73a0-4bf4-8f45-d9c747d71ddd', '봉사활동에 참여하려면 어떻게 해야 하나요?', '회원가입 후 원하는 봉사활동을 신청하시면 됩니다.', 'general', 1, true, '2025-06-25 15:10:34.039251+00', '2025-06-25 15:10:34.039251+00');
INSERT INTO public.faqs VALUES ('37b3df18-6763-44df-9749-838d0fd4c236', '봉사활동 참여 시 준비물이 있나요?', '활동별로 다르며, 각 활동 상세페이지에서 확인할 수 있습니다.', 'general', 2, true, '2025-06-25 15:10:34.039251+00', '2025-06-25 15:10:34.039251+00');
INSERT INTO public.faqs VALUES ('69035e01-c4b6-4bed-96b5-b20d66046015', '포인트는 어떻게 사용하나요?', '포인트는 기부하거나 봉사활동 용품과 교환할 수 있습니다.', 'point', 3, true, '2025-06-25 15:10:34.039251+00', '2025-06-25 15:10:34.039251+00');


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.files VALUES ('9b467361-9382-4f34-bd78-42df49faadcc', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2yuMWk.png', '26b43586-7447-4f58-a2a9-6b2ddea56c57_1751256348_8e8630c5.png', 'static/uploads/posts/images/26b43586-7447-4f58-a2a9-6b2ddea56c57_1751256348_8e8630c5.png', 278596, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-06-30 04:05:48.651461+00');
INSERT INTO public.files VALUES ('c7a89482-1a4b-439d-902c-3dc96aa89111', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosajPI3fF.png', '26b43586-7447-4f58-a2a9-6b2ddea56c57_1751257699_3a41b440.png', 'static/uploads/posts/images/26b43586-7447-4f58-a2a9-6b2ddea56c57_1751257699_3a41b440.png', 247329, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-06-30 04:28:19.583466+00');
INSERT INTO public.files VALUES ('48413c85-c8db-469f-812e-00f4e706463a', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaloYcTZ.jpeg', '26b43586-7447-4f58-a2a9-6b2ddea56c57_1751258089_142ab607.jpeg', 'static/uploads/posts/images/26b43586-7447-4f58-a2a9-6b2ddea56c57_1751258089_142ab607.jpeg', 99228, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-06-30 04:34:49.747301+00');
INSERT INTO public.files VALUES ('bb4c71e1-3db7-4f5f-b458-90869719360d', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2yuMWk.png', '566224a7-06b6-4141-b9c9-0359c2ac8cd1_1751540898_mosa2yuMWk.png', 'static/uploads/posts/images/566224a7-06b6-4141-b9c9-0359c2ac8cd1_1751540898_mosa2yuMWk.png', 278596, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 11:08:19.512+00');
INSERT INTO public.files VALUES ('f10a5925-aa95-4db6-896e-c55fc75e7207', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2yuMWk.png', '74bb43f1-7141-4db7-875b-20048bd9b6dc_1751542436_mosa2yuMWk.png', 'static/uploads/posts/images/74bb43f1-7141-4db7-875b-20048bd9b6dc_1751542436_mosa2yuMWk.png', 278596, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 11:33:57.816783+00');
INSERT INTO public.files VALUES ('13fa6ca5-d807-49b9-87f9-a2ff9f01bff9', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaahvh4l.png', '49f2199f-3409-4404-808d-984faedba904_1751563460_mosaahvh4l.png', 'static/uploads/posts/images/49f2199f-3409-4404-808d-984faedba904_1751563460_mosaahvh4l.png', 242996, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 17:24:22.08409+00');
INSERT INTO public.files VALUES ('8b23817e-5014-44f3-9dba-096527ab27db', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosanvHTPb.jpeg', '6611edaa-cabf-48d4-b745-58a0afd972f4_1751563563_mosanvHTPb.jpeg', 'static/uploads/posts/images/6611edaa-cabf-48d4-b745-58a0afd972f4_1751563563_mosanvHTPb.jpeg', 64439, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 17:26:06.590003+00');
INSERT INTO public.files VALUES ('5592860c-d431-4a70-87b2-8e8b3fbb9957', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosanvHTPb.jpeg', '96f19416-d9fa-495e-b6bc-3843470410a2_1751563728_mosanvHTPb.jpeg', 'static/uploads/posts/images/96f19416-d9fa-495e-b6bc-3843470410a2_1751563728_mosanvHTPb.jpeg', 64439, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 17:28:51.596609+00');
INSERT INTO public.files VALUES ('7adc9f38-6dfe-4ce1-8aaf-b69af1474a5d', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosay1e0g0.jpeg', 'da5e4b4c-2f7a-4092-ac87-1a4e4362723a_1751563745_mosay1e0g0.jpeg', 'static/uploads/posts/images/da5e4b4c-2f7a-4092-ac87-1a4e4362723a_1751563745_mosay1e0g0.jpeg', 73122, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 17:29:08.311731+00');
INSERT INTO public.files VALUES ('17de1e2c-5f87-4f7b-abd9-8387f9b98a68', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaZqVyO2.jpeg', '01b093aa-60ad-4f3e-b362-6233ba5893a5_1751563794_mosaZqVyO2.jpeg', 'static/uploads/posts/images/01b093aa-60ad-4f3e-b362-6233ba5893a5_1751563794_mosaZqVyO2.jpeg', 103178, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 17:29:57.447771+00');
INSERT INTO public.files VALUES ('3f13a855-5834-43ae-9a5b-e1523e00fa05', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaKr2Dti.jpeg', 'e6f1a627-a16a-450c-b853-5f13bb5fd0c5_1751564407_mosaKr2Dti.jpeg', 'static/uploads/posts/images/e6f1a627-a16a-450c-b853-5f13bb5fd0c5_1751564407_mosaKr2Dti.jpeg', 90587, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 17:40:09.775231+00');
INSERT INTO public.files VALUES ('bd8e42ae-71df-4013-bb36-9d9fb81d67b4', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '스크린샷 2025-06-26 오전 10.22.30.png', 'fbd1b718-b7f0-4435-b113-2c7efb7e2896_1751564511_스크린샷_2025-06-26_오전_10.22.30.png', 'static/uploads/posts/images/fbd1b718-b7f0-4435-b113-2c7efb7e2896_1751564511_스크린샷_2025-06-26_오전_10.22.30.png', 1046887, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 17:41:54.938383+00');
INSERT INTO public.files VALUES ('ce118362-74b7-489f-8521-37875c7db75c', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosatmV9JG.jpeg', '3cc1c535-0ffb-4a26-9084-0d90b8615e6d_1751564529_mosatmV9JG.jpeg', 'static/uploads/posts/images/3cc1c535-0ffb-4a26-9084-0d90b8615e6d_1751564529_mosatmV9JG.jpeg', 58895, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 17:42:11.874817+00');
INSERT INTO public.files VALUES ('c9c7ef5e-500f-4736-8378-c46b242a5354', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '스크린샷 2025-06-26 오전 10.22.40.png', 'b6a02743-1f24-4d3f-9b69-aa0e6b9e1f1b_1751564555_스크린샷_2025-06-26_오전_10.22.40.png', 'static/uploads/posts/images/b6a02743-1f24-4d3f-9b69-aa0e6b9e1f1b_1751564555_스크린샷_2025-06-26_오전_10.22.40.png', 96233, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 17:42:39.135488+00');
INSERT INTO public.files VALUES ('8aab377b-7ace-4b78-b936-78cf6116a9f1', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2F1h40.png', 'be680afa-ae70-4bd9-84b8-b44de6f35d86_1751564559_mosa2F1h40.png', 'static/uploads/posts/images/be680afa-ae70-4bd9-84b8-b44de6f35d86_1751564559_mosa2F1h40.png', 213662, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 17:42:40.487618+00');
INSERT INTO public.files VALUES ('f7424550-1030-41fb-aa60-990b37d26697', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaahvh4l (1).png', 'fc2bd47b-7606-4605-812e-2a8e85a7bf70_1751564879_mosaahvh4l_(1).png', 'static/uploads/posts/images/fc2bd47b-7606-4605-812e-2a8e85a7bf70_1751564879_mosaahvh4l_(1).png', 242996, NULL, 'image/png', 'draft', NULL, false, 'completed', '2025-07-03 17:48:01.481322+00');
INSERT INTO public.files VALUES ('1b252839-83ae-4405-84a6-d3a8e6d43559', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2qRnAl.jpeg', '40d0f019-ea10-4225-a29a-a43deb9b63bc_1751565031_mosa2qRnAl.jpeg', 'static/uploads/posts/images/40d0f019-ea10-4225-a29a-a43deb9b63bc_1751565031_mosa2qRnAl.jpeg', 87918, NULL, 'image/jpeg', 'draft', NULL, false, 'completed', '2025-07-03 17:50:33.748863+00');
INSERT INTO public.files VALUES ('f2bd9de8-989b-486a-a8f5-bdcded063156', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaIPqi3H.png', 'eb52d63c-f85c-489f-b94f-c3b4c6520fe4_1751565124_mosaIPqi3H.png', 'static/uploads/posts/images/eb52d63c-f85c-489f-b94f-c3b4c6520fe4_1751565124_mosaIPqi3H.png', 183747, NULL, 'image/png', 'draft', NULL, false, 'completed', '2025-07-03 17:52:06.841476+00');
INSERT INTO public.files VALUES ('fba853d5-123f-4f40-8411-bc23168edd88', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaahvh4l (1).png', '03b4ac75-a85a-4ec7-b929-1a16bbf00563_1751565263_mosaahvh4l_(1).png', 'static/uploads/posts/images/03b4ac75-a85a-4ec7-b929-1a16bbf00563_1751565263_mosaahvh4l_(1).png', 242996, NULL, 'image/png', 'draft', NULL, false, 'completed', '2025-07-03 17:54:25.820079+00');
INSERT INTO public.files VALUES ('705ef93b-531a-41e9-83f1-e1fce989bbdd', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaidl93n.jpeg', 'b40cdf6f-ceaa-460d-96f4-1176024777b4_1751565634_mosaidl93n.jpeg', 'static/uploads/posts/images/b40cdf6f-ceaa-460d-96f4-1176024777b4_1751565634_mosaidl93n.jpeg', 73150, NULL, 'image/jpeg', 'draft', NULL, false, 'completed', '2025-07-03 18:00:36.787644+00');
INSERT INTO public.files VALUES ('ab936603-af30-46ff-a31c-5b483ca48205', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaZ2Zf5q.jpeg', '5710146e-14e7-4bd6-b2f9-09ad39b949e6_1751565980_mosaZ2Zf5q.jpeg', 'static/uploads/posts/images/5710146e-14e7-4bd6-b2f9-09ad39b949e6_1751565980_mosaZ2Zf5q.jpeg', 44474, NULL, 'image/jpeg', 'draft', NULL, false, 'completed', '2025-07-03 18:06:22.011849+00');
INSERT INTO public.files VALUES ('05634cc8-753d-47e1-87c5-013df65b500f', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2yuMWk.png', '3c5f6742-79b3-4c1a-9a9c-c59ceeba8382_1751567199_mosa2yuMWk.png', 'static/uploads/posts/images/3c5f6742-79b3-4c1a-9a9c-c59ceeba8382_1751567199_mosa2yuMWk.png', 278596, NULL, 'image/png', 'draft', NULL, false, 'completed', '2025-07-03 18:26:41.834801+00');
INSERT INTO public.files VALUES ('4248a6be-9081-406d-a606-d0c32c5825ff', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosanMCqpJ.png', '24208303-80ad-4020-8278-c8e5cc9d1a11_1751567759_mosanMCqpJ.png', 'static/uploads/posts/images/24208303-80ad-4020-8278-c8e5cc9d1a11_1751567759_mosanMCqpJ.png', 176363, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 18:36:01.473498+00');
INSERT INTO public.files VALUES ('06854e9d-d970-47cf-97c8-db77e978290e', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaVrJcDr.png', '11665607-f830-44da-b4ae-531c4700f3d9_1751567761_mosaVrJcDr.png', 'static/uploads/posts/images/11665607-f830-44da-b4ae-531c4700f3d9_1751567761_mosaVrJcDr.png', 221065, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 18:36:03.485085+00');
INSERT INTO public.files VALUES ('6464b01c-71a9-4b23-9a02-0342ff43161d', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosaUgI4Ft.jpeg', '3e842f28-92d9-4d39-8b68-0503d3b4b24c_1751567763_mosaUgI4Ft.jpeg', 'static/uploads/posts/images/3e842f28-92d9-4d39-8b68-0503d3b4b24c_1751567763_mosaUgI4Ft.jpeg', 81892, NULL, 'image/jpeg', 'published', NULL, false, 'completed', '2025-07-03 18:36:05.564347+00');
INSERT INTO public.files VALUES ('c2870568-74cf-465d-b5fb-7e8cdb0e9535', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa0VMbEo.png', 'c43d372e-f575-492c-95a0-1f78491436aa_1751567757_mosa0VMbEo.png', 'static/uploads/posts/images/c43d372e-f575-492c-95a0-1f78491436aa_1751567757_mosa0VMbEo.png', 326187, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-03 18:35:59.407438+00');
INSERT INTO public.files VALUES ('7d6045b4-2bd8-4ad8-9154-c2f74309d91e', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '2026학년도 세종과학예술영재학교 입학전형 모집요강_0407.pdf', 'd5d445fa-a280-413d-aac0-7b52fe02f662_1751568359_2026학년도_세종과학예술영재학교_입학전형_모집요강_0407.pdf', 'static/uploads/posts/documents/d5d445fa-a280-413d-aac0-7b52fe02f662_1751568359_2026학년도_세종과학예술영재학교_입학전형_모집요강_0407.pdf', 869087, NULL, 'application/pdf', 'published', NULL, false, 'completed', '2025-07-03 18:45:59.786192+00');
INSERT INTO public.files VALUES ('1a1893db-e81d-4a15-a044-183a512132ba', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2yuMWk.png', '865607f5-4135-42d6-a35b-1668cd4bc5d3_1751861231_mosa2yuMWk.png', 'static/uploads/posts/images/865607f5-4135-42d6-a35b-1668cd4bc5d3_1751861231_mosa2yuMWk.png', 278596, NULL, 'image/png', 'draft', NULL, false, 'completed', '2025-07-07 04:07:13.997525+00');
INSERT INTO public.files VALUES ('f266b011-15b7-4b05-89e8-09af16fcc0ef', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'mosa2yuMWk.png', '1566e58f-2e8d-430b-b0d4-0b37fba6e7dc_1751861457_mosa2yuMWk.png', 'static/uploads/posts/images/1566e58f-2e8d-430b-b0d4-0b37fba6e7dc_1751861457_mosa2yuMWk.png', 278596, NULL, 'image/png', 'published', NULL, false, 'completed', '2025-07-07 04:10:59.750594+00');


--
-- Data for Name: file_entities; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.file_entities VALUES ('8da329c4-fe28-41c5-8c65-4914a85980d4', '9b467361-9382-4f34-bd78-42df49faadcc', 'post', '88f689db-7967-4ac7-94bc-5c6d04dcbc50', 0, '2025-06-30 04:05:50.950639+00');
INSERT INTO public.file_entities VALUES ('f21757ff-5e32-4d42-9c95-ac6da27846fc', 'c7a89482-1a4b-439d-902c-3dc96aa89111', 'post', 'cc942cab-1be7-46e8-ba84-ff06d474dad6', 0, '2025-06-30 04:28:22.075806+00');
INSERT INTO public.file_entities VALUES ('e4f00d38-e45c-4714-95e6-e922cb6ff0e0', '48413c85-c8db-469f-812e-00f4e706463a', 'post', '20b709e8-90fc-42f1-b0a7-35a4773a2108', 0, '2025-06-30 04:34:53.87825+00');
INSERT INTO public.file_entities VALUES ('65cbc9f6-9d58-4784-9d9f-bf22912bb744', 'bb4c71e1-3db7-4f5f-b458-90869719360d', 'post', '34b42ceb-343a-4f98-9345-b199881eb88b', 0, '2025-07-03 11:08:20.089417+00');
INSERT INTO public.file_entities VALUES ('583c8ed5-328e-49c0-b602-3e2335a5191d', 'f10a5925-aa95-4db6-896e-c55fc75e7207', 'post', 'b034a77b-2dd9-4876-ab26-8ab7941a99f5', 0, '2025-07-03 11:34:00.095144+00');
INSERT INTO public.file_entities VALUES ('838ff1bc-3180-419c-86ad-3bcb55437cc8', 'c2870568-74cf-465d-b5fb-7e8cdb0e9535', 'post', '50a91c2a-3046-400b-bdff-3f761f0f54a5', 0, '2025-07-03 18:36:09.4382+00');
INSERT INTO public.file_entities VALUES ('025d597d-09af-4a9d-84ef-3cf06af1cc50', '4248a6be-9081-406d-a606-d0c32c5825ff', 'post', '50a91c2a-3046-400b-bdff-3f761f0f54a5', 1, '2025-07-03 18:36:09.444264+00');
INSERT INTO public.file_entities VALUES ('e809bdf0-2adb-43db-919d-b7616ddc20e2', '06854e9d-d970-47cf-97c8-db77e978290e', 'post', '50a91c2a-3046-400b-bdff-3f761f0f54a5', 2, '2025-07-03 18:36:09.447278+00');
INSERT INTO public.file_entities VALUES ('bbd2519d-47a5-49af-a292-f951a8c7c0d1', '6464b01c-71a9-4b23-9a02-0342ff43161d', 'post', '50a91c2a-3046-400b-bdff-3f761f0f54a5', 3, '2025-07-03 18:36:09.44959+00');
INSERT INTO public.file_entities VALUES ('0a3852e6-4a78-4b08-9574-da9421eab9cf', '7d6045b4-2bd8-4ad8-9154-c2f74309d91e', 'post', '2a3c7e83-075a-428e-b9f5-efd96b4106d8', 0, '2025-07-03 18:46:04.464328+00');
INSERT INTO public.file_entities VALUES ('683b08e6-d240-4122-906f-ab0cbff556f4', 'f266b011-15b7-4b05-89e8-09af16fcc0ef', 'post', '8ba55245-1518-4fc2-93f6-5ac7c8603738', 0, '2025-07-07 04:11:01.905749+00');


--
-- Data for Name: galleries; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.galleries VALUES ('87af94c4-2505-4dab-a54a-63deb718ba0d', '2024년 하반기 봉사활동', '지난 6개월간의 봉사활동 모습들을 모았습니다.', 'activity', 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.galleries VALUES ('192b0367-5374-4ef9-8a26-6aa641edbfb4', '장애인의 날 행사', '매년 4월 20일 장애인의 날 기념행사 사진들', 'event', 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.galleries VALUES ('0e71ecda-ea0b-47ea-83f0-71b16e17de8b', '여름 캠프 활동', '장애인 청소년들과 함께한 여름 캠프', 'camp', 'active', '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');


--
-- Data for Name: hero_sections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.hero_sections VALUES ('0ffa328a-ade7-46d6-bfa5-9168bfc19e9e', '함께하는 따뜻한 마음', '장애인과 함께하는 봉사활동', '우리의 작은 관심과 참여가 더 나은 세상을 만듭니다. 지금 봉사활동에 참여해보세요.', NULL, '봉사활동 참여하기', '/volunteer', true, 1, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.hero_sections VALUES ('e5d6636e-f7d4-44a9-9c8d-733047b3c542', '나눔의 기쁨을 경험하세요', '매월 다양한 봉사활동 프로그램', '정기적인 봉사활동을 통해 의미있는 시간을 보내고 소중한 경험을 쌓아보세요.', NULL, '프로그램 보기', '/programs', false, 2, '2025-06-25 15:01:27.803809+00', '2025-06-25 15:01:27.803809+00');


--
-- Data for Name: image_sizes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: likes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.likes VALUES ('21aee934-fe05-4178-b125-7cdfc6322f1a', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'post', '2d71edf5-ae14-47f1-8d98-2cfe7e9ef22a', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('0890494a-ef33-4c36-aa27-0ab2cc61c529', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'post', '457143cd-0a02-4fca-9d70-a44cd1b37c78', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('9d404409-d43c-4091-bc49-15414e0c2c1d', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'post', 'a425d804-becc-4569-8259-0fe1115db211', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('da755f84-29bd-45c2-9062-42d834054860', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'post', 'a9128625-3515-4eb6-bdee-9c8bffa8c458', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('cffa4a68-9d00-4c13-a559-2f13a33681ac', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'post', '2d71edf5-ae14-47f1-8d98-2cfe7e9ef22a', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('5fad5c57-38e2-42c7-8e2f-0ddcf83139a7', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'post', '60e89ffd-f783-49a0-914b-6367245c0827', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('76175a33-dabd-4196-9175-ea5ce5d106ff', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'post', 'a9128625-3515-4eb6-bdee-9c8bffa8c458', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.likes VALUES ('791fc333-eea4-4c20-847c-e14860fca6b3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'comment', '23856a52-08ce-4d9c-bfb5-b11bbf5d14ca', '2025-07-05 14:35:54.202032+00');
INSERT INTO public.likes VALUES ('bd43b9fd-f1ab-4367-85d8-6c74ff35994d', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'post', 'ebe5550f-980d-4d2d-9f11-c91de949b41b', '2025-07-05 16:23:09.442968+00');


--
-- Data for Name: menus; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.menus VALUES ('c212430b-6d84-4faf-92ac-5312379352c0', '민들레는요', '', 'url', 'fe1a2521-ac5d-4ff4-8c8e-af069350bf23', '/about', 1, true, NULL, '2025-07-07 03:37:34.943872+00', '2025-07-07 03:37:34.943872+00');
INSERT INTO public.menus VALUES ('b9eb876d-44a1-4ca5-954d-c2286354b673', '사업소개', '', 'url', NULL, '/services', 2, true, NULL, '2025-07-07 03:37:34.943872+00', '2025-07-07 03:37:34.943872+00');
INSERT INTO public.menus VALUES ('4ca0e87d-baf1-48e5-a565-67c1ffd91666', '공지사항', '', 'board', '315849de-fbd9-45d4-a5f7-ec0c02bef4fe', '', 3, true, NULL, '2025-07-07 03:37:34.943872+00', '2025-07-07 03:37:34.943872+00');
INSERT INTO public.menus VALUES ('e701f47d-b6d0-4e33-bbe8-e72f7bfac532', '후원하기', '', 'url', 'ba6ac7e9-1f09-4e4f-862c-dc5a3cb88f41', '/donation', 6, true, NULL, '2025-07-07 03:37:34.943872+00', '2025-07-07 03:37:34.943872+00');
INSERT INTO public.menus VALUES ('d9e7e6d4-9bac-43d6-913b-bed71a9fb06f', '정보마당', '', 'board', '38a4fbd8-c1d8-46fe-a98e-a2523432a6f7', '', 4, true, NULL, '2025-07-07 03:37:34.943872+00', '2025-07-07 03:37:34.943872+00');
INSERT INTO public.menus VALUES ('6fe65d85-1270-4792-b4b2-a48b179e0262', '센터일정', '', 'calendar', NULL, '/calendar', 5, true, NULL, '2025-07-07 03:37:34.943872+00', '2025-07-07 03:37:34.943872+00');


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.notifications VALUES ('aad8fae5-edec-4228-b5ec-ac4c06c78fde', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'comment', '새 댓글이 달렸습니다', '정말 수고하셨어요! 저도 다음번에 참여해보고 싶네요.', 'post', '457143cd-0a02-4fca-9d70-a44cd1b37c78', false, NULL, '2025-06-25 15:01:27.803809+00');
INSERT INTO public.notifications VALUES ('1caeb708-b2ea-46fd-acd9-da479873f1e7', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'comment', '새 댓글이 달렸습니다', '첫 봉사활동 참여해주셔서 감사합니다. 앞으로도 많은 참여 부탁드려요!', 'post', '457143cd-0a02-4fca-9d70-a44cd1b37c78', false, NULL, '2025-06-25 15:01:27.803809+00');
INSERT INTO public.notifications VALUES ('99604790-1698-40ca-bc93-22a1883aba83', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'comment', '새 댓글이 달렸습니다', '편한 복장과 개인 물병 정도면 충분합니다. 자세한 내용은 활동 전 안내해드릴게요!', 'post', 'a425d804-becc-4569-8259-0fe1115db211', false, NULL, '2025-06-25 15:01:27.803809+00');
INSERT INTO public.notifications VALUES ('bd09b8b6-4e60-41cd-b61f-7f0f12f3af1c', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'comment', '새 댓글이 달렸습니다', '저도 처음에 많이 궁금했는데, 생각보다 특별한 준비물은 없어요. 마음의 준비만 하시면 됩니다! ^^', 'post', 'a425d804-becc-4569-8259-0fe1115db211', false, NULL, '2025-06-25 15:01:27.803809+00');


--
-- Data for Name: organization_info; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organization_info VALUES ('ae94aac1-1d86-4c87-9ec0-24ed546465b5', '따뜻한 마음 봉사단', '장애인을 위한 다양한 봉사활동을 펼치는 단체입니다.', '서울특별시 강남구 테헤란로 123', '02-1234-5678', 'info@warmheart.org', NULL, NULL, NULL, '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.organization_info VALUES ('4490ec8c-fccc-4962-b49c-df25f25ee24c', '따뜻한 마음 봉사단', '장애인을 위한 다양한 봉사활동을 펼치는 단체입니다.', '서울특별시 강남구 테헤란로 123', '02-1234-5678', 'info@warmheart.org', NULL, NULL, NULL, '2025-06-25 15:10:34.039251+00', '2025-06-25 15:10:34.039251+00');


--
-- Data for Name: pages; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pages VALUES ('9e761c7b-e66f-4082-b139-2550c0debcce', 'overview', '사업소개', '사업소개

IL지원사업
IL지원사업은?
- 장애인자립생활을 위한 법률과 지자체 조례에 근거하여 장애인이 지역사회에서 자립생활을 영위할 수 있도록 지자체로부터 지원받아 시행하는 지원 사업입니다. IL지원사업은 아래 항목으로 세부적으로 나누어서 진행하고 있습니다.

문의: 이건호(IL사업 팀장/동료상담가) 070-7865-1240

○ 권익옹호사업
- 장애인의 권익증진을 위한 사업 및 캠페인 진행
- 24년 기준: 요기어때(계양구 내 휠체어 이용 가능 업체 모니터링), 장애이해교육(직장, 대학생 등 대상으로 장애인식개선교육 진행), 권익옹호스터디(열사학교 )

○ 동료상담
- 개별동료상담과 장애인복지 및 정책 제도 관련의 정보제공, 동료상담양성 프로그램 진행
- 24년 기준: 개별동료상담, 정보제공(달력, 소식지 제작)

○ 개인별자립지원
- 자립생활에 필요한 실질적인 교육과 사회활동 등을 지원
- 24년 기준: 사례지원(다양한 욕구기반을 갖고 있는 장애인들에게 상담과 경제적 지원을 제공), 자조모임(당사자 활동이 중심인 6개 자조모임으로 구성하여 운영),  무엇이든 배워보세요(자립생활에 필요한 현실 가이드 교육), 모여락(다양한 문화체험 진행), 사례지원(사례자 선정 후 지속적인 사례관리 진행)

○ 탈시설지원
- 지역사회 탈시설을 고민하는 장애인들을 위한 사업 진행
- 24년 기준: 시친소(거주시설 장애인과 자립생활 중인 장애인과의 멘티 멘토 활동 캠프), 자립생활교육(자립에 필요한 실생활 교육)

○ 선택사업
- 문화여가체육 활동의 주제로 한 특화 프로그램 계획하여 진행
- 24년 기준: 감정해방힐링여행(개인여행 지원), 토론회(장애관련 정책 토론회 진행),  파워사커대회(전동휠체어 축구 대회)



자립(생활)주택 운영
민들레장애인자립생활센터에서는 장애인의 자립생활을 위한 주택을 운영하고 있습니다. 

○ 모집대상: 인천광역시에 거주 중인 자립생활을 원하는 19세 이상 장애인(재가 장애인, 시설장애인)

○ 모집인원: 주택별 상이(남녀 각각 개별 입주) 

○ 주요내용:
- 주택위치: 계양구 관내(아파트, 빌라)
- 입주기간: 최대5년(생활주택 2년, 자립주택 5년)
- 지원내용: 자립생활기술훈련, 자립생활 지원, 임대료, 공과금, 프로그램 경비 등(식비, 소모품비 등 일상생활비용은 개인 지출)

○ 입주절차: 신청서 제출(구청) -> 초기상담 -> 구청 면접 -> 최종 발표

○ 문의사항: 남성문의 070-7865-1245 / 조기석,  여성문의 070-7865-1242 / 정유숙


활동지원사업
장애인활동지원서비스란?

- 장애인활동지원서비스는  장애로 인한 일상생활의 어려움을  갖고 있는 장애인과 그 가족을 지원하기 위한 목적으로 생겨난 사회서비스입니다. 
- 장애인활동지원서비스 이용자는 신체지원영역, 가사지원영역, 사회활동영역  등을 기관에서 파견된 활동지원사를 통해서 서비스를 제공 받습니다.

1.  신청자격 
 ○ 만 6세 이상부터 만 65세 미만의 장애인복지법 상 등록장애인
   - 소득수준과 무관하게 신청가능
   - 제외대상: 
      장애인시설에 입소한 사람(퇴거 예정자에 한하여 사전신청 허용)
      장기요양급여 수급자(이 부분은 예외가 가능한 부분도 있으니 구체적인 확인이 필요함)
      의료기관에 30일 이상 초과하여 입원 중인 경우
      교정시설 또는 치료감호시설에 수용 중인 경우
      이 외 비슷한 돌봄서비스 유형의 급여를 받고 있는 경우

2. 신청방법(대리신청 가능)
 ○ 방문신청: 급여 대상 장애인의 주민등록상 주소지 읍면동
       - 우편신청 가능
 ○ 온라인 신청: 복지로 사이트(www.bokjiro.go.kr)

3. 신청서류
 ○ 주민센터 방문
   - 사회보장급여 신청서
   - 바우처카드 발급 신청서
 
 ○ 의료기관에서 받아야 할 서류(장애정도 판단 필요자)
      * 장애정도 판단 필요자란? 2011. 3. 31 이전 장애등록자를 말함.
    - (전체/필수) 장애 정도 심사용 진단서
    - (장애유형에 따라 / 지체, 뇌병변,  청각, 시각장애인) 장애유형별 소견서
    - (장애유형에 따라 / 지적, 자폐성장애인) 임상심리평가보고서
   
 ○ 기타
    - (직장생활을 하는 경우) 4대보험가입내역
    - (학교생활을 하는 경우) 재학증명서, 수업료 납부증명서 등
    - (가구환경 파악을 위해) 가족관계 증명서, 한부모 또는 조손 가족에 해당하는 증빙서류 등

4. 신청절차
 1) 읍면동에 문의(유선): 장애정도 판단 필요자인지 아닌지를 확인
 2) (장애정도 판단 필요자라면) 의료기관을 먼저 방문하여 필요한 신청 서류를 발급 받음.
 3) (필요에 따라) 기타 신청서류를 구비
 4) 읍면동 주민센터에 방문하여 신청서 작성 후 제출   

5. 선정절차
   - 신청서를 맞게 제출을 하였다면 아래와 같은 선정 절차를 거치게 됩니다.
 ○ 신청(읍면동사무소) -> 시군구 자료송부 --> 방문조사의뢰(국민연금공단) -> 방문조사 -> 수급자자격심사의뢰(수급자격심의위원회) -> 통과 시 -> 최종선정

6. 문의: 032-556-9294(활동지원팀)


기타 및 회원사업
○ 회원사업이란? 민들레장애인자립생활센터에 회비를 납부하여 총회 회원으로 활동자격을 얻거나 후원회원으로서 자격을 갖춘 분들을 위한 사업을 진행합니다. 
(문의: 032-542-9294)

- 보장구 관련 
ㄴ 보장구 수리: 케어114와 협약을 맺어 매 월 기관 방문하여 보장구 수리를 진행합니다.
ㄴ 보장구 대여: 전동휠체어, 시각장애인 안내 지팡이, 수동 휠체어 등의 보장구를 대여 지원합니다.

- 행사 관련
ㄴ 명절행사: 설과 추석 명절을 맞이하여 합동 차례와 음식 나누기 행사를 진행합니다.
ㄴ 후원행사: 본 기관을 후원해주시거나 정회원으로 회원활동을 하고 계시는 분들을 위하여 연 1회 이상 감사 증정품을 드립니다.
ㄴ 추모행사: 본 기관과 인연을 맺으신 분들을 위한 기일에 맞춰 추모행사를 진행합니다.
ㄴ 소풍 및 나들이: 회원분들 후원자분들과 함께 당일 소풍이나 1박 2일 캠프를 진행합니다.(코로나 여부에 따라 상이)

- 회원교육: 장애인 인권 및 장애인과 관련된 사회적 현상에 대한 교육을 진행합니다. 이외에도 주제에 맞춰서 다양한 교육을 진행하고 있습니다.

- 권익옹호 활동: 지역사회 장애인들이 살기좋은 환경을 만들기 위한 활동으로 장애인 차별상담전화를 운영하고, 현장에 나아가 편의시설 조사를 실시하며 정책 제안 등의 장애인 인권 현장에서 활발히 활동하고 있습니다.
', '', '', '', 'published', true, '2025-06-26 00:44:03.446242+00', 'de166ef3-1f14-4f14-ace8-1752517be700', '2025-06-26 00:44:03.488127+00', '2025-06-26 00:44:03.488127+00', NULL, 0, 0);
INSERT INTO public.pages VALUES ('ba6ac7e9-1f09-4e4f-862c-dc5a3cb88f41', 'cm', '후원안내', '후원안내

후원신청서 링크
★정기후원 원하실 경우 상단 링크를 이용하여 신청해 주시기 바랍니다.

-카드후원, 계좌출금 후원 가능

링크로 작성이 어려울 경우 아래 신청서 작성하여 메일로 보내주시거나 담당자에게 문의해주세요.

*기부금영수증 발급 원하실 경우 주민번호 뒷자리까지 작성 꼭!
홈텍스에서 확인 가능

★일시후원일 경우 국민(민들레장애인자립생활센터)720537-01-002394 입금 해주세요.
*기부금영수증 발급 원하실 경우 담당자 문의

★물품후원일(생활용품 등) 경우 담당자에게 문의 주세요.
*기부금영수증 발급 원하실 경우 담당자 문의

이메일: mincenter08@daum.net
문의: 032-542-9294(사무국장)', '', '', '', 'published', true, '2025-06-26 00:46:32.084423+00', 'de166ef3-1f14-4f14-ace8-1752517be700', '2025-06-26 00:46:32.137648+00', '2025-07-07 03:11:47.986909+00', NULL, 3, 0);
INSERT INTO public.pages VALUES ('fe1a2521-ac5d-4ff4-8c8e-af069350bf23', 'about', '민들레는요', '민들레는요

연혁
2008.05.28. 민들레장애인자립생활센터 설립
-소장: 박길연
2008.10.06. 자립생활주택(민들레홀씨1호)개소
2009.06.18. 1577-1330 장애인차별상담전화 운영단체 협약 체결
2010.01.16. 장애인보장구 무상점검 및 수리 자매결연-케어114
2010.07.14. 인천시 지원 자립생활주택(민들레홀씨2호)위탁기관 선정
2011.03.02. 인천시 지원 자립주택 1호 위탁기관 선정
2011.11.30. 장애인활동지원서비스제공기관 선정
2013.07.01. 인천시 지원 자립주택 2호 위탁기관 선정
2014. 01.01. 소장: 김순미
2014. 03. 05. 인천시장애인체육회 생활체육교실(보치아) 선정
2014. 10. 27~29. 탈시설캠프‘시친소(시설친구를소개합니다.)’1회
2015. 03. 05. 인천시장애인체육회 생활체육교실(전동휠체어축구) 선정
2015. 12. 26. 제1회 민들레센터 발달장애인 말하기대회 개최
2016. 02. 권익옹호 배움터 달달학교 진행
2016. 02. 26. 인천광역시 중증장애인자립지원센터 선정
2016. 04. 02. 전국장애인부모연대 계양지회 협약 체결
2016. 11. 2016 전국장애인전동휠체어축구대회 우승
2016. 11. 16~18. 탈시설캠프‘시친소(시설친구를소개합니다.)’2회
2017. 02. 03. 인천시장애인체육회 생활체육교실(전동휠체어축구) 선정
2017.04.01. 소장: 박길연
2017. 11. 16.~18. 탈시설캠프‘시친소(시설친구를소개합니다.)’3회
2017. 11. 탈시설안내책자 및 사례집 발간
2017. 11.  2017 전국장애인전동휠체어축구대회 우승
2018. 05. 지방선거 정당 정책토론회 주관
2018. 07. 인천시 지원 자립생활주택3호 위탁기관 지정
2018. 10. 경인지역 장애인전동휠체어축구대회 준우승
2018. 10. 10.~12. 탈시설캠프‘시친소(시설친구를소개합니다.)’4회
2019. 01. 07. 인천 중증장애인자립생활센터 지원사업 위탁기관 협약 체결
2019. 02. 11. 2019 장애포럼 참석
2019. 03. 01. 정태수열사상 수상(정명호 권익옹호팀 팀장)
2019. 06. 17. 고 권오진 동지 1주기 추모제
2019. 07. 01. 장애등급제 진짜 폐지 전동행진 참여
2019. 09. 18.~19. 2019 전동휠체어축구 전국대회 개최
2019. 09. 18.~19. 2019 전동휠체어축구 전국대회 4위 입상
2019. 09. 30.~10. 02. 탈시설캠프‘시친소(시설친구를소개합니다.)’5회
2019. 12. 06.~07. 자립생활대회(인천, 강원, 서울 센터 기관 모임)
2019. 12. 26. 권익옹호 활동가워크숍
2020. 01. 21. 민들레장애인자립생활센터 정기총회
2020. 02. 23. 고 한민희 동지 추모제
2020. 04. 08. 고 한민희 동지 49제
2020. 06. 17. 고 권오진 동지 2주기 추모제
2021. 04. 인천장애인체육회 생활체육지원사업(동호인클럽) 선정
2021. 06. 01. 소장: 양준호
2021. 06. 11. 케어114 업무협약 체결
2021. 07. 08. 연세힐링맘 상담센터 업무협약 체결
2022. 05. 08. 고 김은경 동지 기일
2023. 07. 09. 고 김은아 동지 기일
2024. 03. 12. 소장: 박길연 취임(법인대표  겸임)
2025. 01. 01. 소장: 서권일 취임 

주요사업

IL사업
동료상담, 권익옹호활동, 정보제공, 자조모임 등 다양한 사업기획 및 지원

 

자립지원사업
탈시설 및 탈재가장애인의 자립생활전환으로 거주공간을 마련, 자립생활기술 습득

 

활동지원사업
장애인이 지역사회에서 사회구성원으로 동등하게 살아갈 수 있도록 활동지원사 파견

 

기타
차별상담전화, 보장구수리 및 점검, 회원교육, 명절행사, 투쟁활동참여

 
위치
확대
축소
© NAVER Corp.
1000m

확대
축소
민들레장애인자립생활센터
인천광역시 계양구 계산동 1062 A-202

 
SNS 안내

유튜브(Youtube)
''민들레장애인자립생활센터''를 검색해주세요.

 

카카오톡플러스친구
카카오톡 친구추가에서 ''민들레장애인자립생활센터''를 검색해주세요.

', '', '', '', 'published', true, '2025-06-26 00:43:28.49677+00', 'de166ef3-1f14-4f14-ace8-1752517be700', '2025-06-26 00:43:28.549409+00', '2025-07-07 03:13:18.76603+00', NULL, 84, 0);


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.permissions VALUES ('ec04bc0b-5eec-4989-ab20-a6d455cb80ba', 'users.read', '사용자 목록 조회', 'users', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2', 'users.create', '사용자 생성', 'users', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('e2af9343-75e3-42db-a678-c24cc1eb9dda', 'users.update', '사용자 정보 수정', 'users', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('5cc786f4-510e-4e28-ab4d-f979ad2e90ab', 'users.delete', '사용자 삭제', 'users', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05', 'users.roles', '사용자 역할 관리', 'users', 'roles', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('188c9d63-b2a5-4f3a-88d3-4bf690ad715b', 'boards.read', '게시판 목록 조회', 'boards', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('fc591480-ce7e-494a-abb1-f05da3b43c00', 'boards.create', '게시판 생성', 'boards', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('c3f4db40-9e81-450e-884f-68f05a1b29ee', 'boards.update', '게시판 수정', 'boards', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('05c8baa1-c491-4ad2-a35b-28028214048b', 'boards.delete', '게시판 삭제', 'boards', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('dd955dd2-e944-4751-92b2-e9f4930d2171', 'posts.read', '게시글 목록 조회', 'posts', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('7ee6b121-79d5-451a-882a-e10e4b65c7b2', 'posts.create', '게시글 작성', 'posts', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('08e17652-fc1c-477f-874e-327ca6175930', 'posts.update', '게시글 수정', 'posts', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('240e0131-8cae-4bd6-90ac-c8f17c8daced', 'posts.delete', '게시글 삭제', 'posts', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('9eb4c166-f549-448f-9288-c1203f57f013', 'posts.moderate', '게시글 중재', 'posts', 'moderate', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6', 'comments.read', '댓글 목록 조회', 'comments', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a', 'comments.create', '댓글 작성', 'comments', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('10d069a2-3995-45ff-a240-050f1fee0a7c', 'comments.update', '댓글 수정', 'comments', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('586759ab-70e4-4909-81bc-cc9dbe76d64e', 'comments.delete', '댓글 삭제', 'comments', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('5447679d-6216-4454-b8fa-f0bd7d8bb5f9', 'comments.moderate', '댓글 중재', 'comments', 'moderate', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('38b38386-5b6a-4b4c-a774-dafb71663a9e', 'settings.read', '사이트 설정 조회', 'settings', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('420d1ca8-24a1-4091-91ea-21e8fd898d36', 'settings.update', '사이트 설정 수정', 'settings', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('53c54c43-725a-4ff2-96af-05b1f4a42600', 'menus.read', '메뉴 목록 조회', 'menus', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('7ae0adf5-6894-4f27-b5e3-9a1252b64d48', 'menus.create', '메뉴 생성', 'menus', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('c47f6b36-4cc9-43d9-bd58-6767eea06026', 'menus.update', '메뉴 수정', 'menus', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('18329519-90f5-4c46-bae3-fe8a96440dcf', 'menus.delete', '메뉴 삭제', 'menus', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('baf16a50-fe29-4664-ac57-aea87f27a8e1', 'pages.read', '페이지 목록 조회', 'pages', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('53faa02c-0729-4db5-a672-47a689310388', 'pages.create', '페이지 생성', 'pages', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae', 'pages.update', '페이지 수정', 'pages', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('f3115d94-6574-4dcd-a693-cded458f6ec2', 'pages.delete', '페이지 삭제', 'pages', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('d5fd800d-84e7-40d4-bb38-f802cbee49b3', 'calendar.read', '일정 목록 조회', 'calendar', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('61a2391f-ed6a-47f7-a87e-e45087740bd3', 'calendar.create', '일정 생성', 'calendar', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('c2083b31-4fa5-42dd-a264-679af6db51b2', 'calendar.update', '일정 수정', 'calendar', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('90e15cca-f259-459b-a06d-ae7589882259', 'calendar.delete', '일정 삭제', 'calendar', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('b819e4cd-d8f7-42b4-9adb-aeb96832dffd', 'roles.read', '역할 목록 조회', 'roles', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('a71eebce-7bd1-4e1b-ba19-a87eefe1298a', 'roles.create', '역할 생성', 'roles', 'create', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('06e77098-960c-4d8a-86a5-2919a5a463de', 'roles.update', '역할 수정', 'roles', 'update', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('c87367bc-5722-47b9-a8d1-29664d67328a', 'roles.delete', '역할 삭제', 'roles', 'delete', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('ba2168d1-a06b-491e-b73d-85f692a74fdb', 'permissions.read', '권한 목록 조회', 'permissions', 'read', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.permissions VALUES ('4ed5fa1f-bbb9-45fe-9e3c-95334b083c68', 'permissions.assign', '권한 할당', 'permissions', 'assign', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');


--
-- Data for Name: point_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.point_transactions VALUES ('322ea37f-2e60-4f8d-b39e-27cae4e42f63', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'earn', 10, '게시글 작성', 'post', '457143cd-0a02-4fca-9d70-a44cd1b37c78', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('209c39be-ce77-4238-9b30-de135007e662', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'earn', 10, '게시글 작성', 'post', '2d71edf5-ae14-47f1-8d98-2cfe7e9ef22a', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('49d6ad81-8c2a-4bec-99c8-1b5627827bfb', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'earn', 10, '게시글 작성', 'post', '60e89ffd-f783-49a0-914b-6367245c0827', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('cc2fe37a-a21e-4b89-9909-ee152599ef49', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'earn', 10, '게시글 작성', 'post', '5811f59a-fda2-4ccd-9574-232294bfd793', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('776c32d9-ef3c-4a33-af0c-4274b6631717', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'earn', 10, '게시글 작성', 'post', '82dd1e74-3e43-41a7-8b03-c5a99157e959', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('874b10ed-abe9-49d0-92bb-77392e47f296', '020a4cdc-2efb-447d-aafc-e4fe3a80d792', 'earn', 10, '게시글 작성', 'post', 'a425d804-becc-4569-8259-0fe1115db211', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('4f2e1884-dd94-40a3-bd78-1f7b00f731f1', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'earn', 10, '게시글 작성', 'post', 'a9128625-3515-4eb6-bdee-9c8bffa8c458', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('6de799a1-d070-4dd5-98e0-654c41d9d129', 'a32b2cb4-ac87-4bf0-ad40-c7fed30522e4', 'earn', 5, '댓글 작성', 'comment', 'ec3b6b4c-bac3-408e-a4d2-eb04304d87eb', '2025-06-25 15:01:27.803809+00');
INSERT INTO public.point_transactions VALUES ('0baa2add-6b1b-49f2-aced-ffc61ad03ee9', 'f0bd148f-7ca9-43fb-bbea-affb264b461d', 'earn', 5, '댓글 작성', 'comment', '30332d1d-949a-4fb4-a7a7-5dac17f92f1e', '2025-06-25 15:01:27.803809+00');


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.refresh_tokens VALUES ('90d2696d-3cee-4e9d-96fa-4d6e50e40dda', 'de166ef3-1f14-4f14-ace8-1752517be700', '5c7ce8266f53d7a6cb02f7346f15ab5d681036fc7f21a6837d1cd8e63c472426', 'admin', '2025-07-03 09:56:38.98933+00', '2025-06-26 09:56:38.98921+00', true);
INSERT INTO public.refresh_tokens VALUES ('b806232b-16ce-4195-8999-3ef154de6fd9', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'f2d003f2472a1d5e88a612c72f6de67b5cb1566d2a8c637f698159a955d1f091', 'site', '2025-07-12 13:15:46.973181+00', '2025-07-05 13:15:46.974508+00', true);
INSERT INTO public.refresh_tokens VALUES ('bc00d264-eff7-477f-aae1-7138795807b6', 'de166ef3-1f14-4f14-ace8-1752517be700', '824ea4925c700f60d3c2e6027369b95af49ab6f681f1e37f3f19759ac6419541', 'admin', '2025-07-03 13:19:08.260749+00', '2025-06-26 13:19:08.260815+00', true);
INSERT INTO public.refresh_tokens VALUES ('70269b74-d145-44e8-ad5f-2a68e7ac9b47', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '99fffb57c674985530044b3c6d6a41a90015d5324780a7be7bab4c5df333c1d1', 'site', '2025-07-12 16:08:42.30403+00', '2025-07-05 16:08:42.304209+00', true);
INSERT INTO public.refresh_tokens VALUES ('279876b5-b6df-4f9a-84f3-f3ef55e4b8b6', 'de166ef3-1f14-4f14-ace8-1752517be700', '7f8b4957a0da724358ea002991586cc8fb5ce140d4eb354dd7a4802e02c219d2', 'admin', '2025-07-12 22:31:47.239791+00', '2025-07-05 22:31:47.239925+00', true);
INSERT INTO public.refresh_tokens VALUES ('55e7c647-4337-4d5d-b491-12ebaec08158', 'de166ef3-1f14-4f14-ace8-1752517be700', 'f4f8c2fc43f70e0193f3ebb8061a084ee5a3986d726c6deeae367d54df69217e', 'admin', '2025-08-04 23:33:57.880458+00', '2025-07-05 23:33:57.926405+00', true);
INSERT INTO public.refresh_tokens VALUES ('88f33a91-3b29-45cc-9a94-f55a1984b0dd', 'de166ef3-1f14-4f14-ace8-1752517be700', 'e8fee0c2f8db6cbfc090c6994d3ca09386c12060f7196bd2fa1b58beeef45897', 'admin', '2025-07-13 00:07:49.27025+00', '2025-07-06 00:07:49.270739+00', true);
INSERT INTO public.refresh_tokens VALUES ('36ae407d-9511-42d0-9255-3faaca8da1fb', 'de166ef3-1f14-4f14-ace8-1752517be700', 'a5632a4b0a186cfed8898bf6e07c46aa4ecf480e998602cbffeed843e30a6d90', 'admin', '2025-07-25 18:39:18.652839+00', '2025-06-25 18:39:18.697428+00', true);
INSERT INTO public.refresh_tokens VALUES ('f93596f9-044c-4168-8424-6be61442840a', 'de166ef3-1f14-4f14-ace8-1752517be700', '3c54458b433032a693fed1d9887c18f41c296ec2fce1ab605c7a6e98fc69539f', 'admin', '2025-07-13 01:38:08.120759+00', '2025-07-06 01:38:08.120619+00', true);
INSERT INTO public.refresh_tokens VALUES ('f796b82a-8e45-4489-85e6-a8c74566abbe', 'de166ef3-1f14-4f14-ace8-1752517be700', '8fa4c2d9b000145556e0b7b6b55a3a6f360c9b6c754f0d63d9039736342d6e20', 'admin', '2025-07-11 11:11:06.325306+00', '2025-07-04 11:11:06.326123+00', true);
INSERT INTO public.refresh_tokens VALUES ('8e8356d3-bf2e-4f3a-811a-65b0216eff68', 'de166ef3-1f14-4f14-ace8-1752517be700', '0cd95d4cfb0e866f0b9b5c496a0b8a12bb8a3eeea4be35c54510ae1f2dc1d06e', 'admin', '2025-07-02 19:14:43.181931+00', '2025-06-25 19:14:43.179631+00', true);
INSERT INTO public.refresh_tokens VALUES ('bd6b5a26-c8b5-4b4d-b83e-987f12aa3c6b', 'de166ef3-1f14-4f14-ace8-1752517be700', 'd914954dc562c3468bb676a9db1858f9cbaaa92613cc49f2411aee9264b08c34', 'admin', '2025-07-03 00:41:51.687009+00', '2025-06-26 00:41:51.688945+00', true);
INSERT INTO public.refresh_tokens VALUES ('c72b82bd-ef40-4dd6-8769-a42ede75d17a', 'de166ef3-1f14-4f14-ace8-1752517be700', '49546b1f9bd392197050d0bb16abd917689bf1b87853e17b372972f9295a393f', 'admin', '2025-07-13 11:58:07.578884+00', '2025-07-06 11:58:07.579019+00', true);
INSERT INTO public.refresh_tokens VALUES ('baae444f-d3ff-4221-8ad0-aaeda13f0937', 'de166ef3-1f14-4f14-ace8-1752517be700', 'c8f181715219f7adc7102d1fa0457c1bb53f3d2debd5d810d09c187d24ff5bb9', 'admin', '2025-07-13 23:59:00.951436+00', '2025-07-06 23:59:00.947292+00', false);
INSERT INTO public.refresh_tokens VALUES ('0e2594ff-2a03-459f-9b07-c002d86e4e8c', 'de166ef3-1f14-4f14-ace8-1752517be700', '82dfb27942b23fc258d0bcd7a9752a8e20cc2ba61c749f12079358656af938b7', 'admin', '2025-07-03 04:13:02.177788+00', '2025-06-26 04:13:02.177923+00', true);
INSERT INTO public.refresh_tokens VALUES ('7643c964-c4bd-43df-8fc0-e378653650ff', 'de166ef3-1f14-4f14-ace8-1752517be700', '6dce6871002585e17ca57c1e0e2cb5e96d5aa1921ca11d5a3b45607c25c58d92', 'admin', '2025-07-03 07:31:40.781486+00', '2025-06-26 07:31:40.782359+00', true);
INSERT INTO public.refresh_tokens VALUES ('bd9c7843-0b4a-43a7-a06d-dfd0cf29479e', 'de166ef3-1f14-4f14-ace8-1752517be700', '10015d44d40f4dfa60e8f7bb5dca977a9bb30a09146fa0b73fa1c1af59277be0', 'admin', '2025-07-03 07:47:12.113928+00', '2025-06-26 07:47:12.113991+00', true);
INSERT INTO public.refresh_tokens VALUES ('f22231a8-78e9-4650-af65-6ab1769f5043', 'de166ef3-1f14-4f14-ace8-1752517be700', '67e958bd9d34af7892b45a6431be298798df502ea1c18fa68f281905cc8f2a78', 'admin', '2025-07-03 08:04:16.095492+00', '2025-06-26 08:04:16.095815+00', true);
INSERT INTO public.refresh_tokens VALUES ('ee5e9413-dc91-43b1-9eb9-a4406acec142', 'de166ef3-1f14-4f14-ace8-1752517be700', '93f8f9cf434775d583404a6e45ee8f24be2d52c0a3eae3b715a12daa9d12afb6', 'site', '2025-07-03 08:06:51.661565+00', '2025-06-26 08:06:51.661346+00', true);
INSERT INTO public.refresh_tokens VALUES ('f58eae0c-f50a-44ea-9623-9cda87b711c6', 'de166ef3-1f14-4f14-ace8-1752517be700', '0808d99e9b828254553c231a47b26dc5313cac4dc3a99c89d7c3a01eff380444', 'admin', '2025-07-03 08:43:09.625219+00', '2025-06-26 08:43:09.62613+00', true);
INSERT INTO public.refresh_tokens VALUES ('422e2015-683d-4446-9e56-f22546f1b5b5', 'de166ef3-1f14-4f14-ace8-1752517be700', 'a81c4b077e4ab26dafe3a0bdc95d936221c31e8d0a4e60dc2e318644c8200905', 'admin', '2025-07-03 08:58:44.208133+00', '2025-06-26 08:58:44.209763+00', false);
INSERT INTO public.refresh_tokens VALUES ('e46f1ef3-6cb8-465c-84d2-3f090963aa7f', 'de166ef3-1f14-4f14-ace8-1752517be700', '42c8d34e3d1073ad19cfddfe1fae2362230a99ecc2bd1cc9a2f9edd8248765b2', 'admin', '2025-07-26 09:09:10.003775+00', '2025-06-26 09:09:09.980013+00', true);
INSERT INTO public.refresh_tokens VALUES ('0144987c-366c-4806-9b85-b73a924af99d', 'de166ef3-1f14-4f14-ace8-1752517be700', '8d1c663f201d19be7d318001c93054b59ce55308fd0bb20b71a245689e76f35b', 'admin', '2025-07-03 09:25:10.114985+00', '2025-06-26 09:25:10.116012+00', true);
INSERT INTO public.refresh_tokens VALUES ('19342282-b8a5-4524-9553-b591ea733e68', 'de166ef3-1f14-4f14-ace8-1752517be700', 'f3408488cc16337b1ebc6b83f63e931364a937ecbdc61db210ccc05b45cb4dae', 'site', '2025-07-03 08:48:51.322007+00', '2025-06-26 08:48:51.322704+00', true);
INSERT INTO public.refresh_tokens VALUES ('4530b995-8459-48f9-8d32-c599d576e77a', 'de166ef3-1f14-4f14-ace8-1752517be700', '7b8b802a3d98f72d0eff5f2ceb16c2d4391f5ecfa3481221a336e5bf785aa4da', 'admin', '2025-07-03 13:51:28.907054+00', '2025-06-26 13:51:28.908333+00', true);
INSERT INTO public.refresh_tokens VALUES ('5b2aa164-5651-4934-aafc-d66cca6ea8c8', 'de166ef3-1f14-4f14-ace8-1752517be700', 'ca3d44678befa276d0cbcd16f1edddbece2fdc86980f6c4a11eb69723426c83b', 'admin', '2025-07-03 14:06:43.996989+00', '2025-06-26 14:06:43.997493+00', true);
INSERT INTO public.refresh_tokens VALUES ('0872c1fa-906b-4bba-92b8-9e457213e975', 'de166ef3-1f14-4f14-ace8-1752517be700', 'f96a0b88ca35044f4fd4c7c3b06213f7cf5fd22cc6b5335c91b6bd0b831615df', 'admin', '2025-07-03 14:29:53.728872+00', '2025-06-26 14:29:53.729403+00', true);
INSERT INTO public.refresh_tokens VALUES ('8cc7b592-721d-467a-869a-d8d3670645ec', 'de166ef3-1f14-4f14-ace8-1752517be700', 'c0b0340f870bb5076aa08bdc8c3a18c44ecbb1712124ef24ef5d107f8f11960f', 'admin', '2025-07-03 14:46:10.62693+00', '2025-06-26 14:46:10.627181+00', true);
INSERT INTO public.refresh_tokens VALUES ('336bb3a3-de0c-4f37-8831-288bd071e05e', 'de166ef3-1f14-4f14-ace8-1752517be700', '30fbdf3359f807e73a7e0eb7a0b326bcf8267f6f43feb98e93e32161709d68c3', 'admin', '2025-07-03 15:02:03.520088+00', '2025-06-26 15:02:03.523178+00', true);
INSERT INTO public.refresh_tokens VALUES ('6daf4ea6-ac2b-4f4a-b543-1b384de4af46', 'de166ef3-1f14-4f14-ace8-1752517be700', '07c21753a38fda868a47a2417fddfa22a55e15700f222e42941e554fc7cf6d9f', 'site', '2025-07-03 09:56:39.421743+00', '2025-06-26 09:56:39.421238+00', true);
INSERT INTO public.refresh_tokens VALUES ('75c27719-9f30-4d81-a61e-e999d2d82bd6', 'de166ef3-1f14-4f14-ace8-1752517be700', 'b4af1d5f283c902e89df8d482669a05600fba30e1d88577df4dbbfc6532cb867', 'admin', '2025-07-03 16:57:25.32264+00', '2025-06-26 16:57:25.322727+00', true);
INSERT INTO public.refresh_tokens VALUES ('9d7295b0-93ba-4919-b54f-08f4af515d20', 'de166ef3-1f14-4f14-ace8-1752517be700', '3519347e9e64cf8b02860364dcb78ee05da99bac923e00d37e754f2f855729ac', 'admin', '2025-07-03 15:18:22.220427+00', '2025-06-26 15:18:22.219904+00', true);
INSERT INTO public.refresh_tokens VALUES ('be55e133-400d-484d-b39e-2fcfbe826dc7', 'de166ef3-1f14-4f14-ace8-1752517be700', '3530eecbf3dbf30db427a385e1952eda0bc99162eab9f5872dd896a42707fefe', 'admin', '2025-07-03 16:35:57.5971+00', '2025-06-26 16:35:57.597752+00', true);
INSERT INTO public.refresh_tokens VALUES ('bcde06ae-6a35-4489-90af-e77d91772d4e', 'de166ef3-1f14-4f14-ace8-1752517be700', '3530eecbf3dbf30db427a385e1952eda0bc99162eab9f5872dd896a42707fefe', 'admin', '2025-07-03 16:35:57.597957+00', '2025-06-26 16:35:57.598507+00', true);
INSERT INTO public.refresh_tokens VALUES ('2911fa7a-1e7e-4e02-a627-9f98ac8a24cb', 'de166ef3-1f14-4f14-ace8-1752517be700', '3519347e9e64cf8b02860364dcb78ee05da99bac923e00d37e754f2f855729ac', 'site', '2025-07-03 15:18:22.713487+00', '2025-06-26 15:18:22.712681+00', true);
INSERT INTO public.refresh_tokens VALUES ('a8249701-cb78-4043-b011-3943d15f2b40', 'de166ef3-1f14-4f14-ace8-1752517be700', 'ab64b139363e51be6ba7f079f995ee39d1e85640cb8f528a7d8fb8565e11ccf6', 'admin', '2025-07-03 17:13:35.999805+00', '2025-06-26 17:13:36.00052+00', true);
INSERT INTO public.refresh_tokens VALUES ('7fe3ee5d-ca85-4179-9309-34c0b2986011', 'de166ef3-1f14-4f14-ace8-1752517be700', '263d89a15224d09af5d751c39bcb4c29db134954dd9067ee9e711501308e0cbb', 'site', '2025-07-03 18:10:19.963383+00', '2025-06-26 18:10:20.077512+00', true);
INSERT INTO public.refresh_tokens VALUES ('57253878-1236-49dd-8521-66638857cdbe', 'de166ef3-1f14-4f14-ace8-1752517be700', '263d89a15224d09af5d751c39bcb4c29db134954dd9067ee9e711501308e0cbb', 'admin', '2025-07-03 18:10:19.970285+00', '2025-06-26 18:10:20.084399+00', true);
INSERT INTO public.refresh_tokens VALUES ('63e621a7-628d-42d3-93b9-563d64ca833a', 'de166ef3-1f14-4f14-ace8-1752517be700', 'd914228f2c3a2bc567ed7da57e3a4173f4955d377dc66747af2a1bc1a891e155', 'site', '2025-07-04 13:05:18.609004+00', '2025-06-27 13:05:18.610736+00', true);
INSERT INTO public.refresh_tokens VALUES ('4f4f9b4a-667e-4c5f-be77-ab2cee13844e', 'de166ef3-1f14-4f14-ace8-1752517be700', 'd914228f2c3a2bc567ed7da57e3a4173f4955d377dc66747af2a1bc1a891e155', 'admin', '2025-07-04 13:05:18.673524+00', '2025-06-27 13:05:18.674226+00', true);
INSERT INTO public.refresh_tokens VALUES ('28cdeb84-980b-400e-8891-1452501b7094', 'de166ef3-1f14-4f14-ace8-1752517be700', '212ce0d4083cf8a986343e4d8a7c37cdd2320ca43f3218076392fa5ec675c116', 'site', '2025-07-04 13:45:42.72904+00', '2025-06-27 13:45:42.730255+00', true);
INSERT INTO public.refresh_tokens VALUES ('0c37bef3-1006-4ab6-a8f9-570cccf4231f', 'de166ef3-1f14-4f14-ace8-1752517be700', '212ce0d4083cf8a986343e4d8a7c37cdd2320ca43f3218076392fa5ec675c116', 'admin', '2025-07-04 13:45:42.787431+00', '2025-06-27 13:45:42.788335+00', true);
INSERT INTO public.refresh_tokens VALUES ('6070ec5d-1782-4483-9fa6-537228de7ead', 'de166ef3-1f14-4f14-ace8-1752517be700', 'df5d8f99549c4c977e3d2f2a3017c05189adb3297b608920b7f7535e44284080', 'site', '2025-07-04 17:02:42.051397+00', '2025-06-27 17:02:42.054282+00', true);
INSERT INTO public.refresh_tokens VALUES ('c5d38d87-ec3c-43ce-a228-af77ec988ef3', 'de166ef3-1f14-4f14-ace8-1752517be700', 'df5d8f99549c4c977e3d2f2a3017c05189adb3297b608920b7f7535e44284080', 'admin', '2025-07-04 17:02:42.061853+00', '2025-06-27 17:02:42.062451+00', true);
INSERT INTO public.refresh_tokens VALUES ('c8cdd2cb-6e9a-4d54-aa7f-4bc32c990897', 'de166ef3-1f14-4f14-ace8-1752517be700', '6db86e5ca146db52762762ca37f361d54222ef258b53a2be70997285311913c1', 'admin', '2025-07-04 23:59:37.222202+00', '2025-06-27 23:59:37.221411+00', true);
INSERT INTO public.refresh_tokens VALUES ('f0d43c9f-1081-498c-9fcc-960b133d2c21', 'de166ef3-1f14-4f14-ace8-1752517be700', '6db86e5ca146db52762762ca37f361d54222ef258b53a2be70997285311913c1', 'site', '2025-07-04 23:59:37.144132+00', '2025-06-27 23:59:37.143322+00', true);
INSERT INTO public.refresh_tokens VALUES ('9ff1d931-0ea9-4614-9003-d9c15eea41f6', 'de166ef3-1f14-4f14-ace8-1752517be700', '7b542e1103a37568c51096313246da481b140d6b5fe1643917bbfc6af18dc0bd', 'admin', '2025-07-05 20:10:38.997054+00', '2025-06-28 20:10:38.998846+00', true);
INSERT INTO public.refresh_tokens VALUES ('32773b91-d56b-40fb-a58f-656f2218c313', 'de166ef3-1f14-4f14-ace8-1752517be700', '660dd15705fac1ed64038d83f901a38f290385edaa0797407490f5681b73cdac', 'admin', '2025-07-06 04:31:56.805539+00', '2025-06-29 04:31:56.811323+00', true);
INSERT INTO public.refresh_tokens VALUES ('22a755a0-db86-4825-85ab-d2286b84f8c7', 'de166ef3-1f14-4f14-ace8-1752517be700', '7b542e1103a37568c51096313246da481b140d6b5fe1643917bbfc6af18dc0bd', 'site', '2025-07-05 20:10:39.003805+00', '2025-06-28 20:10:39.004523+00', true);
INSERT INTO public.refresh_tokens VALUES ('8fe08fd6-7df8-43de-8d7d-fd30dba228ce', 'de166ef3-1f14-4f14-ace8-1752517be700', 'ee36a9b4421dafba779c2990d0ada472aae1b67f9972dc068b15516ee93d3e2b', 'admin', '2025-07-11 15:16:59.045441+00', '2025-07-04 15:16:59.045742+00', true);
INSERT INTO public.refresh_tokens VALUES ('0cc6ba9c-d7df-417e-9808-7d9295f64bc6', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'cf5ec5389f9cf2426fc124d3fd4add2ec2c63ca811cc3483e805607588ffc0be', 'site', '2025-07-10 18:05:57.616808+00', '2025-07-03 18:05:57.617032+00', true);
INSERT INTO public.refresh_tokens VALUES ('0a00ad7e-9fdc-4e8c-b46a-707c57186f3f', 'de166ef3-1f14-4f14-ace8-1752517be700', 'c0eadf55e5aa325cdf4ffff77c114734191e787c2e235848e49c289abb47db7f', 'admin', '2025-07-06 04:50:45.372881+00', '2025-06-29 04:50:45.373135+00', true);
INSERT INTO public.refresh_tokens VALUES ('f7e2166a-8b7f-4306-a223-f163b7a90c01', 'de166ef3-1f14-4f14-ace8-1752517be700', '2c00a3700ec55eb66c5e33bcb9b9b0767908b601b3535f5a110834dd90176ab1', 'site', '2025-07-06 05:01:20.014148+00', '2025-06-29 05:01:20.014838+00', true);
INSERT INTO public.refresh_tokens VALUES ('668ecbaf-0881-4871-b60d-f5edb435aed2', 'de166ef3-1f14-4f14-ace8-1752517be700', 'ba634cf8f02b1597aad9c7b39e0f261aa540603ac9e24c767518c12028499d5b', 'admin', '2025-07-06 07:03:44.750004+00', '2025-06-29 07:03:44.750772+00', true);
INSERT INTO public.refresh_tokens VALUES ('f8fd789c-279e-4d82-bcc8-c9618677ff33', 'de166ef3-1f14-4f14-ace8-1752517be700', '5fd0a956c36b878d6d2ea9532fe7a73ab1f12fa6549cdf84d7931689a4a1794a', 'site', '2025-07-06 07:18:26.329345+00', '2025-06-29 07:18:26.32995+00', true);
INSERT INTO public.refresh_tokens VALUES ('a76fce39-d45e-4b85-8345-cd81751f3e57', 'de166ef3-1f14-4f14-ace8-1752517be700', 'a3b6ce3f27975c7396a9ff6e5283ef03ee5c673da99e103acb8057a81356bc37', 'site', '2025-07-06 07:43:58.167141+00', '2025-06-29 07:43:58.168208+00', true);
INSERT INTO public.refresh_tokens VALUES ('c51b2d04-6568-4f31-97fa-7e31e2fc5978', 'de166ef3-1f14-4f14-ace8-1752517be700', '23cfde254c180464fa7aa1bb6c5a0e639ec26d24e664afd9d1d3629bb74c5955', 'admin', '2025-07-06 07:24:07.036813+00', '2025-06-29 07:24:07.037809+00', true);
INSERT INTO public.refresh_tokens VALUES ('fac57809-95b3-4cd9-99c7-eeaaf8acf45b', 'de166ef3-1f14-4f14-ace8-1752517be700', '858bcc4bc5df559c634e8a989387dbbaae8d4e7b350339d2b1a77e5591155d4a', 'admin', '2025-07-06 08:16:17.596792+00', '2025-06-29 08:16:17.597388+00', true);
INSERT INTO public.refresh_tokens VALUES ('cd086e46-5de9-42fb-8c12-1635201e17b1', 'de166ef3-1f14-4f14-ace8-1752517be700', '6fff226f1664113080ee0052c806c4205f607c132b2c6a8ec782bc18f6fbd3af', 'admin', '2025-07-06 19:13:29.333205+00', '2025-06-29 19:13:29.333491+00', false);
INSERT INTO public.refresh_tokens VALUES ('99980044-61bd-4df8-92b1-2e1c04e1697d', 'de166ef3-1f14-4f14-ace8-1752517be700', '858bcc4bc5df559c634e8a989387dbbaae8d4e7b350339d2b1a77e5591155d4a', 'site', '2025-07-06 08:16:17.414891+00', '2025-06-29 08:16:17.415206+00', true);
INSERT INTO public.refresh_tokens VALUES ('645701ec-11d5-46a0-9838-b92ccd506a00', 'de166ef3-1f14-4f14-ace8-1752517be700', '6fff226f1664113080ee0052c806c4205f607c132b2c6a8ec782bc18f6fbd3af', 'site', '2025-07-06 19:13:29.415229+00', '2025-06-29 19:13:29.415751+00', false);
INSERT INTO public.refresh_tokens VALUES ('3a12aaff-64f0-43aa-920f-13b8b63e75d3', 'de166ef3-1f14-4f14-ace8-1752517be700', 'b9b012f66030f7728a1ba9aa8114b9bd5e8b8a42a55b90a7b9bacad0718e624d', 'admin', '2025-07-12 08:21:13.987285+00', '2025-07-05 08:21:13.990972+00', true);
INSERT INTO public.refresh_tokens VALUES ('3804d8ed-c439-4153-8e8a-71beb8385686', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '1d05c2cc71400c14950fbc28223491455a8794e97d1a59c9749f294ad4f0d664', 'site', '2025-07-12 12:59:55.321863+00', '2025-07-05 12:59:55.323072+00', true);
INSERT INTO public.refresh_tokens VALUES ('ddd6e2e1-4e9a-4982-a84f-d7ada74719d7', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '8ca23b6aef901d149a8347fb37575b562e5ba30f5968357c6342eb73af90996b', 'site', '2025-07-12 13:40:00.110291+00', '2025-07-05 13:40:00.109068+00', true);
INSERT INTO public.refresh_tokens VALUES ('4dfebecd-9e7f-4394-a49e-6accdb2fd5ae', 'de166ef3-1f14-4f14-ace8-1752517be700', 'aacf6122e2ac89fbb44a84dc66d866b44b761343a2a2517077937833dd7eb0de', 'admin', '2025-07-12 16:40:53.33719+00', '2025-07-05 16:40:53.338513+00', true);
INSERT INTO public.refresh_tokens VALUES ('af5ea018-9cf2-45b3-87e6-5ef8633449be', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ad6bb3aa8ac7ca16b516eac9ac299adfb911f77868e0549c3640bcb2c39453cf', 'site', '2025-07-12 16:58:55.038704+00', '2025-07-05 16:58:55.038228+00', true);
INSERT INTO public.refresh_tokens VALUES ('c402d3a4-3397-4d74-ae16-1d033b91d540', 'de166ef3-1f14-4f14-ace8-1752517be700', '87138d4a7218d4196397a19d57f2bf55bcf41f257ab0ce65805b6c27433c76c8', 'admin', '2025-07-12 22:47:06.705933+00', '2025-07-05 22:47:06.706+00', true);
INSERT INTO public.refresh_tokens VALUES ('207fb549-e13e-4e47-a791-de333fb4745c', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '6070e3f691d462e2acdc42febdcf5ebe4f9cbdc6dab129781b5ae8c75480d289', 'site', '2025-07-12 23:34:25.429983+00', '2025-07-05 23:34:25.439149+00', true);
INSERT INTO public.refresh_tokens VALUES ('c266aaac-1f41-41a6-8a95-64400ba676c7', 'de166ef3-1f14-4f14-ace8-1752517be700', 'b1f5931913533b3331c51be086d2cb666683ea29ddd7f8bd14a97f062df27322', 'admin', '2025-08-02 19:29:40.319913+00', '2025-07-03 19:29:40.323063+00', true);
INSERT INTO public.refresh_tokens VALUES ('28a97374-1bd2-4e04-be4f-c4b2d4a5eec4', 'de166ef3-1f14-4f14-ace8-1752517be700', 'b6f4a7deef159cd73742ef99edcc9f2c34229916fbde1beb186fb61df181f529', 'admin', '2025-07-10 20:28:08.964391+00', '2025-07-03 20:28:08.964687+00', true);
INSERT INTO public.refresh_tokens VALUES ('b44315bd-8be2-4664-a5a6-e3087d634e32', 'de166ef3-1f14-4f14-ace8-1752517be700', '488543bd3e772a51488dc6b72631d5386a81d1aa61c192e5f75a7206597b917c', 'admin', '2025-07-13 00:30:43.216856+00', '2025-07-06 00:30:43.216914+00', true);
INSERT INTO public.refresh_tokens VALUES ('37112371-901c-4f09-804b-c65613714c92', 'de166ef3-1f14-4f14-ace8-1752517be700', '71a7816ea19ab5f17ac8d451c0fe4976051e6742561b8a4ed847af62d71690e5', 'admin', '2025-07-13 11:10:14.98186+00', '2025-07-06 11:10:14.982902+00', true);
INSERT INTO public.refresh_tokens VALUES ('bf6fcf8f-69d9-45cb-84de-5ef3ec5938b2', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '6aa25f17adb6f8cad4162f576afbeffce2ca10e31b825bac009fae104554082a', 'site', '2025-07-12 07:15:27.421084+00', '2025-07-05 07:15:27.420681+00', true);
INSERT INTO public.refresh_tokens VALUES ('408b04d4-36c1-4a37-bb3b-3b9751c19ebb', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '4dd940eb3e86df5e8ff2b912d229be351994d86578f046d5c0f209e946fef7b6', 'site', '2025-07-10 16:02:57.738465+00', '2025-07-03 16:02:57.738306+00', true);
INSERT INTO public.refresh_tokens VALUES ('1e28df57-ac06-4764-a171-1a66139ecaa9', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ce10f00b45ee5ad8ed326264f0c7a80095d99b338f68cd9cc9c1e4900a836a14', 'site', '2025-07-10 16:19:54.808973+00', '2025-07-03 16:19:54.809111+00', true);
INSERT INTO public.refresh_tokens VALUES ('f7386689-5f81-4015-bb43-1119b3318fbf', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e8765ec465d3a25d902a5ed202215c06a681cce35db6d91d1c5f62fa242a25e7', 'site', '2025-07-10 17:24:04.530838+00', '2025-07-03 17:24:04.532819+00', true);
INSERT INTO public.refresh_tokens VALUES ('37154c7c-b955-4144-af42-0d21991c3079', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '13439aa1e38dd3df41798db71c93efe68742e22fbe286c9113dea8c3923f9d12', 'site', '2025-07-02 15:02:33.68501+00', '2025-06-25 15:02:33.685383+00', true);
INSERT INTO public.refresh_tokens VALUES ('5b8384a5-b016-4032-bbef-8c59447dbe5b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '777f6e0e2c3a0842d9d108586f983f0f1572d33232f9e8a18532c1eb38578300', 'site', '2025-07-02 15:43:08.288336+00', '2025-06-25 15:43:08.288544+00', true);
INSERT INTO public.refresh_tokens VALUES ('5fefdc63-6fea-4cdd-9a11-7a1d2b2fdfbd', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '45b834ad46527e31fd55220df610fd508b8d3700a7da63d8199231dbe231d47d', 'site', '2025-07-02 16:49:19.205533+00', '2025-06-25 16:49:19.205499+00', true);
INSERT INTO public.refresh_tokens VALUES ('9c2f20ed-aa54-4b3b-bb67-9829a8967d7f', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'eabfafe91aa25de3feefdfb1ae8a31def5e1a1fe1b13af141dd0fce975a6b962', 'site', '2025-07-02 18:11:19.402253+00', '2025-06-25 18:11:19.399862+00', true);
INSERT INTO public.refresh_tokens VALUES ('5a078428-9448-4bd7-a4a5-dd66be2d2c06', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '94d87a903a2880d06f50eb9dc25575230608ab8c8b2bf757be42d531276a0ede', 'site', '2025-07-02 18:40:12.46204+00', '2025-06-25 18:40:12.461641+00', true);
INSERT INTO public.refresh_tokens VALUES ('871396e9-08c1-44cd-9ce9-d0aa507de065', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '1bce9b92a5331391226b052eb37bf0fcb86f26595833638e164e4af9fe009c4b', 'site', '2025-07-02 19:14:44.031488+00', '2025-06-25 19:14:44.027585+00', true);
INSERT INTO public.refresh_tokens VALUES ('ce8d24f1-d612-4b6f-9d90-350d2b40d7f2', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'a2186ff245fae5121cfc081643a108f3cb170f5c3d778e0261e43674963c23fd', 'site', '2025-07-02 23:29:19.11665+00', '2025-06-25 23:29:19.1164+00', true);
INSERT INTO public.refresh_tokens VALUES ('795be81e-4ecb-4aef-9662-904b362f1a59', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'f8ab31ae62e80157811e757d52d70e6516f250dd20db34755d912c260c454810', 'site', '2025-07-03 00:41:29.714984+00', '2025-06-26 00:41:29.715757+00', true);
INSERT INTO public.refresh_tokens VALUES ('543c45a3-648b-49e0-a0d4-01672cacaac1', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '878abe95ec2d73871e8564ae4b40a23af9dc1a4a1bf2b177ff90769310ea02d2', 'site', '2025-07-10 18:26:15.231228+00', '2025-07-03 18:26:15.231616+00', true);
INSERT INTO public.refresh_tokens VALUES ('99c444d7-32df-4738-a4d2-67c010179348', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '335f18904bfdd991f43febd3f3ddd6eb6a5ec151a09a0485f79b98cafd7ead86', 'site', '2025-07-11 14:05:02.661343+00', '2025-07-04 14:05:02.661989+00', true);
INSERT INTO public.refresh_tokens VALUES ('1b372a67-e7af-487f-a8d8-b748cd328ca1', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ecd1c5f357a1256dbe537aa2c4d9f516d6c5de0c0e90fc24ea6e672eb1e04d0a', 'site', '2025-07-11 14:23:24.061071+00', '2025-07-04 14:23:24.065423+00', true);
INSERT INTO public.refresh_tokens VALUES ('6e7963f4-ad26-4f55-9b66-2f01aaea1e55', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'de007f463a4582d9a1f8d0b0982898489787496dcf5093e1e7adfbb6a9bb3b8f', 'site', '2025-07-11 16:15:08.948755+00', '2025-07-04 16:15:08.946111+00', true);
INSERT INTO public.refresh_tokens VALUES ('6ebc2b11-d7a6-44ae-a41a-2a71a887cbbd', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'fbef10b6463b56b46890d8577d8c4c241530f46c11e25ea544128666a37c3d9e', 'site', '2025-07-12 08:38:49.840266+00', '2025-07-05 08:38:49.840581+00', true);
INSERT INTO public.refresh_tokens VALUES ('730222ed-49a3-44be-a524-c8d0e9c2010f', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'fa377da096fa5155b7e56d20e07475dfcea62cbfbd7ba0f4fa0aeb97f613378c', 'site', '2025-07-12 12:22:50.984986+00', '2025-07-05 12:22:50.985124+00', true);
INSERT INTO public.refresh_tokens VALUES ('3b6718eb-14e0-4a4b-a2d3-b1157aa3be6c', 'de166ef3-1f14-4f14-ace8-1752517be700', 'ca1d334de62cfcb61588783ab310e2028ad4ce9d6b4f764b7ae97e969240c23b', 'admin', '2025-07-13 12:18:23.675816+00', '2025-07-06 12:18:23.676557+00', true);
INSERT INTO public.refresh_tokens VALUES ('1f1ef8ca-a50b-4573-8e49-5416b3e87e97', 'de166ef3-1f14-4f14-ace8-1752517be700', 'c8f181715219f7adc7102d1fa0457c1bb53f3d2debd5d810d09c187d24ff5bb9', 'admin', '2025-07-13 23:59:00.986822+00', '2025-07-06 23:59:00.980422+00', false);
INSERT INTO public.refresh_tokens VALUES ('f1d5e1dc-a72d-412d-8200-0273869137c5', 'de166ef3-1f14-4f14-ace8-1752517be700', 'a2783940453bc262febf8cecab7da35e411c80eea9d377d6219bdd388a2187de', 'admin', '2025-07-14 00:23:10.751719+00', '2025-07-07 00:23:10.751842+00', true);
INSERT INTO public.refresh_tokens VALUES ('7c0f5caa-b29c-4372-82bc-7c9f123e3525', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'f3f6704591aba3758a5d3a9ca9b4865fadbf88636d54c7a16a265a6a3006b52e', 'site', '2025-07-14 00:49:49.419689+00', '2025-07-07 00:49:49.420536+00', true);
INSERT INTO public.refresh_tokens VALUES ('c4867d33-ce89-49af-be60-91b60e6ca9ba', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '948d7cc3b534b7f673697a7dfab8ad3a0d47e161bfc873b1f24860c4c32923d3', 'site', '2025-07-14 01:42:00.889076+00', '2025-07-07 01:42:00.889543+00', true);
INSERT INTO public.refresh_tokens VALUES ('0886b453-a57d-49ca-b7e7-7dfe59649cad', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '1bcd0534ae1c25689b476844e394719936b43da92a52d22e5dd8d02630db3469', 'site', '2025-07-14 03:02:51.620716+00', '2025-07-07 03:02:52.003252+00', true);
INSERT INTO public.refresh_tokens VALUES ('5b585d46-8d81-4dc1-9597-4c8a56e5a73e', 'de166ef3-1f14-4f14-ace8-1752517be700', '37367bbab151786912d061ad53a45f630da97f4bf8297e604dca34a62370ef53', 'admin', '2025-07-14 03:11:55.576964+00', '2025-07-07 03:11:55.576709+00', true);
INSERT INTO public.refresh_tokens VALUES ('cb5525d7-f65b-4aa8-93fb-e3dd4a4a15b7', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '5d68f5b82319c6459353125a7280e628173ca9e2454d50eb57bc982e082e613d', 'site', '2025-07-14 03:37:46.136876+00', '2025-07-07 03:37:46.137456+00', true);
INSERT INTO public.refresh_tokens VALUES ('7a92eae9-005b-4c2c-b378-af5c4ffd0144', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e43934c65b6d9998048a29bb7264b074b20edf9de8b81cedd3da0cf193ec5dd7', 'site', '2025-07-14 05:01:56.14688+00', '2025-07-07 05:01:56.147177+00', false);
INSERT INTO public.refresh_tokens VALUES ('a1668b4f-930f-4212-bc4c-230b9b6658ad', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '648a34dac74319e5a51b5c6d671fc2bfa3bf4e9c32a5327174b976b80ed9c8a5', 'site', '2025-07-12 14:29:03.777065+00', '2025-07-05 14:29:03.776625+00', true);
INSERT INTO public.refresh_tokens VALUES ('476a651e-01bf-477c-8d6d-e4082eb7ff6f', 'de166ef3-1f14-4f14-ace8-1752517be700', 'eb7e52e584bb192edf0fef37a38270ee5135c8d35a4d6abac9c06dc7625ec5cb', 'admin', '2025-07-12 17:28:12.400019+00', '2025-07-05 17:28:12.400148+00', true);
INSERT INTO public.refresh_tokens VALUES ('3f667bfb-fd15-45a3-9bed-44e31260c6f6', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'ee9c015fc18810b7b20fb0a8e8e778d223ea96afe73d96977dedb9f2507d972a', 'site', '2025-07-12 23:00:58.090188+00', '2025-07-05 23:00:58.090304+00', true);
INSERT INTO public.refresh_tokens VALUES ('1c7b76a1-6c1b-49e7-ba2e-58ce5147d750', 'de166ef3-1f14-4f14-ace8-1752517be700', 'a231378b450a15dd635a53a3a8247336c55d855678c6dad46c8f2066b91e017e', 'admin', '2025-07-12 23:49:03.721894+00', '2025-07-05 23:49:03.722973+00', true);
INSERT INTO public.refresh_tokens VALUES ('180597df-c804-4306-8f6e-84ced2904957', 'de166ef3-1f14-4f14-ace8-1752517be700', '1065ae60961a5c1e2177a7ec306c9f1ddc67d3be47c38d9018de974aa15c4e1f', 'admin', '2025-07-13 00:46:02.714011+00', '2025-07-06 00:46:02.719298+00', false);
INSERT INTO public.refresh_tokens VALUES ('9325a95c-13c3-4ec4-b791-bc679de09da0', 'de166ef3-1f14-4f14-ace8-1752517be700', '40e37cc0ca2a88aceda47b3cdfc820d4aaea1e61b480e54625e79268a338c4c7', 'admin', '2025-07-13 11:27:23.814157+00', '2025-07-06 11:27:23.815001+00', true);
INSERT INTO public.refresh_tokens VALUES ('41c465ad-e80a-4584-a9ad-178a3a5941d8', 'de166ef3-1f14-4f14-ace8-1752517be700', '270ab47122eac99a01cbf5225ebc3a084462e3f60aa77f35f85775addbe70190', 'admin', '2025-07-13 12:41:33.796384+00', '2025-07-06 12:41:33.796477+00', true);
INSERT INTO public.refresh_tokens VALUES ('3ad0ae80-b5ed-4623-9fca-8ce955a71532', 'de166ef3-1f14-4f14-ace8-1752517be700', '3178fe2b9274116b619f3e478552aa87dfb8fb1ca8ac34c46313fd2387a63e17', 'admin', '2025-08-05 23:59:12.119891+00', '2025-07-06 23:59:12.122118+00', true);
INSERT INTO public.refresh_tokens VALUES ('071ad3c8-f433-493e-8d3b-69a3e33a8e2c', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '030e063d0d9789b300a66820d42c02c78cefa62143e1b55170787c15afe7f6bb', 'site', '2025-07-14 00:30:27.75752+00', '2025-07-07 00:30:27.757471+00', true);
INSERT INTO public.refresh_tokens VALUES ('90569684-8514-404a-a517-d0c39766200e', 'de166ef3-1f14-4f14-ace8-1752517be700', 'b4e04b46f424f910400ceb4d602d74111135f05bc70494f9333bd703cfd948f5', 'admin', '2025-07-10 20:57:09.558095+00', '2025-07-03 20:57:09.50806+00', true);
INSERT INTO public.refresh_tokens VALUES ('b8aa72dc-4b30-4065-9493-33a1736aef66', 'de166ef3-1f14-4f14-ace8-1752517be700', '7f302487ea2e0ab9f73b3227eca29e986c0dc60c2feda4fedb71b333733ada68', 'admin', '2025-07-11 14:07:01.604849+00', '2025-07-04 14:07:01.605336+00', true);
INSERT INTO public.refresh_tokens VALUES ('0358ff47-89b7-490d-bc70-641c20d666cd', 'de166ef3-1f14-4f14-ace8-1752517be700', 'e8b80b300918165b0c5a0ba04ea4c517b04bdecfef08b58c531195041a028a21', 'admin', '2025-07-14 01:17:05.205959+00', '2025-07-07 01:17:05.204548+00', true);
INSERT INTO public.refresh_tokens VALUES ('d7948311-275f-499e-a0e3-0bf0a20b0e36', 'de166ef3-1f14-4f14-ace8-1752517be700', '84ed3788994fb6736bd666fcc5b081fbc2ca5b470b1500c72cc44139145ff057', 'admin', '2025-07-11 16:41:21.245533+00', '2025-07-04 16:41:21.2458+00', true);
INSERT INTO public.refresh_tokens VALUES ('bc4ea11d-7daf-4216-9a57-a1d7224e1466', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '24e3092a1fd00e169dc7d5df9c3a47f0cbff2e67c018374082da25e1039f4681', 'site', '2025-07-14 01:58:02.658194+00', '2025-07-07 01:58:02.658458+00', true);
INSERT INTO public.refresh_tokens VALUES ('abf293eb-634f-4567-a950-bb4870a961d0', 'de166ef3-1f14-4f14-ace8-1752517be700', '3f3bdc7ec9b87a9de46662792648381b59833fdef48f54a110ee3e3452d6a9e0', 'admin', '2025-07-12 08:38:48.033709+00', '2025-07-05 08:38:48.034064+00', true);
INSERT INTO public.refresh_tokens VALUES ('149ccac8-9617-49ff-be8f-15bb893c17ef', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '7b3ebe14dfc07065516148631c0d50a51b9699944bb5918fa65f19853b6b2e61', 'site', '2025-07-14 02:26:36.961456+00', '2025-07-07 02:26:36.960746+00', true);
INSERT INTO public.refresh_tokens VALUES ('687be60e-6594-4f19-9e43-5da1b43f091b', 'de166ef3-1f14-4f14-ace8-1752517be700', '19284a007a7ba27250f82d7ebb60c5342661f0a47919a1faac14a2d1b998941d', 'admin', '2025-07-14 02:16:34.709242+00', '2025-07-07 02:16:34.71157+00', true);
INSERT INTO public.refresh_tokens VALUES ('1ccba29c-20e1-426c-aea5-35966b4aa35f', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '614f6437131931f23a53163d23b156b65f84cac89185eb07f0037dd46c1a9e8a', 'site', '2025-07-14 03:19:31.720177+00', '2025-07-07 03:19:31.720859+00', true);
INSERT INTO public.refresh_tokens VALUES ('50f22481-fec1-4f95-bd0e-daed52f131f3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'bad36a61ec3124bf727fa4323e70e5f4e4c9307851e909ee571e36cef2a0d154', 'site', '2025-07-14 04:00:07.33573+00', '2025-07-07 04:00:07.336004+00', true);
INSERT INTO public.refresh_tokens VALUES ('ed8ea46c-5c36-4832-b870-57b4b0840fed', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'd35e10c0d40731e42021464a37b5e64260dd844896b14822adcaaad2566cf521', 'site', '2025-07-10 16:35:49.90438+00', '2025-07-03 16:35:49.904433+00', true);
INSERT INTO public.refresh_tokens VALUES ('f531ef70-b459-4f7a-a227-b596c0d45a21', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '2eab09dfa0885e853c43f9bbe96e80238a3404131f37f673093a8abd5d502cd4', 'site', '2025-07-10 17:39:44.649894+00', '2025-07-03 17:39:44.65048+00', true);
INSERT INTO public.refresh_tokens VALUES ('06e0ec82-df86-41d7-8716-393471db2073', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '148bc36b498f0e9816bd011f246909b42d4016dbade025df831958bdbd502993', 'site', '2025-07-03 04:13:03.272286+00', '2025-06-26 04:13:03.271848+00', true);
INSERT INTO public.refresh_tokens VALUES ('4eb59a3a-f47f-49c0-b12a-b0caa9c2ae30', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'c03f5eb25fe33c79a0e6bf342a3cd0aba2d91de5d7a545c59bcc7596787bf034', 'site', '2025-07-07 02:50:59.131461+00', '2025-06-30 02:50:59.13159+00', true);
INSERT INTO public.refresh_tokens VALUES ('d2d7ea27-a938-4520-92fc-64b5e17531b0', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'c53491ed542dae22aa890e7a243d78d06be349a17aadd416e6167c8b57a91d09', 'site', '2025-07-07 03:07:48.375204+00', '2025-06-30 03:07:48.375161+00', true);
INSERT INTO public.refresh_tokens VALUES ('238a8902-a950-4ac9-9842-d2b1fbc91c54', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'b63812db204bc05cd55d20b2dfd8adc4b0f798b7643377f1be905f3da06e4139', 'site', '2025-07-07 03:18:09.361748+00', '2025-06-30 03:18:09.362443+00', true);
INSERT INTO public.refresh_tokens VALUES ('c2a0e813-3e58-482b-a80e-648566be8918', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '1799d27ecc578e62735021312e86e5b6f218bd09e897e34f1105484d13bfde90', 'site', '2025-07-07 03:34:17.434981+00', '2025-06-30 03:34:17.43565+00', true);
INSERT INTO public.refresh_tokens VALUES ('c6b64940-a9db-49de-9f6e-597a2289a602', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '51756f17ba4c6027229fe0e12e3ddcf57569ed52407df77a0a613084c03f7e43', 'site', '2025-07-07 03:34:37.110511+00', '2025-06-30 03:34:37.111432+00', true);
INSERT INTO public.refresh_tokens VALUES ('7b5633f8-4702-477d-9f05-33b1eb651bc8', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e663ff16a15e9e350c3bc8b1448628018f36ab51a468ef856b8135b73f83b6bf', 'site', '2025-07-07 03:50:50.862466+00', '2025-06-30 03:50:50.863049+00', true);
INSERT INTO public.refresh_tokens VALUES ('7b2aa5cc-2130-408d-a328-fc97b4fdcc9f', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'f81685ef552cbde49db69f4a6918362553fd04095cb90e1bb6dc242b51df463b', 'site', '2025-07-10 12:00:38.778508+00', '2025-07-03 12:00:38.778877+00', true);
INSERT INTO public.refresh_tokens VALUES ('42851452-438c-427f-bbc0-3b9be739fc3a', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '5d58e3744be34e829444c6d731b8a42f50f8a7339b2dabdb74b060518eb11146', 'site', '2025-07-10 13:34:23.995846+00', '2025-07-03 13:34:23.995875+00', true);
INSERT INTO public.refresh_tokens VALUES ('8e697a8e-f62d-4bdb-bf65-3eeafe279ab8', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '58c10eeb5aa3adcee1f46b2bd0c4744db9ec6a593d9a213b2a4edc0bc6e6d9d0', 'site', '2025-07-12 15:04:10.567131+00', '2025-07-05 15:04:10.567566+00', true);
INSERT INTO public.refresh_tokens VALUES ('4177765d-7836-46f7-a5ef-2ab36a5e5086', 'de166ef3-1f14-4f14-ace8-1752517be700', '71bb519f93de56beddab460996e977f23d8c37d4e624df66e7b284b913bc0376', 'admin', '2025-07-12 12:07:31.175945+00', '2025-07-05 12:07:31.174547+00', true);
INSERT INTO public.refresh_tokens VALUES ('e3762491-74ac-424a-87d8-658723e48469', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'd0c640d2660ff96a33bca0e72b4e0c3bf7afd9f783e21754fa11738f78bcea07', 'site', '2025-07-12 17:28:13.221352+00', '2025-07-05 17:28:13.221973+00', true);
INSERT INTO public.refresh_tokens VALUES ('9bc3c0e0-aa52-4ee8-ab79-be5d4167c02b', 'de166ef3-1f14-4f14-ace8-1752517be700', '5a3c84c94905a438d981788f81d5826499d793b572cf3edb415d237dfb87e858', 'admin', '2025-07-12 23:19:16.469558+00', '2025-07-05 23:19:16.764765+00', false);
INSERT INTO public.refresh_tokens VALUES ('018b65c8-8a52-4303-9308-27cbe6f986f7', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'f7056c75bfebeaf42974e55f868a508bb51943d548624ca870c09737cfd083ab', 'site', '2025-07-12 23:19:17.007279+00', '2025-07-05 23:19:17.302543+00', true);
INSERT INTO public.refresh_tokens VALUES ('1140c2ad-841c-4601-b5fa-c886256a418c', 'de166ef3-1f14-4f14-ace8-1752517be700', 'f047498ae8425e65b8b0c5d4062f323aca95b53f7733639fbc46e3678bc9982c', 'admin', '2025-07-10 21:28:20.201901+00', '2025-07-03 21:28:20.201847+00', true);
INSERT INTO public.refresh_tokens VALUES ('5067c258-4ab8-4d2e-8882-06875f9adde2', 'de166ef3-1f14-4f14-ace8-1752517be700', '73cac45f7662194f928804d17bda21ef7f25c2ebe1be70e153d24225d9fe2b82', 'admin', '2025-08-05 01:18:20.361358+00', '2025-07-06 01:18:20.405301+00', true);
INSERT INTO public.refresh_tokens VALUES ('0e8c8d1d-5976-4daf-945d-a686a653516a', 'de166ef3-1f14-4f14-ace8-1752517be700', 'c54e04ca76522582306b1326cc8f3ef27a0f046d3314cfc80e89296e15ea7ae5', 'admin', '2025-07-12 02:20:07.32726+00', '2025-07-05 02:20:07.327529+00', true);
INSERT INTO public.refresh_tokens VALUES ('65b292c1-ff4f-47ca-9848-ec7d71ae0dbf', 'de166ef3-1f14-4f14-ace8-1752517be700', '3cf5bd2b2559a40ae55c1363c11272840e62396bec19375d87e2a0d32718af39', 'admin', '2025-07-13 11:42:38.914958+00', '2025-07-06 11:42:38.916524+00', true);
INSERT INTO public.refresh_tokens VALUES ('6713c952-4df9-4536-9c51-0ea28cb346fd', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e4ee8af16bb0080dc1dac5a00e0ceba6109d2595bde1b7141076f7565735342f', 'site', '2025-07-10 15:41:39.369687+00', '2025-07-03 15:41:39.370228+00', true);
INSERT INTO public.refresh_tokens VALUES ('4e44fb7a-3633-44df-bc83-9c538607e8c1', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '3268040edb4ac5d16e86880b8075dbf7b27eba08ea219daad056e84c1da08822', 'site', '2025-07-10 17:07:10.415871+00', '2025-07-03 17:07:10.416025+00', true);
INSERT INTO public.refresh_tokens VALUES ('3fde9b3b-dae0-4973-9878-b96ba556aab4', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '0b875b534f549441169b106d52353674ae0f10fe8e5e8b35434db097d42c77e5', 'site', '2025-07-02 15:02:27.761381+00', '2025-06-25 15:02:27.762197+00', true);
INSERT INTO public.refresh_tokens VALUES ('31369d09-e9e6-48cb-8045-4e5e637de859', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '9aed6336ada14947603c34feccb3b5f7b9c718ccf8a7ce5d878e8b1c4f578a0e', 'site', '2025-07-10 19:22:45.485442+00', '2025-07-03 19:22:45.485203+00', true);
INSERT INTO public.refresh_tokens VALUES ('d3ced486-baf2-4dff-8c8e-381c78db0652', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '8b6a1e4402f9bb0702b65673c174a668ab15ac610304963b120ef316cbf8c0e0', 'site', '2025-07-10 20:13:34.082917+00', '2025-07-03 20:13:34.083749+00', true);
INSERT INTO public.refresh_tokens VALUES ('1b88d46c-6fff-4ee3-90af-9b4880143ab1', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '8d9b6a36b772c88b9b1cac0e7bfbd49aa9fe0a4282f400ba13ba8d7d13b96fc3', 'site', '2025-07-11 11:11:07.747365+00', '2025-07-04 11:11:07.747526+00', true);
INSERT INTO public.refresh_tokens VALUES ('223147ef-1066-42c8-a6cb-5bd2c199bb81', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '33b7f5f825956d651d929ba245ef5b7dd00ef95c4d80f8204b0985efa12b74aa', 'site', '2025-07-11 15:17:00.206083+00', '2025-07-04 15:17:00.206161+00', true);
INSERT INTO public.refresh_tokens VALUES ('ddd0132c-18bc-443b-bd56-ce4d2545f02f', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'c5365d32879d209bf7aff53835b3e1db391c6d92fe3be98d05b474d0365a0744', 'site', '2025-07-07 04:24:38.397411+00', '2025-06-30 04:24:38.397134+00', true);
INSERT INTO public.refresh_tokens VALUES ('cc2706d3-4244-4230-8821-fda0c8993275', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'db563d5a5a2846aec76621d95a1b58c69e876d9e24711f049597c0d252d6ecc4', 'site', '2025-07-10 11:07:57.118092+00', '2025-07-03 11:07:57.118799+00', true);
INSERT INTO public.refresh_tokens VALUES ('bcd6113d-b9c4-45c6-baae-682de4fa55d6', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e4546f2c9f5301f4ef0906e953940be9af499a49c79332f1371e88ffb261db16', 'site', '2025-07-10 11:33:45.233753+00', '2025-07-03 11:33:45.234362+00', true);
INSERT INTO public.refresh_tokens VALUES ('b0568940-c955-4366-9307-e00c589085ba', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '0cdd10d2267df41b3826a3e8b32a286f38de77ca0b8638e50a76e1313b727b38', 'site', '2025-07-10 18:41:43.532338+00', '2025-07-03 18:41:43.532685+00', true);
INSERT INTO public.refresh_tokens VALUES ('2a6f676f-0b96-4ab5-9ba3-17f23f73d0c3', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '7268eee19ee5d86f2b617e1b480372c94238551ea665531acc3e5be798f38271', 'site', '2025-07-10 19:38:50.017167+00', '2025-07-03 19:38:50.018046+00', true);
INSERT INTO public.refresh_tokens VALUES ('04d886db-af15-47e4-97cd-e2d6d1e02ecd', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '6e9627042101fc908f0b5486f96cc387c29b74c4f7851732747b629fcff84888', 'site', '2025-07-11 16:41:22.402585+00', '2025-07-04 16:41:22.401733+00', true);
INSERT INTO public.refresh_tokens VALUES ('fd08f08f-981c-43a8-80d4-3881b6765d2c', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '9ceeee1497c0eea96c885bacf00692cd06de41c0ec1dda6ece8d04ee12e72227', 'site', '2025-07-12 07:56:28.540994+00', '2025-07-05 07:56:28.541089+00', true);
INSERT INTO public.refresh_tokens VALUES ('8a4db49a-dd5a-454b-b1f2-76f9be8eeba4', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '41e4008e0edc8985c6df4e5d4c9bb4a18725449cb000313279fd1728a97808a0', 'site', '2025-07-12 12:39:52.236516+00', '2025-07-05 12:39:52.236579+00', true);
INSERT INTO public.refresh_tokens VALUES ('a74e02d4-4c85-4888-9513-c538855b8821', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '878a58d522e3940884f197bdebaa994149e40c4e4f9fc97549473b5bf2dba38f', 'site', '2025-07-10 14:33:40.583426+00', '2025-07-03 14:33:40.583247+00', true);
INSERT INTO public.refresh_tokens VALUES ('7891d05b-e394-430e-8c61-fb74de3d2d8b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '33b83c0409162c45c204894fb0e1cc43138e75ba520fafa14978d4078e5412c2', 'site', '2025-07-10 14:55:26.761989+00', '2025-07-03 14:55:26.762978+00', true);
INSERT INTO public.refresh_tokens VALUES ('30a3fdc3-30bc-4c4e-9003-ebb34a39ff4a', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e02405567bfe14f0f95a951dc8bf31c16cfbc847f206bbd3b54416c447b7c7a0', 'site', '2025-07-10 15:12:16.655053+00', '2025-07-03 15:12:16.656144+00', true);
INSERT INTO public.refresh_tokens VALUES ('93ead747-a1ca-47a9-bfa5-1a552a9bef4a', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'f92a6a2a7f5bcdc9a42f9fc64371e19e7faf83c2cbd4a1c9e9f59b3c2f76bba2', 'site', '2025-07-10 15:24:17.694904+00', '2025-07-03 15:24:17.696289+00', true);
INSERT INTO public.refresh_tokens VALUES ('496702f8-e018-4781-a78d-a549b7b11dc8', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'c9ebecf54e61e05338376a9d6d2492e2006c30c4594c6d45e0aad3ad63dcce05', 'site', '2025-07-10 16:51:15.265457+00', '2025-07-03 16:51:15.26577+00', true);
INSERT INTO public.refresh_tokens VALUES ('26836f29-023a-4f40-9f8e-c9eb75f32f9b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'd0b547aeae7ce15bedf7bb269144d36503d08bcc25448f4fc2a8a796bb16c69b', 'site', '2025-07-10 18:00:25.047524+00', '2025-07-03 18:00:25.04817+00', true);
INSERT INTO public.refresh_tokens VALUES ('e9af7277-abd1-4a29-8c9b-acb1ced9942d', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '8580f66075d10137306bb4c0506c501cb26543edc69b1dc9ee0820167a2d0d1a', 'site', '2025-07-10 18:58:01.515303+00', '2025-07-03 18:58:01.515748+00', true);
INSERT INTO public.refresh_tokens VALUES ('aad07375-d9d2-496c-a9d0-9e1ff0f56511', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'b2c652a05e4f31e6adf2389fe4aafee1d7dd816479c88bcc6fe28c3cfc7f360e', 'site', '2025-07-10 19:54:30.257425+00', '2025-07-03 19:54:30.259808+00', true);
INSERT INTO public.refresh_tokens VALUES ('952c9cd1-89c8-47ab-9372-36b13dd82356', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'adaa35b7f702123e4d7795be53302669fe5bf8986c04c000b5e3aa78c52ccb55', 'site', '2025-07-10 21:28:21.689486+00', '2025-07-03 21:28:21.68905+00', true);
INSERT INTO public.refresh_tokens VALUES ('c6caeca3-d8c4-4c5a-8f32-7e27e21181cd', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '105850ac813c00089dad89372ddd3ae050b727623d0c8fc84842dbb6f6f96eff', 'site', '2025-07-11 14:52:23.091932+00', '2025-07-04 14:52:23.092462+00', true);
INSERT INTO public.refresh_tokens VALUES ('96642c2a-c396-41d3-ac3d-4672c62ac758', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'aaa99a7550275c25f5e0ce025bd6aec1831cd4ad80579c2709ea1a199779d346', 'site', '2025-07-12 02:20:07.968855+00', '2025-07-05 02:20:07.96966+00', true);
INSERT INTO public.refresh_tokens VALUES ('7aa386b3-1ab6-466e-9c68-5dd18ac3d3a5', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '3c0c11755f2f0ef70521dd5da1dbc66a0d07b1141affa84a909a071a46eb2152', 'site', '2025-07-12 08:15:21.381824+00', '2025-07-05 08:15:21.384025+00', true);
INSERT INTO public.refresh_tokens VALUES ('1886cb48-c2ac-430d-a364-14167bc99160', 'de166ef3-1f14-4f14-ace8-1752517be700', '3cf5bd2b2559a40ae55c1363c11272840e62396bec19375d87e2a0d32718af39', 'admin', '2025-07-13 11:42:38.966224+00', '2025-07-06 11:42:38.965976+00', true);
INSERT INTO public.refresh_tokens VALUES ('28f07fd2-96b1-439b-8e9b-a746d13d8631', 'de166ef3-1f14-4f14-ace8-1752517be700', '48d31df26b1d4fd139b032622c4ccb8318adacf6969b2140ae0d1476010e68b3', 'admin', '2025-07-14 00:38:46.969738+00', '2025-07-07 00:38:46.972677+00', true);
INSERT INTO public.refresh_tokens VALUES ('756bc09f-a67b-401f-9a5d-6b63961167af', 'de166ef3-1f14-4f14-ace8-1752517be700', '64c76ef83c9ad1be270934701acdbc2e60ca097b2327dd4a2b35fa5ad456ce35', 'admin', '2025-07-13 23:19:26.78462+00', '2025-07-06 23:19:26.785297+00', true);
INSERT INTO public.refresh_tokens VALUES ('edb06ebb-e031-4df4-9c44-6a8a7e7c088b', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'e3c47a95f3044a1f24523b7a14b5f4a0d349a5eca0625e9baa9ef38f8c2d7c15', 'site', '2025-07-12 23:55:50.378399+00', '2025-07-05 23:55:50.380632+00', true);
INSERT INTO public.refresh_tokens VALUES ('fa92e237-b3fc-4b66-966c-965c5ee4a631', 'de166ef3-1f14-4f14-ace8-1752517be700', 'a2783940453bc262febf8cecab7da35e411c80eea9d377d6219bdd388a2187de', 'admin', '2025-07-14 00:23:10.750373+00', '2025-07-07 00:23:10.750693+00', true);
INSERT INTO public.refresh_tokens VALUES ('433614c9-419e-4b78-8a34-db1cdbb63072', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '37b527f5cf8fee8db127dfebee51adf461ad7859258046e224e2782c51cf7899', 'site', '2025-07-14 01:25:55.043801+00', '2025-07-07 01:25:55.046365+00', true);
INSERT INTO public.refresh_tokens VALUES ('6d7429f1-a616-41c9-bded-471d7f262eb0', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '284c914f4be507608bb2564bd09dbed76c802825b948ffa3e1461880ab6c4441', 'site', '2025-07-14 02:45:05.074242+00', '2025-07-07 02:45:05.005825+00', true);
INSERT INTO public.refresh_tokens VALUES ('70bedcde-fc77-4f98-b2ad-84451d7a0a6a', 'de166ef3-1f14-4f14-ace8-1752517be700', '66068ba70e812b250733ac825752e5f39c3f595740dbaf9287f7c0298d00626b', 'admin', '2025-07-14 03:36:15.465689+00', '2025-07-07 03:36:15.466434+00', false);
INSERT INTO public.refresh_tokens VALUES ('2af44f3a-168f-450e-bca7-b92f55465bfc', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'fbdd1c7e923d479859a84f58a37d00a3e9671b0375f00252d6f9787327970d17', 'site', '2025-07-14 04:15:13.535663+00', '2025-07-07 04:15:13.534816+00', true);
INSERT INTO public.refresh_tokens VALUES ('c62c0277-4ec9-427a-a09f-f740fee80f07', '26b43586-7447-4f58-a2a9-6b2ddea56c57', 'eea6143aecd5ce88635fdc02afd6ea15f32da44570a5c5839be42222635b2c79', 'site', '2025-07-14 04:30:53.837165+00', '2025-07-07 04:30:53.836834+00', true);


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.roles VALUES ('8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'super_admin', '시스템 전체 관리자 - 모든 권한을 가짐', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.roles VALUES ('7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'admin', '일반 관리자 - 대부분의 관리 기능 사용 가능', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.roles VALUES ('950fce82-5b3a-4b1b-b2f1-8f67557ed209', 'moderator', '중재자 - 게시글과 댓글 관리', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.roles VALUES ('4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', 'editor', '편집자 - 콘텐츠 작성 및 편집', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.roles VALUES ('3ae58427-d64c-417e-903c-fee48fd5b5e5', 'viewer', '조회자 - 읽기 전용 권한', true, '2025-07-06 01:04:07.727488+00', '2025-07-06 01:04:07.727488+00');


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.role_permissions VALUES ('d4b1c7aa-86b0-45ee-8141-4a35aed07867', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'ec04bc0b-5eec-4989-ab20-a6d455cb80ba', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('e15db4b8-332b-4ca6-9229-116dfc9f00a4', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('0f05fc41-ae11-4ae1-8873-128aced01017', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'e2af9343-75e3-42db-a678-c24cc1eb9dda', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('e6784cc9-2b01-4f93-bd84-339fb4d1916a', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '5cc786f4-510e-4e28-ab4d-f979ad2e90ab', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('64d785ee-0289-4d67-9665-75a60eebd97f', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('258c28f0-e299-4a37-bc89-d16ec3319cb5', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '188c9d63-b2a5-4f3a-88d3-4bf690ad715b', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('bc1b4486-85eb-4dc1-9bda-97fb34468184', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'fc591480-ce7e-494a-abb1-f05da3b43c00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('3e376549-9d49-4f46-a341-dc53542365b5', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'c3f4db40-9e81-450e-884f-68f05a1b29ee', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('7c5dce08-3436-4f93-9895-845abc89aba9', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '05c8baa1-c491-4ad2-a35b-28028214048b', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('86375ee2-f541-48c9-b2ad-2a2802cca933', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'dd955dd2-e944-4751-92b2-e9f4930d2171', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('ffd77548-4a1b-4c99-85c5-4eaf7a123138', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '7ee6b121-79d5-451a-882a-e10e4b65c7b2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('50bc4198-eeee-409d-8772-bf71d8f93a7d', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '08e17652-fc1c-477f-874e-327ca6175930', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('ddded639-e0f5-403d-aedf-74deadf3c08c', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '240e0131-8cae-4bd6-90ac-c8f17c8daced', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('7f39f705-0884-4bf5-880c-0d26b471a332', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '9eb4c166-f549-448f-9288-c1203f57f013', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('b350209f-690c-4085-ba9e-e6e101a825af', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('c5d3a2e3-8d5f-42d5-8e69-4fe8ac75f159', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('18fcc6c9-9141-47c8-90aa-2957ebaf1b09', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '10d069a2-3995-45ff-a240-050f1fee0a7c', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('0906b890-7049-4772-8680-b25567c67353', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '586759ab-70e4-4909-81bc-cc9dbe76d64e', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('3b760865-12e2-4105-aa3e-b46ecb21da66', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '5447679d-6216-4454-b8fa-f0bd7d8bb5f9', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('7aec941f-e7ec-480e-85a4-b5fbe351e32f', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '38b38386-5b6a-4b4c-a774-dafb71663a9e', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('231f9dea-a69b-4ad7-a1bf-86f865fadd5f', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '420d1ca8-24a1-4091-91ea-21e8fd898d36', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('76a01de3-1e91-491f-8a8a-976f92fd6634', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '53c54c43-725a-4ff2-96af-05b1f4a42600', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('56f9dc53-7bfc-4ad8-bc43-370e22928877', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '7ae0adf5-6894-4f27-b5e3-9a1252b64d48', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('c7dd73b9-e5f6-4ef2-bc1b-2ec2637e41ef', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'c47f6b36-4cc9-43d9-bd58-6767eea06026', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('5d4392d4-adff-4b70-84df-caecce873e28', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '18329519-90f5-4c46-bae3-fe8a96440dcf', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('db06c4c4-b3f1-4ac0-9f1f-78541394e8c6', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'baf16a50-fe29-4664-ac57-aea87f27a8e1', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('fdf2a3a0-0faf-4460-819f-51dbc40956ca', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '53faa02c-0729-4db5-a672-47a689310388', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('d4dea1dd-a2c5-494b-ab86-7abcf6aa589c', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('171453fd-85cf-42ff-820e-d10b8c199d20', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'f3115d94-6574-4dcd-a693-cded458f6ec2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('45b917a2-8817-43fe-9ca8-4ae41d0c5717', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'd5fd800d-84e7-40d4-bb38-f802cbee49b3', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('302a8d5e-a46f-4d29-9abf-f7f6efd72912', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '61a2391f-ed6a-47f7-a87e-e45087740bd3', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('d5d10aad-ac94-43de-aa9f-9588a8220308', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'c2083b31-4fa5-42dd-a264-679af6db51b2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('f9d88f0f-f44f-4013-a339-6cf73b3fec09', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '90e15cca-f259-459b-a06d-ae7589882259', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('9964bb88-c42f-4626-8053-1e78b066c332', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'b819e4cd-d8f7-42b4-9adb-aeb96832dffd', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('4e07e858-5fe3-41d6-943a-5f4e04662252', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'a71eebce-7bd1-4e1b-ba19-a87eefe1298a', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('9d8628d0-87a3-4657-8654-5ef751851aab', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '06e77098-960c-4d8a-86a5-2919a5a463de', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('4baf1ef2-808b-42e7-91a1-29485d846bdc', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'c87367bc-5722-47b9-a8d1-29664d67328a', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('ded4876b-8ebd-4811-9c23-86391ec9ed28', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', 'ba2168d1-a06b-491e-b73d-85f692a74fdb', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('a659a212-d899-48f9-bf3e-dab283fa6b61', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '4ed5fa1f-bbb9-45fe-9e3c-95334b083c68', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('5ee7165f-c837-4a1e-bb79-447a150ab3af', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'ec04bc0b-5eec-4989-ab20-a6d455cb80ba', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('80598380-17ba-4e5d-9834-04c89f304524', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '6896df6f-1cc4-4d9c-b2bc-a2ed4aef8ed2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('e40a1095-749e-4697-a8b0-3ae09e8bf92e', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'e2af9343-75e3-42db-a678-c24cc1eb9dda', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('bbf27ad0-7c3a-4dad-8d8d-b0f42f594bd4', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '5cc786f4-510e-4e28-ab4d-f979ad2e90ab', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('5e620e02-bb9f-475e-8673-654b9a02ab90', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '05ebc297-1aff-4d7d-8c0f-6b4ade9e7c05', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('dc8fc296-05a6-48c3-b290-13dfd5268b3f', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '188c9d63-b2a5-4f3a-88d3-4bf690ad715b', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('1a2fe248-9586-4d5f-8e72-3bd3a0153e63', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'fc591480-ce7e-494a-abb1-f05da3b43c00', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('9f9eecd6-308d-470b-aa04-142c92f2df28', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'c3f4db40-9e81-450e-884f-68f05a1b29ee', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('99e1567f-2b6f-4735-a469-edfdedfb29de', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '05c8baa1-c491-4ad2-a35b-28028214048b', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('eed971dc-ac62-4b69-b0cc-a7a152084163', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'dd955dd2-e944-4751-92b2-e9f4930d2171', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('734b58f7-f615-4f5f-a408-9c0759d3bc88', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '7ee6b121-79d5-451a-882a-e10e4b65c7b2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('71f9d85a-8b13-4ab3-93c2-c9976889f950', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '08e17652-fc1c-477f-874e-327ca6175930', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('6d504af3-a756-470b-b2ec-bed4f05c76a9', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '240e0131-8cae-4bd6-90ac-c8f17c8daced', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('bd0d6269-723b-4ce6-95d8-b408a37a8666', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '9eb4c166-f549-448f-9288-c1203f57f013', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('f14e7882-de8a-4c0b-ab5a-0ff377ba43cf', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('6121e618-c21a-46f6-a057-05ae2960e590', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('2bf80cc6-aab8-49ec-b35b-c70cd12ee0a0', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '10d069a2-3995-45ff-a240-050f1fee0a7c', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('d05abd3d-a5e1-4a5f-964b-077c76274bbf', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '586759ab-70e4-4909-81bc-cc9dbe76d64e', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('8dcee32a-997a-458d-83c5-a5e9ca9251e8', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '5447679d-6216-4454-b8fa-f0bd7d8bb5f9', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('3a496fef-1489-44ee-8aff-9784c6519a77', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '38b38386-5b6a-4b4c-a774-dafb71663a9e', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('90317c32-7985-4eb2-ae58-c4ec6802ccb3', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '420d1ca8-24a1-4091-91ea-21e8fd898d36', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('f57698f4-0631-414e-88f4-1cd6b720140c', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '53c54c43-725a-4ff2-96af-05b1f4a42600', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('efffa2fe-865a-4bbb-a033-ec300190cbc4', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '7ae0adf5-6894-4f27-b5e3-9a1252b64d48', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('93d8c3e7-4bdf-4cb9-b003-a9da2c1c35b7', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'c47f6b36-4cc9-43d9-bd58-6767eea06026', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('6cf30329-3f9c-499a-aedc-7ec7056c2626', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '18329519-90f5-4c46-bae3-fe8a96440dcf', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('e7907006-b9ef-4294-b76f-5f77ea6a5f82', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'baf16a50-fe29-4664-ac57-aea87f27a8e1', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('dfa063ab-0c46-487b-94d3-024f8f01547e', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '53faa02c-0729-4db5-a672-47a689310388', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('1a54c565-7778-4095-92fd-1ea2a2af1f67', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '5e0a75e7-d4ac-4a8f-aabc-2fe7637150ae', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('b7fa2904-e169-457a-b8fd-cf276da93793', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'f3115d94-6574-4dcd-a693-cded458f6ec2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('46afa25d-0cf9-46e6-aabc-fdd6e90d3017', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'd5fd800d-84e7-40d4-bb38-f802cbee49b3', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('6142e7bd-e5e2-43bb-a9dc-6985fdc7c537', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '61a2391f-ed6a-47f7-a87e-e45087740bd3', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('ee00170d-301c-42b9-9df4-c5afb80575ec', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', 'c2083b31-4fa5-42dd-a264-679af6db51b2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('c27ec8e8-94b3-4152-b07b-7bbe1f2d3053', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '90e15cca-f259-459b-a06d-ae7589882259', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('162da1ad-84c3-4d3b-8d69-ca710a1a9a8d', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '188c9d63-b2a5-4f3a-88d3-4bf690ad715b', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('db54b664-a0d4-40e1-82a6-e6d74bcc8636', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', 'dd955dd2-e944-4751-92b2-e9f4930d2171', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('c4f45770-14c5-4a56-b44a-a1b5ef4372b0', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '7ee6b121-79d5-451a-882a-e10e4b65c7b2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('e69024d8-ebae-4ca5-87c9-a7eb2b9d31b2', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '08e17652-fc1c-477f-874e-327ca6175930', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('e73c9316-9aa2-4c1e-a73c-be3a18b71c4b', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '240e0131-8cae-4bd6-90ac-c8f17c8daced', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('83583fc5-eb53-4c1a-9c4a-563ac37f1edf', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '9eb4c166-f549-448f-9288-c1203f57f013', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('395ce212-22c4-44f9-8afb-13d630b54334', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('0580a21a-54c7-4561-a8fa-eb674dfe7c89', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('1f97bb8e-618c-4f1c-8639-04d84ddeb1cf', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '10d069a2-3995-45ff-a240-050f1fee0a7c', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('a1068c2f-9cd4-40f8-b9e8-dcd4beb3989c', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '586759ab-70e4-4909-81bc-cc9dbe76d64e', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('3e0615d0-d7bf-4ba5-a802-2663738bb313', '950fce82-5b3a-4b1b-b2f1-8f67557ed209', '5447679d-6216-4454-b8fa-f0bd7d8bb5f9', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('9424fb8f-e332-4e95-aef0-bf9e788e2bfa', '4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', '7ee6b121-79d5-451a-882a-e10e4b65c7b2', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('750134c5-28de-4f5e-95df-6d9266c0d913', '4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', '08e17652-fc1c-477f-874e-327ca6175930', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('8124fb71-9236-41ba-9bae-d0771a070924', '4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', '1213ae8b-eedc-4f1a-bbd4-a2625eb65d0a', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('dee36103-7bf8-4170-b950-c55fc1b660e2', '4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', '10d069a2-3995-45ff-a240-050f1fee0a7c', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('8c5e0b29-7344-4c2f-9f3f-1599258b23d6', '3ae58427-d64c-417e-903c-fee48fd5b5e5', 'ec04bc0b-5eec-4989-ab20-a6d455cb80ba', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('fee7595f-091c-43f4-a554-3e4d253cccfd', '3ae58427-d64c-417e-903c-fee48fd5b5e5', '188c9d63-b2a5-4f3a-88d3-4bf690ad715b', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('5d4b8978-3b17-49ba-9ea5-93dafb19936c', '3ae58427-d64c-417e-903c-fee48fd5b5e5', 'dd955dd2-e944-4751-92b2-e9f4930d2171', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('9e622045-4a20-43ae-823d-3c8154629ba1', '3ae58427-d64c-417e-903c-fee48fd5b5e5', '0b2b682b-ddec-4ce0-be98-ffcbd61cdfc6', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('de479f90-7999-4bda-bf59-07c193e94720', '3ae58427-d64c-417e-903c-fee48fd5b5e5', '38b38386-5b6a-4b4c-a774-dafb71663a9e', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('0e911688-0e83-4912-8a29-6bf1cf80058a', '3ae58427-d64c-417e-903c-fee48fd5b5e5', '53c54c43-725a-4ff2-96af-05b1f4a42600', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('9efff941-26e5-4cf8-ab97-63ad19c846a7', '3ae58427-d64c-417e-903c-fee48fd5b5e5', 'baf16a50-fe29-4664-ac57-aea87f27a8e1', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('3ce39d31-08bb-4326-b9d1-66d2a3f2cccf', '3ae58427-d64c-417e-903c-fee48fd5b5e5', 'd5fd800d-84e7-40d4-bb38-f802cbee49b3', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('155ad68c-df65-4310-977f-cc98c9e0caab', '3ae58427-d64c-417e-903c-fee48fd5b5e5', 'b819e4cd-d8f7-42b4-9adb-aeb96832dffd', '2025-07-06 01:04:07.727488+00');
INSERT INTO public.role_permissions VALUES ('c1644735-cc7a-4ebc-b5d7-dc8d9a2f5273', '3ae58427-d64c-417e-903c-fee48fd5b5e5', 'ba2168d1-a06b-491e-b73d-85f692a74fdb', '2025-07-06 01:04:07.727488+00');


--
-- Data for Name: site_info; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.site_info VALUES ('7486aeef-6900-41cc-954a-2d7eb82c449d', '민들레장애인자립생활센터', '함께 만들어가는 따뜻한 세상', '인천광역시 계양구 계산새로71 A동 201~202호(계산동, 하이베라스)', '032-542-9294', 'mincenter08@daum.net', 'https://mincenter.kr', '2025-07-06 00:34:32.735633+00', '2025-07-06 00:49:48.281244+00', '032-232-0739', '박길연', '131-80-12554', '');


--
-- Data for Name: site_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.site_settings VALUES ('8e913fe0-4563-4fca-b930-e8866ead0f81', 'site_name', '따뜻한 마음 봉사단', '사이트 이름', '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.site_settings VALUES ('fc8dd5a1-6de9-4e35-9303-552045febcfb', 'max_file_size', '10485760', '최대 파일 업로드 크기 (10MB)', '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.site_settings VALUES ('140c993b-a506-4089-90a2-10a763be4674', 'points_per_post', '10', '게시글 작성 시 적립 포인트', '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.site_settings VALUES ('61ad73a6-70b1-434a-a518-6fb3dd969b15', 'points_per_comment', '5', '댓글 작성 시 적립 포인트', '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');
INSERT INTO public.site_settings VALUES ('c4a6fbf3-5ffc-4a5e-b606-d3d61a464135', 'draft_expire_days', '7', '임시저장 만료 일수', '2025-06-25 14:55:57.619579+00', '2025-06-25 14:55:57.619579+00');


--
-- Data for Name: sns_links; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: token_blacklist; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_roles VALUES ('2c57e921-bfc8-44fa-9ccf-4278c30eaed2', 'de166ef3-1f14-4f14-ace8-1752517be700', '8251bd9c-7c8c-4a86-bf60-4e9189a4c5fa', '2025-07-06 11:06:22.212544+00');
INSERT INTO public.user_roles VALUES ('398ac58b-4696-48a6-8a10-7a29871ee10d', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '7f188600-b0ed-4dc6-bcdb-74c9916989ed', '2025-07-06 12:00:15.714394+00');
INSERT INTO public.user_roles VALUES ('57e4b841-7105-4b44-9c2c-b150a336e8e1', '26b43586-7447-4f58-a2a9-6b2ddea56c57', '4726d5b0-f6fb-4b9f-b65c-eec8df933dbc', '2025-07-06 12:00:15.714394+00');


--
-- Data for Name: user_social_accounts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- PostgreSQL database dump complete
--

