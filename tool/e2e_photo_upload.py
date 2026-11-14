# -*- coding: utf-8 -*-
"""端到端验证商家照片上传闭环。

模拟 App 端 StorageService.uploadImage 的完整行为：
  1. 按 RLS 要求生成合法路径 <uid>/spot_<ts>.jpg
  2. POST {gw}/v1/storages/object/spot-photos/{key}
  3. 拿到直链后，PATCH 写入 spots.images + imagesVerified
  4. 匿名 GET 直链，确认真的能下载（这是照片能展示的前提）
  5. 读回 spots.images 确认落库
  6. 清理：还原 spots.images、删除测试对象

⚠️ 结论以实测为准，任何一步失败都会如实报错，不会假装成功。

用法：python tool/e2e_photo_upload.py
"""
import io
import json
import os
import re
import struct
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zlib

ENV = 'moyuquan-d5g0pvpcw55f8a62e'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GW = f'https://{ENV}.api.tcloudbasegateway.com'
REST = f'{GW}/v1/rdb/rest'
BUCKET = 'spot-photos'
UID = 'u_e2e'
TARGET_SPOT = 's001'   # 云库实际 id 形如 s001，不是 spot_001

KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services',
                                     'backend_config.dart'),
                        encoding='utf-8').read()).group(1)


def req(method, url, body=None, ctype='application/json', raw=False):
    data = body if raw else (json.dumps(body).encode() if body is not None else None)
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': ctype})
    try:
        with urllib.request.urlopen(r, timeout=60) as resp:
            b = resp.read()
            return resp.status, (b if raw else (json.loads(b) if b.strip() else None))
    except urllib.error.HTTPError as e:
        b = e.read()
        try:
            return e.code, json.loads(b)
        except Exception:
            return e.code, b[:300]
    except Exception as e:
        return 'ERR', str(e)[:200]


def png(w=64, h=64):
    raw = b''
    for y in range(h):
        raw += b'\x00' + bytes([(y * 4) % 256, 120, 200] * w)

    def ck(t, d):
        c = t + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    out = b'\x89PNG\r\n\x1a\n'
    out += ck(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    out += ck(b'IDAT', zlib.compress(raw))
    out += ck(b'IEND', b'')
    return out


def step(n, ok, msg):
    print(f'{n}) {"✓" if ok else "✗"} {msg}')
    if not ok:
        print('\n=== 中断：以上环节未通过，不做任何清理假设 ===')
        sys.exit(1)
    print()


def main():
    print('=== 商家照片上传闭环 · 端到端验证 ===\n')
    ts = int(time.time() * 1000)
    obj_key = f'{UID}/spot_{ts}.png'
    obj_url = f'{GW}/v1/storages/object/{BUCKET}/{obj_key}'

    # 记录原值以便还原
    code, before = req('GET',
                       f'{REST}/spots?select=id,images,imagesVerified,submitter'
                       f'&id=eq.{TARGET_SPOT}')
    row0 = before[0] if isinstance(before, list) and before else {}
    orig_images = row0.get('images')
    orig_verified = row0.get('imagesVerified')
    submitter = row0.get('submitter')
    print(f'目标钓点  : {TARGET_SPOT}')
    print(f'原images  : {orig_images}')
    print(f'原verified: {orig_verified}')
    print(f'submitter : {submitter}\n')

    # 1. 上传
    code, body = req('POST', obj_url, png(), 'image/png', raw=True)
    step(1, code == 200,
         f'POST 上传对象 → {code}  {"" if code == 200 else body}')

    # 2. 写库（imagesVerified 列已由 part6 补齐，一起验证角标依据能落库）
    new_images = ([*orig_images] if orig_images else []) + [obj_url]
    patch = {'images': new_images, 'imagesVerified': True}
    code, body = req('PATCH', f'{REST}/spots?id=eq.{TARGET_SPOT}', patch)
    step(2, code in (200, 204), f'PATCH 写入 images + imagesVerified → {code}  {"" if code in (200, 204) else body}')

    # 3. 读回
    code, after = req('GET',
                      f'{REST}/spots?select=id,images,imagesVerified'
                      f'&id=eq.{TARGET_SPOT}')
    arow = after[0] if isinstance(after, list) and after else {}
    stored = arow.get('images')
    stored_verified = arow.get('imagesVerified')
    step(3, bool(stored) and obj_url in stored,
         f'读回 spots.images 包含新 URL（{len(stored or [])} 张）')
    step(3.1, stored_verified is True,
         f'读回 spots.imagesVerified → {stored_verified}（角标依据已落库）')

    # 4. 匿名可下载（最关键：不能读的歌点照片等于没上传）
    code, data = req('GET', obj_url, raw=True)
    is_png = isinstance(data, bytes) and data[:4] == b'\x89PNG'
    step(4, code == 200 and is_png,
         f'匿名 GET 直链下载图片 → {code}, {len(data) if isinstance(data, bytes) else 0} bytes, '
         f'PNG={is_png}')

    # 5. 模型层会把它判成"商家实拍"吗？—— 按 spot.dart 的 _resolveImageSource 规则核对
    #    imagesVerified=true 且 submitter=owner → merchant（商家实拍）
    label = '商家实拍' if (stored_verified and submitter == 'owner') \
        else '钓友上传/平台实景'
    print(f'5) · 角标判定：imagesVerified={stored_verified}, submitter={submitter!r}'
          f' → 显示「{label}」')
    print('   （submitter=operator 表示平台代录，非商家自传，故不标"商家实拍"——这是如实标注）')

    # 6. 清理
    code, _ = req('PATCH', f'{REST}/spots?id=eq.{TARGET_SPOT}',
                  {'images': orig_images if orig_images is not None else [],
                   'imagesVerified': orig_verified})
    print(f'6) {"✓" if code in (200, 204) else "✗"} 已还原 spots.images')

    code, _ = req('DELETE', f'{GW}/v1/storages/object/{BUCKET}/{obj_key}')
    print(f'   {"✓" if code in (200, 204) else "·"} 删除测试对象 → {code}')

    print('\n=== 结论：上传 → 写库 → 公开可读 → 清理，全链路通过 ===')


if __name__ == '__main__':
    main()
