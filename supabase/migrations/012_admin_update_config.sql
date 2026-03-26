-- ============================================
-- 012: 管理员更新赛事配置 RPC 函数
-- ============================================

-- 批量更新配置项（upsert）
CREATE OR REPLACE FUNCTION events_register.admin_update_config(
  p_entries JSONB  -- e.g. [{"key":"etransfer_email","value":"a@b.com"}, ...]
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
