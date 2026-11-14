# -*- coding: utf-8 -*-
"""清理静态托管里误传的垃圾前缀文件。

起因：在 Git Bash 下跑 `tcb hosting deploy build/web /`，MSYS 把 `/` 前的路径
当成本地路径转换，cloudPath 被解析成
  D:/Program Files/wb/WorkBuddy/resources/vendor/PortableGit/
于是 299 个文件被传到该前缀下（`hosting delete <dir>` 对这种含空格的目录批量删无效，
但按完整 key 单文件删有效，故这里逐个删）。

⚠️ 删除时必须带 MSYS_NO_PATHCONV=1，否则 key 里的斜杠会被再次转换而找不到对象。

用法：python tool/clean_hosting_junk.py --dry-run
"""
import argparse
import os
import re
import subprocess
import sys

ENV = 'moyuquan-d5g0pvpcw55f8a62e'
JUNK = 'D:/Program Files/wb/WorkBuddy/resources/vendor/PortableGit/'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ANSI = re.compile(r'\x1b\[[0-9;]*m')


def run(args):
    # 必须 shell=True：tcb.cmd 在 Git Bash 下用 list 方式调用拿不到 stdout
    env = dict(os.environ, MSYS_NO_PATHCONV='1', MSYS2_ARG_CONV_EXCL='*')
    cmd = 'tcb.cmd ' + ' '.join(f'"{a}"' if ' ' in a else a for a in args)
    p = subprocess.run(cmd, capture_output=True, text=True, shell=True,
                       encoding='utf-8', errors='replace', env=env)
    return (p.stdout or '') + (p.stderr or '')


def list_keys():
    out = run(['hosting', 'list', '/', '-e', ENV])
    keys = []
    for line in ANSI.sub('', out).splitlines():
        # 表格行形如： │ 296 │ <key> │ <date> │ "<etag>" │ <size> │
        if '│' not in line:
            continue
        parts = [c.strip() for c in line.split('│')]
        if len(parts) >= 3 and parts[1].isdigit() and parts[2]:
            keys.append(parts[2])
    return keys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    keys = list_keys()
    junk = [k for k in keys if k.startswith(JUNK)]
    print(f'远端共 {len(keys)} 个文件，其中垃圾前缀 {len(junk)} 个')
    if not junk:
        print('✓ 无需清理')
        return 0
    if a.dry_run:
        for k in junk[:10]:
            print('  将删除', k)
        if len(junk) > 10:
            print(f'  ... 其余 {len(junk) - 10} 个')
        return 0

    ok = 0
    for i, k in enumerate(junk, 1):
        out = run(['hosting', 'delete', k, '-e', ENV])
        if 'deleted successfully' in out:
            ok += 1
        else:
            print(f'  ✗ {k}: {out.strip()[-120:]}')
        if i % 30 == 0:
            print(f'  ... {i}/{len(junk)}')
    print(f'\n已删除 {ok}/{len(junk)}')
    print(f'剩余垃圾文件: {len([k for k in list_keys() if k.startswith(JUNK)])}')
    return 0 if ok == len(junk) else 1


if __name__ == '__main__':
    sys.exit(main())