-- =============================================================
-- 摸鱼圈 · 社交 / 渔获 / 装备 / 私信 / 内容安全 全套建表脚本
-- =============================================================
-- 用法：腾讯云开发控制台 → 数据库 → SQL 编辑器 → 整段粘贴 → 执行
-- 特点：
--   1. 幂等，可重复执行（IF NOT EXISTS / DROP POLICY IF EXISTS）
--   2. 列名驼峰并加双引号，与前端 toJson() 字段 1:1 对应（PostgREST 大小写敏感）
--   3. 全部 grant 给 anon —— 前端用 Publishable Key（role=anon）直连 PostgREST
--
-- 覆盖的假数据模块：
--   spot_comments  →钓点评论（已有服务，缺表）
--   post_comments  → 帖子评论（原本是 3 条写死）
--   catches        → 渔获（原本 16 条 mock，无网络层）
--   catch_likes    → 渔获点赞
--   follows        → 关注关系（原本内存单例 + 10 个假用户）
--   favorites      → 收藏（原本内存单例）
--   post_likes     → 帖子点赞（原本纯内存 delta）
--   spot_likes     → 钓点点赞
--   conversations  → 私信会话（原本只有摘要）
--   chat_messages  → 私信消息体（原本完全不存在）
--   blocks/reports → 拉黑/举报（原本内存，SQL 已在 schema_moderation.sql，此处重建并补 select）
--   equips         → 装备图鉴（原本 183 条硬编码在 catch_page.dart）
--   equip_reviews  → 装备评价（原本 3 条模板拼接）
--   user_locations → 地图钓友图层
-- =============================================================


-- -------------------------------------------------------------
-- 1. 钓点评论
-- -------------------------------------------------------------
create table if not exists public.spot_comments (
  "id"          text primary key,
  "spotId"      text not null,
  "authorId"    text not null default 'me',
  "authorName"  text default '',
  "authorAvatar" text default '',
  "content"     text not null,
  "images"      text default '',          -- 逗号分隔的 URL；base64 图片用 data: 前缀
  "parentId"    text default '',          -- 回复的评论 id，'' 表示顶层评论
  "likeCount"   integer default 0,
  "createdAt"   text not null             -- ISO8601 字符串，与其他表保持一致
);
create index if not exists idx_spot_comments_spot on public.spot_comments ("spotId", "createdAt" desc);


-- -------------------------------------------------------------
-- 2. 帖子评论
-- -------------------------------------------------------------
create table if not exists public.post_comments (
  "id"          text primary key,
  "postId"      text not null,
  "authorId"    text not null default 'me',
  "authorName"  text default '',
  "authorAvatar" text default '',
  "content"     text not null,
  "images"      text default '',
  "parentId"    text default '',
  "likeCount"   integer default 0,
  "createdAt"   text not null
);
create index if not exists idx_post_comments_post on public.post_comments ("postId", "createdAt" desc);


-- -------------------------------------------------------------
-- 3. 渔获（大鱼榜 / 人气钓友榜的真实数据源）
-- -------------------------------------------------------------
create table if not exists public.catches (
  "id"          text primary key,
  "userId"      text not null,
  "userName"    text default '',
  "userAvatar"  text default '',
  "fish"        text not null,            -- 鱼种
  "species"     text default '',          -- 拉丁学名/子类
  "weightKg"    numeric,                  -- 重量（kg），大鱼榜排序键
  "lengthCm"    numeric,
  "spotId"      text default '',
  "spotName"    text default '',
  "city"        text default '',
  "images"      text default '',          -- 逗号分隔
  "note"        text default '',
  "baitUsed"    text default '',
  "gearUsed"    text default '',          -- JSON：使用的竿/轮/线组
  "catchTime"   text default '',          -- 出钓时间
  "likeCount"   integer default 0,
  "commentCount" integer default 0,
  "verified"    boolean default false,    -- 大鱼认证
  "verifiedBy"  text default '',
  "verifiedAt"  text default '',
  "createdAt"   text not null
);
create index if not exists idx_catches_weight on public.catches ("weightKg" desc nulls last);
create index if not exists idx_catches_created on public.catches ("createdAt" desc);
create index if not exists idx_catches_user on public.catches ("userId");


