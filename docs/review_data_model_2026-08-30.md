# 审核数据模型设计 v1.1

## 核心原则
- 先发后审 + 敏感词机筛 + 人工抽检
- UGC 内容必须 status 字段兜底
- 举报表独立，按类型+优先级处理

---

## 一、Spot 模型新增字段

```dart
// lib/models/spot.dart 新增
class Spot {
  // ... 现有字段 ...

  // === 审核相关 ===
  String status;        // 'approved' | 'pending' | 'rejected'
  String? rejectReason; // 拒绝原因（rejected 时填写）
  String submittedBy;    // 提交者 userId（匿名提交时为 'anonymous'）
  DateTime submittedAt;
  DateTime? reviewedAt;
  String? reviewedBy;   // 审核员 userId

  // 商家认领
  bool claimed;         // 是否被商家认领
  String? claimedBy;   // 认领者 userId
  DateTime? claimedAt;

  // 联系方式状态
  String phoneStatus;   // 'verified' | 'self_reported' | 'unverified' | 'to_be_claimed'
}
```

---

## 二、Post 模型新增字段

```dart
// lib/models/post.dart 新增
class Post {
  // ... 现有字段 ...

  // === 审核相关 ===
  String status;           // 'approved' | 'pending' | 'rejected'
  String? rejectReason;    // 拒绝原因
  String submittedBy;       // 作者 userId
  DateTime submittedAt;
  DateTime? reviewedAt;
  String? reviewedBy;      // 审核员 userId

  // 内容安全
  bool containsSensitive;  // 敏感词机筛结果（true = 需人工复核）
  String? sensitiveWords;  // 命中的敏感词列表，逗号分隔
}
```

---

## 三、Report 举报表（新增）

```sql
-- schema_report.sql
CREATE TABLE reports (
  id TEXT PRIMARY KEY,
  report_type TEXT NOT NULL,   -- 'post' | 'comment' | 'spot' | 'user'
  target_id TEXT NOT NULL,     -- 被举报内容 ID
  reporter_id TEXT,            -- 举报者 userId（可选，匿名）
  reason TEXT NOT NULL,        -- 举报原因
  reason_detail TEXT,          -- 详细说明
  status TEXT DEFAULT 'pending', -- 'pending' | 'handled' | 'dismissed'
  priority TEXT DEFAULT 'normal', -- 'low' | 'normal' | 'high' | 'urgent'
  -- high: 色情/政治/人身攻击
  -- urgent: 涉未成年人/违法行为举报
  handled_by TEXT,
  handled_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_priority ON reports(priority);
CREATE INDEX idx_reports_type ON reports(report_type, target_id);
```

---

## 四、User 模型新增字段（审核员角色）

```dart
class UserProfile {
  // ... 现有字段 ...

  // 角色权限
  String role;  // 'user' | 'reviewer' | 'admin'
  // reviewer: 可审核帖子/评论/钓点
  // admin: 全部权限 + 商家认领审批 + 审核员管理
}
```

---

## 五、CloudBase CMS 配置

接入 CloudBase 内置 CMS：
- 环境：moyuquan-d5g0pvpcw55f8a62e（已存在）
- 内容集合：spots / posts / reports
- 子账号：给 1-2 个兼职审核员开 CMS 操作员角色

CMS 可视化能力：
- 帖子列表：按 status 筛选 pending 条，支持一键 approve/reject
- 钓点列表：同上，支持商家认领审批
- 举报列表：按 priority 排序，urgent 优先处理

---

## 六、敏感词机筛（轻量实现）

在发布/提交时前端先拦，腾讯云函数里也跑一遍：

```javascript
// 云函数 sensitiveCheck
const sensitiveWords = [
  // 导流类（必拦）
  'v:', 'vx:', '微:', 'wx:', 'weixin',
  'qq:', 'q群',
  // 竞品类
  '钓鱼人', '钓鱼之家', '两步路', '行者',
  // 违规类（标准词库）
  // ... 接入第三方词库或自建
];

function check(text) {
  const lower = text.toLowerCase();
  const hits = sensitiveWords.filter(w => lower.includes(w.toLowerCase()));
  return { safe: hits.length === 0, words: hits };
}
```

---

## 七、v1.1 接入优先级

| 功能 | 优先级 | 工作量 |
|------|--------|--------|
| Post.status 字段 + 审核列表页 | P0 | 半天 |
| Spot.status 字段 + 钓点审核 | P0 | 半天 |
| CloudBase CMS 接入 | P0 | 2小时 |
| Report 举报表 | P1 | 半天 |
| 敏感词机筛（前端+云函数） | P1 | 半天 |
| 商家认领流程 | P2 | 1天 |
| 审核员角色分离 | P2 | 半天 |
