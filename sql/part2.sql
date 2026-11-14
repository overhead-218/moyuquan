-- =============================================================
-- 摸鱼圈 App - 建表脚本 第 2 段
-- 关注关系 / 收藏 / 私信会话 / 私信消息体
-- 幂等：可重复执行
-- =============================================================

create table if not exists public.follows (
  "id" text primary key,
  "followerId" text not null,
  "followeeId" text not null,
  "createdAt" text not null
);
create index if not exists idx_follows_follower
  on public.follows ("followerId");
create index if not exists idx_follows_followee
  on public.follows ("followeeId");
grant select, insert, update, delete on public.follows to anon;

create table if not exists public.favorites (
  "id" text primary key,
  "userId" text not null,
  "targetType" text not null,
  "targetId" text not null,
  "createdAt" text not null
);
create index if not exists idx_favorites_user
  on public.favorites ("userId", "targetType");
grant select, insert, update, delete on public.favorites to anon;

create table if not exists public.conversations (
  "id" text primary key,
  "userAId" text not null,
  "userBId" text not null,
  "lastMsg" text default '',
  "lastAt" text default '',
  "unreadA" integer default 0,
  "unreadB" integer default 0,
  "createdAt" text default ''
);
create index if not exists idx_conversations_a
  on public.conversations ("userAId");
create index if not exists idx_conversations_b
  on public.conversations ("userBId");
grant select, insert, update, delete on public.conversations to anon;

create table if not exists public.chat_messages (
  "id" text primary key,
  "conversationId" text not null,
  "senderId" text not null,
  "type" text default 'text',
  "content" text default '',
  "mediaUrl" text default '',
  "readAt" text default '',
  "createdAt" text not null
);
create index if not exists idx_chat_messages_conv
  on public.chat_messages ("conversationId", "createdAt");
grant select, insert, update, delete on public.chat_messages to anon;