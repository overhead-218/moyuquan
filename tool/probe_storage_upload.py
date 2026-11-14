# -*- coding: utf-8 -*-
"""探针：用 Publishable Key（App 端唯一可用的凭证）测试能否直接上传对象。

这是决定「商家照片上传闭环能不能在 App 里打通」的关键实验：
  · PostgREST 只服务数据库，网关上没有 /v1/storage 之类的裸上传端点（实测全 404）
  · PG 模式的存储上传要走 Storage API → COS，客户端需要先拿签名
所以这里逐个试候选路径，确认到底有没有 App 端可用的上传通道。

用法：python tool/probe_storage_upload.py
"""
import io
import json
import os
import re
import struct
import urllib.error
import urllib.parse
import urllib.request
import zlib

ENV = 'moyuquan-d5g0pvpcw55f8a62e'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUCKET = 'spot-photos'
KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(os.path.join(ROOT, 'lib', 'services',
                                     'backend_config.dart'),
                        encoding='utf-8').read()).group(1)

GW = f'https://{ENV}.api.tcloudbasegateway.com'
UID = 'probe_uid1'


def png_bytes(w=8, h=8):
    raw = b''
    for _ in range(h):
        raw += b'\x00' + bytes([30, 160, 120] * w)

    def chunk(tag, data):
        c = tag + data
        return (struct.pack('>I', len(data)) + c
                + struct.pack('>I', zlib.crc32(c) & 0xffffffff))

    out = b'\x89PNG\r\n\x1a\n'
    out += chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    out += chunk(b'IDAT', zlib.compress(raw))
    out += chunk(b'IEND', b'')
    return out


def probe(url, method='GET', body=None, ctype='application/json', raw=False):
    data = body if raw else (json.dumps(body).encode() if body is not None else None)
    r = urllib.request.Request(url, data=data, method=method, headers={
        'Authorization': 'Bearer ' + KEY, 'Content-Type': ctype})
    try:
        with urllib.request.urlopen(r, timeout=25) as resp:
            return resp.status, resp.read()[:300]
    except urllib.error.HTTPError as e:
        try:
            b = e.read()[:300]
        except Exception:
            b = b''
        return e.code, b
    except Exception as e:
        return 'ERR', str(e)[:150]


def main():
    print(f'env  : {ENV}')
    print(f'bucket: {BUCKET}')
    print(f'uid  : {UID}\n')

    key = f'{UID}/probe_{int(0)}.png'
    payload = png_bytes()

    # ── 候选上传端点 ────────────────────────────────────────
    candidates = [
        (f'{GW}/v1/storage/object/{BUCKET}/{key}', 'POST'),
        (f'{GW}/v1/storages/object/{BUCKET}/{key}', 'PUT'),
        (f'{GW}/v1/storages/object/{BUCKET}/{key}', 'POST'),
        (f'{GW}/v1/storages/upload/{BUCKET}/{key}', 'POST'),
        (f'{GW}/v1/storages/object/upload/{BUCKET}/{key}', 'POST'),
        (f'{GW}/v1/storage/v1/object/{BUCKET}/{key}', 'PUT'),
        (f'{GW}/v1/rdb/rest/storage/objects', 'POST'),
    ]
    print('=== 候选上传端点 ===')
    for url, method in candidates:
        code, body = probe(url, method, payload, 'image/png', raw=True)
        mark = '✓' if code == 200 else ' '
        print(f'{mark} {code:<5} {method:<5} {url.replace(GW, "")[:78]}')
        if code not in (404, 401, 403):
            print(f'        {body[:180]}')

    # ── 已确认可用：签名下载 ────────────────────────────────
    print('\n=== 已确认可用（CLI 走的服务端签名）===')
    sign_url = (f'{GW}/v1/storages/object/sign/{BUCKET}/{key}'
                '?token=<需服务端签发>')
    code, body = probe(sign_url)
    print(f'  {code} 无 token 时的响应（预期非 200，说明签名确实被校验）')
    print(f'  {body[:150]}')


if __name__ == '__main__':
    main()