-- -------------------------------------------------------------
-- 4. 渔获点赞（幂等：唯一键防重复计数）
-- -------------------------------------------------------------
create table if not exists public.catch_likes (
  "id"        text primary key,
  "catchId"   text not null,
  "userId"    text not null default 'me',
  "createdAt" text not null,
  unique ("catchId", "userId")
);


-- -------------------------------------------------------------
-- 5. 关注关系
-- -------------------------------------------------------------
create table if not exists public.follows (
  "id"          text primary key,
  "followerId"  text not null default 'me',
  "followeeId"  text not null,
  "createdAt"   text not null,
  unique ("followerId", "followeeId")
);
create index if not exists idx_follows_follower on public.follows ("followerId");
create index if not exists idx_follows_followee on public.follows ("followeeId");


-- -------------------------------------------------------------
-- 6. 收藏（帖子 / 钓点 / 装备统一存一张表）
-- -------------------------------------------------------------
create table if not exists public.favorites (
  "id"         text primary key,
  "userId"     text not null default 'me',
  "targetType" text not null,             -- post | spot | equip
  "targetId"   text not null,
  "createdAt"  text not null,
  unique ("userId", "targetType", "targetId")
);
create index if not exists idx_favorites_user on public.favorites ("userId", "targetType");


-- -------------------------------------------------------------
-- 7. 帖子点赞 / 钓点点赞
-- -------------------------------------------------------------
create table if not exists public.post_likes (
  "id"        text primary key,
  "postId"    text not null,
  "userId"    text not null default 'me',
  "createdAt" text not null,
  unique ("postId", "userId")
);

create table if not exists public.spot_likes (
  "id"        text primary key,
  "spotId"    text not null,
  "userId"    text not null default 'me',
  "createdAt" text not null,
  unique ("spotId", "userId")
);


-- -------------------------------------------------------------
-- 8. 私信：会话 + 消息体
-- -------------------------------------------------------------
create table if not exists public.conversations (
  "id"      text primary key,             -- 形如 conv_u001_u002
  "userAId" text not null,
  "userBId" text not null,
  "lastMsg" text default '',
  "lastAt"  text default '',
  "unreadA" integer default 0,
  "unreadB" integer default 0,
  "createdAt" text default '',
  unique ("userAId", "userBId")
);
create index if not exists idx_conv_a on public.conversations ("userAId", "lastAt" desc);
create index if not exists idx_conv_b on public.conversations ("userBId", "lastAt" desc);

create table if not exists public.chat_messages (
  "id"             text primary key,
  "conversationId" text not null,
  "senderId"       text not null,
  "type"           text default 'text',   -- text | image | location | catchCard
  "content"        text default '',
  "mediaUrl"       text default '',
  "readAt"         text default '',
  "createdAt"      text not null
);
create index if not exists idx_chat_conv on public.chat_messages ("conversationId", "createdAt");


-- -------------------------------------------------------------
-- 9. 内容安全：拉黑 / 举报
--    与 schema_moderation.sql 结构一致，但 id 用 text 便于前端生成，
--    并补齐 anon 的 SELECT 权限（否则前端拉黑列表永远读不到）。
-- -------------------------------------------------------------
drop table if exists public.blocks;
create table if not exists public.blocks (
  "id"        text primary key,
  "blockerId" text not null default 'me',
  "blockedId" text not null,
  "createdAt" text not null,
  unique ("blockerId", "blockedId")
);
create index if not exists idx_blocks_blocker on public.blocks ("blockerId");

drop table if exists public.reports;
create table if not exists public.reports (
  "id"           text primary key,
  "targetType"   text not null,
  "targetId"     text not null,
  "targetUserId" text default '',
  "reason"       text not null,
  "reporterId"   text default 'me',
  "status"       text default 'pending', -- pending | accepted | rejected
  "createdAt"    text not null,
  "handledAt"    text default ''
);
create index if not exists idx_reports_status on public.reports ("status", "createdAt" desc);


