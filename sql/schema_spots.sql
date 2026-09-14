-- 摸鱼圈钓点表（云开发 PG 模式 / PostgREST）
-- 列名与 Spot.toJson() 字段 1:1（驼峰，建表时加双引号保留大小写，否则 PostgREST 大小写不匹配）
-- 在云开发控制台的「SQL 型数据库 / SQL 编辑器」里执行本脚本。

create table if not exists public.spots (
  "id" text primary key,
  "name" text not null,
  "type" text,
  "typeEmoji" text,
  "city" text,
  "district" text,
  "address" text,
  "latitude" numeric,
  "longitude" numeric,
  "images" jsonb,
  "fishSpecies" jsonb,
  "fishPeakSeason" jsonb,
  "lastStockingDate" text,
  "stockingCycleDays" integer,
  "price" numeric,
  "priceNote" text,
  "businessHours" text,
  "contactPhone" text,
  "wechat" text,
  "ownerName" text,
  "rating" numeric,
  "reviewCount" integer,
  "viewCount" integer,
  "favoriteCount" integer,
  "postCount" integer,
  "description" text,
  "updatedAt" text,
  "submitter" text,
  "claimedBy" text,
  "claimedAt" text,
  "hasAccommodation" boolean,
  "roomType" text,
  "roomCapacity" integer,
  "hasWifi" boolean,
  "accommodationNote" text,
  "accommodationImages" jsonb,
  "commonAreaImages" jsonb,
  "facilities" jsonb
);

-- 行级安全：匿名（前端 Publishable Key / anon 角色）可读全部钓点
alter table public.spots enable row level security;

drop policy if exists "anon_select_spots" on public.spots;
create policy "anon_select_spots" on public.spots
  for select to anon using (true);

-- 允许匿名新增（UGC 投稿）与更新（商家认领）
drop policy if exists "anon_insert_spots" on public.spots;
create policy "anon_insert_spots" on public.spots
  for insert to anon with check (true);

drop policy if exists "anon_update_spots" on public.spots;
create policy "anon_update_spots" on public.spots
  for update to anon using (true) with check (true);

-- 确保 anon 角色有访问权限
grant select, insert, update, delete on public.spots to anon;
