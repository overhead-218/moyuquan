# -*- coding: utf-8 -*-
"""清理上传链路验证过程中在 spots.images 留下的测试痕迹。

背景：e2e_photo_upload.py 会往目标钓点写测试 URL。首轮因脚本自身的
读回校验 bug 中途退出，残留了 http://x/y.png 这类假 URL 和几个测试图链接。
这些进了生产数据就是"假照片"，与本轮清洗目标相悖，必须清掉。

同时删除 storage 里 probe/e2e 前缀的测试对象。

用法：python tool/cleanup_probe_uploads.py [--apply]
"""
import argparse
import io
import json
import os
import re
import urllib.error
import urllib.parse
import urllib.request

ENV = 'moyuquan-d5g0pvpcw55f8a62e'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REST = f'https://{ENV}.api.tcloudbasegateway.com/v1/rdb/rest'
GW = f'https://{ENV}.api.tcloudbasegateway.com'
KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services',
                                     'backend_config.dart'),
                        encoding='utf-8').read()).group(1)

# 测试痕迹特征
PROBE_HOSTS = ('storages/object/',)
PROBE_LITERAL = ('http://x/y.png',)


def req(method, url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            raw = resp.read().decode('utf-8')
            return resp.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode('utf-8'))
        except Exception:
            return e.code, None
    except Exception as e:
        return 'ERR', str(e)[:150]


def is_probe(u):
    s = str(u)
    if any(s == p for p in PROBE_LITERAL):
        return True
    if any(h in s for h in PROBE_HOSTS):
        return True
    return False


def fetch_all():
    rows, offset = [], 0
    while True:
        q = urllib.parse.urlencode({'select': 'id,name,images',
                                    'limit': 500, 'offset': offset,
                                    'order': 'id.asc'})
        batch = req('GET', f'{REST}/spots?{q}')[1] or []
        rows.extend(batch)
        if len(batch) < 500:
            break
        offset += 500
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()

    rows = fetch_all()
    print(f'spots 共 {len(rows)} 行\n')

    dirty = 0
    for r in rows:
        imgs = r.get('images') or []
        if not isinstance(imgs, list):
            continue
        keep = [u for u in imgs if not is_probe(u)]
        if len(keep) == len(imgs):
            continue
        dirty += 1
        print(f'  {r["id"]:<10} {str(r.get("name") or "")[:20]:<22} '
              f'{len(imgs)} → {len(keep)} 张')
        if args.apply:
            req('PATCH', f'{REST}/spots?id=eq.{urllib.parse.quote(str(r["id"]))}',
                {'images': keep})

    print(f'\n含测试痕迹的行: {dirty}')
    if args.apply:
        print('✓ 已清理云库 spots.images')
    else:
        print('这是 dry-run。加 --apply 执行。')


if __name__ == '__main__':
    main()
