-- ============================================
-- 004: 视图
-- ============================================

SET search_path TO events_register, extensions, public;

-- ============================================
-- 1. 队伍详情视图（管理员用）
-- ============================================
CREATE OR REPLACE VIEW events_register.teams_detail AS
SELECT
  t.id AS team_id,
  t.team_name_zh,
  t.team_name_en,
  t.gender_type,
  t.combined_age,
  t.status,
  t.payment_status,
  t.seed,
  t.created_at,
  c.name_en AS category_en,
  c.name_zh AS category_zh,
  c.slug AS category_slug,
  p1.name_en AS player1_name_en,
  p1.name_zh AS player1_name_zh,
  p1.gender AS player1_gender,
  events_register.calculate_age_on_date(p1.date_of_birth) AS player1_age,
  p2.name_en AS player2_name_en,
  p2.name_zh AS player2_name_zh,
  p2.gender AS player2_gender,
  events_register.calculate_age_on_date(p2.date_of_birth) AS player2_age
FROM events_register.teams t
JOIN events_register.categories c ON t.category_id = c.id
JOIN events_register.players p1 ON t.player1_id = p1.id
JOIN events_register.players p2 ON t.player2_id = p2.id
WHERE t.status != 'cancelled';

-- ============================================
-- 2. 各组别报名统计视图
-- ============================================
CREATE OR REPLACE VIEW events_register.category_stats AS
SELECT
  c.id,
  c.name_en,
  c.name_zh,
  c.slug,
  c.max_teams,
  c.is_open,
  COUNT(t.id) FILTER (WHERE t.status IN ('pending', 'confirmed')) AS registered_teams,
  c.max_teams - COUNT(t.id) FILTER (WHERE t.status IN ('pending', 'confirmed')) AS remaining_slots
FROM events_register.categories c
LEFT JOIN events_register.teams t ON c.id = t.category_id
GROUP BY c.id, c.name_en, c.name_zh, c.slug, c.max_teams, c.is_open;

-- ============================================
-- 3. 公开队伍查询函数（脱敏）
-- ============================================
CREATE OR REPLACE FUNCTION events_register.get_public_teams()
RETURNS TABLE (
  team_id UUID,
  category_slug TEXT,
  category_zh TEXT,
  category_en TEXT,
  gender_type events_register.gender_type_enum,
  combined_age INTEGER,
  player1_display_name TEXT,
  player2_display_name TEXT,
  created_at TIMESTAMPTZ
) SECURITY DEFINER
SET search_path = events_register, extensions
AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    c.slug,
    c.name_zh,
    c.name_en,
    t.gender_type,
    t.combined_age,
    CASE
      WHEN p1.name_en LIKE '% %'
      THEN split_part(p1.name_en, ' ', 1) || ' ' || left(split_part(p1.name_en, ' ', 2), 1) || '.'
      ELSE p1.name_en
    END,
    CASE
      WHEN p2.name_en LIKE '% %'
      THEN split_part(p2.name_en, ' ', 1) || ' ' || left(split_part(p2.name_en, ' ', 2), 1) || '.'
      ELSE p2.name_en
    END,
    t.created_at
  FROM events_register.teams t
  JOIN events_register.categories c ON t.category_id = c.id
  JOIN events_register.players p1 ON t.player1_id = p1.id
  JOIN events_register.players p2 ON t.player2_id = p2.id
  WHERE t.status IN ('pending', 'confirmed');
END;
$$ LANGUAGE plpgsql;
