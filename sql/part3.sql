-- =============================================================
-- 摸鱼圈 App - 建表脚本 第 3 段
-- 渔获 / 渔获点赞 / 拉黑 / 举报
-- 幂等：可重复执行
-- =============================================================

create table if not exists public.catches (
  "id" text primary key,
  "userId" text not null,
  "userName" text default '',
  "fishName" text default '',
  "weightKg" numeric default 0,
  "lengthCm" numeric default 0,
  "spotName" text default '',
  "city" text default '',
  "photoUrl" text default '',
  "note" text default '',
  "likeCount" integer default 0,
  "commentCount" integer default 0,
  "caughtAt" text default '',
  "createdAt" text not null
);
create index if not exists idx_catches_user
  on public.catches ("userId", "createdAt" desc);
create index if not exists idx_catches_weight
  on public.catches ("weightKg" desc);
grant select, insert, update, delete on public.catches to anon;

create table if not exists public.catch_likes (
  "id" text primary key,
  "catchId" text not null,
  "userId" text not null,
  "createdAt" text not null
);
create index if not exists idx_catch_likes_catch
  on public.catch_likes ("catchId");
grant select, insert, update, delete on public.catch_likes to anon;

create table if not exists public.blocks (
  "id" text primary key,
  "userId" text not null,
  "blockedId" text not null,
  "createdAt" text not null
);
create index if not exists idx_blocks_user
  on public.blocks ("userId");
grant select, insert, update, delete on public.blocks to anon;

create table if not exists public.reports (
  "id" text primary key,
  "reporterId" text not null,
  "targetType" text not null,
  "targetId" text not null,
  "reason" text default '',
  "detail" text default '',
  "status" text default 'pending',
  "createdAt" text not null
);
create index if not exists idx_reports_status
  on public.reports ("status", "createdAt" desc);
grant select, insert, update, delete on public.reports to anon;