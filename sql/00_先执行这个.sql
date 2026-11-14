-- =============================================================
-- 摸鱼圈 · 最小可用建表（先让「帖子留言」跑起来）
-- =============================================================
-- 用法：腾讯云开发控制台 → 数据库 → SQL 编辑器
--      整段粘贴 → 执行
--
-- 为什么需要：云库现在 16 张表一张都没有（实测全部 404），
--   所以 App 里所有「看起来该有」的按钮都写不进数据。
--
-- 特点：
--   1. 幂等，可重复执行（IF NOT EXISTS）
--   2. 列名驼峰加双引号，与前端字段 1:1 对应
--      （PostgREST 对大小写敏感，写错就 400）
--   3. grant 给 anon —— 前端用 Publishable Key 直连
-- =============================================================


-- -------------------------------------------------------------
-- 1. 帖子评论（当前最急：别人帖子下方的留言框）
-- -------------------------------------------------------------
create table if not exists public.post_comments (
  "id"          text primary key,
  "postId"      text not null,
  "authorId"    text not null default 'me',
  "authorName"  text default '',
  "authorAvatar" text default '',
  "content"     text not null,
  "images"      text default '',
  "parentId"    text default '',        -- 顶级评论留空，回复时填被回复的 id
  "likeCount"   integer default 0,
  "createdAt"   text not null
);
create index if not exists idx_post_comments_post
  on public.post_comments ("postId", "createdAt" desc);

grant select, insert, update, delete
  on public.post_comments to anon;


-- -------------------------------------------------------------
-- 2. 帖子点赞
-- -------------------------------------------------------------
create table if not exists public.post_likes (
  "id"        text primary key,
  "postId"    text not null,
  "userId"    text not null,
  "createdAt" text not null
);
create index if not exists idx_post_likes_post
  on public.post_likes ("postId");

grant select, insert, update, delete
  on public.post_likes to anon;


-- -------------------------------------------------------------
-- 3. 钓点评论 + 钓点点赞
-- -------------------------------------------------------------
create table if not exists public.spot_comments (
  "id"          text primary key,
  "spotId"      text not null,
  "authorId"    text not null default 'me',
  "authorName"  text default '',
  "authorAvatar" text default '',
  "content"     text not null,
  "images"      text default '',
  "parentId"    text default '',
  "likeCount"   integer default 0,
  "createdAt"   text not null
);
create index if not exists idx_spot_comments_spot
  on public.spot_comments ("spotId", "createdAt" desc);

grant select, insert, update, delete
  on public.spot_comments to anon;

create table if not exists public.spot_likes (
  "id"        text primary key,
  "spotId"    text not null,
  "userId"    text not null,
  "createdAt" text not null
);
create index if not exists idx_spot_likes_spot
  on public.spot_likes ("spotId");

grant select, insert, update, delete
  on public.spot_likes to anon;


-- -------------------------------------------------------------
-- 4. 关注 / 粉丝
-- -------------------------------------------------------------
create table if not exists public.follows (
  "id"         text primary key,
  "followerId" text not null,
  "followeeId" text not null,
  "createdAt"  text not null
);
create index if not exists idx_follows_follower
  on public.follows ("followerId");
create index if not exists idx_follows_followee
  on public.follows ("followeeId");

grant select, insert, update, delete
  on public.follows to anon;


-- -------------------------------------------------------------
-- 5. 收藏
-- -------------------------------------------------------------
create table if not exists public.favorites (
  "id"         text primary key,
  "userId"     text not null,
  "targetType" text not null,           -- post | spot
  "targetId"   text not null,
  "createdAt"  text not null
);
create index if not exists idx_favorites_user
  on public.favorites ("userId", "targetType");

grant select, insert, update, delete
  on public.favorites to anon;


-- -------------------------------------------------------------
-- 6. 私信会话 + 消息体
-- -------------------------------------------------------------
create table if not exists public.conversations (
  "id"       text primary key,
  "userAId"  text not null,
  "userBId"  text not null,
  "lastMsg"  text default '',
  "lastAt"   text default '',
  "unreadA"  integer default 0,
  "unreadB"  integer default 0,
  "createdAt" text default ''
);
create index if not exists idx_conversations_a
  on public.conversations ("userAId");
create index if not exists idx_conversations_b
  on public.conversations ("userBId");

grant select, insert, update, delete
  on public.conversations to anon;

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
create index if not exists idx_chat_messages_conv
  on public.chat_messages ("conversationId", "createdAt");

grant select, insert, update, delete
  on public.chat_messages to anon;


-- -------------------------------------------------------------
-- 7. 渔获 + 渔获点赞
-- -------------------------------------------------------------
create table if not exists public.catches (
  "id"          text primary key,
  "userId"      text not null,
  "userName"    text default '',
  "fishName"    text default '',
  "weightKg"    numeric default 0,
  "lengthCm"    numeric default 0,
  "spotName"    text default '',
  "city"        text default '',
  "photoUrl"    text default '',
  "note"        text default '',
  "likeCount"   integer default 0,
  "commentCount" integer default 0,
  "caughtAt"    text default '',
  "createdAt"   text not null
);
create index if not exists idx_catches_user
  on public.catches ("userId", "createdAt" desc);
