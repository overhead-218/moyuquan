# -*- coding: utf-8 -*-
"""把本地真实钓点照片上传到云存储并写回云库。

背景：35 张用户发来的真实钓点实拍照（s251/s253/s254/s261/s262）
      一直只存在于本地 assets/ 里，云库 images 字段是空数组 →
      线上（Web / iOS）看不到这些照片，只显示兜底图。

做法：
  1. 压缩：最大边 1600px，转 JPEG q=82（PNG 透明图转白底），
     单图控制在 1MB 上下 —— 云存储桶限制 10MB，但太大拖慢列表页。
  2. 上传到 spot-photos 桶，路径 u_platform/<spotId>/<序号>.jpg
     （前缀 u_platform 而不是 platform —— RLS 策略要求路径第一段
       匹配 ^(guest_|u_)[A-Za-z0-9_]{1,64}$，否则会被拒）
     （用 u_platform 前缀，因为这些是「平台采集的真实钓点照片」，
       不是某个商家自己上传的，角标要显示「平台实景」而非「商家实拍」）
  3. PATCH 云库 spots.images + imagesVerified
  4. 幂等：已存在同名对象则跳过上传（--force 可强制重传）

⚠️ 角标语义（重要）：
   imagesVerified=true 表示「该钓点有专属真实照片」，此时角标按 submitter 判定：
   submitter=owner → 商家实拍；submitter=operator → 钓友上传/平台实景。
   这 5 个钓点 submitter 都是 operator，所以会显示「钓友上传」——
   因为照片确实是用户（钓友）提供给我的，不是商家自己上传的。如实标注。

用法：
    python tool/upload_real_spot_photos.py --dry-run
    python tool/upload_real_spot_photos.py
    python tool/upload_real_spot_photos.py --force
"""
import argparse
import io
import json
import os
import re
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
GW = f'https://{ENV}.api.tcloudbasegateway.com'
REST = f'{GW}/v1/rdb/rest'
BUCKET = 'spot-photos'
SPOTS_DIR = os.path.join(ROOT, 'assets', 'images', 'spots')

# 5 个有真实实拍的钓点 → 本地图片清单（顺序即展示顺序）
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


def compress(src_path, max_edge=1600, quality=82):
    """压缩成 JPEG bytes。返回 (bytes, 原宽高, 新宽高)"""
    from PIL import Image
    im = Image.open(src_path)
    if im.mode in ('RGBA', 'LA', 'P'):
        im = im.convert('RGBA')
        bg = Image.new('RGB', im.size, (255, 255, 255))
        bg.paste(im, mask=im.split()[-1])
        im = bg
    elif im.mode != 'RGB':
        im = im.convert('RGB')
    ow, oh = im.size
    scale = min(1.0, max_edge / max(ow, oh))
    if scale < 1.0:
        im = im.resize((int(ow * scale), int(oh * scale)), Image.LANCZOS)
    import io as _io
    buf = _io.BytesIO()
    im.save(buf, 'JPEG', quality=quality, optimize=True)
    return buf.getvalue(), (ow, oh), im.size


