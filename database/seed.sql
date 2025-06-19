-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 샘플 데이터 삽입 스크립트
-- 개발 및 테스트용 데이터

-- 게시판 생성
INSERT INTO boards (name, description, category, display_order, is_public, allow_anonymous) VALUES
    ('공지사항', '중요한 공지사항을 확인하세요', 'notice', 1, true, false),
    ('봉사활동 후기', '봉사활동 경험을 공유해보세요', 'review', 2, true, false),
    ('자유게시판', '자유롭게 이야기를 나누세요', 'free', 3, true, false),
    ('질문과 답변', '궁금한 점을 물어보세요', 'qna', 4, true, false)
ON CONFLICT (name) DO NOTHING;

-- 카테고리 생성 (게시판별)
DO $$
DECLARE
    board_notice_id uuid;
    board_review_id uuid;
    board_free_id uuid;
    board_qna_id uuid;
BEGIN
    -- 게시판 ID 가져오기
    SELECT id INTO board_notice_id FROM boards WHERE name = '공지사항';
    SELECT id INTO board_review_id FROM boards WHERE name = '봉사활동 후기';
    SELECT id INTO board_free_id FROM boards WHERE name = '자유게시판';
    SELECT id INTO board_qna_id FROM boards WHERE name = '질문과 답변';
    
    -- 공지사항 카테고리
    INSERT INTO categories (board_id, name, description, display_order) VALUES
        (board_notice_id, '일반공지', '일반적인 공지사항', 1),
        (board_notice_id, '긴급공지', '긴급한 공지사항', 2),
        (board_notice_id, '행사안내', '다가오는 행사 안내', 3);
    
    -- 봉사활동 후기 카테고리
    INSERT INTO categories (board_id, name, description, display_order) VALUES
        (board_review_id, '복지관봉사', '복지관 관련 봉사활동 후기', 1),
        (board_review_id, '교육봉사', '교육 관련 봉사활동 후기', 2),
        (board_review_id, '행사봉사', '행사 지원 봉사활동 후기', 3),
        (board_review_id, '기타봉사', '기타 봉사활동 후기', 4);
    
    -- 자유게시판 카테고리
    INSERT INTO categories (board_id, name, description, display_order) VALUES
        (board_free_id, '일반', '일반적인 이야기', 1),
        (board_free_id, '정보공유', '유용한 정보 공유', 2),
        (board_free_id, '모임후기', '봉사자 모임 후기', 3);
    
    -- 질문과 답변 카테고리
    INSERT INTO categories (board_id, name, description, display_order) VALUES
        (board_qna_id, '봉사활동', '봉사활동 관련 질문', 1),
        (board_qna_id, '시설이용', '시설 이용 관련 질문', 2),
        (board_qna_id, '기타', '기타 질문', 3);
END $$;

-- 추가 사용자 생성 (테스트용)
INSERT INTO users (email, password_hash, name, role, status, email_verified, points) VALUES
    ('user1@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e', '김봉사', 'user', 'active', true, 150),
    ('user2@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e', '이도움', 'user', 'active', true, 230),
    ('user3@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewmWQOmGM0aZOJ8e', '박나눔', 'user', 'active', true, 80)
ON CONFLICT (email) DO NOTHING;

-- 히어로 섹션 데이터
INSERT INTO hero_sections (title, subtitle, description, button_text, button_link, is_active, display_order) VALUES
    ('함께하는 따뜻한 마음', '장애인과 함께하는 봉사활동', '우리의 작은 관심과 참여가 더 나은 세상을 만듭니다. 지금 봉사활동에 참여해보세요.', '봉사활동 참여하기', '/volunteer', true, 1),
    ('나눔의 기쁨을 경험하세요', '매월 다양한 봉사활동 프로그램', '정기적인 봉사활동을 통해 의미있는 시간을 보내고 소중한 경험을 쌓아보세요.', '프로그램 보기', '/programs', false, 2)
ON CONFLICT DO NOTHING;

-- 갤러리 데이터
INSERT INTO galleries (title, description, category) VALUES
    ('2024년 하반기 봉사활동', '지난 6개월간의 봉사활동 모습들을 모았습니다.', 'activity'),
    ('장애인의 날 행사', '매년 4월 20일 장애인의 날 기념행사 사진들', 'event'),
    ('여름 캠프 활동', '장애인 청소년들과 함께한 여름 캠프', 'camp')
ON CONFLICT DO NOTHING;

