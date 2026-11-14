-- =============================================================
-- 摸鱼圈 App - 建表脚本 第 1 段
-- 帖子评论 / 帖子点赞 / 钓点评论 / 钓点点赞
-- 幂等：可重复执行
-- =============================================================

create table if not exists public.post_comments (
  "id" text primary key,
  "postId" text not null,
  "authorId" text not null default 'me',
  "authorName" text default '',
  "authorAvatar" text default '',
  "content" text not null,
  "images" text default '',
  "parentId" text default '',
  "likeCount" integer default 0,
  "createdAt" text not null
);
create index if not exists idx_post_comments_post
  on public.post_comments ("postId", "createdAt" desc);
grant select, insert, update, delete on public.post_comments to anon;

create table if not exists public.post_likes (
  "id" text primary key,
  "postId" text not null,
  "userId" text not null,
  "createdAt" text not null
);
create index if not exists idx_post_likes_post
  on public.post_likes ("postId");
grant select, insert, update, delete on public.post_likes to anon;

create table if not exists public.spot_comments (
  "id" text primary key,
  "spotId" text not null,
  "authorId" text not null default 'me',
  "authorName" text default '',
  "authorAvatar" text default '',
  "content" text not null,
  "images" text default '',
  "parentId" text default '',
  "likeCount" integer default 0,
  "createdAt" text not null
);
create index if not exists idx_spot_comments_spot
  on public.spot_comments ("spotId", "createdAt" desc);
grant select, insert, update, delete on public.spot_comments to anon;

create table if not exists public.spot_likes (
  "id" text primary key,
  "spotId" text not null,
  "userId" text not null,
  "createdAt" text not null
);
create index if not exists idx_spot_likes_spot
  on public.spot_likes ("spotId");
grant select, insert, update, delete on public.spot_likes to anon;