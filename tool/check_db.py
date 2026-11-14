# -*- coding: utf-8 -*-
"""建表验证脚本：在腾讯云控制台执行完SQL 后，运行这个确认。

用法：
    python tool/check_db.py

正常输出应该是「16/16 全部就绪」。
"""
import io
import json
import os
import re
import urllib.error
import urllib.request

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_ID = 'moyuquan-d5g0pvpcw55f8a62e'
REST_BASE = f'https://{ENV_ID}.api.tcloudbasegateway.com/v1/rdb/rest'

# 表名 -> 该表被哪个功能依赖
TABLES = {
    'post_comments':  '帖子留言（你现在问的）',
    'post_likes':     '帖子点赞',
    'spot_comments':  '钓点留言',
    'spot_likes':     '钓点点赞',
    'follows':        '关注 / 粉丝',
    'favorites':      '收藏',
    'conversations':  '私信会话列表',
    'chat_messages':  '私信消息体',
    'catches':        '渔获榜',
    'catch_likes':    '渔获点赞',
    'blocks':         '拉黑',
    'reports':        '举报',
    'equips':         '装备图鉴（1548 件真实商品）',
    'equip_reviews':  '装备评价',
    'user_locations': '地图钓友图层',
    'app_config':     '版本检查',
}


def get_key():
    p = os.path.join(PROJECT_ROOT, 'lib', 'services', 'backend_config.dart')
    s = io.open(p, encoding='utf-8').read()
    m = re.search(r"publishableKey\s*=\s*'([^']+)'", s)
    if not m:
        raise SystemExit('未能从 backend_config.dart 解析 publishableKey')
    return m.group(1)


def probe(table, key):
    url = f'{REST_BASE}/{table}?select=*&limit=1'
    req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + key})
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            body = r.read().decode('utf-8', 'ignore')
            rows = json.loads(body) if body.strip() else []
            return True, f'就绪（现有 {len(rows)}+ 行）'
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False, '不存在 ← 需要建表'
        body = e.read().decode('utf-8', 'ignore')[:120]
        return False, f'HTTP {e.code}: {body}'
    except Exception as e:
        return False, str(e)[:80]


def main():
    key = get_key()
    print(f'环境: {ENV_ID}')
    print(f'接口: {REST_BASE}\n')
    print('=' * 62)

    ready, missing = [], []
    for t, desc in TABLES.items():
        ok, msg = probe(t, key)
        mark = '✓' if ok else '✗'
        print(f'{mark} {t:<16} {desc}')
        print(f'    {msg}')
        (ready if ok else missing).append(t)

    print('=' * 62)
    print(f'就绪 {len(ready)} / {len(TABLES)}')

    if missing:
        print('\n还缺这些表，请在腾讯云控制台执行：')
        print(f'  {os.path.join(PROJECT_ROOT, "sql", "00_先执行这个.sql")}')
        print('\n然后重新运行本脚本验证。')
    else:
        print('\n全部就绪！接下来可以双击 build_web.bat 完成构建 + 部署。')
        print('装备数据导入：python tool/import_gear.py --upload')


if __name__ == '__main__':
    main()