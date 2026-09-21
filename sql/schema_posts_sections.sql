-- 帖子讲解目录（sections）字段：Postgres jsonb 列
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS sections JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.posts.sections IS '讲解目录章节数组：[{title, body}]，guide 类官方帖使用';
