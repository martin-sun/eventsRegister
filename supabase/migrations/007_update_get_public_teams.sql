-- ============================================
-- 007: 更新公开队伍查询函数（增加 status 和 seed）
-- ============================================

SET search_path TO events_register, extensions, public;

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
  status events_register.team_status_enum,
  seed INTEGER,
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
    t.status,
    t.seed,
    t.created_at
  FROM events_register.teams t
  JOIN events_register.categories c ON t.category_id = c.id
  JOIN events_register.players p1 ON t.player1_id = p1.id
  JOIN events_register.players p2 ON t.player2_id = p2.id
  WHERE t.status IN ('pending', 'confirmed');
END;
$$ LANGUAGE plpgsql;
