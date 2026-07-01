-- Schema V6: Day-specific scheduling for medications and measurement reminders

-- Add days column to medications table (array of day numbers: 0=Sunday, 1=Monday, etc.)
-- NULL or empty means every day
ALTER TABLE medications 
ADD COLUMN IF NOT EXISTS days INTEGER[];

-- Add day-specific reminder columns to user_profiles
ALTER TABLE user_profiles 
ADD COLUMN IF NOT EXISTS reminder_glucose_days INTEGER[],
ADD COLUMN IF NOT EXISTS reminder_bp_days INTEGER[];

-- Comment: days array uses 0-6 where 0=Sunday, 1=Monday, 2=Tuesday, etc.
-- Example: [1,3,5] means Monday, Wednesday, Friday
-- NULL or empty array means every day
