-- Add confirmation email tracking to teams table
ALTER TABLE events_register.teams
  ADD COLUMN IF NOT EXISTS confirmation_email_sent_at TIMESTAMPTZ;

-- Update teams_detail view to include email tracking
CREATE OR REPLACE VIEW events_register.teams_detail AS
SELECT
  t.id AS team_id,
  t.team_name_zh,
  t.team_name_en,
  t.gender_type,
  t.combined_age,
  t.status,
  t.payment_status,
  t.paid_at,
  t.payment_notes,
  UPPER(LEFT(REPLACE(t.id::TEXT, '-', ''), 8)) AS payment_ref,
  t.seed,
  t.created_at,
  c.name_en AS category_en,
  c.name_zh AS category_zh,
  c.slug AS category_slug,
  p1.id AS player1_id,
  p1.name_en AS player1_name_en,
  p1.name_zh AS player1_name_zh,
  p1.gender AS player1_gender,
  p1.email AS player1_email,
  p1.phone AS player1_phone,
  p1.wechat_id AS player1_wechat,
  events_register.calculate_age_on_date(p1.date_of_birth) AS player1_age,
  p2.id AS player2_id,
  p2.name_en AS player2_name_en,
  p2.name_zh AS player2_name_zh,
  p2.gender AS player2_gender,
  p2.email AS player2_email,
  p2.phone AS player2_phone,
  p2.wechat_id AS player2_wechat,
  events_register.calculate_age_on_date(p2.date_of_birth) AS player2_age,
  t.confirmation_email_sent_at
FROM events_register.teams t
JOIN events_register.categories c ON t.category_id = c.id
JOIN events_register.players p1 ON t.player1_id = p1.id
JOIN events_register.players p2 ON t.player2_id = p2.id;
