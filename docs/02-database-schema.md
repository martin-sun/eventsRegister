# 02 - 数据库设计 / Database Schema

## ER 关系图

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   players   │     │    teams     │     │  categories │
│─────────────│     │──────────────│     │─────────────│
│ id (PK)     │──┐  │ id (PK)      │  ┌──│ id (PK)     │
│ name_zh     │  │  │ category_id  │──┘  │ name_en     │
│ name_en     │  │  │ player1_id   │──┐  │ name_zh     │
│ email       │  ├──│ player2_id   │──┘  │ min_age_sum │
│ phone       │  │  │ team_name    │     │ max_teams   │
│ gender      │  │  │ gender_type  │     │ is_open     │
│ date_of_birth│  │  │ combined_age │     └─────────────┘
│ wechat_id   │  │  │ status       │
│ created_at  │  │  │ payment_status│    ┌─────────────┐
└─────────────┘  │  │ created_at   │    │  sponsors   │
                 │  └──────────────┘    │─────────────│
                 │                      │ id (PK)     │
                 │                      │ name_zh     │
                 │                      │ name_en     │
                 │                      │ level       │
                 │                      │ logo_url    │
                 │                      │ website     │
                 │                      │ contact     │
                 │                      │ amount      │
                 │                      │ is_confirmed│
                 │                      └─────────────┘
                 │
                 │  ┌──────────────────┐
                 │  │  registrations   │
                 │  │──────────────────│
                 └──│ id (PK)          │
                    │ player_id (FK)   │
                    │ team_id (FK)     │
                    │ role             │
                    │ registered_at    │
                    └──────────────────┘
```

## SQL 建表语句

```sql
-- ============================================
-- 001_init.sql — Supabase Migration
-- ============================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. 比赛项目表 categories
-- ============================================
CREATE TABLE categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_en     TEXT NOT NULL,             -- 'Doubles 100+ Group'
  name_zh     TEXT NOT NULL,             -- '双打100岁组'
  slug        TEXT NOT NULL UNIQUE,      -- 'doubles-100', 'doubles-80'
  min_age_sum INTEGER NOT NULL,          -- 100 或 80
  max_teams   INTEGER NOT NULL DEFAULT 32,
  is_open     BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 初始数据
INSERT INTO categories (name_en, name_zh, slug, min_age_sum, max_teams, sort_order) VALUES
  ('Doubles 100+ Group', '双打100岁组', 'doubles-100', 100, 32, 1),
  ('Doubles 80+ Group',  '双打80岁组',  'doubles-80',  80,  32, 2);

-- ============================================
-- 2. 选手表 players
-- ============================================
CREATE TYPE gender_enum AS ENUM ('male', 'female');

CREATE TABLE players (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_zh        TEXT,                    -- 中文姓名（可选）
  name_en        TEXT NOT NULL,           -- 英文姓名（必填）
  email          TEXT NOT NULL,
  phone          TEXT,
  gender         gender_enum NOT NULL,
  date_of_birth  DATE NOT NULL,
  wechat_id      TEXT,                    -- 微信号（可选）
  notes          TEXT,                    -- 备注
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- 确保 email 唯一（同一赛事不重复报名）
  CONSTRAINT players_email_unique UNIQUE (email)
);

-- ============================================
-- 3. 队伍表 teams
-- ============================================
CREATE TYPE gender_type_enum AS ENUM ('mens', 'womens', 'mixed');
CREATE TYPE team_status_enum AS ENUM ('pending', 'confirmed', 'waitlist', 'cancelled');
CREATE TYPE payment_status_enum AS ENUM ('unpaid', 'paid', 'refunded');

CREATE TABLE teams (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id     UUID NOT NULL REFERENCES categories(id),
  player1_id      UUID NOT NULL REFERENCES players(id),
  player2_id      UUID NOT NULL REFERENCES players(id),
  team_name_zh    TEXT,                   -- 队伍中文名（可选）
  team_name_en    TEXT,                   -- 队伍英文名（可选）
  gender_type     gender_type_enum NOT NULL, -- 男双/女双/混双
  combined_age    INTEGER NOT NULL,       -- 两人年龄之和（取整后）
  status          team_status_enum NOT NULL DEFAULT 'pending',
  payment_status  payment_status_enum NOT NULL DEFAULT 'unpaid',
  seed            INTEGER,               -- 种子排名（可选）
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- 两个选手不能相同
  CONSTRAINT team_different_players CHECK (player1_id != player2_id)
);

