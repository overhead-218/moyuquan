-- 重建 posts / profiles 表（按前端 toJson 字段，列名驼峰+双引号保留大小写）
-- 在控制台「SQL 编辑器」Ctrl+A 清空后整段粘贴执行。

drop table if exists public.posts;
drop table if exists public.profiles;

create table if not exists public.posts (
  "id" text primary key,
  "authorId" text,
  "authorName" text,
  "authorAvatar" text,
  "type" text,
  "title" text,
  "content" text,
  "location" text,
  "imageUrl" text,
  "height" numeric,
  "likeCount" integer,
  "commentCount" integer,
  "createdAt" text
);

create table if not exists public.profiles (
  "id" text primary key,
  "name" text,
  "bio" text,
  "city" text,
  "gender" text,
  "avatarEmoji" text
);

grant select, insert, update, delete on public.posts to anon;
grant select, insert, update, delete on public.profiles to anon;

alter table public.posts enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "anon_all_posts" on public.posts;
create policy "anon_all_posts" on public.posts for all to anon using (true) with check (true);

drop policy if exists "anon_all_profiles" on public.profiles;
create policy "anon_all_profiles" on public.profiles for all to anon using (true) with check (true);
