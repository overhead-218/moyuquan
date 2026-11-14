# -*- coding: utf-8 -*-
"""生成一张 8x8 纯红测试 PNG（不依赖外部图片），用于验证云存储上传链路。"""
import os
import struct
import zlib

W = H = 8
raw = b''
for _ in range(H):
    raw += b'\x00' + bytes([220, 40, 40] * W)


def chunk(tag, data):
    c = tag + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)


png = b'\x89PNG\r\n\x1a\n'
png += chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0))
png += chunk(b'IDAT', zlib.compress(raw))
png += chunk(b'IEND', b'')

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), '_probe.png')
with open(out, 'wb') as f:
    f.write(png)
print(f'wrote {out} ({len(png)} bytes)')
