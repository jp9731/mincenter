-- post_move_history 테이블의 타입을 UUID로 변경
ALTER TABLE post_move_history 
    ALTER COLUMN post_id TYPE UUID USING post_id::text::uuid,
    ALTER COLUMN original_board_id TYPE UUID USING original_board_id::text::uuid,
    ALTER COLUMN original_category_id TYPE UUID USING original_category_id::text::uuid,
    ALTER COLUMN moved_board_id TYPE UUID USING moved_board_id::text::uuid,
    ALTER COLUMN moved_category_id TYPE UUID USING moved_category_id::text::uuid,
    ALTER COLUMN moved_by TYPE UUID USING moved_by::text::uuid;

-- post_hide_history 테이블의 타입을 UUID로 변경
ALTER TABLE post_hide_history 
    ALTER COLUMN post_id TYPE UUID USING post_id::text::uuid,
    ALTER COLUMN hidden_by TYPE UUID USING hidden_by::text::uuid;
