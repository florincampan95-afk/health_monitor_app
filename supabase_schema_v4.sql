-- Schema V4: Multiple emergency contacts

-- Table for multiple emergency contacts
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  relationship TEXT, -- 'spouse', 'child', 'parent', 'sibling', 'friend', 'other'
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own emergency contacts" ON emergency_contacts
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own emergency contacts" ON emergency_contacts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own emergency contacts" ON emergency_contacts
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own emergency contacts" ON emergency_contacts
  FOR DELETE USING (auth.uid() = user_id);

-- Allow reading emergency contacts via shared access (for web portal)
CREATE POLICY "Allow reading emergency contacts via shared access" ON emergency_contacts
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM shared_access 
    WHERE shared_access.patient_user_id = emergency_contacts.user_id 
    AND shared_access.is_active = true
  )
);
