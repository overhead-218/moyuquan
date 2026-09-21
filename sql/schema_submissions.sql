-- 钓友 UGC 投稿 / 纠错审核表
-- 在 CloudBase 控制台 → 数据库 → PostgreSQL → SQL 执行 中粘贴运行
-- 两张表均放开 anon INSERT（用户无需登录即可提交），运营后台审核后写入正式 spot_service

-- 1) 新钓点投稿
CREATE TABLE IF NOT EXISTS public.spot_submissions (
  id            BIGSERIAL PRIMARY KEY,
  spot_id      TEXT,
  name         TEXT,
  type         TEXT,
  type_emoji   TEXT,
  city         TEXT,
  district     TEXT,
  address      TEXT,
  latitude     DOUBLE PRECISION,
  longitude    DOUBLE PRECISION,
  images_json  TEXT,                       -- JSON 数组：base64 data URI 或 http URL
  fish_species TEXT,                       -- JSON 数组
  fish_peak_season TEXT,                   -- JSON 对象
  price        DOUBLE PRECISION,
  price_note   TEXT,
  business_hours TEXT,
  contact_phone TEXT,
  wechat       TEXT,
  owner_name   TEXT,
  description  TEXT,
  facilities_json TEXT,                    -- JSON 数组
  has_accommodation BOOLEAN DEFAULT FALSE,
  submitter_phone TEXT,
  submitter_name TEXT,
  status       TEXT DEFAULT 'pending',     -- pending | approved | rejected
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_submissions_status ON public.spot_submissions (status);

-- 2) 图片/信息纠错
CREATE TABLE IF NOT EXISTS public.spot_corrections (
  id            BIGSERIAL PRIMARY KEY,
  spot_id      TEXT,
  spot_name    TEXT,
  reason       TEXT,                        -- 图片错误 / 信息有误 / 钓点已关闭 / 其他
  note         TEXT,
  submitter_name TEXT,
  status       TEXT DEFAULT 'pending',
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_corrections_status ON public.spot_corrections (status);

-- RLS：允许匿名插入（提交），运营用 service_role 后台审核/读取
ALTER TABLE public.spot_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spot_corrections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS anon_insert_submissions ON public.spot_submissions;
CREATE POLICY anon_insert_submissions ON public.spot_submissions
  FOR INSERT TO anon WITH CHECK (true);

DROP POLICY IF EXISTS anon_insert_corrections ON public.spot_corrections;
CREATE POLICY anon_insert_corrections ON public.spot_corrections
  FOR INSERT TO anon WITH CHECK (true);

GRANT INSERT ON TABLE public.spot_submissions TO anon;
GRANT INSERT ON TABLE public.spot_corrections TO anon;
GRANT USAGE ON SEQUENCE public.spot_submissions_id_seq TO anon;
GRANT USAGE ON SEQUENCE public.spot_corrections_id_seq TO anon;