-- -------------------------------------------------------------
-- 10. 装备图鉴
-- -------------------------------------------------------------
create table if not exists public.equips (
  "id"         text primary key,
  "brand"      text default '',
  "name"       text not null,             -- 展示名，如「禧玛诺 EXSENCE」
  "model"      text default '',          -- 型号，如Infinity B86MH
  "category"   text not null,             -- rod_spin | rod_bait | rod_casting | reel | lure | bait | additive | line | hook
  "slot"       text default '',           -- 对应装备栏槽位：rod | reel | line | bait
  "waterType"  text default '',           -- 海水 | 淡水 | 通用
  "handle"     text default '',           -- 直柄 | 枪柄（路亚竿柄型）
  "sections"   text default '',           -- 独节 | 两节 | 一本半
  "reelType"   text default '',           -- 纺车 | 水滴 | 鼓轮
  "hand"       text default '',           -- 左 | 右（卷线器左右手）
  "specs"      text default '',           -- JSON：解析出的规格键值
  "tags"       text default '',           -- JSON 数组
  "description" text default '',
  "imageUrl"   text default '',
  "gallery"    text default '',           -- JSON 数组
  "price"      numeric,
  "brandSeries" text default '',
  "score"      integer default 0,-- 口碑分
  "heat"       integer default 0,          -- 热度
  "replyCount" integer default 0,
  "createdAt"  text default ''
);
create index if not exists idx_equips_cat on public.equips ("category", "heat" desc);

create table if not exists public.equip_reviews (
  "id"         text primary key,
  "equipId"    text not null,
  "authorId"   text not null default '',   -- 与 UserProfile.id 一致，非固定 'me'
  "authorName" text default '',
  "rating"     integer default 5,          -- 1~5 星，真实评分
  "content"    text not null,
  "likeCount"  integer default 0,
  "createdAt"  text not null
);
create index if not exists idx_equip_reviews_equip on public.equip_reviews ("equipId", "createdAt" desc);


-- -------------------------------------------------------------
-- 11. 地图钓友图层
-- -------------------------------------------------------------
create table if not exists public.user_locations (
  "userId"     text primary key,
  "lat"        numeric not null,
  "lon"        numeric not null,
  "city"       text default '',
  "visibility" text default 'public',    -- public | private
  "updatedAt"  text not null
);


-- -------------------------------------------------------------
-- 11b. 应用版本配置（「检查更新」的真实数据源）
--     向该表插一行即可向所有客户端推送新版本。
-- -------------------------------------------------------------
create table if not exists public.app_config (
  "id"         text primary key,        -- 固定 'android' / 'ios'
  "version"    text not null,           -- 如 1.2.0
  "build"      integer not null,        -- 构建号
  "downloadUrl" text default '',        -- 下载/落地页地址
  "releaseNotes" text default '',       -- 更新说明
  "forceUpdate" boolean default false,  -- 是否强制更新
  "updatedAt"  text default ''
);

insert into public.app_config ("id","version","build","forceUpdate","updatedAt")
values ('android', '1.1.0', 11, false, now()::text)
on conflict ("id") do nothing;

grant select, insert, update, delete on public.app_config to anon;


-- -------------------------------------------------------------
-- 12. 权限授予（PostgREST 直连模式必须显式 grant）
-- -------------------------------------------------------------
grant select, insert, update, delete on
  public.spot_comments, public.post_comments,
  public.catches, public.catch_likes,
  public.follows, public.favorites,
  public.post_likes, public.spot_likes,
  public.conversations, public.chat_messages,
  public.blocks, public.reports,
  public.equips, public.equip_reviews,
  public.user_locations, public.app_config
  to anon;

-- 确保序列访问（若将来改用自增 id）
grant usage, select on all sequences in schema public to anon;

-- =============================================================
-- 执行后自检（应全部返回 0，即表示表已存在）
--   select count(*) from spot_comments;
--   select count(*) from catches;
--   select count(*) from follows;
--   select count(*) from chat_messages;
--   select count(*) from equips;
-- =============================================================