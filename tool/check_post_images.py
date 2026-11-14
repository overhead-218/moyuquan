# -*- coding: utf-8 -*-
"""体检云库 posts 表的配图来源：统计 imageUrl 里有多少是通用图池/工程本地假图。

背景：与 clean_spot_images.py 同一类问题。post_service.dart 的 mock 帖子
里 38 处 imageUrl 指向 `assets/images/spots/wm_XX.jpg`，这是多帖共用的通用
钓鱼图池，不是这些帖子的真实配图；这些帖子此前已被 seed 进云库。

用法：
    python tool/check_post_images.py
"""
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


def fetch_all():
    rows, offset = [], 0
    while True:
        q = urllib.parse.urlencode({'select': 'id,title,imageUrl',
                                   'limit': 500, 'offset': offset,
                                   'order': 'id.asc'})
        batch = req('GET', f'{REST_BASE}/{TABLE}?{q}') or []
        rows.extend(batch)
        if len(batch) < 500:
            break
        offset += 500
    return rows


def main():
    rows = fetch_all()
    print(f'posts 共 {len(rows)} 行\n')
    fake, real, empty = [], [], []
    for r in rows:
        u = (r.get('imageurl') or r.get('imageUrl') or '').strip()
        if not u:
            empty.append(r)
        elif u.startswith('http') and '/spots/wm_' not in u and '/spots/spot_' not in u:
            real.append(r)
        else:
            fake.append((r, u))

    print(f'无配图（空）        : {len(empty)}')
    print(f'真实/官方配图(http)  : {len(real)}')
    print(f'通用图池等假图      : {len(fake)}')
    print('\n假图样例：')
    for r, u in fake[:12]:
        print(f"  {r.get('id')}  {(r.get('title') or '')[:20]:<22} {u.rsplit('/', 1)[-1]}")
    buckets = {}
    for _, u in fake:
        b = u.rsplit('/', 1)[-1] if '/' in u else u
        buckets[b] = buckets.get(b, 0) + 1
    print('\n按文件统计：')
    for k, v in sorted(buckets.items(), key=lambda x: -x[1]):
        print(f'  {k}: {v}')


if __name__ == '__main__':
    main()
