-- ============================================
-- 009: 付款追踪字段 + 管理员辅助函数
-- ============================================

-- 1. teams 表新增付款追踪字段
ALTER TABLE events_register.teams
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS payment_notes TEXT;

-- 2. tournament_config 新增 E-Transfer 配置
INSERT INTO events_register.tournament_config (key, value) VALUES
  ('etransfer_email', '"tournament@email.com"'),
  ('contact_phone', '"(306) 555-1234"'),
  ('contact_wechat', '"saskatoon_badminton"'),
  ('payment_deadline_hours', '72')
ON CONFLICT (key) DO NOTHING;

-- 3. 管理员判断辅助函数
CREATE OR REPLACE FUNCTION events_register.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 4. 更新 teams_detail 视图，增加付款参考号
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
  UPPER(LEFT(t.id::TEXT, 8)) AS payment_ref,
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
  events_register.calculate_age_on_date(p2.date_of_birth) AS player2_age
FROM events_register.teams t
JOIN events_register.categories c ON t.category_id = c.id
JOIN events_register.players p1 ON t.player1_id = p1.id
JOIN events_register.players p2 ON t.player2_id = p2.id;

-- 5. 管理员标记付款的 RPC 函数
CREATE OR REPLACE FUNCTION events_register.admin_mark_payment(
  p_team_id UUID,
  p_payment_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  UPDATE events_register.teams
  SET payment_status = 'paid',
      paid_at = NOW(),
      payment_notes = p_payment_notes
  WHERE id = p_team_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Team not found: %', p_team_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. 管理员更新队伍状态的 RPC 函数
CREATE OR REPLACE FUNCTION events_register.admin_update_team_status(
  p_team_id UUID,
  p_status TEXT
)
RETURNS VOID AS $$
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  IF p_status NOT IN ('pending', 'confirmed', 'waitlist', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid status: %', p_status;
  END IF;

  UPDATE events_register.teams
  SET status = p_status::events_register.team_status_enum
  WHERE id = p_team_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Team not found: %', p_team_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 管理员仪表盘统计 RPC
CREATE OR REPLACE FUNCTION events_register.admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  SELECT json_build_object(
    'total_teams', COUNT(*),
    'confirmed_teams', COUNT(*) FILTER (WHERE status = 'confirmed'),
    'pending_teams', COUNT(*) FILTER (WHERE status = 'pending'),
    'waitlist_teams', COUNT(*) FILTER (WHERE status = 'waitlist'),
    'cancelled_teams', COUNT(*) FILTER (WHERE status = 'cancelled'),
    'paid_teams', COUNT(*) FILTER (WHERE payment_status = 'paid' AND status != 'cancelled'),
    'unpaid_teams', COUNT(*) FILTER (WHERE payment_status = 'unpaid' AND status != 'cancelled'),
    'total_revenue', COALESCE(SUM(CASE WHEN payment_status = 'paid' AND status != 'cancelled' THEN 60 ELSE 0 END), 0),
    'expected_revenue', COALESCE(COUNT(*) FILTER (WHERE status != 'cancelled') * 60, 0)
  ) INTO result
  FROM events_register.teams;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
