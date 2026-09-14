-- 摸鱼圈全量数据表（云开发 MySQL 模式）
-- 列名与 toJson() 字段 1:1（保持驼峰，PostgREST / 文档型 API 都能识别）
-- 在云开发控制台「SQL 编辑器 / 数据库」里执行本脚本。

-- ── posts 帖子 ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS posts (
  id            VARCHAR(64)  PRIMARY KEY,
  authorId      VARCHAR(64),
  authorName    VARCHAR(128),
  authorAvatar  VARCHAR(512),
  type          VARCHAR(32),
  title         VARCHAR(256),
  content       TEXT,
  location      VARCHAR(256),
  imageUrl      VARCHAR(512),
  height        DOUBLE,
  likeCount     INT          DEFAULT 0,
  commentCount  INT          DEFAULT 0,
  createdAt     VARCHAR(64)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── messages 会话 ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
  id      VARCHAR(64)  PRIMARY KEY,
  name    VARCHAR(128),
  last    VARCHAR(512),
  time    VARCHAR(64),
  avatar  VARCHAR(512),
  unread  INT          DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── profiles 用户资料（当前用户固定 id='me'）────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id           VARCHAR(64)  PRIMARY KEY,
  name         VARCHAR(128),
  bio          VARCHAR(512),
  city         VARCHAR(64),
  gender       VARCHAR(32),
  avatarEmoji  VARCHAR(32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 权限：云开发控制台「权限设置 / 角色管理」给 anon 角色勾选这三张表的
-- select / insert / update / delete 权限即可。
-- 如果用的是「应用层 API Key」配 PostgREST 风格，anon 默认即可读写。
</content>
</invoke>
