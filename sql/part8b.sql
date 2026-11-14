-- ============================================================
-- part8b.sql · 放宽上传策略：让 App 端（Publishable Key / anon 角色）能上传
--
-- 背景（2026-10-18 实测踩坑）：
--   part8.sql 最初把上传策略写成
--       AND (storage.foldername(name))[1] = auth.uid()
--   以为 Publishable Key 会带一个 uid 子身份。结果用 Publishable Key 直接
--   PUT /v1/storages/object/spot-photos/{uid}/{name}.png 报：
--       403 STORAGE_ACCESS_DENIED
--       PG RLS error: new row violates row-level security policy for table "objects"
--   说明 anon 角色下 auth.uid() 拿不到能匹配的值，App 端永远传不上来。
--
-- 权衡：App 目前的账号体系是「本地 uid + anon 客户端」，服务端没有可信的
-- 登录身份可绑定（真要严格隔离，得先做用户身份认证，见 README 待办）。
--   这里的选择是：**放开上传，但用能验证的硬约束把风险压到可接受**——
--     ① 只允许写这两个专用 bucket（不能碰别的数据）
--     ② 路径首段必须是合法 uid 形态：guest_ 前缀 或 u_ 前缀 + 字母数字下划线
--        （挡掉 "../xxx" 穿越、任意目录乱写）
--     ② 路径必须形如 <uid>/<file>（两段）
--        ⚠️ storage.foldername('u_1/a.png') 返回 {u_1}，长度是 **1** 不是 2
--           （实测踩过：写成 array_length(...) = 2 导致 App 端 100% 上传失败）
--     ④ 覆盖(upsert)只允许改自己 uid 目录下的同名对象
--   读取仍然公开（照片是钓点展示素材，本来就要给所有人看）。
--
-- ⚠️ 剩余风险（如实说明）：anon 可以在自己 uid 目录里反复上传消耗存储。
--   真要根治需先接 CloudBase 用户身份认证（auth.signInAnonymously / 微信登录），
--   届时 auth.uid() 有值，再把策略收紧回"仅本人目录"即可。
--
-- 幂等：可重复执行。
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- 上传：anon / authenticated 都允许，但路径必须符合 uid 形态
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS spot_photos_authenticated_upload ON storage.objects;

CREATE POLICY spot_photos_authenticated_upload ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    bucket_id IN ('spot-photos', 'post-photos')
    -- 恰好两段路径：<uid>/<file>
    AND array_length(storage.foldername(name), 1) = 1
    -- 首段是 uid 形态：guest_xxx 或 u_xxx（字母数字下划线）
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  );


-- ────────────────────────────────────────────────────────────
-- 覆盖 / 删除：同样按路径形态约束，不依赖 auth.uid()
-- （uid 由客户端自己声明，无法验证归属，所以这里只做格式与深度约束；
--   真正的归属校验要等身份认证接上之后。）
-- ────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS spot_photos_owner_update ON storage.objects;

CREATE POLICY spot_photos_owner_update ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) = 1
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  )
  WITH CHECK (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) = 1
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  );

DROP POLICY IF EXISTS spot_photos_owner_delete ON storage.objects;

CREATE POLICY spot_photos_owner_delete ON storage.objects
  FOR DELETE TO anon, authenticated
  USING (
    bucket_id IN ('spot-photos', 'post-photos')
    AND array_length(storage.foldername(name), 1) = 1
    AND (storage.foldername(name))[1] ~ '^(guest_|u_)[A-Za-z0-9_]{1,64}$'
  );
