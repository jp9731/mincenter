-- 게시글 이동 이력 관리 테이블
CREATE TABLE IF NOT EXISTS public.post_moves (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    post_id uuid NOT NULL,
    from_board_id uuid NOT NULL,
    to_board_id uuid NOT NULL,
    from_category_id uuid,
    to_category_id uuid,
    moved_by uuid NOT NULL, -- 이동을 수행한 사용자 ID
    move_reason text,
    moved_at timestamp with time zone DEFAULT now() NOT NULL,
    
    CONSTRAINT post_moves_pkey PRIMARY KEY (id),
    CONSTRAINT post_moves_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE,
    CONSTRAINT post_moves_from_board_id_fkey FOREIGN KEY (from_board_id) REFERENCES public.boards(id),
    CONSTRAINT post_moves_to_board_id_fkey FOREIGN KEY (to_board_id) REFERENCES public.boards(id),
    CONSTRAINT post_moves_from_category_id_fkey FOREIGN KEY (from_category_id) REFERENCES public.board_categories(id),
    CONSTRAINT post_moves_to_category_id_fkey FOREIGN KEY (to_category_id) REFERENCES public.board_categories(id),
    CONSTRAINT post_moves_moved_by_fkey FOREIGN KEY (moved_by) REFERENCES public.users(id)
);

-- 게시글 숨김 이력 관리 테이블
CREATE TABLE IF NOT EXISTS public.post_hides (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    post_id uuid NOT NULL,
    hidden_by uuid NOT NULL, -- 숨김을 수행한 사용자 ID
    hide_reason text NOT NULL,
    hidden_at timestamp with time zone DEFAULT now() NOT NULL,
    
    CONSTRAINT post_hides_pkey PRIMARY KEY (id),
    CONSTRAINT post_hides_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE,
    CONSTRAINT post_hides_hidden_by_fkey FOREIGN KEY (hidden_by) REFERENCES public.users(id)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_post_moves_post_id ON public.post_moves(post_id);
CREATE INDEX IF NOT EXISTS idx_post_moves_moved_at ON public.post_moves(moved_at);
CREATE INDEX IF NOT EXISTS idx_post_hides_post_id ON public.post_hides(post_id);
CREATE INDEX IF NOT EXISTS idx_post_hides_hidden_at ON public.post_hides(hidden_at);

-- 댓글 숨김 이력 관리 테이블
CREATE TABLE IF NOT EXISTS public.comment_hides (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    comment_id uuid NOT NULL,
    hidden_by uuid NOT NULL, -- 숨김을 수행한 사용자 ID
    hide_reason text NOT NULL,
    hidden_at timestamp with time zone DEFAULT now() NOT NULL,
    
    CONSTRAINT comment_hides_pkey PRIMARY KEY (id),
    CONSTRAINT comment_hides_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id) ON DELETE CASCADE,
    CONSTRAINT comment_hides_hidden_by_fkey FOREIGN KEY (hidden_by) REFERENCES public.users(id)
);

-- 댓글 숨김 이력 인덱스
CREATE INDEX IF NOT EXISTS idx_comment_hides_comment_id ON public.comment_hides(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_hides_hidden_at ON public.comment_hides(hidden_at);
