-- Migration script for post reply and comment nested reply features
-- This script safely applies database schema changes with checks for existing elements

-- 1. Add columns to posts table for reply functionality
DO $$
BEGIN
    -- Add parent_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'posts' AND column_name = 'parent_id') THEN
        ALTER TABLE posts ADD COLUMN parent_id uuid;
        RAISE NOTICE 'Added parent_id column to posts table';
    ELSE
        RAISE NOTICE 'parent_id column already exists in posts table';
    END IF;

    -- Add depth column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'posts' AND column_name = 'depth') THEN
        ALTER TABLE posts ADD COLUMN depth integer DEFAULT 0;
        RAISE NOTICE 'Added depth column to posts table';
    ELSE
        RAISE NOTICE 'depth column already exists in posts table';
    END IF;

    -- Add reply_count column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'posts' AND column_name = 'reply_count') THEN
        ALTER TABLE posts ADD COLUMN reply_count integer DEFAULT 0;
        RAISE NOTICE 'Added reply_count column to posts table';
    ELSE
        RAISE NOTICE 'reply_count column already exists in posts table';
    END IF;
END $$;

-- 2. Add columns to comments table for nested reply functionality
DO $$
BEGIN
    -- Add depth column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'comments' AND column_name = 'depth') THEN
        ALTER TABLE comments ADD COLUMN depth integer DEFAULT 0;
        RAISE NOTICE 'Added depth column to comments table';
    ELSE
        RAISE NOTICE 'depth column already exists in comments table';
    END IF;

    -- Add is_deleted column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'comments' AND column_name = 'is_deleted') THEN
        ALTER TABLE comments ADD COLUMN is_deleted boolean DEFAULT false;
        RAISE NOTICE 'Added is_deleted column to comments table';
    ELSE
        RAISE NOTICE 'is_deleted column already exists in comments table';
    END IF;
END $$;

-- 3. Add foreign key constraints
DO $$
BEGIN
    -- Add foreign key constraint for posts.parent_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'posts' AND constraint_name = 'fk_posts_parent') THEN
        ALTER TABLE posts 
        ADD CONSTRAINT fk_posts_parent 
        FOREIGN KEY (parent_id) REFERENCES posts(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint fk_posts_parent to posts table';
    ELSE
        RAISE NOTICE 'Foreign key constraint fk_posts_parent already exists in posts table';
    END IF;

    -- Add foreign key constraint for comments.parent_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_name = 'comments' AND constraint_name = 'fk_comments_parent') THEN
        ALTER TABLE comments 
        ADD CONSTRAINT fk_comments_parent 
        FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint fk_comments_parent to comments table';
    ELSE
        RAISE NOTICE 'Foreign key constraint fk_comments_parent already exists in comments table';
    END IF;
END $$;

-- 4. Create indexes if they don't exist
DO $$
BEGIN
    -- Create index for posts.parent_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'posts' AND indexname = 'idx_posts_parent_id') THEN
        CREATE INDEX idx_posts_parent_id ON posts(parent_id);
        RAISE NOTICE 'Created index idx_posts_parent_id on posts table';
    ELSE
        RAISE NOTICE 'Index idx_posts_parent_id already exists on posts table';
    END IF;

    -- Create index for posts depth and parent_id combination if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'posts' AND indexname = 'idx_posts_depth_parent') THEN
        CREATE INDEX idx_posts_depth_parent ON posts(depth, parent_id);
        RAISE NOTICE 'Created index idx_posts_depth_parent on posts table';
    ELSE
        RAISE NOTICE 'Index idx_posts_depth_parent already exists on posts table';
    END IF;

    -- Create index for comments.parent_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'comments' AND indexname = 'idx_comments_parent_id') THEN
        CREATE INDEX idx_comments_parent_id ON comments(parent_id);
        RAISE NOTICE 'Created index idx_comments_parent_id on comments table';
    ELSE
        RAISE NOTICE 'Index idx_comments_parent_id already exists on comments table';
    END IF;

    -- Create index for comments depth and parent_id combination if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'comments' AND indexname = 'idx_comments_depth_parent') THEN
        CREATE INDEX idx_comments_depth_parent ON comments(depth, parent_id);
        RAISE NOTICE 'Created index idx_comments_depth_parent on comments table';
    ELSE
        RAISE NOTICE 'Index idx_comments_depth_parent already exists on comments table';
    END IF;

    -- Create index for comments is_deleted if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE tablename = 'comments' AND indexname = 'idx_comments_is_deleted') THEN
        CREATE INDEX idx_comments_is_deleted ON comments(is_deleted);
        RAISE NOTICE 'Created index idx_comments_is_deleted on comments table';
    ELSE
        RAISE NOTICE 'Index idx_comments_is_deleted already exists on comments table';
    END IF;
END $$;

-- 5. Create or replace function to update reply count
CREATE OR REPLACE FUNCTION update_post_reply_count() 
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Increment reply count for parent post
        IF NEW.parent_id IS NOT NULL THEN
            UPDATE posts 
            SET reply_count = COALESCE(reply_count, 0) + 1 
            WHERE id = NEW.parent_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Decrement reply count for parent post
        IF OLD.parent_id IS NOT NULL THEN
            UPDATE posts 
            SET reply_count = GREATEST(COALESCE(reply_count, 0) - 1, 0) 
            WHERE id = OLD.parent_id;
        END IF;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 6. Create trigger for reply count if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.triggers 
                   WHERE trigger_name = 'trigger_update_post_reply_count') THEN
        CREATE TRIGGER trigger_update_post_reply_count
            AFTER INSERT OR DELETE ON posts
            FOR EACH ROW
            EXECUTE FUNCTION update_post_reply_count();
        RAISE NOTICE 'Created trigger trigger_update_post_reply_count on posts table';
    ELSE
        RAISE NOTICE 'Trigger trigger_update_post_reply_count already exists on posts table';
    END IF;
END $$;

-- 7. Update existing data to ensure consistency
-- Set default values for new columns where they might be NULL
UPDATE posts SET depth = 0 WHERE depth IS NULL;
UPDATE posts SET reply_count = 0 WHERE reply_count IS NULL;
UPDATE comments SET depth = 0 WHERE depth IS NULL;
UPDATE comments SET is_deleted = false WHERE is_deleted IS NULL;

-- 8. Calculate existing reply counts for posts that have replies
UPDATE posts 
SET reply_count = (
    SELECT COUNT(*) 
    FROM posts AS replies 
    WHERE replies.parent_id = posts.id
)
WHERE id IN (
    SELECT DISTINCT parent_id 
    FROM posts 
    WHERE parent_id IS NOT NULL
);

RAISE NOTICE 'Migration completed successfully!';