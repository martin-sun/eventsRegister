# 09 - 部署方案 / Deployment

## 部署平台：Cloudflare Pages

免费额度充足、全球 CDN、自动 SSL，非常适合本项目。

### 部署步骤

```bash
# 1. 安装 Cloudflare adapter
pnpm add -D @sveltejs/adapter-cloudflare

# 2. 推送到 GitHub，在 Cloudflare Dashboard 连接仓库自动部署
git push origin main
```

### svelte.config.js

```javascript
import adapter from '@sveltejs/adapter-cloudflare';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  kit: {
    adapter: adapter({
      // 如需使用 Cloudflare 特定功能可在此配置
      // routes: { include: ['/*'], exclude: ['<all>'] }
    }),
  },
};

export default config;
```

### Cloudflare Pages 项目配置

在 Cloudflare Dashboard → Pages → Create a project：

| 配置项 | 值 |
|--------|------|
| Framework preset | SvelteKit |
| Build command | `pnpm run build` |
| Build output directory | `.svelte-kit/cloudflare` |
| Node.js version | 18+ |

## 环境变量配置

在 Cloudflare Dashboard → Pages → Settings → Environment variables 中设置：

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `PUBLIC_SUPABASE_URL` | Supabase 项目 URL | `https://xxxxx.supabase.co` |
| `PUBLIC_SUPABASE_ANON_KEY` | Supabase 匿名 Key | `eyJhbGci...` |

注意：`PUBLIC_` 前缀表示这些变量会暴露给客户端，这是预期行为 — 安全性由 Supabase RLS 保障。

## 自定义域名

1. 在 Cloudflare Pages → Custom domains 中添加域名（如 `badminton.saskatoonchinese.ca`）
2. 如果域名已托管在 Cloudflare DNS，自动生效
3. 如果域名在其他注册商，添加 CNAME 记录指向 `<project>.pages.dev`
4. Cloudflare 自动签发 SSL 证书

## Supabase 项目设置

### 创建项目
1. 访问 [supabase.com](https://supabase.com) 创建项目
2. 选择 Region: `us-east-1`（距萨斯卡通最近的可用区域）
3. 记录项目 URL 和 anon key

### 执行数据库迁移
在 Supabase SQL Editor 中依次执行：
1. `02-database-schema.md` 中的建表 SQL
2. `08-supabase-rls.md` 中的 RLS 策略 SQL

### 创建 Storage Bucket
1. 在 Supabase Dashboard → Storage 中创建 `sponsor-logos` bucket
2. 设置为 Public bucket（允许匿名读取）

### 创建管理员账号
1. 在 Supabase Dashboard → Authentication 中创建管理员用户
2. 执行 `set_admin_role()` 函数授予管理员角色

## CI/CD 流程

```
GitHub Push → Cloudflare Pages Auto Deploy
     │
     ├── main 分支 → 生产环境 (production)
     └── 其他分支 → Preview 环境（自动生成 preview URL）
```

### 本地预览

```bash
# 使用 wrangler 本地测试 Cloudflare Pages 构建
pnpm add -D wrangler
pnpm run build
npx wrangler pages dev .svelte-kit/cloudflare
```

## 上线前检查清单

- [ ] Supabase 数据库迁移完成
- [ ] RLS 策略全部启用
- [ ] 管理员账号创建完成
- [ ] 赞助商 Logo 上传完毕
- [ ] 中英文翻译检查完毕
- [ ] 移动端响应式测试
- [ ] 报名流程端到端测试
- [ ] Cloudflare Pages 环境变量配置正确
- [ ] 自定义域名 + SSL 配置
- [ ] 报名页面显示正确的付款信息
- [ ] 倒计时显示正确
- [ ] 各组别名额上限配置正确
