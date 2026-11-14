# -*- coding: utf-8 -*-
"""清洗云库 posts 表配图：剔除通用图池假图，置空交由前端诚实占位。

⚠️ 表结构实测结论（2026-10-18）：
  · posts 的列名是**驼峰原样**（imageUrl / likeCount），不是像 spots/profiles
    那样被 PG 归一成小写 —— 因为这些列是用带引号的 `ADD COLUMN "imageUrl"` 建的。
    所以本脚本读写都直接用驼峰，不要 lowercase。
  · posts 表**没有 images 列**（只有 imageUrl 单图）。
    这意味着 `Post.toJson()` 里写的 `'images': images` 会让用户发帖整条报
    PGRST204 写不进去 —— 这是个独立的 bug，已单独修（见 post.dart）。
    因此本脚本只处理 imageUrl。

背景（2026-10-18 实测 42 行确认）：
  · 42 条帖子中 38 条 imageUrl 指向 `assets/images/spots/wm_XX.jpg`
    —— 这是多帖共用的通用钓鱼图池，同一张 wm_01.jpg 被 p_001 和另一帖复用，
       并不是这些帖子的真实配图（"二十年没见过的野生甲鱼"配的是通用风景照）
  · 真正算得上的只有 3 张官方自己做的引导帖配图 off_claim/off_find/off_community
  · 另有 1 条本来就无图

与 spots 的处理保持同一标准：宁可显示"暂无配图"，也不拿通用图冒充实景。

⚠️ 官方引导帖（id 以 p_off_ 开头、图在 official/ 目录）必须保留，
   那是运营自己做的示意图，不是钓鱼。

本脚本做的事：
  1. 逐行读 id / imageUrl
  2. 只保留官方引导帖的配图（/assets/assets/images/official/）
  3. 其余一律置空 imageUrl=''
  4. **不删行、不删帖**，只改配图字段，幂等可重复执行

用法：
    python tool/clean_post_images.py --dry-run   # 只看会改什么
    python tool/clean_post_images.py --apply     # 真写库
"""
import argparse
import io
import json
import os
import re
import urllib.parse
import urllib.request

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_ID = 'moyuquan-d5g0pvpcw55f8a62e'
REST_BASE = f'https://{ENV_ID}.api.tcloudbasegateway.com/v1/rdb/rest'
TABLE = 'posts'

# 官方引导帖自己的示意图，保留
KEEP_RE = re.compile(r'/images/official/', re.IGNORECASE)
# 通用钓鱼图池：多帖共用，一律剔除
FAKE_RE = re.compile(r'/images/spots/(wm_|spot_)', re.IGNORECASE)


def get_key():
    p = os.path.join(PROJECT_ROOT, 'lib', 'services', 'backend_config.dart')
    return re.search(r"publishableKey\s*=\s*'([^']+)'",
                     io.open(p, encoding='utf-8').read()).group(1)


KEY = get_key()


def req(method, url, body=None):
    data = json.dumps(body).encode('utf-8') if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(r, timeout=60) as resp:
        raw = resp.read().decode('utf-8')
        return json.loads(raw) if raw.strip() else None


def pick(row, *names):
    """PostgREST 驼峰建列落库为全小写，读回要兼容大小写"""
    for n in names:
        for k in (n, n.lower()):
            if k in row and row[k] is not None:
                return row[k]
    return None


def is_fake(u):
    u = str(u).strip()
    if not u:
        return False
    if KEEP_RE.search(u):
        return False
    return True


def to_list(v):
    if v is None:
        return []
    if isinstance(v, list):
        return [str(x) for x in v if str(x).strip()]
    if isinstance(v, str) and v.strip():
        return [v]
    return []


def fetch_all():
    rows, offset = [], 0
    while True:
        q = urllib.parse.urlencode({
            'select': 'id,title,imageUrl',
            'limit': 500, 'offset': offset, 'order': 'id.asc'})
        batch = req('GET', f'{REST_BASE}/{TABLE}?{q}') or []
        rows.extend(batch)
        if len(batch) < 500:
            break
        offset += 500
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true', help='真正写库')
    ap.add_argument('--dry-run', action='store_true', help='只报告不改数据')
    args = ap.parse_args()

    rows = fetch_all()
    print(f'posts 共 {len(rows)} 行\n')

    cleaned = 0
    removed_imgs = 0
    kept = 0
    for r in rows:
        pid = str(pick(r, 'id'))
        cur = (pick(r, 'imageUrl') or '').strip()

        patch = {}
        if cur and is_fake(cur):
            patch['imageUrl'] = ''
            removed_imgs += 1
        elif cur:
            kept += 1

        if not patch:
            continue
        cleaned += 1
        print(f'  {pid:<10} {(pick(r, "title") or "")[:24]:<26} '
              f'{(cur.rsplit("/", 1)[-1] if cur else "(空)"):<18} → 清空')
        if args.apply:
            req('PATCH', f'{REST_BASE}/{TABLE}?id=eq.{urllib.parse.quote(pid)}',
                patch)

    print(f'\n需清洗的行        : {cleaned}')
    print(f'剔除的配图 URL 数  : {removed_imgs}')
    print(f'保留的官方引导配图 : {kept}')
    if args.apply:
        print('\n✓ 已写库完成。App 内刷新信息流即可看到占位效果。')
    else:
        print('\n这是 dry-run，未改动任何数据。确认无误后加 --apply 执行。')


if __name__ == '__main__':
    main()