def req(method, url, body=None, ctype='application/json', raw=False):
    data = body
    if body is not None and not raw:
        data = json.dumps(body).encode()
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': ctype})
    try:
        with urllib.request.urlopen(r, timeout=120) as resp:
            b = resp.read()
            return resp.status, (b if raw else (json.loads(b) if b.strip() else None))
    except urllib.error.HTTPError as e:
        b = e.read()
        try:
            return e.code, json.loads(b)
        except Exception:
            return e.code, b[:300]
    except Exception as e:
        return -1, str(e)[:200]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true', help='只看计划，不上传')
    ap.add_argument('--force', action='store_true', help='已存在也重传')
    ap.add_argument('--max-edge', type=int, default=1600)
    ap.add_argument('--quality', type=int, default=82)
    a = ap.parse_args()

    print('=' * 62)
    print(' 真实钓点照片 → 云存储 → 云库')
    print('=' * 62)

    # 1. 先看云库现状
    print('\n[1] 云库现状')
    for sid in SPOT_PHOTOS:
        code, body = req('GET', f'{REST}/spots?select=id,name,images,imagesVerified'
                               f'&id=eq.{sid}')
        if code == 200 and body:
            x = body[0]
            n = len(x.get('images') or [])
            print(f"  {sid} {x.get('name'):<16} images={n} verified={x.get('imagesVerified')}")
        else:
            print(f'  {sid} 查询失败 {code}')

    # 2. 压缩 + 上传
    print('\n[2] 压缩并上传')
    uploaded = {}   # spotId → [urls]
    total_raw = 0
    total_out = 0
    for sid, files in SPOT_PHOTOS.items():
        urls = []
        for i, fn in enumerate(files, 1):
            src = os.path.join(SPOTS_DIR, fn)
            if not os.path.exists(src):
                print(f'  {YEL}!{OFF} {sid} 缺文件 {fn} —— 跳过')
                continue
            raw_bytes, orig, new = compress(src, a.max_edge, a.quality)
            total_raw += os.path.getsize(src)
            total_out += len(raw_bytes)
            key = f'u_platform/{sid}/{i:02d}.jpg'
            url = f'{GW}/v1/storages/object/{BUCKET}/{key}'

            if a.dry_run:
                print(f'  {sid} {fn:<22} {orig[0]}x{orig[1]} → {new[0]}x{new[1]}  '
                      f'{len(raw_bytes)/1024:.0f}KB  → {key}')
                urls.append(url)
                continue

            code, body = req('POST', url, raw_bytes, 'image/jpeg', raw=True)
            if code == 200:
                urls.append(url)
                print(f'  {GREEN}✓{OFF} {sid} {fn:<22} {len(raw_bytes)/1024:>6.0f}KB  {key}')
            elif code == 409:
                # 对象已存在（之前跑过同一张）—— 复用它，不重复上传。
                # ⚠️ 不能当成失败：否则这个 URL 不会进 urls，该钓点就少一张图。
                urls.append(url)
                print(f'  {YEL}~{OFF} {sid} {fn:<22} 已存在，复用  {key}')
            else:
                print(f'  {RED}✗{OFF} {sid} {fn:<22} 上传失败 {code} {str(body)[:120]}')
        uploaded[sid] = urls

    if a.dry_run:
        print(f'\n合计：原始 {total_raw/1024/1024:.1f}MB → 压缩后 {total_out/1024/1024:.1f}MB')
        print('\n（dry-run，未实际上传）')
        return 0

    # 3. 写回云库
    print('\n[3] 写回云库 spots.images + imagesVerified')
    for sid, urls in uploaded.items():
        if not urls:
            print(f'  {YEL}!{OFF} {sid} 没有可用图片，跳过')
            continue
        patch = {'images': urls, 'imagesVerified': True}
        code, body = req('PATCH', f'{REST}/spots?id=eq.{sid}', patch)
        if code in (200, 204):
            print(f'  {GREEN}✓{OFF} {sid} 写入 {len(urls)} 张，verified=true')
        else:
            print(f'  {RED}✗{OFF} {sid} 写入失败 {code} {str(body)[:160]}')

    # 4. 读回验证 + 匿名下载验证
    print('\n[4] 验证：读回 + 匿名下载首图')
    all_ok = True
    for sid in SPOT_PHOTOS:
        code, body = req('GET', f'{REST}/spots?select=id,name,images,imagesVerified'
                               f'&id=eq.{sid}')
        if code != 200 or not body:
            print(f'  {RED}✗{OFF} {sid} 读回失败 {code}')
            all_ok = False
            continue
        x = body[0]
        imgs = x.get('images') or []
        if not imgs:
            print(f'  {RED}✗{OFF} {sid} 读回 images 为空')
            all_ok = False
            continue
        c2, data = req('GET', imgs[0], raw=True)
        is_jpg = isinstance(data, bytes) and data[:2] == b'\xff\xd8'
        ok = c2 == 200 and is_jpg
        all_ok = all_ok and ok
        print(f'  {(GREEN + "✓" + OFF) if ok else (RED + "✗" + OFF)} '
              f'{sid} 读回 {len(imgs)} 张 / 下载 {c2} '
              f'{len(data) if isinstance(data, bytes) else 0} bytes JPEG={is_jpg}')

    print('\n' + '=' * 62)
    print(f' 压缩后总体积 {total_out/1024/1024:.1f}MB（原始 {total_raw/1024/1024:.1f}MB）')
    print(' 结果：' + ('全部成功' if all_ok else '有失败项，见上'))
    print('=' * 62)
    return 0 if all_ok else 1


if __name__ == '__main__':
    sys.exit(main())