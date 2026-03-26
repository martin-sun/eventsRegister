# 05 - 报名流程与业务逻辑 / Registration Flow

## 报名流程图

```
用户访问报名页面
        │
        ▼
┌─────────────────┐
│  检查报名是否开放  │ ← tournament_config.registration_open
└────────┬────────┘
         │
    ┌────┴────┐
    │ 已关闭?  │──是──→ 显示"报名已截止"
    └────┬────┘
         │ 否
         ▼
┌─────────────────┐
│  选择比赛组别     │
│  100岁组 / 80岁组│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  检查该组是否满员  │ ← category_stats.remaining_slots
└────────┬────────┘
         │
    ┌────┴────┐
    │ 已满员?  │──是──→ 显示"该组已满"，可选择另一组或加入候补
    └────┬────┘
         │ 否
         ▼
┌─────────────────┐
│  填写选手1信息    │
│  (姓名/性别/DOB  │
│   /邮箱/电话等)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  前端校验选手1    │
│  - 年龄 ≥ 35    │
│  - 邮箱格式     │
│  - 必填字段     │
└────────┬────────┘
         │ 通过
         ▼
┌─────────────────┐
│  填写选手2信息    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  前端校验选手2    │
│  + 年龄之和校验  │
│  + 自动判断类型  │
│    (男双/女双/混双)│
└────────┬────────┘
         │ 通过
         ▼
┌─────────────────┐
│  确认信息页      │
│  展示所有信息    │
│  + 费用说明      │
└────────┬────────┘
         │ 用户确认
         ▼
┌─────────────────────────────────┐
│  Supabase 事务操作               │
│                                  │
│  1. INSERT player1 → players     │
│     (ON CONFLICT email → 更新)  │
│  2. INSERT player2 → players     │
│     (ON CONFLICT email → 更新)  │
│  3. INSERT team → teams          │
│     (触发 trigger 校验:          │
│      - 年龄校验                  │
│      - 单项目校验                │
│      - 自动设置 gender_type)     │
│  4. 检查组别名额                 │
└────────┬────────────────────────┘
         │
    ┌────┴────┐
    │ 成功?   │──否──→ 显示具体错误信息
    └────┬────┘        (年龄不足/已报名/满员等)
         │ 是
         ▼
┌─────────────────┐
│  报名成功页面           │
│  - 显示付款参考号       │
│    (team ID 前8位大写)  │
│  - E-Transfer 付款指引  │
│    (收款邮箱/金额/备注) │
│  - 组委会联系方式       │
└─────────────────────────┘
```

## 核心业务逻辑（前端）

### 年龄计算函数

```typescript
// src/lib/utils.ts

const TOURNAMENT_DATE = new Date('2026-05-24');

/**
 * 计算选手在比赛日的年龄（取整，向下取整）
 * 如：40.5岁 → 40岁
 */
export function calculateAge(dateOfBirth: Date): number {
  const birth = new Date(dateOfBirth);
  let age = TOURNAMENT_DATE.getFullYear() - birth.getFullYear();
  const monthDiff = TOURNAMENT_DATE.getMonth() - birth.getMonth();

  if (monthDiff < 0 || (monthDiff === 0 && TOURNAMENT_DATE.getDate() < birth.getDate())) {
    age--;
  }

  return age; // 自然取整（向下）
}

/**
 * 校验选手年龄是否满足最低要求
 */
export function isAgeEligible(dateOfBirth: Date): boolean {
  return calculateAge(dateOfBirth) >= 35;
}

/**
 * 校验队伍年龄之和是否满足组别要求
 */
export function isCombinedAgeEligible(
  dob1: Date,
  dob2: Date,
  minAgeSum: number
): boolean {
  return calculateAge(dob1) + calculateAge(dob2) >= minAgeSum;
}

/**
 * 根据两位选手性别判断队伍类型
 */
export function getGenderType(
  gender1: 'male' | 'female',
  gender2: 'male' | 'female'
): 'mens' | 'womens' | 'mixed' {
  if (gender1 === 'male' && gender2 === 'male') return 'mens';
  if (gender1 === 'female' && gender2 === 'female') return 'womens';
  return 'mixed';
}
```

### 报名提交逻辑

