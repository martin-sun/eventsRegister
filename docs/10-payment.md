# 10 - E-Transfer 付款流程 / E-Transfer Payment

## 概述

本赛事仅支持 **Interac e-Transfer** 付款，管理员手动确认到账后标记付款状态。不集成在线支付网关，不做自动对账。

## 付款流程图

```
报名成功
    │
    ▼
┌─────────────────────────┐
│  显示付款指引页面         │
│  - 收款邮箱              │
│  - 付款金额              │
│  - 付款参考号（必填备注） │
│  - 注意事项              │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  用户通过银行 App 发送    │
│  Interac e-Transfer      │
│  备注填写付款参考号       │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  管理员收到 e-Transfer   │
│  - 登录后台              │
│  - 根据备注中的参考号    │
│    找到对应队伍           │
│  - 标记 paid + 记录时间  │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  队伍付款状态更新为 paid  │
│  公开队伍列表可见付款标记 │
└─────────────────────────┘
```

## 付款参考号

每支队伍报名成功后生成一个唯一付款参考号，用于 e-Transfer 备注中对账。

**生成规则：** 取 `teams.id`（UUID）前 8 位，转大写。

```
示例：team.id = "a1b2c3d4-5678-..." → 付款参考号: A1B2C3D4
```

> 管理员根据 e-Transfer 备注中的参考号匹配队伍，标记付款完成。

## 用户端 — 付款指引页面

报名成功后（Step 5），页面显示以下付款信息：

```
┌─────────────────────────────────────────┐
│  ✅ 报名成功！                           │
│                                          │
│  报名编号: A1B2C3D4                      │
│  组别: 双打100岁组                        │
│  选手: John W. & Mary L.                 │
│  类型: 混双 · 年龄和 100                  │
│                                          │
│  ─────────────────────────────────────── │
│                                          │
│  💳 付款说明                              │
│                                          │
│  请通过 Interac e-Transfer 支付报名费：   │
│                                          │
│  收款邮箱:  tournament@email.com  [复制]  │
│  付款金额:  $60.00 CAD                    │
│  备注(必填): A1B2C3D4            [复制]   │
│                                          │
│  ⚠️ 重要提示：                            │
│  1. 备注中必须填写付款参考号 A1B2C3D4     │
│     以便组委会识别您的付款                 │
│  2. 收款方已开启自动存款(Auto-deposit)，  │
│     无需安全问题                           │
│  3. 付款后通常 5 分钟内到账               │
│  4. 请在报名后 72 小时内完成付款，         │
│     逾期未付款的报名可能被取消             │
│                                          │
│  如有疑问请联系组委会：                    │
│  电话: (306) 555-1234                     │
│  微信: saskatoon_badminton                │
│                                          │
│  [查看我的报名]  [返回首页]               │
└─────────────────────────────────────────┘
```

**复制按钮：** 收款邮箱和参考号旁提供一键复制按钮，方便用户在银行 App 中粘贴。

## 配置项

E-Transfer 相关配置存储在 `tournament_config` 表中：

```sql
INSERT INTO tournament_config (key, value) VALUES
  ('etransfer_email', '"tournament@email.com"'),
  ('contact_phone', '"(306) 555-1234"'),
  ('contact_wechat', '"saskatoon_badminton"'),
  ('payment_deadline_hours', '72');
```

| 配置项 | 说明 | 示例值 |
|--------|------|--------|
| `etransfer_email` | E-Transfer 收款邮箱 | `tournament@email.com` |
| `contact_phone` | 组委会联系电话 | `(306) 555-1234` |
| `contact_wechat` | 组委会微信号 | `saskatoon_badminton` |
| `payment_deadline_hours` | 付款期限（小时） | `72` |

> 所有付款相关文案从 `tournament_config` 动态读取，管理员可在后台修改，无需改代码。

## 管理端 — 付款确认流程

### 报名管理页 `/admin/registrations`

付款相关操作集成在现有报名管理页中：

```
┌──────────────────────────────────────────────────────────────┐
│  报名管理                                                     │
│                                                               │
│  筛选: [全部] [待付款 unpaid] [已付款 paid]  搜索: [________] │
│                                                               │
│  ┌────┬────────┬──────────┬────────┬──────┬────────┬──────┐  │
│  │ #  │ 参考号  │ 选手     │ 组别   │ 状态 │ 付款   │ 操作 │  │
│  ├────┼────────┼──────────┼────────┼──────┼────────┼──────┤  │
│  │ 1  │A1B2C3D4│John/Mary │100岁组 │已确认│✅ 已付 │ ...  │  │
│  │ 2  │E5F6G7H8│Bob/Tom   │ 80岁组 │待确认│⏳ 待付 │ ...  │  │
│  │ 3  │I9J0K1L2│Amy/Lisa  │100岁组 │已确认│⏳ 待付 │ ...  │  │
│  └────┴────────┴──────────┴────────┴──────┴────────┴──────┘  │
│                                                               │
│  [导出 CSV]                                                   │
└──────────────────────────────────────────────────────────────┘
```

