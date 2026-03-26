-- ============================================
-- 008: 报名注册 RPC 函数（SECURITY DEFINER）
-- ============================================
-- 因为 players/teams 表的 RLS 不允许匿名用户 SELECT，
-- 所以无法通过普通 insert().select('id') 获取插入后的 ID。
-- 此函数以 SECURITY DEFINER 方式运行，绕过 RLS 完成整个报名流程。
-- 现有触发器（年龄校验、性别类型、名额检查等）仍然正常触发。
--
-- 注意：不使用 INSERT ON CONFLICT，因为 BEFORE INSERT 触发器
-- （check_registration_rate_limit）会在 ON CONFLICT 检测之前触发，
-- 导致已有邮箱的选手报名失败。改为显式检查后插入或更新。

SET search_path TO events_register, extensions, public;

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
  -- 1. Find or create player 1
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

  -- 2. Find or create player 2
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

  -- 3. Insert team (triggers handle: age validation, gender_type, capacity, registration open check)
  INSERT INTO events_register.teams (category_id, player1_id, player2_id)
  VALUES (p_category_id, v_p1_id, v_p2_id)
  RETURNING id, status, gender_type, combined_age
  INTO v_team_id, v_status, v_gender_type, v_combined_age;

  -- 4. Return result
  RETURN jsonb_build_object(
    'team_id', v_team_id,
    'status', v_status,
    'gender_type', v_gender_type,
    'combined_age', v_combined_age
  );
END;
$$ LANGUAGE plpgsql;
