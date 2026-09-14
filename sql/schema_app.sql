-- 摸鱼圈数据表（腾讯云开发 PostgreSQL 模式）
-- 用法：在控制台「SQL 编辑器」先 Ctrl+A 全选清空，再整段粘贴本文件，点「执行」。
-- 列名驼峰，用双引号包裹以保留大小写，匹配前端 toJson() 字段名。
-- 本脚本幂等：可重复执行，表/策略已存在也不会报错。

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

create table if not exists public.messages (
  "id" text primary key,
  "name" text,
  "last" text,
  "time" text,
  "avatar" text,
  "unread" integer
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
grant select, insert, update, delete on public.messages to anon;
grant select, insert, update, delete on public.profiles to anon;

alter table public.posts enable row level security;
alter table public.messages enable row level security;
alter table public.profiles enable row level security;

do $$
declare t text;
begin
  foreach t in array array['posts','messages','profiles']
  loop
    execute format('drop policy if exists "anon_all_%I" on public.%I;', t, t);
    execute format('create policy "anon_all_%I" on public.%I for all to anon using (true) with check (true);', t, t);
  end loop;
end $$;
