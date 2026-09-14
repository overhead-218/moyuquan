-- 短信验证码表（临时存储，TTL 自动清理旧记录）
CREATE TABLE IF NOT EXISTS sms_verify_codes (
  id          BIGSERIAL PRIMARY KEY,
  phone       VARCHAR(20) NOT NULL,
  code        VARCHAR(6) NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  used        BOOLEAN DEFAULT FALSE
);

-- 索引（按手机号查最新未用验证码）
CREATE INDEX IF NOT EXISTS idx_sms_phone_unused
  ON sms_verify_codes(phone, created_at DESC)
  WHERE used = FALSE;

-- RLS
ALTER TABLE sms_verify_codes ENABLE ROW LEVEL SECURITY;

-- 匿名只写（发码）只查自己的
CREATE POLICY "anon_insert" ON sms_verify_codes
  FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_select" ON sms_verify_codes
  FOR SELECT USING (true);
CREATE POLICY "anon_update" ON sms_verify_codes
  FOR UPDATE USING (true);

-- TTL 清理（保留最近 10 分钟的记录即可）
-- 定时任务或应用层清理，这里用 PostgREST 触发器简化
CREATE OR REPLACE FUNCTION cleanup_old_codes()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM sms_verify_codes
    WHERE created_at < NOW() - INTERVAL '10 minutes'
       OR used = TRUE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 每次插入新验证码时自动清理旧记录
CREATE TRIGGER trg_cleanup_on_insert
  AFTER INSERT ON sms_verify_codes
  FOR EACH STATEMENT EXECUTE FUNCTION cleanup_old_codes();
