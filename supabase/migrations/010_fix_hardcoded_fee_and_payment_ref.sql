-- ============================================
-- 010: 修复硬编码金额 + 统一付款参考号格式
-- ============================================

-- 1. 更新 teams_detail 视图，统一 payment_ref 格式（去除连字符后取前 8 字符）
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
  events_register.calculate_age_on_date(p2.date_of_birth) AS player2_age
FROM events_register.teams t
JOIN events_register.categories c ON t.category_id = c.id
JOIN events_register.players p1 ON t.player1_id = p1.id
JOIN events_register.players p2 ON t.player2_id = p2.id;

-- 2. 更新 admin_dashboard_stats，从 tournament_config 读取 registration_fee
CREATE OR REPLACE FUNCTION events_register.admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  fee NUMERIC;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  -- Read fee from config (per person), team fee = fee * 2
  SELECT COALESCE((value::TEXT)::NUMERIC, 30) INTO fee
  FROM events_register.tournament_config
  WHERE key = 'registration_fee';

  SELECT json_build_object(
    'total_teams', COUNT(*),
    'confirmed_teams', COUNT(*) FILTER (WHERE status = 'confirmed'),
    'pending_teams', COUNT(*) FILTER (WHERE status = 'pending'),
    'waitlist_teams', COUNT(*) FILTER (WHERE status = 'waitlist'),
    'cancelled_teams', COUNT(*) FILTER (WHERE status = 'cancelled'),
    'paid_teams', COUNT(*) FILTER (WHERE payment_status = 'paid' AND status != 'cancelled'),
    'unpaid_teams', COUNT(*) FILTER (WHERE payment_status = 'unpaid' AND status != 'cancelled'),
    'total_revenue', COALESCE(SUM(CASE WHEN payment_status = 'paid' AND status != 'cancelled' THEN fee * 2 ELSE 0 END), 0),
    'expected_revenue', COALESCE(COUNT(*) FILTER (WHERE status != 'cancelled') * fee * 2, 0)
  ) INTO result
  FROM events_register.teams;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