```typescript
// src/lib/registration.ts
import { supabase } from './supabase';
import type { PlayerInput, RegistrationResult } from './types';

export async function submitRegistration(
  categoryId: string,
  player1: PlayerInput,
  player2: PlayerInput
): Promise<RegistrationResult> {

  // 1. Upsert 选手1
  const { data: p1, error: e1 } = await supabase
    .from('players')
    .upsert(
      {
        email: player1.email,
        name_en: player1.name_en,
        name_zh: player1.name_zh || null,
        gender: player1.gender,
        date_of_birth: player1.date_of_birth,
        phone: player1.phone || null,
        wechat_id: player1.wechat_id || null,
      },
      { onConflict: 'email' }
    )
    .select('id')
    .single();

  if (e1) return { success: false, error: e1.message };

  // 2. Upsert 选手2
  const { data: p2, error: e2 } = await supabase
    .from('players')
    .upsert(
      {
        email: player2.email,
        name_en: player2.name_en,
        name_zh: player2.name_zh || null,
        gender: player2.gender,
        date_of_birth: player2.date_of_birth,
        phone: player2.phone || null,
        wechat_id: player2.wechat_id || null,
      },
      { onConflict: 'email' }
    )
    .select('id')
    .single();

  if (e2) return { success: false, error: e2.message };

  // 3. 创建队伍（trigger 会自动校验年龄和单项目约束）
  const { data: team, error: e3 } = await supabase
    .from('teams')
    .insert({
      category_id: categoryId,
      player1_id: p1.id,
      player2_id: p2.id,
      // gender_type 和 combined_age 由 trigger 自动设置
      // 这里传入占位值，trigger 会覆盖
      gender_type: 'mixed',
      combined_age: 0,
    })
    .select('id, gender_type, combined_age, status')
    .single();

  if (e3) {
    // 解析 trigger 抛出的错误信息
    return { success: false, error: parseSupabaseError(e3.message) };
  }

  return {
    success: true,
    team: team,
  };
}

function parseSupabaseError(message: string): string {
  if (message.includes('Combined age')) {
    return 'reg_sum_error'; // i18n key
  }
  if (message.includes('at least 35')) {
    return 'reg_age_error';
  }
  if (message.includes('already registered')) {
    return 'reg_duplicate_error';
  }
  return 'common_error';
}
```

## TypeScript 类型定义

```typescript
// src/lib/types.ts

export interface PlayerInput {
  name_en: string;
  name_zh?: string;
  email: string;
  phone?: string;
  gender: 'male' | 'female';
  date_of_birth: string; // YYYY-MM-DD
  wechat_id?: string;
}

export interface RegistrationResult {
  success: boolean;
  error?: string;
  team?: {
    id: string;
    gender_type: 'mens' | 'womens' | 'mixed';
    combined_age: number;
    status: string;
  };
}

export interface TeamDetail {
  team_id: string;
  team_name_zh: string | null;
  team_name_en: string | null;
  gender_type: 'mens' | 'womens' | 'mixed';
  combined_age: number;
  status: string;
  payment_status: string;
  payment_ref: string;            // 付款参考号（team ID 前8位大写）
  paid_at: string | null;         // 付款确认时间
  payment_notes: string | null;   // 付款备注
  category_en: string;
  category_zh: string;
  category_slug: string;
  player1_name_en: string;
  player1_name_zh: string | null;
  player1_gender: string;
  player1_age: number;
  player2_name_en: string;
  player2_name_zh: string | null;
  player2_gender: string;
  player2_age: number;
}

export interface CategoryStat {
  id: string;
  name_en: string;
  name_zh: string;
  slug: string;
  max_teams: number;
  is_open: boolean;
  registered_teams: number;
  remaining_slots: number;
}
```

## 付款流程

仅支持 **Interac e-Transfer** 付款，管理员手动确认到账。

1. 报名成功后页面显示付款指引：收款邮箱、金额、付款参考号
2. 用户通过银行 App 发送 e-Transfer，备注中填写付款参考号
3. 管理员在后台根据参考号匹配队伍，标记 `unpaid → paid`

> 详细付款流程、页面设计及配置项见 [10-payment.md](./10-payment.md)

## 候补机制

当某组别报名满 32 对时：
1. 新报名自动标记 `status = 'waitlist'`
2. 前端显示"已加入候补名单"
3. 如有队伍取消，管理员手动将候补队伍改为 `confirmed`
