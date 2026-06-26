# API Contract

跨组件的接口契约 SSOT。token-scope 本身不对外提供 HTTP 接口，但作为消费方调用上游供应商的余额接口，本文件记录**消费侧契约**：URL、认证、字段映射、错误处理。

- Status: confirmed   （允许值：`draft` / `confirmed` / `superseded` / `n/a`）

## Change History

| Date | Version | Change | Reason | Decision |
|---|---|---|---|---|
| 2026-06-24 | v0.1 | 登记 DeepSeek `/user/balance` 消费契约 | v0.1 唯一供应商 | Confirmed by user |

## Content

### Base URL

- DeepSeek 默认：`https://api.deepseek.com`
- 用户可在账号配置里覆盖（用于自部署或反向代理场景）

### Auth

- 方式：HTTP Bearer
- Header：`Authorization: Bearer <apiKey>`
- apiKey 来源：用户在主 App 输入，**仅存 Keychain**

### Error format

| HTTP 状态 | UsageResult 状态 | 说明 |
|---|---|---|
| 2xx | success（若解析正常） | 写入 UsageSnapshot |
| 401 / 403 | invalid | 标"账号失效"；对应 cc-switch `make_auth_error` |
| 其他 4xx | failure | 显示 "API error (HTTP {status})" |
| 5xx | failure | 同上 |
| 超时 / DNS / 断网 | failure | 显示 "Network error: ..." |
| JSON 解析失败 | failure | 显示 "Failed to parse response" |

`failure` 与 `invalid` 的关键区别：`failure` 保留上一次 success 快照展示并显示"X 分钟前"；`invalid` 替换为红色失效卡，并阻断继续刷新（用户改 key 后才解除）。

### Pagination

不适用。

### Endpoints

#### DeepSeek — Get Balance

- **Endpoint**：`GET {baseURL}/user/balance`
- **Headers**：
  - `Authorization: Bearer <apiKey>`
  - `Accept: application/json`
- **Timeout**：15s（对齐 cc-switch `balance.rs`）
- **Response Body**：
  ```json
  {
    "is_available": true,
    "balance_infos": [
      {
        "currency": "CNY",
        "total_balance": "38.20",
        "granted_balance": "0.00",
        "topped_up_balance": "38.20"
      }
    ]
  }
  ```
- **字段映射到 UsageSnapshot**：

  | DeepSeek 字段 | UsageSnapshot 字段 | 备注 |
  |---|---|---|
  | `balance_infos[i].currency` | `planName` | DeepSeek 没有 plan 概念，复用 currency 作为标签（对齐 cc-switch balance.rs 第 113 行） |
  | `balance_infos[i].total_balance` | `remaining` | 字符串或数字，需 `parse_f64_field` 同型处理 |
  | `balance_infos[i].currency` | `unit` | ISO 币种 |
  | `is_available` | `isValid` | true / false |
  | `!is_available` | `invalidMessage = "Insufficient balance"` | 余额耗尽场景 |

- **多 balance_infos 处理**：DeepSeek 可能返回多种币种（如 CNY + USD），v0.1 全部入库；UI 只显示第一条（CNY 优先）；Widget 只显示一行。
- **空数组处理**：`balance_infos` 为空 → `UsageResult.success = true, data = nil`，UI 显示"暂无数据"。

### Mock data rules

- 单测使用 `URLProtocol` 拦截，注入固定 JSON
- 测试用例覆盖：
  - T-API-1：正常 CNY 单币种返回
  - T-API-2：多币种返回
  - T-API-3：`is_available=false`
  - T-API-4：HTTP 401（→ invalid）
  - T-API-5：HTTP 500（→ failure）
  - T-API-6：超时（→ failure）
  - T-API-7：JSON 解析错误（→ failure）
  - T-API-8：`total_balance` 为字符串而非数字
  - T-API-9：空 balance_infos
- 所有 mock 输入快照来自 cc-switch `balance.rs` DeepSeek 段实测样例
