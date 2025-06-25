-- Add migration script here

-- Add is_public field to calendar_events table
ALTER TABLE calendar_events ADD COLUMN is_public BOOLEAN DEFAULT TRUE;

-- Create index for is_public field
CREATE INDEX idx_calendar_events_is_public ON calendar_events(is_public);

-- Update existing events to be public by default
UPDATE calendar_events SET is_public = TRUE WHERE is_public IS NULL; 