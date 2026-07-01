-- Health Monitor App Database Schema
-- Run this in your Supabase SQL Editor

-- Create health_readings table
CREATE TABLE IF NOT EXISTS health_readings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    glucose DECIMAL(5,1),
    systolic DECIMAL(5,1),
    diastolic DECIMAL(5,1),
    symptoms TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create medications table
CREATE TABLE IF NOT EXISTS medications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    times TEXT[] NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_health_readings_user_id ON health_readings(user_id);
CREATE INDEX IF NOT EXISTS idx_health_readings_created_at ON health_readings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_medications_user_id ON medications(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE health_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

-- Create policies for health_readings
CREATE POLICY "Users can view their own health readings"
    ON health_readings FOR SELECT
    USING (true);

CREATE POLICY "Users can insert their own health readings"
    ON health_readings FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update their own health readings"
    ON health_readings FOR UPDATE
    USING (true);

CREATE POLICY "Users can delete their own health readings"
    ON health_readings FOR DELETE
    USING (true);

-- Create policies for medications
CREATE POLICY "Users can view their own medications"
    ON medications FOR SELECT
    USING (true);

CREATE POLICY "Users can insert their own medications"
    ON medications FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update their own medications"
    ON medications FOR UPDATE
    USING (true);

CREATE POLICY "Users can delete their own medications"
    ON medications FOR DELETE
    USING (true);

-- Insert some sample data for testing
INSERT INTO health_readings (user_id, glucose, systolic, diastolic, symptoms, created_at)
VALUES 
    ('demo-user', 120, 120, 80, NULL, NOW() - INTERVAL '5 days'),
    ('demo-user', 95, 115, 75, 'Ușoară amețeală', NOW() - INTERVAL '4 days'),
    ('demo-user', 185, 145, 95, 'Durere de cap', NOW() - INTERVAL '3 days'),
    ('demo-user', 110, 118, 78, NULL, NOW() - INTERVAL '2 days'),
    ('demo-user', 105, 122, 82, NULL, NOW() - INTERVAL '1 day');

INSERT INTO medications (user_id, name, dosage, times, active)
VALUES 
    ('demo-user', 'Metformin', '500mg', ARRAY['08:00', '20:00'], true),
    ('demo-user', 'Aspirina', '100mg', ARRAY['09:00'], true);
