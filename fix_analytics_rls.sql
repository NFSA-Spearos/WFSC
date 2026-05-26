-- Fix RLS policy for user_analytics table
-- Run this if analytics are being recorded but not displaying

-- Drop the old restrictive policy
DROP POLICY IF EXISTS "Admin read analytics" ON user_analytics;

-- Create new permissive read policy
CREATE POLICY "Allow public read analytics"
  ON user_analytics FOR SELECT
  USING (true);

-- Verify policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'user_analytics';
