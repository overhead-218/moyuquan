# -*- coding: utf-8 -*-
"""钓点字段填充率体检：查清「钓点详情页很多空」到底是云库缺数据还是前端映射漏了。

用法：
    python tool/check_spots.py
"""
import io
import json
import os
import re
import urllib.parse
import urllib.request

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def get_key():
    p = os.path.join(PROJECT_ROOT, 'lib', 'services', 'backend_config.dart')
    s = io.open(p, encoding='utf-8').read()
    return re.search(r"publishableKey\s*=\s*'([^']+)'", s).group(1)


KEY = get_key()
ENV_ID = 'moyuquan-d5g0pvpcw55f8a62e'
REST_BASE = f'https://{ENV_ID}.api.tcloudbasegateway.com/v1/rdb/rest'

# 详情页真正会展示 / 会读到的字段
FIELDS = [
    'city', 'district', 'address', 'latitude', 'longitude',
    'images', 'fishSpecies', 'fishPeakSeason',
    'lastStockingDate', 'stockingCycleDays',
    'price', 'priceNote', 'priceTiers',
    'businessHours', 'contactPhone', 'wechat', 'ownerName',
    'rating', 'reviewCount', 'viewCount', 'favoriteCount', 'postCount',
    'description', 'updatedAt', 'submitter', 'status',
    'claimedBy', 'claimedAt',
    'hasAccommodation', 'roomType', 'roomCapacity', 'hasWifi',
    'accommodationNote', 'accommodationImages', 'commonAreaImages',
    'facilities', 'imageCaptions', 'imagesVerified',
]


def fetch_all(table):
    rows, offset, page = [], 0, 500
    while True:
        q = urllib.parse.urlencode({
            'select': '*', 'limit': page, 'offset': offset, 'order': 'id.asc',
        })
        req = urllib.request.Request(f'{REST_BASE}/{table}?{q}',
                                     headers={'Authorization': 'Bearer ' + KEY})
        with urllib.request.urlopen(req, timeout=60) as r:
            batch = json.loads(r.read().decode('utf-8'))
        rows.extend(batch)
        if len(batch) < page:
            break
        offset += page
    return rows


def filled(v):
    """判断字段是否'有内容'（区分 null / 空串 / 空列表 / 0）。"""
    if v is None:
        return False
    if isinstance(v, str) and not v.strip():
        return False
    if isinstance(v, (list, dict)) and len(v) == 0:
        return False
    return True


def main():
    rows = fetch_all('spots')
    n = len(rows)
    print(f'spots 共 {n} 行\n')
    print(f'{"字段":<22}{"有值":>7}{"占比":>9}   缺失示例')
    print('-' * 72)
    empty_all = []
    for f in FIELDS:
        c = sum(1 for r in rows if filled(r.get(f)))
        pct = c / n * 100 if n else 0
        miss = [str(r.get('id')) for r in rows if not filled(r.get(f))][:3]
        flag = '' if pct >= 60 else ('  ← 全空' if c == 0 else '  ← 稀疏')
        print(f'{f:<22}{c:>7}{pct:>8.1f}%   {",".join(miss)}{flag}')
        if c == 0:
            empty_all.append(f)

    # 字段名在库里根本不存在的情况
    present = set()
    for r in rows:
        present |= set(r.keys())
    missing_col = [f for f in FIELDS if f not in present]
    print('\n' + '=' * 72)
    if missing_col:
        print('❌ 云库 spots 表缺少这些列（前端永远读到 null）：')
        for f in missing_col:
            print('   -', f)
    else:
        print('✅ 前端所有字段在云库都有对应列')
    if empty_all:
        print('\n⚠️  列存在但 597 行全为空（需运营补录）：', ', '.join(empty_all))
    print('\n库里实际列：', ', '.join(sorted(present)))


if __name__ == '__main__':
    main()
