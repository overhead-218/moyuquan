#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
把真实钓具商品数据导入腾讯云 equips 表（装备图鉴）。

数据来源：gear_web/assets/gear.json（1548 条真实商品，含品牌/型号/价格/规格/图片）

用法：
    python tool/import_gear.py                    # 只做本地校验，打印统计
    python tool/import_gear.py --upload           # 实际写入云库
    python tool/import_gear.py --upload --limit50 # 只传前 50 条试水

环境要求：无第三方依赖（仅标准库 urllib）
"""
import argparse
import json
import io
import os
import re
import sys
import time

import urllib.request
import urllib.error

# ── 云库连接配置（与 lib/services/backend_config.dart 保持一致）────────────────
ENV_ID = 'moyuquan-d5g0pvpcw55f8a62e'
REST_BASE = f'https://{ENV_ID}.api.tcloudbasegateway.com/v1/rdb/rest'
PUBLISHABLE_KEY = None  # 由下方从 backend_config.dart 读取

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEAR_JSON_CANDIDATES = [
    os.path.join(PROJECT_ROOT, 'assets', 'gear.json'),
    r'C:\Users\一碗木瓜水\WorkBuddy\哪都通1号\gear_web\assets\gear.json',
]


def read_key():
    """从 Flutter 工程配置里读 Publishable Key，避免两处维护。"""
    path = os.path.join(PROJECT_ROOT, 'lib', 'services', 'backend_config.dart')
    if not os.path.exists(path):
        raise SystemExit(f'找不到 {path}')
    s = io.open(path, encoding='utf-8').read()
    m = re.search(r"publishableKey\s*=\s*'([^']+)'", s)
    if not m:
        raise SystemExit('未能从 backend_config.dart 解析 publishableKey')
    return m.group(1)


def find_gear_json():
    for p in GEAR_JSON_CANDIDATES:
        if os.path.exists(p):
            return p
    raise SystemExit('找不到 gear.json，候选路径：\n  ' + '\n  '.join(GEAR_JSON_CANDIDATES))


# ── slot / scene → 云库 category 与中文分类映射 ─────────────────────────────
SLOT_TO_CATEGORY = {
    'rod_spin': 'rod_spin',        # 路亚直柄/纺车竿
    'rod_bait': 'rod_bait',        # 台钓竿
    'rod_casting': 'rod_casting',  # 枪柄抛投竿
    'reel': 'reel',
    'reel_left': 'reel',           # 左手轮
    'reel_right': 'reel',          # 右手轮
    'lure': 'lure',
    'leader': 'line',              # 前导线
}

SCENE_TO_CATEGORY = {
    'deepsea': 'rod_spin',     # 深海（多为海钓竿/大物轮）
    'shore': 'rod_spin',
    'shore_lure': 'rod_casting',
    'jigging': 'rod_spin',
    'baitcasting': 'rod_bait',
    'casting': 'rod_casting',
}


def pick_category(item):
    """按 slot 优先、scene 兜底确定分类。"""
    slot = item.get('slot') or ''
    if slot in SLOT_TO_CATEGORY:
        return SLOT_TO_CATEGORY[slot]
    scene = item.get('scene') or ''
    return SCENE_TO_CATEGORY.get(scene, 'reel')


def pick_spec_slot(item):
    """对应 App 装备栏槽位：rod | reel | line | bait"""
    slot = item.get('slot') or ''
    if slot in ('rod_spin', 'rod_bait', 'rod_casting'):
        return 'rod'
    if slot in ('reel', 'reel_left', 'reel_right'):
        return 'reel'
    if slot == 'leader':
        return 'line'
    if slot == 'lure':
        return 'bait'
    return ''


def specs_to_text(specs):
    """specs 是 [['键','值'],...] → JSON 字符串，便于 App 结构化展示。"""
    if not specs:
        return ''
    try:
        return json.dumps({str(k): str(v) for k, v in specs}, ensure_ascii=False)
    except Exception:
        return ''


# waterName 统一为 App 使用的「海水 / 淡水 / 通用」
WATER_TO_APP = {
    '海钓': '海水',
    '海水': '海水',
    '淡水': '淡水',
    '河流': '淡水',
    '湖泊': '淡水',
    '通用': '通用',
}

# rodSlotName（直柄(纺车) / 枪柄(拖钓)…）本身是"柄型+用途"组合，
# 其中柄型抽到 handle，完整描述放 tags，避免把"直柄(纺车)"误当成"节数"。
def pick_handle(item):
    h = (item.get('handle') or '').strip()
    if h:
        return h
    slot_desc = (item.get('rodSlotName') or '')
    for key in ('直柄', '枪柄', '拖钓柄', '水滴柄', '枪柄(水滴)'):
        if key in slot_desc:
            return '拖钓柄' if key == '拖钓柄' else key
    return ''


def pick_water(item):
    return WATER_TO_APP.get((item.get('waterName') or '').strip(), '')


def pick_tags(item):
    tags = []
    for v in (item.get('sceneName'), item.get('waterName'),
              item.get('rarityName'), item.get('rodSlotName')):
        v = (v or '').strip()
        if v and v not in tags:
            tags.append(v)
    st = item.get('stats') or {}
    for k, label in (('power', '强度'), ('sens', '感度'),
                     ('cap', '容饵'), ('rec', '回收'), ('value', '性价比')):
        if isinstance(st.get(k), (int, float)):
            tags.append(f'{label}{int(st[k])}')
    return json.dumps(tags, ensure_ascii=False)


def build_row(item):
    """gear.json 一条 → equips 表一行（列名与 schema_social.sql 对应）。"""
    return {
        'id': item['id'],
        'brand': item.get('brand') or '',
        'name': item.get('name') or '',
        'model': item.get('size') or '',
        'category': pick_category(item),
        'slot': pick_spec_slot(item),
        'waterType': pick_water(item),
        'handle': pick_handle(item),
        # gear.json 未提供节数（独节/两节/一本半），不编造，留空由运营补录
        'sections': '',
        'reelType': item.get('reelTypeName') or '',
        'hand': item.get('handName') or '',
        'specs': specs_to_text(item.get('specs')),
        'tags': pick_tags(item),
        'description': item.get('name') or '',
        'imageUrl': item.get('img') or '',
        'gallery': json.dumps([item['img']] if item.get('img') else [], ensure_ascii=False),
        'price': item.get('price'),
        'brandSeries': item.get('series') or '',
        'score': item.get('score') or 0,
        # 热度用真实销量代理（无浏览量字段），评分用真实星级，回复数真实为 0
        'heat': item.get('stars') or 0,
        'replyCount': 0,
        'createdAt': time.strftime('%Y-%m-%dT%H:%M:%S'),
    }


HEADERS = {
    'Authorization': 'Bearer {key}',
    'Content-Type': 'application/json',
    # 按主键冲突时更新，保证可重复导入（重新灌数据会覆盖旧的）
    'Prefer': 'resolution=merge-duplicates,return=minimal',
}


def upload(rows, key, batch=100, dry=False):
    url = f'{REST_BASE}/equips'
    headers = dict(HEADERS)
    headers['Authorization'] = headers['Authorization'].format(key=key)
    headers['Prefer'] = 'resolution=merge-duplicates,return=minimal'

    if dry:
        print(f'[dry-run] 将会POST {len(rows)} 行到 {url}')
        return

    ok = 0
    fail = 0
    for i in range(0, len(rows), batch):
        chunk = rows[i:i + batch]
        try:
            req = urllib.request.Request(
                url, data=json.dumps(chunk).encode('utf-8'),
                headers=headers, method='POST')
            try:
                with urllib.request.urlopen(req, timeout=45) as resp:
                    if resp.status < 300:
                        ok += len(chunk)
                        print(f'  ✓ 已写入 {ok}/{len(rows)}')
                    else:
                        fail += len(chunk)
                        print(f'  ✗ 批次 {i//batch} 失败 [{resp.status}]')
            except urllib.error.HTTPError as e:
                fail += len(chunk)
                body = e.read().decode('utf-8', 'ignore')[:300]
                print(f'  ✗ 批次 {i//batch} 失败 [{e.code}]: {body}')
        except Exception as e:
            fail += len(chunk)
            print(f'  ✗ 批次 {i//batch} 异常: {e}')
        time.sleep(0.15)

    print(f'\n导入完成：成功 {ok} 条，失败 {fail} 条')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--upload', action='store_true', help='实际写入云库（默认只校验）')
    ap.add_argument('--limit', type=int, default=0, help='只导入前 N 条')
    args = ap.parse_args()

    path = find_gear_json()
    print(f'数据源：{path}')
    gear = json.load(io.open(path, encoding='utf-8'))
    print(f'原始条目：{len(gear)}')

    # 去重（同 id 只留一条）
    seen = set()
    rows = []
    for it in gear:
        iid = it.get('id')
        if not iid or iid in seen:
            continue
        seen.add(iid)
        rows.append(build_row(it))

    if args.limit:
        rows = rows[:args.limit]
    print(f'待导入：{len(rows)} 条')

    # 本地统计
    import collections
    print('\n分类分布：')
    for k, v in collections.Counter(r['category'] for r in rows).most_common():
        print(f'  {k:<14} {v}')
    print('\n槽位分布：')
    for k, v in collections.Counter(r['slot'] for r in rows).most_common():
        print(f'  {k:<14} {v}')
    priced = sum(1 for r in rows if r['price'])
    imaged = sum(1 for r in rows if r['imageUrl'])
    print(f'\n有价格：{priced}/{len(rows)}    有图片：{imaged}/{len(rows)}')

    print('\n样例行：')
    print(json.dumps(rows[0], ensure_ascii=False, indent=2)[:600])

    if not args.upload:
        print('\n（这是校验模式。加 --upload 才会真正写入云库）')
        return

    key = read_key()
    print(f'\n开始上传到 {REST_BASE}/equips ...')
    upload(rows, key)


if __name__ == '__main__':
    main()