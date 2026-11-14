-- ============================================================
-- 摸鱼圈 · 放宽对象存储上传策略（支持平台批量图库路径）
--
-- 背景：商家照片上传闭环已跑通，但原策略只允许「一层路径 + u_/guest_ 前缀」：
--     array_length(storage.foldername(name), 1) = 1
--     AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
--   → 平台批量上传的真实钓点图（u_platform/s251/01.jpg，2 层）会被拒。
--
-- ⚠️ storage.foldername('u_1/a.png') 返回 {u_1}，长度是 1 不是 2
--    （曾踩过：写成 = 2 导致上传 100% 失败）
--
-- 路径约定（第一段即「归属前缀」，决定角标语义）：
--   u_<uid>/xxx.jpg       商家/用户自己上传 → 商家实拍 / 钓友上传
--   u_platform/<spotId>/NN.jpg  平台批量上架的真实钓点图 → 平台实景
--   guest_xxx/xxx.jpg     游客上传
--
-- 安全性说明：anon 可上传意味着任何人能往自己前缀下塞文件消耗存储。
--   这是「有身份认证之前」的已知取舍，真正的硬防线是桶容量上限。
--   收紧要等真实身份体系接上后，把 WITH CHECK 加上 auth.uid() 绑定。
-- ============================================================

DROP POLICY IF EXISTS spot_photos_authenticated_upload ON storage.objects;

-- 允许 1~2 层路径；第一段必须是我们约定的前缀
CREATE POLICY spot_photos_authenticated_upload ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) BETWEEN 1 AND 2
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  );

-- 更新：同样按路径形态约束（owner_update / owner_delete 之前是 ALL，无 with_check）
DROP POLICY IF EXISTS spot_photos_owner_update ON storage.objects;
CREATE POLICY spot_photos_owner_update ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) BETWEEN 1 AND 2
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  )
  WITH CHECK (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) BETWEEN 1 AND 2
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  );

DROP POLICY IF EXISTS spot_photos_owner_delete ON storage.objects;
CREATE POLICY spot_photos_owner_delete ON storage.objects
  FOR DELETE TO anon, authenticated
  USING (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) BETWEEN 1 AND 2
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  );

-- 结果校验（应看到 4 条策略）
SELECT policyname, cmd FROM pg_policies
 WHERE tablename='objects' ORDER BY policyname;
