# -*- coding: utf-8 -*-
"""验证 part6 的 4 列已到位且可读。"""
import re, json, urllib.request

SRC = open("lib/services/backend_config.dart", encoding="utf-8").read()
KEY = re.search(r"publishableKey\s*=\s*r?['\"]([^'\"]+)", SRC).group(1)
GW = re.search(r"gatewayBase\s*=\s*r?['\"]([^'\"]+)", SRC).group(1).rstrip("/")
base = f"{GW}/v1/rdb/rest"

def g(path):
    req = urllib.request.Request(base + path, headers={"Authorization": f"Bearer {KEY}"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:200]
    except Exception as e:
        return -1, str(e)[:200]

cols = ["priceTiers", "status", "imageCaptions", "imagesVerified"]
code, body = g("/spots?select=" + ",".join(cols) + "&limit=2")
print("整行读取", code)
if code == 200:
    for row in body:
        print(json.dumps(row, ensure_ascii=False))
else:
    print(body)
for c in cols:
    c2, b2 = g(f"/spots?select={c}&limit=1")
    print(("✓" if c2 == 200 else "✗"), c.ljust(16), c2, "" if c2 == 200 else str(b2)[:120])

# 回填统计
c3, b3 = g("/spots?select=status&limit=1000")
if c3 == 200:
    print("读回 status 行数:", len(b3), "样例:", b3[0] if b3 else None)