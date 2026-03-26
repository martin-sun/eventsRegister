-- ============================================
-- 002: 创建数据表
-- ============================================

SET search_path TO events_register, extensions, public;

-- ============================================
-- 1. 比赛项目表 categories
-- ============================================
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

-- ============================================
-- 2. 选手表 players
-- ============================================
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

-- ============================================
-- 3. 队伍表 teams
-- ============================================
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
  seed            INTEGER,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT team_different_players CHECK (player1_id != player2_id)
);

CREATE INDEX idx_teams_category ON events_register.teams(category_id);
CREATE INDEX idx_teams_status ON events_register.teams(status);
CREATE INDEX idx_teams_player1 ON events_register.teams(player1_id);
CREATE INDEX idx_teams_player2 ON events_register.teams(player2_id);

-- ============================================
-- 4. 赞助商表 sponsors
-- ============================================
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

-- ============================================
-- 5. 赛事配置表 tournament_config
-- ============================================
CREATE TABLE events_register.tournament_config (
  key         TEXT PRIMARY KEY,
  value       JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 初始数据：比赛项目
-- ============================================
INSERT INTO events_register.categories (name_en, name_zh, slug, min_age_sum, max_teams, sort_order) VALUES
  ('Doubles 100+ Group', '双打100岁组', 'doubles-100', 100, 32, 1),
  ('Doubles 80+ Group',  '双打80岁组',  'doubles-80',  80,  32, 2);

-- ============================================
-- 初始数据：已确认赞助商
-- ============================================
INSERT INTO events_register.sponsors (name_zh, name_en, level, amount, is_confirmed, sort_order) VALUES
  ('林与唐地产公司', 'Lin & Tang Real Estate', 'title', 1200, TRUE, 1),
  ('海外新生活', 'Overseas New Life', 'media', 0, TRUE, 100);

-- ============================================
-- 初始数据：赛事配置
-- ============================================
INSERT INTO events_register.tournament_config (key, value) VALUES
  ('tournament_date', '"2026-05-24T09:30:00-06:00"'),
  ('venue', '{"en": "Riverside Badminton & Tennis Club", "zh": "Riverside 羽毛球网球俱乐部"}'),
  ('registration_fee', '30'),
  ('min_age', '35'),
  ('registration_open', 'true'),
  ('registration_deadline', '"2026-05-17T23:59:59-06:00"'),
  ('max_players', '128');
