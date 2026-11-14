# -*- coding: utf-8 -*-
"""把 catch_page.dart 中 4 个硬编码装备列表替换为真实云库数据（EquipService）。"""
import io

P = 'lib/pages/catch_page.dart'
with io.open(P, encoding='utf-8') as f:
    src = f.read()
lines = src.splitlines(True)

RODS = (1320, 2668)
REELS = (2711, 4059)
LURES = (4103, 4204)
BAITS = (4274, 4375)

repl_rods = """  /// 真实鱼竿数据：来自云库 equips 表（真实商品），不再是硬编码编造数据
  List<_EquipItem> get _rods => EquipService.allRods().map(_equipToCard).toList();
"""

repl_reels = """  /// 真实卷线器数据：来自云库 equips 表
  List<_EquipItem> get _reels => EquipService.allReels().map(_equipToCard).toList();
"""

repl_lures = """  /// 真实软饵/拟饵数据：来自云库 equips 表
  List<_EquipItem> get _lures =>
      EquipService.byCategory('lure').map(_equipToCard).toList();
"""

repl_baits = """  /// 真实小药/饵料数据：来自云库 equips 表（无数据时展示空态）
  List<_EquipItem> get _baits =>
      EquipService.byCategory('bait').map(_equipToCard).toList();
"""

# 从后往前替换，避免行号漂移
for (s, e), r in [((BAITS), repl_baits), ((LURES), repl_lures),
                  ((REELS), repl_reels), ((RODS), repl_rods)]:
    lines[s - 1:e] = [r]

out = ''.join(lines)

# 追加转换函数
converter = """
/// 云库 EquipItem → 卡片展示模型
_EquipItem _equipToCard(EquipItem e) {
  final type = _equipTypeLabel(e);
  final tags = <String>[
    if (e.brand.isNotEmpty) e.brand,
    if (e.brandSeries.isNotEmpty) e.brandSeries,
    if (e.handle.isNotEmpty) e.handle,
    if (e.sections.isNotEmpty) e.sections,
    if (e.reelType.isNotEmpty) e.reelType,
    if (e.hand.isNotEmpty) '${e.hand}手',
    if (e.waterType.isNotEmpty) e.waterType,
    ...e.tags.take(3),
  ];
  return _EquipItem(
    name: e.fullName,
    spec: e.model.isNotEmpty ? e.model : e.specText,
    type: type,
    waterType: e.waterType.isEmpty ? '通用' : e.waterType,
    score: e.score,
    heat: e.heat,
    replies: e.replyCount,
    tags: tags.take(6).toList(),
    imageUrl: e.imageUrl.isEmpty ? null : e.imageUrl,
    gallery: e.gallery,
    desc: e.description,
  );
}

/// 依据装备字段推导中文分类标签
String _equipTypeLabel(EquipItem e) {
  if (e.handle.isNotEmpty && e.sections.isNotEmpty) {
    return '路亚竿 · ${e.handle} · ${e.sections}';
  }
  if (e.handle.isNotEmpty) return '路亚竿 · ${e.handle}';
  if (e.sections.isNotEmpty) return '竿 · ${e.sections}';
  if (e.hand.isNotEmpty && e.reelType.isNotEmpty) {
    return '${e.reelType} · ${e.hand}手';
  }
  if (e.reelType.isNotEmpty) return e.reelType;
  return e.category;
}
"""
out = out.rstrip() + '\n' + converter

with io.open(P, 'w', encoding='utf-8') as f:
    f.write(out)
print('patched ok')