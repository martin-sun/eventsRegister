-- ============================================================
-- events_register 线上 Supabase 完整 Schema 初始化脚本
-- 合并所有 12 个 migration，按依赖顺序排列，使用最终版本
-- 在 Supabase SQL Editor 中一次性运行即可
-- ============================================================

-- ============================================
-- 1. 创建独立 Schema + 启用扩展
-- ============================================
CREATE SCHEMA IF NOT EXISTS events_register;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- ============================================
-- 2. 枚举类型
-- ============================================
CREATE TYPE events_register.gender_enum AS ENUM ('male', 'female');
CREATE TYPE events_register.gender_type_enum AS ENUM ('mens', 'womens', 'mixed');
CREATE TYPE events_register.team_status_enum AS ENUM ('pending', 'confirmed', 'waitlist', 'cancelled');
CREATE TYPE events_register.payment_status_enum AS ENUM ('unpaid', 'paid', 'refunded');
CREATE TYPE events_register.sponsor_level_enum AS ENUM (
  'title',     -- 冠名赞助
  'diamond',   -- 钻石赞助
  'platinum',  -- 白金赞助
  'gold',      -- 黄金赞助
  'friend',    -- 友情赞助
  'media'      -- 媒体支持
);

-- ============================================
-- 3. 数据表
-- ============================================

