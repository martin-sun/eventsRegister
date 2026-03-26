-- ============================================
-- 006: 授权 Supabase 角色访问 events_register schema
-- anon = 匿名用户, authenticated = 已登录用户
-- 行级权限由 RLS 策略控制（005）
-- ============================================

GRANT USAGE ON SCHEMA events_register TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA events_register TO anon, authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA events_register TO anon, authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA events_register TO anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA events_register
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA events_register
  GRANT USAGE ON SEQUENCES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA events_register
  GRANT EXECUTE ON FUNCTIONS TO anon, authenticated;
