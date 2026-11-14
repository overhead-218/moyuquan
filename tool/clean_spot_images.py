# -*- coding: utf-8 -*-
"""清洗云库 spots.images：剔除所有非真实照片，只保留真实来源。

背景（2026-10-18 实测 597 行确认）：
  · 250 行的 images 塞的是 `assets/images/spots/wm_02.jpg` 这类通用图池路径
  · 剩余行的 images 塞的是 `assets/images/spots/spot_001.jpg` 这类"钓点专属"路径，
    但抽查发现这些文件与钓点**毫无关系**：spot_001.jpg 是一张菠萝，
    spot_025.jpg 是东京街道，spot_060.jpg 是洛杉矶夕阳 —— 是随机抓的无关图库图
  · 真正的真实照片只有 http 开头的 46 行（Wikimedia 公共图库照，
    万峰湖/千岛湖/抚仙湖等真实湖泊照片）

也就是说：597 个钓点里 551 个没有一张能对得上号的照片。
前端此前把它们当"实景"展示，是用假图冒充实景，必须清掉。

本脚本做的事：
  1. 逐行读 images / accommodationImages / commonAreaImages
  2. 只保留 http(s) 开头的 URL（真实网络照片）
  3. 其余一律剔除；某行剔完变空数组则写回 []
  4. **不删行**，只改这三个字段，幂等可重复执行

用法：
    python tool/clean_spot_images.py --dry-run   # 只看会改什么
    python tool/clean_spot_images.py --apply     # 真写库
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
TABLE = 'spots'
POOL_RE = re.compile(r'wm_\d+\.(jpg|jpeg|png)$', re.IGNORECASE)
FIELDS = ['images', 'accommodationImages', 'commonAreaImages']


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


def is_fake(u):
    """非真实照片：
    · wm_*.jpg      —— 通用钓鱼图池，多钓点共用
    · spot_*.jpg    —— 抽查为随机无关图库图（菠萝/东京街道/洛杉矶夕阳）
    · 任何非 http 开头路径 —— 工程本地 asset 都不是商家实拍
    """
    u = str(u)
    if u.startswith('http'):
        return False
    return True


def to_list(v):
    if v is None:
        return []
    if isinstance(v, list):
        return [str(x) for x in v]
    if isinstance(v, str) and v.strip():
        return [v]
    return []


def fetch_all():
    rows, offset = [], 0
    while True:
        q = urllib.parse.urlencode({
            'select': 'id,name,' + ','.join(FIELDS),
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
    print(f'spots 共 {len(rows)} 行\n')

    total_removed = 0
    cleaned_rows = 0
    now_empty = 0
    kept_http = 0

    for r in rows:
        patch = {}
        for f in FIELDS:
            cur = to_list(r.get(f))
            keep = [u for u in cur if not is_fake(u)]
            removed = len(cur) - len(keep)
            if removed:
                total_removed += removed
                patch[f] = keep
            if f == 'images':
                kept_http += sum(1 for u in keep if u.startswith('http'))
        if not patch:
            continue
        cleaned_rows += 1
        if all(len(patch.get(f, to_list(r.get(f)))) == 0 for f in FIELDS):
            now_empty += 1
        if args.apply:
            req('PATCH', f'{REST_BASE}/{TABLE}?id=eq.{urllib.parse.quote(str(r["id"]))}',
                patch)

    print(f'含假图路径的行        : {cleaned_rows}')
    print(f'剔除的图片 URL 总数   : {total_removed}')
    print(f'清洗后变为「零照片」  : {now_empty}  （前端显示「暂无实景照片」占位）')
    print(f'保留的真实照片(http)  : {kept_http}  （Wikimedia 等公共图库实景）')
    if args.apply:
        print('\n✓ 已写库完成。可在 App 内刷新验证。')
    else:
        print('\n这是 dry-run，未改动任何数据。确认无误后加 --apply 执行。')


if __name__ == '__main__':
    main()
