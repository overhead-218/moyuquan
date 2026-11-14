# -*- coding: utf-8 -*-
"""清洗本地 mock 钓点数据里的 picsum 随机图引用。

背景：assets/images/spots/ 下的 spot_XXX.jpg 是 2026-08-15 从 picsum 随机图库
      下载的通用摄影图（实际内容是菠萝、棕熊、云雾山峰等），按 id 取模分配给
      各钓点，与钓点实景毫无关系。截图里「滇池野钓湾」显示菠萝就是这么来的。

      这类图比「暂无实景照片」的占位块更糟 —— 占位是诚实的，随机图是误导。

做法：把 spot_service.dart 里 mock 数据中所有指向 assets/images/spots/ 的
      images 引用清空（保留 s251/s253/s254/s261/s262 这 5 个有真实实拍的，
      它们的图已上传到云存储并写回云库，线上会走云库 URL）。

⚠️ 只改本地 mock 数据，不碰云库（云库已由 upload_real_spot_photos.py 处理）。
⚠️ 幂等：可重复执行。

⚠️ 实现教训（踩过）：不能用「找 [ 配对 ]」的字符扫描来定位列表边界 ——
   单行形态 `images: ['a', 'b'],` 里如果只按深度配对，很容易把下一个字段的
   '[' 或 ']' 当成边界，切错位置导致整文件语法崩掉（实测 28032 个 error）。
   正确做法：按【行】处理。两种形态：
     A. 单行：images: ['a', 'b'],           → 整行替换为 images: [],
     B. 多行：images: [                      → 删掉从这行到 ']' 结束的所有行
"""
import argparse
import io
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'lib', 'services', 'spot_service.dart')

# 这 5 个钓点有真实实拍（已上传云存储），保留它们的本地引用作为离线兜底
KEEP_REAL = {'s251', 's253', 's254', 's261', 's262'}

GREEN, RED, YEL, OFF = '\033[92m', '\033[91m', '\033[93m', '\033[0m'
ASSET_RE = re.compile(r"'assets/images/spots/[^']+'")


def process(text):
    """返回 (新文本, 清理数量, 保留数量)"""
    lines = text.split('\n')
    out = []
    i = 0
    cleared = 0
    kept = 0

    while i < len(lines):
        line = lines[i]

        # 定位本行之前最近的 spot id
        window = '\n'.join(out[-80:])
        ids = re.findall(r"id:\s*'(s\d+)'", window)
        sid = ids[-1] if ids else None

        # 形态 A：单行列表
        m = re.match(r"^(\s*)images:\s*\[(.*)\],\s*$", line)
        if m and ASSET_RE.search(m.group(2)):
            if sid in KEEP_REAL:
                out.append(line)
                kept += len(ASSET_RE.findall(m.group(2)))
            else:
                out.append(f"{m.group(1)}images: [],")
                cleared += 1
            i += 1
            continue

        # 形态 A2：accommodationImages / commonAreaImages 等其他图字段
        # 只清 picsum 随机图；assets 引用是真实照片（s251/s262 的浮屋实拍），保留
        m = re.match(r"^(\s*)(accommodationImages|commonAreaImages):\s*const\s*\[(.*)\],\s*$",
                     line)
        if m and 'picsum.photos' in m.group(3):
            out.append(f"{m.group(1)}{m.group(2)}: const [],")
            cleared += 1
            i += 1
            continue

        m = re.match(r"^(\s*)(accommodationImages|commonAreaImages):\s*\[(.*)\],\s*$",
                     line)
        if m and 'picsum.photos' in m.group(3):
            out.append(f"{m.group(1)}{m.group(2)}: [],")
            cleared += 1
            i += 1
            continue

        # 形态 B：多行列表（images: [ 单独一行）
        # 同时支持 accommodationImages / commonAreaImages: const [ 这种形态
        m = re.match(r"^(\s*)(images|accommodationImages|commonAreaImages):\s*"
                     r"(const\s*)?\[\s*$", line)
        if m:
            field = m.group(2)
            is_const = m.group(3) or ''
            # 找到配对的 ']' 行
            j = i + 1
            body = []
            while j < len(lines):
                body.append(lines[j])
                if re.match(r"^\s*\],?\s*$", lines[j]):
                    break
                j += 1
            if j >= len(lines):
                # 没找到配对 ']'，保守起见原样保留，不动
                out.append(line)
                i += 1
                continue
            content = '\n'.join(body)
            has_asset = ASSET_RE.search(content)
            has_picsum = 'picsum.photos' in content
            # 只有 images 字段的 assets 引用（picsum 随机图）需要清；
            # accommodationImages / commonAreaImages 里的 assets 引用是【真实照片】
            # （s251/s262 的浮屋实拍），必须保留。
            if field == 'images':
                should_clear = bool(has_asset) and sid not in KEEP_REAL
                if sid in KEEP_REAL and has_asset:
                    kept += len(ASSET_RE.findall(content))
            else:
                should_clear = has_picsum
                if has_asset:
                    kept += len(ASSET_RE.findall(content))
            if should_clear:
                out.append(f"{m.group(1)}{field}: {is_const}[],")
                cleared += 1
            else:
                out.append(line)
                out.extend(body)
            i = j + 1
            continue

        out.append(line)
        i += 1

    return '\n'.join(out), cleared, kept


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    text = io.open(SRC, encoding='utf-8').read()
    before_refs = len(ASSET_RE.findall(text))
    new_text, cleared, kept = process(text)
    after_refs = len(ASSET_RE.findall(new_text))

    print(f'原 assets 引用总数：{before_refs}')
    print(f'清空的 images 列表：{cleared} 个')
    print(f'保留的真实实拍引用：{kept} 处')
    print(f'新文件 assets 引用总数：{after_refs}')
    print(f'新文件 picsum 引用总数：{len(re.findall(r"picsum.photos", new_text))}\n')

    if a.dry_run:
        print('（dry-run，未改动文件）')
        return 0

    # 语法自检：括号配平 + 关键结构还在
    if new_text.count('(') != new_text.count(')'):
        print(f'{RED}✗{OFF} 括号不配平（{new_text.count("(")} vs {new_text.count(")")}）—— 中止！')
        return 1
    if 'Spot(' not in new_text or 'class SpotService' not in new_text:
        print(f'{RED}✗{OFF} 关键结构丢失 —— 中止！')
        return 1

    io.open(SRC, 'w', encoding='utf-8').write(new_text)
    print(f'{GREEN}✓{OFF} 已写入 {SRC}')
    print('  请跑 flutter analyze 复核')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())