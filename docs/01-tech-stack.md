# 01 - 技术栈与项目初始化 / Tech Stack & Setup

## 技术栈

| 类别 | 技术 | 说明 |
|------|------|------|
| 前端框架 | SvelteKit | SSR + SPA，快速、轻量 |
| 样式 | Tailwind CSS | 实用优先的 CSS 框架 |
| UI 组件 | shadcn-svelte | 基于 Tailwind 的组件库 |
| 数据库 | Supabase (PostgreSQL) | 含 Auth、Storage、Realtime |
| 国际化 | sveltekit-i18n 或 paraglide-js | 中英文双语 |
| 部署 | Cloudflare Pages | 全球 CDN、免费 SSL、自动部署 |
| 包管理 | pnpm | 快速、节省磁盘 |

## 项目初始化命令

```bash
# 创建 SvelteKit 项目
pnpm create svelte@latest saskatoon-badminton
cd saskatoon-badminton

# 安装核心依赖
pnpm add @supabase/supabase-js
pnpm add -D tailwindcss postcss autoprefixer
pnpm add -D @tailwindcss/forms @tailwindcss/typography

# 安装 shadcn-svelte（可选，推荐）
pnpm add -D bits-ui clsx tailwind-merge tailwind-variants

# 安装 i18n
pnpm add @inlang/paraglide-sveltekit

# 初始化 Tailwind
npx tailwindcss init -p
```

## 项目目录结构

```
saskatoon-badminton/
├── src/
│   ├── lib/
│   │   ├── components/          # 公共组件
│   │   │   ├── Header.svelte
│   │   │   ├── Footer.svelte
│   │   │   ├── LanguageSwitcher.svelte
│   │   │   ├── RegistrationForm.svelte
│   │   │   ├── TeamCard.svelte
│   │   │   ├── SponsorBanner.svelte
│   │   │   └── CountdownTimer.svelte
│   │   ├── i18n/                # 国际化
│   │   │   ├── zh.json          # 中文翻译
│   │   │   └── en.json          # 英文翻译
│   │   ├── supabase.ts          # Supabase 客户端初始化
│   │   ├── types.ts             # TypeScript 类型定义
│   │   └── utils.ts             # 工具函数（年龄计算等）
│   ├── routes/
│   │   ├── +layout.svelte       # 全局布局（Header + Footer + 语言切换）
│   │   ├── +page.svelte         # 首页（赛事介绍）
│   │   ├── register/
│   │   │   └── +page.svelte     # 报名页面
│   │   ├── teams/
│   │   │   └── +page.svelte     # 已报名队伍展示
│   │   ├── rules/
│   │   │   └── +page.svelte     # 赛制规则
│   │   ├── sponsors/
│   │   │   └── +page.svelte     # 赞助商展示
│   │   └── admin/
│   │       ├── +page.svelte     # 管理后台首页
│   │       ├── registrations/
│   │       │   └── +page.svelte # 报名管理
│   │       └── sponsors/
│   │           └── +page.svelte # 赞助商管理
│   └── app.html
├── static/
│   ├── images/                  # 赞助商 logo 等静态资源
│   └── favicon.ico
├── supabase/
│   └── migrations/              # 数据库迁移文件
│       └── 001_init.sql
├── messages/                    # paraglide 翻译文件
│   ├── zh.json
│   └── en.json
├── svelte.config.js
├── tailwind.config.js
├── vite.config.ts
└── package.json
```

## 环境变量

```env
# .env.local
PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
```

## Supabase 客户端初始化

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import { PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY } from '$env/static/public'
import type { Database } from './types'

export const supabase = createClient<Database>(
  PUBLIC_SUPABASE_URL,
  PUBLIC_SUPABASE_ANON_KEY
)
```
