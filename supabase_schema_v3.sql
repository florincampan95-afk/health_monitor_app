-- Schema V3: New features for health monitoring app

-- 1. Medication adherence tracking - log when patient takes medication
CREATE TABLE IF NOT EXISTS medication_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  scheduled_time TIME NOT NULL,
  taken_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending', -- 'taken', 'missed', 'pending', 'skipped'
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. User profiles with settings
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  doctor_name TEXT,
  doctor_phone TEXT,
  doctor_email TEXT,
  -- Target ranges
  glucose_min DECIMAL DEFAULT 70,
  glucose_max DECIMAL DEFAULT 125,
  systolic_max DECIMAL DEFAULT 140,
  diastolic_max DECIMAL DEFAULT 90,
  -- Preferences
  dark_mode BOOLEAN DEFAULT FALSE,
  reminder_glucose_enabled BOOLEAN DEFAULT FALSE,
  reminder_glucose_time TIME DEFAULT '07:00',
  reminder_bp_enabled BOOLEAN DEFAULT FALSE,
  reminder_bp_time TIME DEFAULT '08:00',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Shared access - allow caregivers/doctors to view patient data
CREATE TABLE IF NOT EXISTS shared_access (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  shared_with_email TEXT NOT NULL,
  shared_with_name TEXT,
  access_code TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'viewer', -- 'viewer', 'caregiver', 'doctor'
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Add reading_type and context to health_readings
ALTER TABLE health_readings 
ADD COLUMN IF NOT EXISTS reading_context TEXT, -- 'fasting', 'after_meal', 'before_meal', 'after_exercise', 'before_sleep'
ADD COLUMN IF NOT EXISTS meal_type TEXT; -- 'breakfast', 'lunch', 'dinner', 'snack'

-- Enable RLS
ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_access ENABLE ROW LEVEL SECURITY;

-- RLS Policies for medication_logs
CREATE POLICY "Users can view own medication logs" ON medication_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own medication logs" ON medication_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own medication logs" ON medication_logs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own medication logs" ON medication_logs
  FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for user_profiles
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for shared_access
CREATE POLICY "Users can view own shared access" ON shared_access
  FOR SELECT USING (auth.uid() = patient_user_id);
CREATE POLICY "Users can insert own shared access" ON shared_access
  FOR INSERT WITH CHECK (auth.uid() = patient_user_id);
CREATE POLICY "Users can update own shared access" ON shared_access
  FOR UPDATE USING (auth.uid() = patient_user_id);
CREATE POLICY "Users can delete own shared access" ON shared_access
  FOR DELETE USING (auth.uid() = patient_user_id);

-- Function to auto-create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id, full_name)
  VALUES (NEW.id, NEW.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for auto-creating profile (drop if exists first)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
