-- ============================================================
-- part8.sql · 对象存储（商家照片上传闭环）
--
-- 目标：让商家/钓友在钓点详情页上传真实照片后，照片能真正落到云存储，
--       拿到可访问的 URL 并写回 spots.images，前端 displayImages 立即展示。
--
-- 现状（2026-10-18 实测）：
--   · storage schema 已存在且结构完整（buckets / objects / s3_multipart_uploads）
--   · 但 storage.buckets 表里 **0 个 bucket** —— 前端选完图无处可存，
--     所以 spot_detail_new.dart 的上传只做了本地预览，如实告知"未接对象存储"
--   · RLS 策略也一条都没有
--
-- 本脚本做的事：
--   1. 建两个桶：
--        spot-photos —— 钓点实景照片（商家/钓友上传，需公开可读才能展示）
--        post-photos —— 帖子配图（同上，为后续发帖多图预留）
--   2. 写 RLS：anon 可读（展示照片）、authenticated 可上传
--      ⚠️ 照片要能被所有人看到（这是钓点展示需求，不是私有相册），
--         所以 SELECT 放开给 anon；INSERT 允许登录用户，
--         且限定只能往自己 uid 目录写，防止刷存储。
--   3. 全部幂等：可重复执行不报错
--
-- 执行方式：云开发控制台 SQL 工作台，或
--   tcb db execute -e moyuquan-d5g0pvpcw55f8a62e --file sql/part8.sql
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- 1. 建桶
-- ────────────────────────────────────────────────────────────
-- 单文件上限 10MB；只放三种常见图片格式。
-- public=true 才会生成固定可访问的 CDN 直链，否则每次访问都要签名，
-- 而 spots.images 里存的是长期字段，必须是稳定的直链。
INSERT INTO storage.buckets
  (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('spot-photos', 'spot-photos', true, 10485760,
   ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('post-photos', 'post-photos', true, 10485760,
   ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO UPDATE
  SET public              = EXCLUDED.public,
      file_size_limit     = EXCLUDED.file_size_limit,
      allowed_mime_types  = EXCLUDED.allowed_mime_types,
      updated_at          = now();


-- ────────────────────────────────────────────────────────────
-- 2. RLS 策略
-- ────────────────────────────────────────────────────────────
-- storage.objects 上三角色默认已有 ALL 权限，**不需要再 GRANT**，
-- 权限完全由 RLS 决定。
--
-- 路径约定：<bucket>/<uid>/<文件名>
--   storage.foldername('u_123/xxx.jpg') → {'u_123'}
--   取 [1] 得到 uid，和 auth.uid() 比对即"只能写自己目录"。

-- 2.1 任何人可读桶元数据（前端要能枚举可用桶）
DROP POLICY IF EXISTS buckets_select_all ON storage.buckets;
CREATE POLICY buckets_select_all ON storage.buckets
  FOR SELECT TO anon, authenticated
  USING (true);


-- ── 钓点实景照片 ────────────────────────────────────────────

-- 照片公开展示：任何人（含未登录访客）都能读
DROP POLICY IF EXISTS spot_photos_public_read ON storage.objects;
CREATE POLICY spot_photos_public_read ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id IN ('spot-photos', 'post-photos'));

-- 登录用户可上传。允许两种身份：
--   ① 商家/钓友本人已登录 → auth.uid() 有值，照片写到自己目录
--   ② 游客建档（uid 以 guest_ 开头）也允许写自己目录
-- 这样"没登录也能传图但只能传到自己目录"的安全底线仍在。
DROP POLICY IF EXISTS spot_photos_authenticated_upload ON storage.objects;
CREATE POLICY spot_photos_authenticated_upload ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('spot-photos', 'post-photos')
    AND (storage.foldername(name))[1] = auth.uid()
  );

-- 上传方可以覆盖/更新自己目录下的对象（upsert 用）
DROP POLICY IF EXISTS spot_photos_owner_update ON storage.objects;
CREATE POLICY spot_photos_owner_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id IN ('spot-photos', 'post-photos')
    AND (storage.foldername(name))[1] = auth.uid()
  )
  WITH CHECK (
    bucket_id IN ('spot-photos', 'post-photos')
    AND (storage.foldername(name))[1] = auth.uid()
  );

-- 上传方可以删除自己目录下的对象（商家换图、删错图）
DROP POLICY IF EXISTS spot_photos_owner_delete ON storage.objects;
CREATE POLICY spot_photos_owner_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id IN ('spot-photos', 'post-photos')
    AND (storage.foldername(name))[1] = auth.uid()
  );
