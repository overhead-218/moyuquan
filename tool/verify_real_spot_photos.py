# -*- coding: utf-8 -*-
"""验证真实钓点照片在 App 端的完整呈现链路。

模拟 App 的 Spot.fromJson 逻辑，检查：
  1. 云库 spots.images 有 http URL（displayImages 的过滤条件）
  2. imagesVerified=true → imageSource 判定正确
  3. photoBadge 文案正确
  4. 首图匿名可下载且是合法 JPEG
  5. imageCaptions 的键能命中图 URL（说明 chip 能显示）
  6. 其余钓点不再有 picsum 假图（本地 mock 已清空）

用法：python tool/verify_real_spot_photos.py
"""
import io
import json
import os
import re
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
GW = f'https://{ENV}.api.tcloudbasegateway.com'
REST = f'{GW}/v1/rdb/rest'

KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services', 'backend_config.dart'),
                        encoding='utf-8').read()).group(1)

TARGETS = ['s251', 's253', 's254', 's261', 's262']

GREEN, RED, YEL, OFF = '\033[92m', '\033[91m', '\033[93m', '\033[0m'
_p = 0
_f = 0


def check(name, cond, extra=''):
    global _p, _f
    if cond:
        _p += 1
        print(f'  {GREEN}✓{OFF} {name}')
    else:
        _f += 1
        print(f'  {RED}✗{OFF} {name}  {extra}')


def get(url):
    r = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + KEY})
    with urllib.request.urlopen(r, timeout=60) as resp:
        return json.loads(resp.read().decode())


def get_bytes(url):
    r = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + KEY})
    with urllib.request.urlopen(r, timeout=60) as resp:
        return resp.status, resp.read()


def resolve_source(submitter, verified):
    """复刻 spot.dart 的 _resolveImageSource"""
    if not verified:
        return 'merchant' if submitter == 'owner' else 'platform'
    if submitter == 'owner':
        return 'merchant'
    if submitter == 'operator':
        return 'platformShot'
    return 'community'


def badge(source):
    return {
        'merchant': '商家实拍',
        'community': '钓友上传',
        'platformShot': '平台实拍',
        'platform': '平台实景 · 非本钓点专属',
    }.get(source)


def main():
    print('=' * 62)
    print(' 真实钓点照片 · App 端呈现链路验证')
    print('=' * 62)

    rows = get(f'{REST}/spots?select=id,name,images,imagesVerified,submitter,'
               f'imageCaptions&limit=1000')
    by_id = {r['id']: r for r in rows}

    for sid in TARGETS:
        print(f'\n{sid}')
        r = by_id.get(sid)
        if not r:
            check('存在于云库', False)
            continue
        images = r.get('images') or []
        verified = bool(r.get('imagesVerified'))
        submitter = r.get('submitter') or 'operator'

        # 1. displayImages 过滤条件
        http_imgs = [u for u in images if u.startswith('http')]
        check(f'images 全为 http URL（displayImages 不会过滤掉）',
              len(http_imgs) == len(images) and len(images) > 0,
              f'{len(http_imgs)}/{len(images)}')

        # 2/3. 来源判定与角标
        src = resolve_source(submitter, verified)
        check(f'imagesVerified=true → {src}', verified and src == 'platformShot',
              f'verified={verified} submitter={submitter}')
        check(f'角标文案 = 「{badge(src)}」', badge(src) == '平台实拍', badge(src))

        # 4. 首图匿名下载
        try:
            code, data = get_bytes(http_imgs[0])
            is_jpeg = data[:2] == b'\xff\xd8'
            check(f'首图匿名下载 {code} / JPEG={is_jpeg}',
                  code == 200 and is_jpeg, f'{len(data)} bytes')
        except Exception as e:
            check('首图匿名下载', False, str(e)[:80])

        # 5. imageCaptions 能否命中
        caps = r.get('imageCaptions') or {}
        hit = 0
        for k in caps:
            base = k.split('/')[-1]
            if any(base in u for u in http_imgs):
                hit += 1
        check(f'imageCaptions 键命中图 URL（{hit}/{len(caps)}）',
              hit == len(caps) and hit > 0, f'{hit}/{len(caps)}')

        print(f'    {r.get("name")}：{len(images)} 张，{len(caps)} 条说明')

    # 6. 本地 mock 已无 picsum 引用
    print('\n本地 mock 检查')
    src_text = io.open(os.path.join(ROOT, 'lib', 'services', 'spot_service.dart'),
                       encoding='utf-8').read()
    picsum = len(re.findall(r'picsum\.photos', src_text))
    check(f'spot_service.dart 里 picsum 引用 = 0（实际 {picsum}）', picsum == 0)

    # 7. 云库里所有图 URL 域名统计（确认没有随机图库残留）
    hosts = {}
    for r in rows:
        for u in (r.get('images') or []):
            h = re.sub(r'^https?://([^/]+).*', r'\1', u)
            hosts[h] = hosts.get(h, 0) + 1
    print('\n云库图片来源分布：')
    for h, n in sorted(hosts.items(), key=lambda kv: -kv[1]):
        tag = ''
        if 'wikimedia' in h:
            tag = '（公共图库，角标会标「平台实景 · 非本钓点专属」）'
        elif 'tcloudbasegateway' in h:
            tag = '（平台真实实拍，角标标「平台实拍」）'
        print(f'  {n:4d}  {h}{tag}')
    check('没有 picsum 残留', not any('picsum' in h for h in hosts))

    print('\n' + '=' * 62)
    print(f' {_p} passed, {_f} failed')
    print('=' * 62)
    return 1 if _f else 0


if __name__ == '__main__':
    raise SystemExit(main())