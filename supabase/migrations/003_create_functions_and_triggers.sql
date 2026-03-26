-- ============================================
-- 003: 数据库函数和触发器
-- ============================================

SET search_path TO events_register, extensions, public;

-- ============================================
-- 1. 计算年龄（基于比赛日期）
-- ============================================
CREATE OR REPLACE FUNCTION events_register.calculate_age_on_date(
  birth_date DATE,
  target_date DATE DEFAULT '2026-05-24'
) RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(YEAR FROM age(target_date, birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 2. 检查队伍年龄之和
-- ============================================
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

-- ============================================
-- 3. 检查选手是否已报名其他项目
-- ============================================
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

-- ============================================
-- 4. 自动判断 gender_type
-- ============================================
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

-- ============================================
-- 5. 报名速率限制
-- ============================================
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

-- ============================================
-- 6. 报名截止检查
-- ============================================
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

-- ============================================
-- 7. 名额检查（超出自动转 waitlist）
-- ============================================
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
