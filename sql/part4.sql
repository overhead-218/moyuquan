-- =============================================================
-- 摸鱼圈 App - 建表脚本 第 4 段
-- 装备图鉴 / 装备评价 / 地图钓友图层 / 版本配置
-- 幂等：可重复执行
-- =============================================================

create table if not exists public.equips (
  "id" text primary key,
  "brand" text default '',
  "name" text not null,
  "model" text default '',
  "category" text not null,
  "slot" text default '',
  "waterType" text default '',
  "handle" text default '',
  "sections" text default '',
  "reelType" text default '',
  "hand" text default '',
  "specs" text default '',
  "tags" text default '',
  "description" text default '',
  "imageUrl" text default '',
  "gallery" text default '',
  "price" numeric,
  "brandSeries" text default '',
  "score" integer default 0,
  "heat" integer default 0,
  "replyCount" integer default 0,
  "createdAt" text default ''
);
create index if not exists idx_equips_cat
  on public.equips ("category", "heat" desc);
grant select, insert, update, delete on public.equips to anon;

create table if not exists public.equip_reviews (
  "id" text primary key,
  "equipId" text not null,
  "authorId" text not null default '',
  "authorName" text default '',
  "rating" integer default 5,
  "content" text not null,
  "likeCount" integer default 0,
  "createdAt" text not null
);
create index if not exists idx_equip_reviews_equip
  on public.equip_reviews ("equipId", "createdAt" desc);
grant select, insert, update, delete on public.equip_reviews to anon;

create table if not exists public.user_locations (
  "id" text primary key,
  "userId" text not null,
  "lat" numeric,
  "lng" numeric,
  "city" text default '',
  "spotName" text default '',
  "updatedAt" text default ''
);
create index if not exists idx_user_locations_user
  on public.user_locations ("userId");
grant select, insert, update, delete on public.user_locations to anon;

create table if not exists public.app_config (
  "id" text primary key,
  "version" text default '',
  "build" integer default 0,
  "forceUpdate" boolean default false,
  "url" text default '',
  "note" text default '',
  "updatedAt" text default ''
);
grant select, insert, update, delete on public.app_config to anon;

insert into public.app_config ("id","version","build","forceUpdate","updatedAt")
values ('android', '1.1.0', 11, false, now()::text)
on conflict ("id") do nothing;

insert into public.app_config ("id","version","build","forceUpdate","updatedAt")
values ('web', '1.1.0', 11, false, now()::text)
on conflict ("id") do nothing;