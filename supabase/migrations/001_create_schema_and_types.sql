-- ============================================
-- 001: 创建独立 Schema 和枚举类型
-- events_register schema 与其他项目隔离
-- ============================================

-- 创建独立 schema
CREATE SCHEMA IF NOT EXISTS events_register;

-- 启用 UUID 扩展（全局共享）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- 设置搜索路径
SET search_path TO events_register, extensions, public;

-- ============================================
-- 枚举类型
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
