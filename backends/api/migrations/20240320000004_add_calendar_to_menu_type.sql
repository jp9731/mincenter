-- Add calendar to menu_type enum if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum 
        WHERE enumlabel = 'calendar' 
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'menu_type')
    ) THEN
        ALTER TYPE menu_type ADD VALUE 'calendar';
    END IF;
END $$; 