-- Schema V5: Security improvements for shared access codes

-- Add used_at column to track one-time use
ALTER TABLE shared_access 
ADD COLUMN IF NOT EXISTS used_at TIMESTAMPTZ;

-- Update RLS policy to allow reading shared_access for code validation (anonymous)
-- This allows the web portal to validate codes without authentication
DROP POLICY IF EXISTS "Allow anonymous code validation" ON shared_access;
CREATE POLICY "Allow anonymous code validation" ON shared_access
FOR SELECT USING (true);

-- Policy for health_readings via shared access (cast to handle UUID/TEXT mismatch)
DROP POLICY IF EXISTS "Allow reading health_readings via shared access" ON health_readings;
CREATE POLICY "Allow reading health_readings via shared access" ON health_readings
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM shared_access 
    WHERE shared_access.patient_user_id::text = health_readings.user_id::text
    AND shared_access.is_active = true
    AND (shared_access.expires_at IS NULL OR shared_access.expires_at > NOW())
  )
);

-- Policy for medications via shared access
DROP POLICY IF EXISTS "Allow reading medications via shared access" ON medications;
CREATE POLICY "Allow reading medications via shared access" ON medications
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM shared_access 
    WHERE shared_access.patient_user_id::text = medications.user_id::text
    AND shared_access.is_active = true
    AND (shared_access.expires_at IS NULL OR shared_access.expires_at > NOW())
  )
);

-- Policy for user_profiles via shared access
DROP POLICY IF EXISTS "Allow reading user_profiles via shared access" ON user_profiles;
CREATE POLICY "Allow reading user_profiles via shared access" ON user_profiles
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM shared_access 
    WHERE shared_access.patient_user_id::text = user_profiles.user_id::text
    AND shared_access.is_active = true
    AND (shared_access.expires_at IS NULL OR shared_access.expires_at > NOW())
  )
);

-- Allow updating shared_access to mark as used (for one-time codes)
DROP POLICY IF EXISTS "Allow marking code as used" ON shared_access;
CREATE POLICY "Allow marking code as used" ON shared_access
FOR UPDATE USING (true)
WITH CHECK (true);

-- Allow deleting shared_access codes (for one-time use deletion)
DROP POLICY IF EXISTS "Allow deleting used codes" ON shared_access;
CREATE POLICY "Allow deleting used codes" ON shared_access
FOR DELETE USING (true);
