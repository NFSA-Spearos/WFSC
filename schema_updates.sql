-- User tracking table
CREATE TABLE IF NOT EXISTS user_analytics (
  id BIGSERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  session_id TEXT NOT NULL,
  page_view TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  user_agent TEXT,
  referrer TEXT
);

-- Add index for efficient queries
CREATE INDEX IF NOT EXISTS idx_user_analytics_user_id ON user_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_session_id ON user_analytics(session_id);
CREATE INDEX IF NOT EXISTS idx_user_analytics_timestamp ON user_analytics(timestamp);

-- Enable RLS
ALTER TABLE user_analytics ENABLE ROW LEVEL SECURITY;

-- Allow inserts from anyone (for tracking)
CREATE POLICY "Allow anonymous tracking inserts"
  ON user_analytics FOR INSERT
  WITH CHECK (true);

-- Allow anyone to read analytics (app-level admin check)
CREATE POLICY "Allow public read analytics"
  ON user_analytics FOR SELECT
  USING (true);
