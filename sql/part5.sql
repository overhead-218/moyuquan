-- =============================================================
-- 摸鱼圈 App - 第 5 段（新增）
-- 评论点赞表：小红书风格的评论点赞需要
-- 幂等：可重复执行
-- =============================================================

create table if not exists public.comment_likes (
  "id" text primary key,
  "commentId" text not null,
  "postId" text default '',
  "userId" text not null,
  "createdAt" text not null
);
create index if not exists idx_comment_likes_comment
  on public.comment_likes ("commentId");
create index if not exists idx_comment_likes_user
  on public.comment_likes ("userId", "postId");

grant select, insert, update, delete
  on public.comment_likes to anon;

-- 确保 post_comments 已有这3 个字段（楼中楼 + 图片 + 点赞数）
-- 没有的话补上，已存在则跳过
alter table public.post_comments add column if not exists "parentId" text default '';
alter table public.post_comments add column if not exists "images" text default '';
alter table public.post_comments add column if not exists "likeCount" integer default 0;