-- part7.sql：修复「注册用户搜不到 / 私信发不出去」链路
--
-- 2026-10-18 端到端实测发现的真实问题（不是猜的，是库上验证过的）：
--
--   profiles 表实际只有 7 列：id / name / bio / city / gender /
--                          avatarEmoji / avatarData
--   ⚠️ 缺 nickname —— 前端 markLoggedIn 会写 loginMethod（也缺），
--      整条 upsert 因 PGRST204 失败，新注册用户根本进不了 profiles 表，
--      所以「搜人搜不到」。而且手机号登录的展示名是 138****8888 脱敏号，
--      本来就搜不到，必须有 nickname 字段当公开可检索标识。
--
--   chat_messages 表缺 senderName / receiverId / images
--      —— 缺 receiverId 时消息发不出去；缺 senderName 时会话列表显示不出对方昵称。
--
--   conversations 表缺 userAName / userBName
--      —— 会话列表拿不到对端昵称，只能显示 uid。
--
-- 执行方式：腾讯云控制台 → 云开发 → 数据库 → SQL 编辑器，整段粘贴执行。
-- 幂等：可重复执行。全部是 add column if not exists，不会破坏已有数据。

-- ── profiles：补昵称与活跃时间 ──────────────────────────────
alter table profiles add column if not exists nickname text default '';
alter table profiles add column if not exists loginMethod text default '';
alter table profiles add column if not exists createdAt timestamptz default now();
alter table profiles add column if not exists lastActiveAt timestamptz default now();

-- 历史数据回填：用 name 兜底（name 已经是可读名，昵称至少不是空）
update profiles set nickname = name where nickname is null or nickname = '';

-- ── conversations：补对端昵称，避免会话列表只显示 uid ──────────
alter table conversations add column if not exists userAName text default '';
alter table conversations add column if not exists userBName text default '';

-- ── chat_messages：补收件人与发件人昵称、图片列 ────────────────
alter table chat_messages add column if not exists senderName text default '';
alter table chat_messages add column if not exists receiverId text default '';
alter table chat_messages add column if not exists images jsonb default '[]'::jsonb;

-- ── 匿名读写权限 ────────────────────────────────────────────
grant select, insert, update, delete on profiles to anon;
grant select, insert, update, delete on conversations to anon;
grant select, insert, update, delete on chat_messages to anon;