-- 3.1 比赛项目表
CREATE TABLE events_register.categories (
  id          UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name_en     TEXT NOT NULL,
  name_zh     TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  min_age_sum INTEGER NOT NULL,
  max_teams   INTEGER NOT NULL DEFAULT 32,
  is_open     BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 选手表
CREATE TABLE events_register.players (
  id             UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name_zh        TEXT,
  name_en        TEXT NOT NULL,
  email          TEXT NOT NULL,
  phone          TEXT,
  gender         events_register.gender_enum NOT NULL,
  date_of_birth  DATE NOT NULL,
  wechat_id      TEXT,
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT players_email_unique UNIQUE (email)
);

-- 3.3 队伍表（含 009 新增的付款追踪字段）
CREATE TABLE events_register.teams (
  id              UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  category_id     UUID NOT NULL REFERENCES events_register.categories(id),
  player1_id      UUID NOT NULL REFERENCES events_register.players(id),
  player2_id      UUID NOT NULL REFERENCES events_register.players(id),
  team_name_zh    TEXT,
  team_name_en    TEXT,
  gender_type     events_register.gender_type_enum NOT NULL,
  combined_age    INTEGER NOT NULL,
  status          events_register.team_status_enum NOT NULL DEFAULT 'pending',
  payment_status  events_register.payment_status_enum NOT NULL DEFAULT 'unpaid',
  paid_at         TIMESTAMPTZ,
  payment_notes   TEXT,
  confirmation_email_sent_at TIMESTAMPTZ,
  seed            INTEGER,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT team_different_players CHECK (player1_id != player2_id)
);

CREATE INDEX idx_teams_category ON events_register.teams(category_id);
CREATE INDEX idx_teams_status ON events_register.teams(status);
CREATE INDEX idx_teams_player1 ON events_register.teams(player1_id);
CREATE INDEX idx_teams_player2 ON events_register.teams(player2_id);

-- 3.4 赞助商表
CREATE TABLE events_register.sponsors (
  id            UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  name_zh       TEXT NOT NULL,
  name_en       TEXT NOT NULL,
  level         events_register.sponsor_level_enum NOT NULL,
  logo_url      TEXT,
  website       TEXT,
  contact_name  TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  amount        DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_confirmed  BOOLEAN NOT NULL DEFAULT FALSE,
  description_zh TEXT,
  description_en TEXT,
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sponsors_level ON events_register.sponsors(level);

-- 3.5 赛事配置表
CREATE TABLE events_register.tournament_config (
  key         TEXT PRIMARY KEY,
  value       JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 4. 初始数据
-- ============================================

-- 比赛项目
INSERT INTO events_register.categories (name_en, name_zh, slug, min_age_sum, max_teams, sort_order) VALUES
  ('Doubles 100+ Group', '双打100岁组', 'doubles-100', 100, 32, 1),
  ('Doubles 80+ Group',  '双打80岁组',  'doubles-80',  80,  32, 2);

-- 已确认赞助商
INSERT INTO events_register.sponsors (name_zh, name_en, level, amount, is_confirmed, sort_order) VALUES
  ('林与唐地产公司', 'Lin & Tang Real Estate', 'title', 1200, TRUE, 1),
  ('海外新生活', 'Overseas New Life', 'media', 0, TRUE, 100);

-- 赛事配置
INSERT INTO events_register.tournament_config (key, value) VALUES
  ('tournament_date', '"2026-05-24T09:30:00-06:00"'),
  ('venue', '{"en": "Riverside Badminton & Tennis Club", "zh": "Riverside 羽毛球网球俱乐部"}'),
  ('registration_fee', '30'),
  ('min_age', '35'),
  ('registration_open', 'true'),
  ('registration_deadline', '"2026-05-17T23:59:59-06:00"'),
  ('max_players', '128'),
  ('etransfer_email', '"tournament@email.com"'),
  ('contact_phone', '"(306) 555-1234"'),
  ('contact_wechat', '"saskatoon_badminton"'),
  ('payment_deadline_hours', '72');

-- ============================================
-- 5. 函数和触发器
-- ============================================

-- 5.1 管理员判断辅助函数（被多个 RPC 依赖，必须先创建）
CREATE OR REPLACE FUNCTION events_register.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN COALESCE(
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin',
    false
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- 5.2 计算年龄（基于比赛日期）
CREATE OR REPLACE FUNCTION events_register.calculate_age_on_date(
  birth_date DATE,
  target_date DATE DEFAULT '2026-05-24'
) RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(YEAR FROM age(target_date, birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5.3 检查队伍年龄之和
CREATE OR REPLACE FUNCTION events_register.check_team_age_requirement()
RETURNS TRIGGER AS $$
DECLARE
  p1_age INTEGER;
  p2_age INTEGER;
  min_sum INTEGER;
BEGIN
  SELECT events_register.calculate_age_on_date(date_of_birth) INTO p1_age
  FROM events_register.players WHERE id = NEW.player1_id;

  SELECT events_register.calculate_age_on_date(date_of_birth) INTO p2_age
  FROM events_register.players WHERE id = NEW.player2_id;

  SELECT min_age_sum INTO min_sum
  FROM events_register.categories WHERE id = NEW.category_id;

  NEW.combined_age := p1_age + p2_age;

  IF NEW.combined_age < min_sum THEN
    RAISE EXCEPTION 'Combined age (%) does not meet minimum requirement (%) for this category',
      NEW.combined_age, min_sum;
  END IF;

  IF p1_age < 35 OR p2_age < 35 THEN
    RAISE EXCEPTION 'Each player must be at least 35 years old on tournament date';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_team_age
  BEFORE INSERT OR UPDATE ON events_register.teams
  FOR EACH ROW EXECUTE FUNCTION events_register.check_team_age_requirement();

-- 5.4 检查选手是否已报名其他项目
CREATE OR REPLACE FUNCTION events_register.check_player_single_registration()
RETURNS TRIGGER AS $$
DECLARE
  existing_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO existing_count
  FROM events_register.teams
  WHERE (player1_id = NEW.player1_id OR player2_id = NEW.player1_id)
    AND status != 'cancelled'
    AND id != COALESCE(NEW.id, extensions.uuid_generate_v4());

  IF existing_count > 0 THEN
    RAISE EXCEPTION 'Player 1 is already registered in another team';
  END IF;

  SELECT COUNT(*) INTO existing_count
  FROM events_register.teams
  WHERE (player1_id = NEW.player2_id OR player2_id = NEW.player2_id)
    AND status != 'cancelled'
    AND id != COALESCE(NEW.id, extensions.uuid_generate_v4());

  IF existing_count > 0 THEN
    RAISE EXCEPTION 'Player 2 is already registered in another team';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_single_registration
  BEFORE INSERT OR UPDATE ON events_register.teams
  FOR EACH ROW EXECUTE FUNCTION events_register.check_player_single_registration();

-- 5.5 自动判断 gender_type
CREATE OR REPLACE FUNCTION events_register.auto_set_gender_type()
RETURNS TRIGGER AS $$
DECLARE
  p1_gender events_register.gender_enum;
  p2_gender events_register.gender_enum;
BEGIN
  SELECT gender INTO p1_gender FROM events_register.players WHERE id = NEW.player1_id;
  SELECT gender INTO p2_gender FROM events_register.players WHERE id = NEW.player2_id;

  IF p1_gender = 'male' AND p2_gender = 'male' THEN
    NEW.gender_type := 'mens';
  ELSIF p1_gender = 'female' AND p2_gender = 'female' THEN
    NEW.gender_type := 'womens';
  ELSE
    NEW.gender_type := 'mixed';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_gender_type
  BEFORE INSERT OR UPDATE ON events_register.teams
  FOR EACH ROW EXECUTE FUNCTION events_register.auto_set_gender_type();

-- 5.6 报名速率限制
CREATE OR REPLACE FUNCTION events_register.check_registration_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  recent_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO recent_count
  FROM events_register.players
  WHERE email = NEW.email
    AND created_at > NOW() - INTERVAL '5 minutes';

  IF recent_count > 0 THEN
    RAISE EXCEPTION 'Please wait before submitting again';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_rate_limit
  BEFORE INSERT ON events_register.players
  FOR EACH ROW EXECUTE FUNCTION events_register.check_registration_rate_limit();

-- 5.7 报名截止检查
CREATE OR REPLACE FUNCTION events_register.check_registration_open()
RETURNS TRIGGER AS $$
DECLARE
  is_open BOOLEAN;
  deadline TIMESTAMPTZ;
BEGIN
  SELECT (value::text)::boolean INTO is_open
  FROM events_register.tournament_config WHERE key = 'registration_open';

  SELECT (value::text)::timestamptz INTO deadline
  FROM events_register.tournament_config WHERE key = 'registration_deadline';

  IF NOT is_open OR NOW() > deadline THEN
    RAISE EXCEPTION 'Registration is closed';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_registration_open
  BEFORE INSERT ON events_register.teams
  FOR EACH ROW EXECUTE FUNCTION events_register.check_registration_open();

-- 5.8 名额检查（超出自动转 waitlist）
CREATE OR REPLACE FUNCTION events_register.check_category_capacity()
RETURNS TRIGGER AS $$
DECLARE
  current_count INTEGER;
  max_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO current_count
  FROM events_register.teams
  WHERE category_id = NEW.category_id
    AND status IN ('pending', 'confirmed');

  SELECT max_teams INTO max_count
  FROM events_register.categories
  WHERE id = NEW.category_id;

  IF current_count >= max_count THEN
    NEW.status := 'waitlist';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_capacity
  BEFORE INSERT ON events_register.teams
  FOR EACH ROW EXECUTE FUNCTION events_register.check_category_capacity();

-- 5.9 报名注册 RPC 函数
CREATE OR REPLACE FUNCTION events_register.register_team(
  p1_name_en TEXT,
  p1_email TEXT,
  p1_gender events_register.gender_enum,
  p1_dob DATE,
  p1_phone TEXT DEFAULT NULL,
  p1_wechat TEXT DEFAULT NULL,
  p2_name_en TEXT DEFAULT NULL,
  p2_email TEXT DEFAULT NULL,
  p2_gender events_register.gender_enum DEFAULT NULL,
  p2_dob DATE DEFAULT NULL,
  p2_phone TEXT DEFAULT NULL,
  p2_wechat TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL
) RETURNS JSONB
SECURITY DEFINER
SET search_path = events_register, extensions
AS $$
DECLARE
  v_p1_id UUID;
  v_p2_id UUID;
  v_team_id UUID;
  v_status events_register.team_status_enum;
  v_gender_type events_register.gender_type_enum;
  v_combined_age INTEGER;
BEGIN
  -- Find or create player 1
  SELECT id INTO v_p1_id
  FROM events_register.players WHERE email = p1_email;

  IF v_p1_id IS NULL THEN
    INSERT INTO events_register.players (name_en, email, gender, date_of_birth, phone, wechat_id)
    VALUES (p1_name_en, p1_email, p1_gender, p1_dob, p1_phone, p1_wechat)
    RETURNING id INTO v_p1_id;
  ELSE
    UPDATE events_register.players SET
      name_en = p1_name_en,
      gender = p1_gender,
      date_of_birth = p1_dob,
      phone = COALESCE(p1_phone, phone),
      wechat_id = COALESCE(p1_wechat, wechat_id)
    WHERE id = v_p1_id;
  END IF;

  -- Find or create player 2
  SELECT id INTO v_p2_id
  FROM events_register.players WHERE email = p2_email;

  IF v_p2_id IS NULL THEN
    INSERT INTO events_register.players (name_en, email, gender, date_of_birth, phone, wechat_id)
    VALUES (p2_name_en, p2_email, p2_gender, p2_dob, p2_phone, p2_wechat)
    RETURNING id INTO v_p2_id;
  ELSE
    UPDATE events_register.players SET
      name_en = p2_name_en,
      gender = p2_gender,
      date_of_birth = p2_dob,
      phone = COALESCE(p2_phone, phone),
      wechat_id = COALESCE(p2_wechat, wechat_id)
    WHERE id = v_p2_id;
  END IF;

  -- Insert team
  INSERT INTO events_register.teams (category_id, player1_id, player2_id)
  VALUES (p_category_id, v_p1_id, v_p2_id)
  RETURNING id, status, gender_type, combined_age
  INTO v_team_id, v_status, v_gender_type, v_combined_age;

  RETURN jsonb_build_object(
    'team_id', v_team_id,
    'status', v_status,
    'gender_type', v_gender_type,
    'combined_age', v_combined_age
  );
END;
$$ LANGUAGE plpgsql;

-- 5.10 管理员标记付款
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

-- 5.11 管理员更新队伍状态
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

-- 5.11b 管理员永久删除队伍及其孤立选手
CREATE OR REPLACE FUNCTION events_register.admin_delete_team(
  p_team_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_player1_id UUID;
  v_player2_id UUID;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  SELECT player1_id, player2_id INTO v_player1_id, v_player2_id
  FROM events_register.teams
  WHERE id = p_team_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Team not found: %', p_team_id;
  END IF;

  DELETE FROM events_register.teams WHERE id = p_team_id;

  DELETE FROM events_register.players p
  WHERE p.id IN (v_player1_id, v_player2_id)
    AND NOT EXISTS (
      SELECT 1 FROM events_register.teams t
      WHERE t.player1_id = p.id OR t.player2_id = p.id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5.12 管理员仪表盘统计（从 tournament_config 读取报名费）
CREATE OR REPLACE FUNCTION events_register.admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
  fee NUMERIC;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

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

-- 5.13 创建/更新赞助商
CREATE OR REPLACE FUNCTION events_register.admin_upsert_sponsor(
  p_id UUID DEFAULT NULL,
  p_name_zh TEXT DEFAULT '',
  p_name_en TEXT DEFAULT '',
  p_level TEXT DEFAULT 'friend',
  p_logo_url TEXT DEFAULT NULL,
  p_website TEXT DEFAULT NULL,
  p_contact_name TEXT DEFAULT NULL,
  p_contact_phone TEXT DEFAULT NULL,
  p_contact_email TEXT DEFAULT NULL,
  p_amount DECIMAL DEFAULT 0,
  p_is_confirmed BOOLEAN DEFAULT FALSE,
  p_description_zh TEXT DEFAULT NULL,
  p_description_en TEXT DEFAULT NULL,
  p_sort_order INTEGER DEFAULT 0
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  IF p_id IS NOT NULL THEN
    UPDATE events_register.sponsors SET
      name_zh = p_name_zh,
      name_en = p_name_en,
      level = p_level::events_register.sponsor_level_enum,
      logo_url = p_logo_url,
      website = p_website,
      contact_name = p_contact_name,
      contact_phone = p_contact_phone,
      contact_email = p_contact_email,
      amount = p_amount,
      is_confirmed = p_is_confirmed,
      description_zh = p_description_zh,
      description_en = p_description_en,
      sort_order = p_sort_order
    WHERE id = p_id
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Sponsor not found: %', p_id;
    END IF;
  ELSE
    INSERT INTO events_register.sponsors (
      name_zh, name_en, level, logo_url, website,
      contact_name, contact_phone, contact_email,
      amount, is_confirmed, description_zh, description_en, sort_order
    ) VALUES (
      p_name_zh, p_name_en, p_level::events_register.sponsor_level_enum,
      p_logo_url, p_website,
      p_contact_name, p_contact_phone, p_contact_email,
      p_amount, p_is_confirmed, p_description_zh, p_description_en, p_sort_order
    )
    RETURNING id INTO v_id;
  END IF;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5.14 删除赞助商
CREATE OR REPLACE FUNCTION events_register.admin_delete_sponsor(
  p_id UUID
)
RETURNS VOID AS $$
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  DELETE FROM events_register.sponsors WHERE id = p_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sponsor not found: %', p_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5.15 切换赞助商确认状态
CREATE OR REPLACE FUNCTION events_register.admin_toggle_sponsor_confirmed(
  p_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_new_status BOOLEAN;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  UPDATE events_register.sponsors
  SET is_confirmed = NOT is_confirmed
  WHERE id = p_id
  RETURNING is_confirmed INTO v_new_status;

  IF v_new_status IS NULL THEN
    RAISE EXCEPTION 'Sponsor not found: %', p_id;
  END IF;

  RETURN v_new_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5.16 管理员批量更新赛事配置
CREATE OR REPLACE FUNCTION events_register.admin_update_config(
  p_entries JSONB
)
RETURNS VOID AS $$
DECLARE
  entry JSONB;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  FOR entry IN SELECT * FROM jsonb_array_elements(p_entries)
  LOOP
    INSERT INTO events_register.tournament_config (key, value, updated_at)
    VALUES (entry->>'key', entry->'value', NOW())
    ON CONFLICT (key) DO UPDATE
    SET value = EXCLUDED.value, updated_at = NOW();
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5.17 设置管理员角色
CREATE OR REPLACE FUNCTION events_register.set_admin_role(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. 视图（最终版本，来自 010）
-- ============================================

-- 6.1 队伍详情视图（管理员用）
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

-- 6.2 各组别报名统计视图
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

-- 6.3 公开队伍查询函数（脱敏，来自 007）
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

-- ============================================
-- 7. Row Level Security 策略
-- ============================================

ALTER TABLE events_register.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.tournament_config ENABLE ROW LEVEL SECURITY;

-- categories: 所有人可读，管理员可写
CREATE POLICY "categories_select_all"
  ON events_register.categories FOR SELECT
  USING (true);

CREATE POLICY "categories_admin_all"
  ON events_register.categories FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- players: 匿名可插入，管理员可读写
CREATE POLICY "players_insert_anon"
  ON events_register.players FOR INSERT
  WITH CHECK (true);

CREATE POLICY "players_select_admin"
  ON events_register.players FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "players_update_admin"
  ON events_register.players FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "players_delete_admin"
  ON events_register.players FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');

-- teams: 匿名可插入，管理员可读写
CREATE POLICY "teams_insert_anon"
  ON events_register.teams FOR INSERT
  WITH CHECK (true);

CREATE POLICY "teams_select_admin"
  ON events_register.teams FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "teams_update_admin"
  ON events_register.teams FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "teams_delete_admin"
  ON events_register.teams FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');

-- sponsors: 公开可读已确认的，管理员全部可读写
CREATE POLICY "sponsors_select_confirmed"
  ON events_register.sponsors FOR SELECT
  USING (is_confirmed = true);

CREATE POLICY "sponsors_select_admin"
  ON events_register.sponsors FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "sponsors_admin_write"
  ON events_register.sponsors FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- tournament_config: 所有人可读，管理员可写
CREATE POLICY "config_select_all"
  ON events_register.tournament_config FOR SELECT
  USING (true);

CREATE POLICY "config_admin_write"
  ON events_register.tournament_config FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- ============================================
-- 8. 授权 Supabase 角色访问
-- ============================================

GRANT USAGE ON SCHEMA events_register TO anon, authenticated, service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA events_register TO anon, authenticated, service_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA events_register TO anon, authenticated, service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA events_register TO anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA events_register
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA events_register
  GRANT USAGE ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA events_register
  GRANT EXECUTE ON FUNCTIONS TO anon, authenticated, service_role;