-- 샘플 게시글 생성
DO $$
DECLARE
    board_notice_id uuid;
    board_review_id uuid;
    board_free_id uuid;
    board_qna_id uuid;
    user1_id uuid;
    user2_id uuid;
    user3_id uuid;
    admin_id uuid;
BEGIN
    -- 게시판 ID 가져오기
    SELECT id INTO board_notice_id FROM boards WHERE name = '공지사항';
    SELECT id INTO board_review_id FROM boards WHERE name = '봉사활동 후기';
    SELECT id INTO board_free_id FROM boards WHERE name = '자유게시판';
    SELECT id INTO board_qna_id FROM boards WHERE name = '질문과 답변';
    
    -- 사용자 ID 가져오기
    SELECT id INTO admin_id FROM users WHERE email = 'admin@example.com';
    SELECT id INTO user1_id FROM users WHERE email = 'user1@example.com';
    SELECT id INTO user2_id FROM users WHERE email = 'user2@example.com';
    SELECT id INTO user3_id FROM users WHERE email = 'user3@example.com';

    -- 공지사항 게시글
    INSERT INTO posts (board_id, user_id, title, content, is_notice, views) VALUES
        (board_notice_id, admin_id, '[중요] 2024년 하반기 봉사활동 계획 안내', 
         '안녕하세요. 따뜻한 마음 봉사단입니다.

2024년 하반기 봉사활동 계획을 안내드립니다.

## 주요 일정
- 7월: 여름 장애인 캠프 (7/15-7/17)
- 8월: 장애인 체육대회 지원 (8/20)
- 9월: 추석 나눔 행사 (9/15)
- 10월: 장애인 일자리 박람회 (10/12)
- 11월: 김장 나눔 봉사 (11/20)
- 12월: 연말 감사 행사 (12/22)

많은 참여 부탁드립니다.', true, 156),
        
        (board_notice_id, admin_id, '봉사활동 참여 시 주의사항', 
         '봉사활동 참여 전 반드시 확인해주세요.

1. 활동 30분 전까지 도착
2. 편안한 복장 착용
3. 개인 물병 지참
4. 안전교육 필수 이수

안전한 봉사활동을 위해 협조 부탁드립니다.', true, 89);

    -- 봉사활동 후기 게시글
    INSERT INTO posts (board_id, user_id, title, content, views, likes) VALUES
        (board_review_id, user1_id, '장애인 복지관 청소 봉사 후기', 
         '오늘 처음으로 장애인 복지관 청소 봉사에 참여했습니다.

생각보다 많은 일들이 있었지만, 함께 참여한 봉사자들과 협력해서 깨끗하게 정리할 수 있었어요. 
특히 복지관을 이용하시는 분들이 고마워하시는 모습을 보니 정말 뿌듯했습니다.

다음에도 꼭 참여하고 싶어요! 😊', 45, 12),
        
        (board_review_id, user2_id, '시각장애인 도서 낭독 봉사 경험담', 
         '매주 토요일 시각장애인을 위한 도서 낭독 봉사를 하고 있습니다.

처음에는 어떻게 읽어야 할지 몰라서 많이 긴장했는데, 
이제는 자연스럽게 감정을 담아서 읽을 수 있게 되었어요.

이용자분들이 책 내용에 대해 함께 이야기하실 때가 가장 보람찹니다.
작은 나눔이지만 서로에게 의미있는 시간이 되고 있습니다.', 67, 18),
        
        (board_review_id, user3_id, '휠체어 이용자와 함께한 나들이', 
         '휠체어를 이용하시는 분들과 함께 공원 나들이를 다녀왔습니다.

평소에 생각하지 못했던 불편함들을 많이 느꼈어요.
턱이 있는 곳, 경사가 있는 길, 좁은 통로 등...

하지만 함께 웃고 이야기하며 즐거운 시간을 보낼 수 있어서 좋았습니다.
앞으로도 이런 활동에 더 적극적으로 참여하고 싶어요.', 34, 8);

    -- 자유게시판 게시글
    INSERT INTO posts (board_id, user_id, title, content, views, likes) VALUES
        (board_free_id, user1_id, '봉사활동 동기들과 점심 모임 후기', 
         '지난주에 함께 봉사활동을 했던 분들과 점심을 먹었어요.

봉사활동 이야기도 하고, 서로의 근황도 나누면서 
정말 즐거운 시간을 보냈습니다.

이렇게 좋은 사람들을 만날 수 있어서 봉사활동이 더욱 의미있게 느껴져요.', 23, 5),
        
        (board_free_id, user2_id, '여러분의 봉사활동 동기는 무엇인가요?', 
         '안녕하세요! 봉사활동을 시작한지 3개월 정도 되었는데요.

처음에는 단순히 도움이 되고 싶다는 마음으로 시작했지만,
지금은 오히려 제가 더 많은 것을 배우고 받는 것 같아요.

여러분들은 어떤 계기로 봉사활동을 시작하셨나요?
궁금해서 질문드립니다! 😊', 41, 7);

    -- 질문과 답변 게시글
    INSERT INTO posts (board_id, user_id, title, content, views) VALUES
        (board_qna_id, user3_id, '처음 봉사활동 참여 시 준비물은?', 
         '다음주에 처음으로 봉사활동에 참여하게 되었습니다.

특별히 준비해야 할 것들이 있을까요?
복장이나 개인적으로 가져가면 좋은 물건들이 있다면 알려주세요!', 28),
        
        (board_qna_id, user1_id, '포인트는 어떻게 사용하나요?', 
         '봉사활동을 하면서 포인트가 쌓였는데,
이 포인트를 어떻게 사용할 수 있는지 궁금합니다.

혹시 기부도 가능한가요?', 19);

END $$;

-- 댓글 추가
DO $$
DECLARE
    post_id_1 uuid;
    post_id_2 uuid;
    user1_id uuid;
    user2_id uuid;
    admin_id uuid;
BEGIN
    -- 필요한 ID들 가져오기
    SELECT id INTO admin_id FROM users WHERE email = 'admin@example.com';
    SELECT id INTO user1_id FROM users WHERE email = 'user1@example.com';
    SELECT id INTO user2_id FROM users WHERE email = 'user2@example.com';
    
    -- 특정 게시글 ID 가져오기
    SELECT id INTO post_id_1 FROM posts WHERE title = '장애인 복지관 청소 봉사 후기';
    SELECT id INTO post_id_2 FROM posts WHERE title = '처음 봉사활동 참여 시 준비물은?';

    -- 댓글 추가
    INSERT INTO comments (post_id, user_id, content, likes) VALUES
        (post_id_1, user2_id, '정말 수고하셨어요! 저도 다음번에 참여해보고 싶네요.', 3),
        (post_id_1, admin_id, '첫 봉사활동 참여해주셔서 감사합니다. 앞으로도 많은 참여 부탁드려요!', 5),
        (post_id_2, admin_id, '편한 복장과 개인 물병 정도면 충분합니다. 자세한 내용은 활동 전 안내해드릴게요!', 2),
        (post_id_2, user1_id, '저도 처음에 많이 궁금했는데, 생각보다 특별한 준비물은 없어요. 마음의 준비만 하시면 됩니다! ^^', 4);

END $$;

-- 포인트 거래 내역 추가
INSERT INTO point_transactions (user_id, type, amount, reason, reference_type, reference_id) 
SELECT 
    u.id,
    'earn',
    10,
    '게시글 작성',
    'post',
    p.id
FROM users u
JOIN posts p ON u.id = p.user_id
WHERE u.email != 'admin@example.com'
ON CONFLICT DO NOTHING;

INSERT INTO point_transactions (user_id, type, amount, reason, reference_type, reference_id) 
SELECT 
    u.id,
    'earn',
    5,
    '댓글 작성',
    'comment',
    c.id
FROM users u
JOIN comments c ON u.id = c.user_id
WHERE u.email != 'admin@example.com'
ON CONFLICT DO NOTHING;

-- 좋아요 데이터 추가
DO $$
DECLARE
    user_ids uuid[];
    post_ids uuid[];
    comment_ids uuid[];
    i integer;
    j integer;
BEGIN
    -- 사용자 ID 배열 생성
    SELECT ARRAY_AGG(id) INTO user_ids FROM users WHERE email != 'admin@example.com';
    SELECT ARRAY_AGG(id) INTO post_ids FROM posts;
    SELECT ARRAY_AGG(id) INTO comment_ids FROM comments;

    -- 랜덤하게 좋아요 추가 (게시글)
    IF user_ids IS NOT NULL AND post_ids IS NOT NULL THEN
        FOR i IN 1..array_length(user_ids, 1) LOOP
            FOR j IN 1..array_length(post_ids, 1) LOOP
                IF random() < 0.3 THEN -- 30% 확률로 좋아요
                    INSERT INTO likes (user_id, entity_type, entity_id) 
                    VALUES (user_ids[i], 'post', post_ids[j])
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
        END LOOP;
    END IF;

    -- 랜덤하게 좋아요 추가 (댓글)
    IF user_ids IS NOT NULL AND comment_ids IS NOT NULL THEN
        FOR i IN 1..array_length(user_ids, 1) LOOP
            FOR j IN 1..array_length(comment_ids, 1) LOOP
                IF random() < 0.2 THEN -- 20% 확률로 좋아요
                    INSERT INTO likes (user_id, entity_type, entity_id) 
                    VALUES (user_ids[i], 'comment', comment_ids[j])
                    ON CONFLICT DO NOTHING;
                END IF;
            END LOOP;
        END LOOP;
    END IF;

    -- 게시글 좋아요 수 업데이트
    UPDATE posts SET likes = (
        SELECT COUNT(*) FROM likes 
        WHERE entity_type = 'post' AND entity_id = posts.id
    );

    -- 댓글 좋아요 수 업데이트
    UPDATE comments SET likes = (
        SELECT COUNT(*) FROM likes 
        WHERE entity_type = 'comment' AND entity_id = comments.id
    );

END $$;

-- 알림 샘플 데이터
INSERT INTO notifications (user_id, type, title, message, entity_type, entity_id) 
SELECT 
    p.user_id,
    'comment',
    '새 댓글이 달렸습니다',
    c.content,
    'post',
    p.id
FROM posts p
JOIN comments c ON p.id = c.post_id
WHERE p.user_id != c.user_id
ON CONFLICT DO NOTHING;

-- 임시저장 샘플 데이터
DO $$
DECLARE
    board_free_id uuid;
    user1_id uuid;
BEGIN
    SELECT id INTO board_free_id FROM boards WHERE name = '자유게시판';
    SELECT id INTO user1_id FROM users WHERE email = 'user1@example.com';
    
    IF board_free_id IS NOT NULL AND user1_id IS NOT NULL THEN
        INSERT INTO drafts (user_id, board_id, title, content, auto_save_count) VALUES
            (user1_id, board_free_id, '작성 중인 글 제목', '이것은 임시저장된 글 내용입니다...', 3)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

-- 뷰 생성: 인기 게시글
CREATE OR REPLACE VIEW popular_posts AS
SELECT 
    p.id,
    p.title,
    p.content,
    p.views,
    p.likes,
    p.created_at,
    u.name as author_name,
    b.name as board_name,
    (p.views * 0.1 + p.likes * 1.0) as popularity_score
FROM posts p
JOIN users u ON p.user_id = u.id
JOIN boards b ON p.board_id = b.id
WHERE p.status = 'active'
ORDER BY popularity_score DESC;

-- 뷰 생성: 사용자 활동 통계
CREATE OR REPLACE VIEW user_activity_stats AS
SELECT 
    u.id,
    u.name,
    u.email,
    u.points,
    COUNT(DISTINCT p.id) as post_count,
    COUNT(DISTINCT c.id) as comment_count,
    COUNT(DISTINCT l.id) as like_given_count,
    (SELECT COUNT(*) FROM likes WHERE entity_type = 'post' AND entity_id IN (SELECT id FROM posts WHERE user_id = u.id)) as likes_received_count
FROM users u
LEFT JOIN posts p ON u.id = p.user_id AND p.status = 'active'
LEFT JOIN comments c ON u.id = c.user_id AND c.status = 'active'
LEFT JOIN likes l ON u.id = l.user_id
WHERE u.status = 'active'
GROUP BY u.id, u.name, u.email, u.points;

-- 인덱스 추가 (성능 최적화)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_popularity ON posts((views * 0.1 + likes * 1.0) DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_files_created_at ON files(created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

-- 마지막 업데이트: 사용자 포인트 계산
UPDATE users SET points = (
    SELECT COALESCE(SUM(
        CASE 
            WHEN type = 'earn' THEN amount
            WHEN type = 'use' THEN -amount
            ELSE 0
        END
    ), 0)
    FROM point_transactions 
    WHERE user_id = users.id
);

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '=== 데이터베이스 초기화 완료 ===';
    RAISE NOTICE '관리자 계정: admin@example.com / admin123';
    RAISE NOTICE '테스트 계정: user1@example.com / admin123';
    RAISE NOTICE '샘플 데이터가 성공적으로 생성되었습니다.';
END $$;