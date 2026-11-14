# -*- coding: utf-8 -*-
"""核对 Spot.toJson() 的键与云库 spots 表真实列是否 1:1。

背景：toJson 里混入派生字段 imageSource（云库无此列）会让 insert/upsert
整条报 PGRST204 —— 商家提交/编辑钓点全失败。本脚本防复发。
"""
import io
import json
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'

src = io.open(os.path.join(ROOT, 'lib', 'models', 'spot.dart'), encoding='utf-8').read()
# 锚定 Spot 自己的 toJson：'id': id 是 Spot 独有（PriceTier 是 label/unit/note）
m = re.search(r"Map<String, dynamic> toJson\(\) => \{\s*\n\s*'id': id,(.*?)'priceTiers':.*?\n  \};",
              src, re.S)
if not m:
    print('✗ 未能定位 Spot.toJson，请检查 spot.dart 结构')
    raise SystemExit(1)
body = m.group(0)
keys = re.findall(r"^\s*'([A-Za-z_][A-Za-z0-9_]*)':", body, re.M)

ansi = re.compile(r'\x1b\[[0-9;]*m')
p = subprocess.run(['tcb.cmd', 'db', 'execute', '-e', ENV, '--sql',
                    "select column_name from information_schema.columns "
                    "where table_name='spots' order by ordinal_position;"],
                   capture_output=True, text=True, encoding='utf-8', errors='replace')
cols = []
for line in ansi.sub('', p.stdout).splitlines():
    parts = [c.strip() for c in line.split('│')]
    if len(parts) >= 2 and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', parts[1] or ''):
        cols.append(parts[1])

extra = [k for k in keys if k not in cols]   # 代码写了、库里没有 → 会报 PGRST204
missing = [c for c in cols if c not in keys]  # 库里有、代码没写 → 字段丢失

print(f'toJson 键数: {len(keys)}   云库列数: {len(cols)}\n')
print('❌ 代码写了但云库无此列（写库必失败）:', extra or '无')
print('⚠️ 云库有但 toJson 未覆盖（更新时会丢）:', missing or '无')

# 再实测一次真实写入
import urllib.request
import urllib.error
KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services', 'backend_config.dart'),
                        encoding='utf-8').read()).group(1)
url = f'https://{ENV}.api.tcloudbasegateway.com/v1/rdb/rest/spots?select=id&limit=1'
try:
    urllib.request.urlopen(urllib.request.Request(
        url, headers={'Authorization': 'Bearer ' + KEY}), timeout=20)
    print('\n✓ 云库连通')
except urllib.error.HTTPError as e:
    print('\n✗ 云库探测失败', e.read().decode()[:150])

sys_ok = not extra
print('\n结论:', 'toJson 与云库列名对齐' if sys_ok else '仍有不匹配键，需修')