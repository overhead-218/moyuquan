-- ============================================================
-- 摸鱼圈 · 短信验证码表（public.sms_verify_codes）补齐脚本
-- 用途：结构升级（哈希存储 + 错误计数） + anon 角色表级授权
-- 执行位置：云开发控制台 → 数据库 → SQL 执行 → 粘贴 → 点 ▶ 执行
-- 可重复执行（幂等）
-- ============================================================

-- 1) 验证码改为存「服务端哈希」（64 位十六进制），不再存明文。
--    原因：短信表对 anon 角色是「可读写」（云函数用 Publishable Key 访问），
--    若存明文，攻击者用 App 里公开的 Publishable Key 就能 SELECT 出所有人的待验证码 → 批量登录。
--    云函数改为只写 HMAC-SHA256(CODE_PEPPER, phone|code)，pepper 只存在于云函数环境变量里。
ALTER TABLE public.sms_verify_codes
  ALTER COLUMN code TYPE VARCHAR(64);

-- 2) 单条验证码的错误次数（错满 5 次即作废，需重新发送；配合 60 秒重发间隔防在线爆破）
ALTER TABLE public.sms_verify_codes
  ADD COLUMN IF NOT EXISTS attempts INTEGER NOT NULL DEFAULT 0;

-- 3) 表级授权（关键缺口！）
--    RLS 策略只决定「能操作哪些行」，GRANT 才决定「能不能操作这张表」，两者缺一不可。
--    此前只建了 RLS 策略、没有表级授权 → 云函数写入时报
--    42501 permission denied for table sms_verify_codes
GRANT SELECT, INSERT, UPDATE ON TABLE public.sms_verify_codes TO anon;
-- BIGSERIAL 主键的序列也要授权，否则插入会被序列权限拦住
GRANT USAGE ON SEQUENCE public.sms_verify_codes_id_seq TO anon;

-- 4) 结果校验（应看到 anon 拥有 INSERT / SELECT / UPDATE）
SELECT grantee, privilege_type
  FROM information_schema.role_table_grants
 WHERE table_name = 'sms_verify_codes'
   AND grantee = 'anon'
 ORDER BY privilege_type;
