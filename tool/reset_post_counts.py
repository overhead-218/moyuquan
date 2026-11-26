# -*- coding: utf-8 -*-
"""把 posts 表的 likeCount / commentCount 聚合字段重置为真实计数。

背景（2026-11-26）：种子帖子的 likeCount（1024/891/...）和 commentCount
（156/102/...）是编出来的假数，post_likes / post_comments 表实际是 0 条。
用户在详情页看到「15 条评论」下面却是空态 —— 数据自相矛盾。

原则：聚合字段以明细表为准。本脚本幂等（已是真实值就跳过）。

用法：python tool/reset_post_counts.py
"""
import io
import json
import os
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CFG = os.path.join(ROOT, 'lib', 'services', 'backend_config.dart')

KEY = re.search(r"publishableKey\s*=\s*'([^']+)'",
                io.open(CFG, encoding='utf-8').read()).group(1)
BASE = ('https://moyuquan-d5g0pvpcw55f8a62e.api.tcloudbasegateway.com'
        '/v1/rdb/rest')


def req(path, method='GET', body=None):
    r = urllib.request.Request(
        BASE + path,
        data=json.dumps(body).encode('utf-8') if body else None,
        headers={'Authorization': 'Bearer ' + KEY,
                 'Content-Type': 'application/json'},
        method=method)
    with urllib.request.urlopen(r, timeout=60) as resp:
        raw = resp.read()
    return json.loads(raw) if raw else []


def main():
    posts = req('/posts?select=id,likeCount,commentCount&limit=1000')
    print(f'posts 共 {len(posts)} 条')

    # 明细表真实计数
    likes = req('/post_likes?select=postId&limit=1000')
    comments = req('/post_comments?select=postId&limit=1000')
    like_n, com_n = {}, {}
    for r in likes:
        pid = r.get('postId') or ''
        like_n[pid] = like_n.get(pid, 0) + 1
    for r in comments:
        pid = r.get('postId') or ''
        com_n[pid] = com_n.get(pid, 0) + 1

    fixed = skipped = 0
    for p in posts:
        pid = p['id']
        real_like = like_n.get(pid, 0)
        real_com = com_n.get(pid, 0)
        cur_like = p.get('likeCount') or 0
        cur_com = p.get('commentCount') or 0
        if cur_like == real_like and cur_com == real_com:
            skipped += 1
            continue
        patch = {}
        if cur_like != real_like:
            patch['likeCount'] = real_like
        if cur_com != real_com:
            patch['commentCount'] = real_com
        try:
            req(f'/posts?id=eq.{pid}', method='PATCH', body=patch)
            fixed += 1
            print(f'  修正 {pid}: 赞 {cur_like}→{real_like}，'
                  f'评论 {cur_com}→{real_com}')
        except Exception as e:  # noqa: BLE001
            print(f'  ✗ {pid} 写入失败: {e}')

    print(f'完成：修正 {fixed} 条，已一致跳过 {skipped} 条')


if __name__ == '__main__':
    sys.exit(main())
