-- Add migration script here

-- Create pages table (IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(500) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    meta_title VARCHAR(255),
    meta_description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    is_published BOOLEAN NOT NULL DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    view_count INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0
);

-- Create index for slug (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_pages_slug ON pages(slug);

-- Create index for status and published (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_pages_status_published ON pages(status, is_published);

-- Create index for sort order (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_pages_sort_order ON pages(sort_order);

-- Create index for created_at (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_pages_created_at ON pages(created_at);

-- Create function to increment view count (IF NOT EXISTS)
CREATE OR REPLACE FUNCTION increment_page_view_count(page_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE pages 
    SET view_count = view_count + 1 
    WHERE id = page_id;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at (IF NOT EXISTS)
CREATE OR REPLACE FUNCTION update_pages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    CREATE TRIGGER trigger_update_pages_updated_at
        BEFORE UPDATE ON pages
        FOR EACH ROW
        EXECUTE FUNCTION update_pages_updated_at();
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
