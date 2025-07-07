-- 기본 사용자에게 super_admin 역할 할당
-- 실제 사용자 ID로 변경해야 합니다
INSERT INTO user_roles (user_id, role_id)
SELECT 
    (SELECT id FROM users WHERE email = 'admin@example.com' LIMIT 1),
    (SELECT id FROM roles WHERE name = 'super_admin')
ON CONFLICT (user_id, role_id) DO NOTHING;

-- 다른 사용자들에게 기본 역할 할당 (예시)
-- INSERT INTO user_roles (user_id, role_id)
-- SELECT 
--     (SELECT id FROM users WHERE email = 'moderator@example.com' LIMIT 1),
--     (SELECT id FROM roles WHERE name = 'moderator')
-- ON CONFLICT (user_id, role_id) DO NOTHING;

-- INSERT INTO user_roles (user_id, role_id)
-- SELECT 
--     (SELECT id FROM users WHERE email = 'editor@example.com' LIMIT 1),
--     (SELECT id FROM roles WHERE name = 'editor')
-- ON CONFLICT (user_id, role_id) DO NOTHING; 