-- 索引：加速查询
CREATE INDEX idx_teams_category ON teams(category_id);
CREATE INDEX idx_teams_status ON teams(status);
CREATE INDEX idx_teams_player1 ON teams(player1_id);
CREATE INDEX idx_teams_player2 ON teams(player2_id);

-- ============================================
-- 4. 赞助商表 sponsors
-- ============================================
CREATE TYPE sponsor_level_enum AS ENUM (
  'title',     -- 冠名赞助
  'diamond',   -- 钻石赞助 $800
  'platinum',  -- 白金赞助 $500
  'gold',      -- 黄金赞助 $300
  'friend',    -- 友情赞助 $100
  'media'      -- 媒体支持
);

CREATE TABLE sponsors (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name_zh       TEXT NOT NULL,
  name_en       TEXT NOT NULL,
  level         sponsor_level_enum NOT NULL,
  logo_url      TEXT,                     -- Supabase Storage URL
  website       TEXT,
  contact_name  TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  amount        DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_confirmed  BOOLEAN NOT NULL DEFAULT FALSE,
  description_zh TEXT,                    -- 赞助商描述（中文）
  description_en TEXT,                    -- 赞助商描述（英文）
  sort_order    INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sponsors_level ON sponsors(level);

-- 初始赞助商数据
INSERT INTO sponsors (name_zh, name_en, level, amount, is_confirmed, sort_order) VALUES
  ('林与唐地产公司', 'Lin & Tang Real Estate', 'title', 1200, TRUE, 1),
  ('海外新生活', 'Overseas New Life', 'media', 0, TRUE, 100);

-- ============================================
-- 5. 赛事配置表 tournament_config
-- ============================================
CREATE TABLE tournament_config (
  key         TEXT PRIMARY KEY,
  value       JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 初始配置
INSERT INTO tournament_config (key, value) VALUES
  ('tournament_date', '"2026-05-24T09:30:00-06:00"'),
  ('venue', '{"en": "Riverside Badminton & Tennis Club", "zh": "Riverside 羽毛球网球俱乐部"}'),
  ('registration_fee', '30'),
  ('min_age', '35'),
  ('registration_open', 'true'),
  ('registration_deadline', '"2026-05-17T23:59:59-06:00"'),
  ('max_players', '128');

-- ============================================
-- 6. 数据库函数：计算年龄（取整）
-- ============================================
CREATE OR REPLACE FUNCTION calculate_age_on_date(
  birth_date DATE,
  target_date DATE DEFAULT '2026-05-24'
) RETURNS INTEGER AS $$
BEGIN
  RETURN EXTRACT(YEAR FROM age(target_date, birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- 7. 数据库函数：检查队伍年龄之和
-- ============================================
CREATE OR REPLACE FUNCTION check_team_age_requirement()
RETURNS TRIGGER AS $$
DECLARE
  p1_age INTEGER;
  p2_age INTEGER;
  min_sum INTEGER;
BEGIN
  -- 获取两位选手的年龄
  SELECT calculate_age_on_date(date_of_birth) INTO p1_age
  FROM players WHERE id = NEW.player1_id;

  SELECT calculate_age_on_date(date_of_birth) INTO p2_age
  FROM players WHERE id = NEW.player2_id;

  -- 获取组别最低年龄之和
  SELECT min_age_sum INTO min_sum
  FROM categories WHERE id = NEW.category_id;

  -- 计算并存储 combined_age
  NEW.combined_age := p1_age + p2_age;

  -- 验证年龄之和
  IF NEW.combined_age < min_sum THEN
    RAISE EXCEPTION 'Combined age (%) does not meet minimum requirement (%) for this category',
      NEW.combined_age, min_sum;
  END IF;

  -- 验证每位选手至少35岁
  IF p1_age < 35 OR p2_age < 35 THEN
    RAISE EXCEPTION 'Each player must be at least 35 years old on tournament date';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_team_age
  BEFORE INSERT OR UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION check_team_age_requirement();

-- ============================================
-- 8. 数据库函数：检查选手是否已报名其他项目
-- ============================================
CREATE OR REPLACE FUNCTION check_player_single_registration()
RETURNS TRIGGER AS $$
DECLARE
  existing_count INTEGER;
BEGIN
  -- 检查 player1 是否已在其他有效队伍中
  SELECT COUNT(*) INTO existing_count
  FROM teams
  WHERE (player1_id = NEW.player1_id OR player2_id = NEW.player1_id)
    AND status != 'cancelled'
    AND id != COALESCE(NEW.id, uuid_generate_v4());

  IF existing_count > 0 THEN
    RAISE EXCEPTION 'Player 1 is already registered in another team';
  END IF;

  -- 检查 player2 是否已在其他有效队伍中
  SELECT COUNT(*) INTO existing_count
  FROM teams
  WHERE (player1_id = NEW.player2_id OR player2_id = NEW.player2_id)
    AND status != 'cancelled'
    AND id != COALESCE(NEW.id, uuid_generate_v4());

  IF existing_count > 0 THEN
    RAISE EXCEPTION 'Player 2 is already registered in another team';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_single_registration
  BEFORE INSERT OR UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION check_player_single_registration();

-- ============================================
-- 9. 数据库函数：自动判断 gender_type
-- ============================================
CREATE OR REPLACE FUNCTION auto_set_gender_type()
RETURNS TRIGGER AS $$
DECLARE
  p1_gender gender_enum;
  p2_gender gender_enum;
BEGIN
  SELECT gender INTO p1_gender FROM players WHERE id = NEW.player1_id;
  SELECT gender INTO p2_gender FROM players WHERE id = NEW.player2_id;

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
  BEFORE INSERT OR UPDATE ON teams
  FOR EACH ROW EXECUTE FUNCTION auto_set_gender_type();

-- ============================================
-- 10. 视图：队伍详情（方便前端查询）
-- ============================================
CREATE OR REPLACE VIEW teams_detail AS
SELECT
  t.id AS team_id,
  t.team_name_zh,
  t.team_name_en,
  t.gender_type,
  t.combined_age,
  t.status,
  t.payment_status,
  t.seed,
  t.created_at,
  c.name_en AS category_en,
  c.name_zh AS category_zh,
  c.slug AS category_slug,
  p1.name_en AS player1_name_en,
  p1.name_zh AS player1_name_zh,
  p1.gender AS player1_gender,
  calculate_age_on_date(p1.date_of_birth) AS player1_age,
  p2.name_en AS player2_name_en,
  p2.name_zh AS player2_name_zh,
  p2.gender AS player2_gender,
  calculate_age_on_date(p2.date_of_birth) AS player2_age
FROM teams t
JOIN categories c ON t.category_id = c.id
JOIN players p1 ON t.player1_id = p1.id
JOIN players p2 ON t.player2_id = p2.id
WHERE t.status != 'cancelled';

-- ============================================
-- 11. 视图：各组别报名统计
-- ============================================
CREATE OR REPLACE VIEW category_stats AS
SELECT
  c.id,
  c.name_en,
  c.name_zh,
  c.slug,
  c.max_teams,
  c.is_open,
  COUNT(t.id) FILTER (WHERE t.status IN ('pending', 'confirmed')) AS registered_teams,
  c.max_teams - COUNT(t.id) FILTER (WHERE t.status IN ('pending', 'confirmed')) AS remaining_slots
FROM categories c
LEFT JOIN teams t ON c.id = t.category_id
GROUP BY c.id, c.name_en, c.name_zh, c.slug, c.max_teams, c.is_open;
```

## 数据模型说明

### players（选手）
- `name_zh` 可选，`name_en` 必填 — 照顾非华人选手
- `wechat_id` 可选 — 华人社区常用联系方式
- `email` 唯一约束 — 防止同一选手重复报名
- `date_of_birth` 存储出生日期，年龄由数据库函数动态计算

### teams（队伍）
- `gender_type` 由 trigger 自动根据两位选手性别设置
- `combined_age` 由 trigger 自动计算并校验
- `status` 流转：`pending` → `confirmed` → `cancelled`
- `payment_status`：`unpaid` → `paid` → `refunded`

### 数据库级约束（Triggers）
1. **年龄校验** — 每位选手≥35岁，且年龄之和满足组别要求
2. **单项目校验** — 每位选手只能在一个有效队伍中
3. **性别类型自动设置** — 根据选手性别自动判断男双/女双/混双
