-- ============================================
-- 005: Row Level Security 策略
-- ============================================

-- ============================================
-- 启用 RLS
-- ============================================
ALTER TABLE events_register.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_register.tournament_config ENABLE ROW LEVEL SECURITY;

-- ============================================
-- categories: 所有人可读，管理员可写
-- ============================================
CREATE POLICY "categories_select_all"
  ON events_register.categories FOR SELECT
  USING (true);

CREATE POLICY "categories_admin_all"
  ON events_register.categories FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- ============================================
-- players: 匿名可插入，管理员可读写
-- ============================================
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

-- ============================================
-- teams: 匿名可插入，管理员可读写
-- ============================================
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

-- ============================================
-- sponsors: 公开可读已确认的，管理员全部可读写
-- ============================================
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

-- ============================================
-- tournament_config: 所有人可读，管理员可写
-- ============================================
CREATE POLICY "config_select_all"
  ON events_register.tournament_config FOR SELECT
  USING (true);

CREATE POLICY "config_admin_write"
  ON events_register.tournament_config FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- ============================================
-- 管理员角色设置函数
-- ============================================
CREATE OR REPLACE FUNCTION events_register.set_admin_role(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
