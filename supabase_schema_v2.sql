-- Health Monitor App - Complete Database Schema
-- Run this in Supabase SQL Editor

-- Create health_readings table with UUID user_id
CREATE TABLE IF NOT EXISTS health_readings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    glucose DECIMAL(5,1),
    systolic DECIMAL(5,1),
    diastolic DECIMAL(5,1),
    symptoms TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create medications table with UUID user_id
CREATE TABLE IF NOT EXISTS medications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
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

-- Enable Row Level Security
ALTER TABLE health_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

-- Health readings policies
CREATE POLICY "Users can view their own health readings"
    ON health_readings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health readings"
    ON health_readings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health readings"
    ON health_readings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own health readings"
    ON health_readings FOR DELETE
    USING (auth.uid() = user_id);

-- Medications policies
CREATE POLICY "Users can view their own medications"
    ON medications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own medications"
    ON medications FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own medications"
    ON medications FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own medications"
    ON medications FOR DELETE
    USING (auth.uid() = user_id);
