# -*- coding: utf-8 -*-
"""把本地 mock 里的图片说明（imageCaptions）按新云库 URL 写回云库。

背景：真实实拍图已上传云存储（u_platform/<spotId>/NN.jpg），
      但图片说明（'航拍浮屋全景' / '浮屋设施' / '商家联系页' 等）只存在于
      本地 mock 的 imageCaptions 里，且键是旧的 assets 路径。
      云库 imageCaptions 为空 → 详情页图片右上角没有说明 chip。

做法：读本地 mock 的 imageCaptions（键 = assets 路径，值 = 说明文字），
      按【上传顺序】把说明文字映射到对应的云库 URL，写回云库。

      映射依据：upload_real_spot_photos.py 的 SPOT_PHOTOS 定义了
      「本地文件名 → 云库序号」的顺序，两边一致。

用法：
    python tool/sync_image_captions.py --dry-run
    python tool/sync_image_captions.py
"""
import argparse
import io
import json
import os
import re
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
GW = f'https://{ENV}.api.tcloudbasegateway.com'
REST = f'{GW}/v1/rdb/rest'
SRC = os.path.join(ROOT, 'lib', 'services', 'spot_service.dart')

# 与 upload_real_spot_photos.py 保持一致：本地文件名顺序 = 云库序号顺序
SPOT_PHOTOS = {
    's251': ['spot_251_03.jpg', 'spot_251_04.jpg', 'spot_251_05.jpg',
             'spot_251_06.jpg', 'spot_251_07.jpg', 'spot_251_08.jpg',
             'spot_251_09.jpg', 'spot_251_01.png', 'spot_251_02.png',
             'spot_251_10.png'],
    's253': ['spot_253_1.png', 'spot_253_2.jpg', 'spot_253_3.jpg'],
    's254': ['spot_254_1.jpg', 'spot_254_2.jpg', 'spot_254_3.jpg',
             'spot_254_4.jpg', 'spot_254_5.jpg', 'spot_254_6.jpg',
             'spot_254_7.jpg', 'spot_254_album.png', 'spot_254_detail.png'],
    's261': ['spot_261_01.jpg', 'spot_261_02.png', 'spot_261_03.png'],
    's262': ['spot_262_01.jpg', 'spot_262_02.jpg', 'spot_262_03.jpg',
             'spot_262_04.jpg', 'spot_262_05.jpg', 'spot_262_06.jpg',
             'spot_262_07.jpg', 'spot_262_08.jpg', 'spot_262_09.png',
             'spot_262_10.png'],
}

KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services', 'backend_config.dart'),
                        encoding='utf-8').read()).group(1)

GREEN, RED, YEL, OFF = '\033[92m', '\033[91m', '\033[93m', '\033[0m'


def req(method, url, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            b = resp.read()
            return resp.status, (json.loads(b) if b.strip() else None)
    except urllib.error.HTTPError as e:
        b = e.read()
        try:
            return e.code, json.loads(b)
        except Exception:
            return e.code, b[:300]


def parse_local_captions():
    """从 spot_service.dart 解析每个 spot 的 imageCaptions（键=assets路径 值=说明）"""
    text = io.open(SRC, encoding='utf-8').read()
    result = {}
    # 以 id: 'sXXX' 为锚点切块：
    # re.split 带捕获组 → [前段, 'id: \'s001\'', 块1, 'id: \'s002\'', 块2, ...]
    parts = re.split(r"(id:\s*'(s\d+)')", text)
    # parts[0]=文件头, parts[1]=完整锚点, parts[2]=id, parts[3]=块1, parts[4]=锚点, ...
    # 块 i 位于 parts[3*i]，其 id 为 parts[3*i-1]
    for i in range(3, len(parts), 3):
        sid = parts[i - 1]
        block = parts[i]
        m = re.search(r'imageCaptions:\s*\{(.*?)\n\s*\}', block, re.S)
        if not m:
            continue
        caps = {}
        for km in re.finditer(r"'assets/images/spots/([^']+)'\s*:\s*'([^']*)'", m.group(1)):
            caps[km.group(1)] = km.group(2)
        if caps:
            result[sid] = caps
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    print('=' * 62)
    print(' 图片说明同步到云库')
    print('=' * 62)

    local = parse_local_captions()
    print(f'\n本地解析到 {len(local)} 个钓点的 imageCaptions')
    for sid, caps in local.items():
        print(f'  {sid}: {len(caps)} 条')

    all_ok = True
    for sid, files in SPOT_PHOTOS.items():
        caps = local.get(sid, {})
        if not caps:
            print(f'\n{YEL}!{OFF} {sid} 本地没有说明文字，跳过')
            continue

        # 读云库当前的 images 列表（顺序 = 上传顺序）
        code, row = req('GET', f'{REST}/spots?select=id,name,images&id=eq.{sid}')
        if code != 200 or not row:
            print(f'\n{RED}✗{OFF} {sid} 读云库失败 {code}')
            all_ok = False
            continue
        urls = row[0].get('images') or []
        if len(urls) != len(files):
            print(f'\n{RED}✗{OFF} {sid} 图数不匹配：云库 {len(urls)} vs 本地 {len(files)}')
            all_ok = False
            continue

        # 按位置映射：本地第 i 个文件 → 云库第 i 个 URL
        new_caps = {}
        for i, fn in enumerate(files):
            cap = caps.get(fn)
            if cap:
                new_caps[urls[i]] = cap

        print(f'\n{sid} {row[0].get("name")}：{len(new_caps)}/{len(urls)} 张配到说明')
        for u, c in list(new_caps.items())[:3]:
            print(f'    {u.split("/")[-1]:<12} → {c}')
        if len(new_caps) > 3:
            print(f'    ... 其余 {len(new_caps) - 3} 条')

        if a.dry_run:
            continue

        code, body = req('PATCH', f'{REST}/spots?id=eq.{sid}', {'imageCaptions': new_caps})
        if code in (200, 204):
            print(f'  {GREEN}✓{OFF} 已写回云库')
        else:
            print(f'  {RED}✗{OFF} 写回失败 {code} {str(body)[:160]}')
            all_ok = False

    if a.dry_run:
        print('\n（dry-run，未改动云库）')
    else:
        # 读回验证
        print('\n[验证] 读回检查')
        for sid in SPOT_PHOTOS:
            code, row = req('GET', f'{REST}/spots?select=id,imageCaptions&id=eq.{sid}')
            n = len((row[0].get('imageCaptions') or {})) if (code == 200 and row) else 0
            print(f'  {sid}: {n} 条说明 {"✓" if n else "✗"}')

    print('\n' + '=' * 62)
    print(' 结果：' + ('成功' if all_ok else '有失败项'))
    print('=' * 62)
    return 0 if all_ok else 1


if __name__ == '__main__':
    raise SystemExit(main())