### 标记付款操作

管理员点击"标记已付款"后弹出确认弹窗：

```
┌───────────────────────────────┐
│  确认付款                      │
│                                │
│  队伍: John W. & Mary L.      │
│  参考号: A1B2C3D4              │
│  应付金额: $60.00              │
│                                │
│  付款备注: [________________]  │
│  （可选，如：3月20日到账）      │
│                                │
│  [取消]        [确认已付款]    │
└───────────────────────────────┘
```

**确认后执行：**
```sql
UPDATE teams
SET payment_status = 'paid',
    paid_at = NOW(),
    payment_notes = '管理员备注内容'
WHERE id = :team_id;
```

## 数据库字段扩展

在 `teams` 表中新增以下字段以支持付款追踪：

```sql
-- 在 teams 表中新增
paid_at         TIMESTAMPTZ,           -- 付款确认时间
payment_notes   TEXT                   -- 付款备注（管理员填写）
```

`payment_status_enum` 保持现有定义：`unpaid | paid | refunded`

### teams_detail 视图更新

```sql
-- 在 teams_detail 视图中新增以下字段
t.paid_at,
t.payment_notes,
UPPER(LEFT(t.id::TEXT, 8)) AS payment_ref  -- 付款参考号
```

## 前端实现要点

### 付款指引组件

```typescript
// src/lib/components/PaymentInstructions.svelte
// Props:
interface PaymentInstructionsProps {
  paymentRef: string;       // 付款参考号（team ID 前8位大写）
  amount: number;           // 付款金额
  etransferEmail: string;   // 收款邮箱（从 tournament_config 读取）
  contactPhone: string;     // 联系电话
  contactWechat: string;    // 联系微信
  deadlineHours: number;    // 付款期限
}
```

### 复制到剪贴板

```typescript
async function copyToClipboard(text: string) {
  await navigator.clipboard.writeText(text);
  // 显示 "已复制" 提示
}
```

### 付款参考号生成

```typescript
// 前端展示用
function getPaymentRef(teamId: string): string {
  return teamId.replace(/-/g, '').substring(0, 8).toUpperCase();
}
```

## i18n 翻译键

```json
{
  "payment_title": "付款说明",
  "payment_etransfer_instruction": "请通过 Interac e-Transfer 支付报名费：",
  "payment_recipient": "收款邮箱",
  "payment_amount": "付款金额",
  "payment_memo": "备注（必填）",
  "payment_memo_warning": "备注中必须填写付款参考号 {ref} 以便组委会识别您的付款",
  "payment_auto_deposit": "收款方已开启自动存款(Auto-deposit)，无需安全问题",
  "payment_arrival_time": "付款后通常 5 分钟内到账",
  "payment_deadline_warning": "请在报名后 {hours} 小时内完成付款，逾期未付款的报名可能被取消",
  "payment_contact_title": "如有疑问请联系组委会",
  "payment_copy": "复制",
  "payment_copied": "已复制",
  "payment_status_unpaid": "待付款",
  "payment_status_paid": "已付款",
  "payment_status_refunded": "已退款",
  "admin_confirm_payment": "确认付款",
  "admin_payment_notes": "付款备注",
  "admin_mark_paid": "标记已付款"
}
```

对应英文翻译：

```json
{
  "payment_title": "Payment Instructions",
  "payment_etransfer_instruction": "Please pay the registration fee via Interac e-Transfer:",
  "payment_recipient": "Recipient Email",
  "payment_amount": "Amount",
  "payment_memo": "Memo (Required)",
  "payment_memo_warning": "You MUST include reference number {ref} in the memo so we can identify your payment",
  "payment_auto_deposit": "Auto-deposit is enabled — no security question needed",
  "payment_arrival_time": "Funds are typically deposited within 5 minutes",
  "payment_deadline_warning": "Please complete payment within {hours} hours of registration. Unpaid registrations may be cancelled.",
  "payment_contact_title": "Questions? Contact the organizing committee",
  "payment_copy": "Copy",
  "payment_copied": "Copied",
  "payment_status_unpaid": "Unpaid",
  "payment_status_paid": "Paid",
  "payment_status_refunded": "Refunded",
  "admin_confirm_payment": "Confirm Payment",
  "admin_payment_notes": "Payment Notes",
  "admin_mark_paid": "Mark as Paid"
}
```
