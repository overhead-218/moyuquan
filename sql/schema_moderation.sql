-- 摸鱼圈 UGC 内容安全表（Apple Guideline 1.2 合规：举报 / 拉黑）
-- 在云开发控制台「数据库 → SQL 执行」里粘贴运行。
-- 列名与 ModerationService 推送字段 1:1 对应（驼峰加引号，PostgREST 大小写敏感）。

-- 举报记录
CREATE TABLE IF NOT EXISTS "reports" (
  "id"          SERIAL PRIMARY KEY,
  "targetType"  TEXT NOT NULL,          -- post | user | comment | message
  "targetId"    TEXT NOT NULL,
  "targetUserId" TEXT DEFAULT '',
  "reason"      TEXT NOT NULL,
  "reporterId"  TEXT DEFAULT 'me',
  "createdAt"   TIMESTAMPTZ DEFAULT NOW(),
  "handled"     BOOLEAN DEFAULT FALSE
);

-- 拉黑关系
CREATE TABLE IF NOT EXISTS "blocks" (
  "id"         SERIAL PRIMARY KEY,
  "blockerId"  TEXT NOT NULL DEFAULT 'me',
  "blockedId"  TEXT NOT NULL,
  "createdAt"  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE ("blockerId", "blockedId")
);

-- 匿名角色（anon）读写策略：允许插入，禁止篡改他人记录
-- 说明：前端使用 Publishable Key（role=anon），以下策略保证用户只能新增自己的举报/拉黑。
ALTER TABLE "reports" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "blocks"  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_insert_reports" ON "reports";
CREATE POLICY "anon_insert_reports" ON "reports"
  FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS "anon_insert_blocks" ON "blocks";
CREATE POLICY "anon_insert_blocks" ON "blocks"
  FOR INSERT TO anon WITH CHECK (true);
