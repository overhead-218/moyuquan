# -*- coding: utf-8 -*-
"""注册用户链路体检：profiles / conversations / chat_messages 实测。

用法：
    python tool/check_users.py
"""
import io, json, os, re, urllib.parse, urllib.request
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
BASE = f'https://{ENV}.api.tcloudbasegateway.com/v1/rdb/rest'
KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT,'lib','services','backend_config.dart'),
                         encoding='utf-8').read()).group(1)

def req(m, url, body=None):
    d = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=d, method=m, headers={
        'Authorization':'Bearer '+KEY, 'Content-Type':'application/json'})
    with urllib.request.urlopen(r, timeout=40) as resp:
        raw = resp.read().decode('utf-8')
        return json.loads(raw) if raw.strip() else None

def fetch(table):
    out, off = [], 0
    while True:
        q = urllib.parse.urlencode({'select':'*','limit':500,'offset':off,'order':'id.asc'})
        b = req('GET', f'{BASE}/{table}?{q}') or []
        out += b
        if len(b) < 500: break
        off += 500
    return out

def filled(v):
    if v is None: return False
    if isinstance(v,str) and not v.strip(): return False
    if isinstance(v,(list,dict)) and len(v)==0: return False
    return True

for t in ('profiles','conversations','chat_messages'):
    try:
        rows = fetch(t)
        print(f'=== {t} === {len(rows)} 行')
        if rows and rows[0]:
            print('  列:', ', '.join(sorted(rows[0].keys())))
        for r in rows[:8]:
            print('  ', {k: (str(v)[:28] if v is not None else None)
                          for k,v in r.items()})
        print()
    except Exception as e:
        print(f'=== {t} === 查询失败: {str(e)[:160]}\n')
