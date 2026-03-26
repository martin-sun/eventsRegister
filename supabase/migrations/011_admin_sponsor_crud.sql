-- ============================================
-- 011: 赞助商管理 CRUD RPC 函数
-- ============================================

-- 1. 创建/更新赞助商
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
    -- Update
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
    -- Insert
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

-- 2. 删除赞助商
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

-- 3. 切换赞助商确认状态
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
