-- part6.sql：补齐 spots 表缺失的 4 列 + 回填 status
-- 背景：tool/check_spots.py 实测 597 行，前端 Spot 模型读这 4 个字段时永远拿到 null，
--       导致详情页「多档收费 / 审核状态 / 图片说明 / 实景图标记」全部显示不出来。
--
-- ⚠️ 2026-11 修正：列名【必须带双引号】。
--    spots 表既有列是驼峰原样保留的（imageUrl / hasWifi / roomType ...），
--    PG 只在【不加双引号】时才把标识符归一成小写。不带引号建出来的列会是
--    pricetiers / imagecaptions / imagesverified，而前端读写用的是驼峰 → 全部读不到。
--    对比：profiles / conversations / chat_messages 表的驼峰列被归一成小写，那几张表要写小写。
--    动手前务必先 select=列名&limit=1 探测，不要套用别的表的规则。
--
-- ✅ 已由 tool/run_part6.py 在云端执行生效（9 条全 OK），无需再手动执行。
--    执行方式（若需重跑）：python tool/run_part6.py
--    幂等：可重复执行，不会报错。

alter table spots add column if not exists "priceTiers" jsonb default '[]'::jsonb;
alter table spots add column if not exists "status" text default 'active';
alter table spots add column if not exists "imageCaptions" jsonb default '{}'::jsonb;
alter table spots add column if not exists "imagesVerified" boolean default false;

-- status 回填：已认领的算 active，其余默认 active（前台只展示 active 的钓点）
update spots set "status" = 'active' where "status" is null or "status" = '';
update spots set "priceTiers" = '[]'::jsonb where "priceTiers" is null;
update spots set "imageCaptions" = '{}'::jsonb where "imageCaptions" is null;
update spots set "imagesVerified" = false where "imagesVerified" is null;

grant select, insert, update, delete on spots to anon;

-- 注：grant 里给了 delete，但 spots 的 RLS 只有 SELECT/INSERT/UPDATE 三条策略，
--     没有 DELETE 策略 → 经 PostgREST 发 DELETE 会返回 204 但实际不删任何行（静默失败）。
--     App 目前没有「删除钓点」功能，所以暂未暴露。将来要加删除功能，
--     必须先补一条 anon_delete_spots 策略，否则会「看起来删掉了其实没删」。
--     不擅自开放：anon 可删意味着任何人拿到 publishable key 就能删钓点。
