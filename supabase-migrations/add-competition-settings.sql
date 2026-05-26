-- Create a simple settings table for competition state
CREATE TABLE IF NOT EXISTS competition_settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default settings
INSERT INTO competition_settings (key, value) 
VALUES 
  ('results_finalized', 'false'),
  ('current_day', '0')
ON CONFLICT (key) DO NOTHING;

-- Enable RLS
ALTER TABLE competition_settings ENABLE ROW LEVEL SECURITY;

-- Public can read settings
CREATE POLICY "Public read competition_settings" ON competition_settings FOR SELECT TO public USING (true);

-- Only authenticated users can update (your admin account)
CREATE POLICY "Auth update competition_settings" ON competition_settings FOR UPDATE TO authenticated USING (true);
