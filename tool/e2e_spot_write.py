# -*- coding: utf-8 -*-
"""实测：Spot.toJson() 现在能不能真的写进云库。

背景：toJson 曾混入派生字段 imageSource（云库无此列），
      导致 insert/upsert 整条 PGRST204 —— 商家提交/编辑钓点全失败。
本脚本拿真实 spot 行的字段集合做一次 insert + upsert + update，全部走 PostgREST。
"""
import io
import json
import os
import re
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
REST = f'https://{ENV}.api.tcloudbasegateway.com/v1/rdb/rest'
PROBE_ID = 'zz_probe_spot'

KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services', 'backend_config.dart'),
                        encoding='utf-8').read()).group(1)


def req(method, url, body=None, prefer='return=representation'):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json',
        'Prefer': prefer})
    try:
        with urllib.request.urlopen(r, timeout=40) as resp:
            b = resp.read()
            return resp.status, (json.loads(b) if b.strip() else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]
    except Exception as e:
        return 'ERR', str(e)[:200]


def show(n, code, body, want=(200, 201, 204)):
    ok = code in want
    print(f'{n}) {"✓" if ok else "✗"} {code}  {"" if ok else body}')
    return ok


# 用真实行做模板，保证字段集合与线上一致
c, rows = req('GET', f'{REST}/spots?select=*&limit=1')
if c != 200 or not rows:
    print('✗ 读不到 spots 样本行', c, rows)
    raise SystemExit(1)
row = dict(rows[0])
row['id'] = PROBE_ID
row['name'] = '__探针行_可安全删除__'
# 派生字段不入库（与修复后的 toJson 一致）
for k in ('imageSource',):
    row.pop(k, None)
print(f'样本行字段数: {len(row)}（已剔除 imageSource）\n')

ok = show('1 insert（Spot._pushAdd 路径）', *req('POST', f'{REST}/spots', row),
          want=(200, 201))
# 2. upsert 复刻 TcbRestClient.upsert 的 Prefer 头：重复 id 应被静默忽略
if ok:
    ok = show('2 upsert（resolution=ignore-duplicates，同 id 不报错）',
              *req('POST', f'{REST}/spots', row,
                   prefer='resolution=ignore-duplicates,return=minimal'),
              want=(200, 201, 204))
show('3 PATCH 更新（SpotService._pushClaim 路径）', *req('PATCH',
     f'{REST}/spots?id=eq.{PROBE_ID}', {'name': '__探针行_改名__'},
     prefer='return=minimal'))

c, back = req('GET', f'{REST}/spots?select=id,name,imagesVerified,status,priceTiers'
                     f'&id=eq.{PROBE_ID}')
print(f'4) {"✓" if c == 200 and back else "✗"} 读回 → {back}')

c, _ = req('DELETE', f'{REST}/spots?id=eq.{PROBE_ID}')
print(f'5) {"✓" if c in (200, 204) else "✗"} 清理探针行 → {c}')

print('\n结论:', 'Spot.toJson() 写库链路正常' if ok else '写库仍有问题')