create index if not exists idx_catches_weight
  on public.catches ("weightKg" desc);

grant select, insert, update, delete
  on public.catches to anon;

create table if not exists public.catch_likes (
  "id"        text primary key,
  "catchId"   text not null,
  "userId"    text not null,
  "createdAt" text not null
);
create index if not exists idx_catch_likes_catch
  on public.catch_likes ("catchId");

grant select, insert, update, delete
  on public.catch_likes to anon;


-- -------------------------------------------------------------
-- 8. 拉黑 / 举报
-- -------------------------------------------------------------
create table if not exists public.blocks (
  "id"         text primary key,
  "userId"     text not null,      -- 谁拉黑
  "blockedId"  text not null,      -- 被拉黑
  "createdAt"  text not null
);
create index if not exists idx_blocks_user
  on public.blocks ("userId");

grant select, insert, update, delete
  on public.blocks to anon;

create table if not exists public.reports (
  "id"          text primary key,
  "reporterId"  text not null,
  "targetType"  text not null,     -- post | spot | comment | user
  "targetId"    text not null,
  "reason"      text default '',
  "detail"      text default '',
  "status"      text default 'pending',
  "createdAt"   text not null
);
create index if not exists idx_reports_status
  on public.reports ("status", "createdAt" desc);

grant select, insert, update, delete
  on public.reports to anon;


-- -------------------------------------------------------------
-- 9. 装备图鉴 + 装备评价
-- -------------------------------------------------------------
create table if not exists public.equips (
  "id"          text primary key,
  "brand"       text default '',
  "name"        text not null,
  "model"       text default '',
  "category"    text not null,      -- rod_spin | rod_bait | rod_casting | reel | lure | line
  "slot"        text default '',    -- 对应装备栏槽位：rod | reel | line | bait
  "waterType"   text default '',    -- 海水 | 淡水 | 通用
  "handle"      text default '',    -- 直柄 | 枪柄（路亚竿柄型）
  "sections"    text default '',    -- 独节 | 两节 | 一本半
  "reelType"    text default '',    -- 纺车轮 | 水滴轮 | 鼓轮
  "hand"        text default '',    -- 左手 | 右手（卷线器左右手）
  "specs"       text default '',    -- JSON 字符串：规格键值
  "tags"        text default '',    -- JSON 数组
  "description" text default '',
  "imageUrl"    text default '',
  "gallery"     text default '',    -- JSON 数组
  "price"       numeric,
  "brandSeries" text default '',
  "score"       integer default 0,
  "heat"        integer default 0,
  "replyCount"  integer default 0,
  "createdAt"   text default ''
);
create index if not exists idx_equips_cat
  on public.equips ("category", "heat" desc);

grant select, insert, update, delete
  on public.equips to anon;

create table if not exists public.equip_reviews (
  "id"         text primary key,
  "equipId"    text not null,
  "authorId"   text not null default '',
  "authorName" text default '',
  "rating"     integer default 5,      -- 1~5 星，真实评分
  "content"    text not null,
  "likeCount"  integer default 0,
  "createdAt"  text not null
);
create index if not exists idx_equip_reviews_equip
  on public.equip_reviews ("equipId", "createdAt" desc);

grant select, insert, update, delete
  on public.equip_reviews to anon;


-- -------------------------------------------------------------
-- 10. 地图钓友图层 + 版本配置
-- -------------------------------------------------------------
create table if not exists public.user_locations (
  "id"        text primary key,
  "userId"    text not null,
  "lat"       numeric,
  "lng"       numeric,
  "city"      text default '',
  "spotName"  text default '',
  "updatedAt" text default ''
);
create index if not exists idx_user_locations_user
  on public.user_locations ("userId");

grant select, insert, update, delete
  on public.user_locations to anon;

create table if not exists public.app_config (
  "id"          text primary key,     -- android | ios | web
  "version"     text default '',
  "build"       integer default 0,
  "forceUpdate" boolean default false,
  "url"         text default '',
  "note"        text default '',
  "updatedAt"   text default ''
);

grant select, insert, update, delete
  on public.app_config to anon;

insert into public.app_config ("id","version","build","forceUpdate","updatedAt")
values ('android', '1.1.0', 11, false, now()::text)
on conflict ("id") do nothing;

insert into public.app_config ("id","version","build","forceUpdate","updatedAt")
values ('web', '1.1.0', 11, false, now()::text)
on conflict ("id") do nothing;


-- =============================================================
-- 执行完毕的验证方法：
-- 浏览器打开下面地址，应返回 []（表示表建好了，只是还没有数据）：
-- https://moyuquan-d5g0pvpcw55f8a62e.api.tcloudbasegateway.com/v1/rdb/rest/post_comments?select=*
--
-- 若返回 "Could not find the table"，说明没执行成功。
-- =============================================================