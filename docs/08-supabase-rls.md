# 08 - Supabase 安全策略 / Supabase RLS & Security

## 设计原则

由于没有后端 API，所有数据操作都通过 Supabase Client 直接执行。安全性完全依赖于：

1. **Row Level Security (RLS)** — 行级安全策略
2. **Database Triggers** — 数据库级业务规则校验
3. **Supabase Auth** — 管理员身份认证

## 用户角色

| 角色 | 说明 | 认证方式 |
|------|------|----------|
| 匿名用户 (anon) | 普通访客，可浏览信息和提交报名 | 无需登录 |
| 管理员 (admin) | 组委会成员，可管理所有数据 | Supabase Auth 邮箱登录 |

## RLS 策略

### 启用 RLS

```sql
ALTER TABLE players ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_config ENABLE ROW LEVEL SECURITY;
```

### categories（比赛项目）

```sql
-- 所有人可读
CREATE POLICY "categories_select_all"
  ON categories FOR SELECT
  USING (true);

-- 仅管理员可写
CREATE POLICY "categories_admin_all"
  ON categories FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');
```

### players（选手）

```sql
-- 匿名用户可以插入新选手（报名时）
CREATE POLICY "players_insert_anon"
  ON players FOR INSERT
  WITH CHECK (true);

-- 匿名用户不能读取选手详细信息（隐私保护）
-- 只有管理员可以查看完整选手信息
CREATE POLICY "players_select_admin"
  ON players FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- 仅管理员可以更新和删除
CREATE POLICY "players_update_admin"
  ON players FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "players_delete_admin"
  ON players FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');
```

### teams（队伍）

```sql
-- 匿名用户可以插入新队伍（报名时）
CREATE POLICY "teams_insert_anon"
  ON teams FOR INSERT
  WITH CHECK (true);

-- 所有人可以通过视图读取队伍信息（脱敏后的公开信息）
-- 但直接查询 teams 表仅限管理员
CREATE POLICY "teams_select_admin"
  ON teams FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- 仅管理员可以更新和删除
CREATE POLICY "teams_update_admin"
  ON teams FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "teams_delete_admin"
  ON teams FOR DELETE
  USING (auth.jwt() ->> 'role' = 'admin');
```

### teams_detail 视图（公开的队伍展示）

```sql
-- 视图不受 RLS 约束，但我们用 SECURITY DEFINER 函数来提供脱敏数据
CREATE OR REPLACE FUNCTION get_public_teams()
RETURNS TABLE (
  team_id UUID,
  category_slug TEXT,
  category_zh TEXT,
  category_en TEXT,
  gender_type gender_type_enum,
  combined_age INTEGER,
  player1_display_name TEXT,  -- 脱敏：只显示姓 + 名首字母
  player2_display_name TEXT,
  created_at TIMESTAMPTZ
) SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    c.slug,
    c.name_zh,
    c.name_en,
    t.gender_type,
    t.combined_age,
    -- 英文名脱敏：John Smith → John S.
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
    t.created_at
  FROM teams t
  JOIN categories c ON t.category_id = c.id
  JOIN players p1 ON t.player1_id = p1.id
  JOIN players p2 ON t.player2_id = p2.id
  WHERE t.status IN ('pending', 'confirmed');
END;
$$ LANGUAGE plpgsql;
```

### sponsors（赞助商）

```sql
-- 所有人可读已确认的赞助商
CREATE POLICY "sponsors_select_confirmed"
  ON sponsors FOR SELECT
  USING (is_confirmed = true);

-- 管理员可读所有赞助商（含未确认）
CREATE POLICY "sponsors_select_admin"
  ON sponsors FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

-- 仅管理员可写
CREATE POLICY "sponsors_admin_write"
  ON sponsors FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');
```

### tournament_config（赛事配置）

```sql
-- 所有人可读
CREATE POLICY "config_select_all"
  ON tournament_config FOR SELECT
  USING (true);

-- 仅管理员可写
CREATE POLICY "config_admin_write"
  ON tournament_config FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');
```

## 管理员角色设置

通过 Supabase Auth 的 Custom Claims 设置管理员角色：

```sql
-- 在 Supabase SQL Editor 中执行
-- 为指定用户设置 admin 角色
CREATE OR REPLACE FUNCTION set_admin_role(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || '{"role": "admin"}'::jsonb
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 使用方法：在 Supabase Dashboard 找到用户 ID 后执行
-- SELECT set_admin_role('用户的UUID');
```

## 报名防滥用措施

### 1. 速率限制
虽然 Supabase 不原生支持细粒度速率限制，但可以通过以下方式实现：

```sql
-- 限制同一 IP/session 在短时间内的报名次数
-- 通过检查 created_at 时间窗口实现
CREATE OR REPLACE FUNCTION check_registration_rate_limit()
RETURNS TRIGGER AS $$
DECLARE
  recent_count INTEGER;
BEGIN
  -- 同一邮箱5分钟内只能报名一次
  SELECT COUNT(*) INTO recent_count
  FROM players
  WHERE email = NEW.email
    AND created_at > NOW() - INTERVAL '5 minutes';

  IF recent_count > 0 THEN
    RAISE EXCEPTION 'Please wait before submitting again';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### 2. 报名截止自动关闭

```sql
-- 在 teams INSERT 时检查报名是否开放
CREATE OR REPLACE FUNCTION check_registration_open()
RETURNS TRIGGER AS $$
DECLARE
  is_open BOOLEAN;
  deadline TIMESTAMPTZ;
BEGIN
  SELECT (value::text)::boolean INTO is_open
  FROM tournament_config WHERE key = 'registration_open';

  SELECT (value::text)::timestamptz INTO deadline
  FROM tournament_config WHERE key = 'registration_deadline';

  IF NOT is_open OR NOW() > deadline THEN
    RAISE EXCEPTION 'Registration is closed';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_registration_open
  BEFORE INSERT ON teams
  FOR EACH ROW EXECUTE FUNCTION check_registration_open();
```

### 3. 名额检查

```sql
-- 在 teams INSERT 时检查组别名额
CREATE OR REPLACE FUNCTION check_category_capacity()
RETURNS TRIGGER AS $$
DECLARE
  current_count INTEGER;
  max_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO current_count
  FROM teams
  WHERE category_id = NEW.category_id
    AND status IN ('pending', 'confirmed');

  SELECT max_teams INTO max_count
  FROM categories
  WHERE id = NEW.category_id;

  IF current_count >= max_count THEN
    NEW.status := 'waitlist';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_capacity
  BEFORE INSERT ON teams
  FOR EACH ROW EXECUTE FUNCTION check_category_capacity();
```

## Supabase Storage 安全策略

```sql
-- sponsor-logos bucket: 公开读，仅管理员写
CREATE POLICY "sponsor_logos_select"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'sponsor-logos');

CREATE POLICY "sponsor_logos_insert_admin"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'sponsor-logos'
    AND auth.jwt() ->> 'role' = 'admin'
  );

CREATE POLICY "sponsor_logos_delete_admin"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'sponsor-logos'
    AND auth.jwt() ->> 'role' = 'admin'
  );
```
