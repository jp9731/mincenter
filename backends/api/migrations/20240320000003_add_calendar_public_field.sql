-- Add migration script here

-- Add is_public field to calendar_events table (IF NOT EXISTS)
DO $$ BEGIN
    ALTER TABLE calendar_events ADD COLUMN is_public BOOLEAN DEFAULT TRUE;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Create index for is_public field (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_calendar_events_is_public ON calendar_events(is_public);

-- Update existing events to be public by default (IF NOT EXISTS)
UPDATE calendar_events SET is_public = TRUE WHERE is_public IS NULL; 