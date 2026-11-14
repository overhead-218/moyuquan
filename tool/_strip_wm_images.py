# -*- coding: utf-8 -*-
"""一次性代码改写：把 post_service.dart 里 38 处 wm_*.jpg 假图从 mock 里删掉。

这些帖子（"二十年没见过的野生甲鱼"、"凌晨四点的滁河"…）配的是多帖共用的
通用钓鱼图池 wm_01.jpg~wm_35.jpg，并不是这些帖子的真实配图。与 spots / 云库
已清洗的口径保持一致：宁可无图，也不要拿通用图冒充实景。

删法：整行移除 `imageUrl:'...wm_XX.jpg', height:NNN,`，让 Post 走 imageUrl:''
的默认空值，UI 显示诚实占位。官方引导帖的 off_*.png 不动。
"""
import io
import re

P = 'lib/services/post_service.dart'
s = io.open(P, encoding='utf-8').read()

pat = re.compile(r"^[ \t]*imageUrl:'[^']*/images/spots/wm_\d+\.jpg', height:\d+,\n", re.M)
hits = pat.findall(s)
new, n = pat.subn('', s)

if n:
    io.open(P, 'w', encoding='utf-8').write(new)
print(f'removed {n} wm imageUrl lines')
print(f'remaining wm_ occurrences: {new.count("wm_")}')
