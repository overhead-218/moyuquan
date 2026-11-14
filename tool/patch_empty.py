# -*- coding: utf-8 -*-
import io
P='lib/pages/catch_page.dart'
s=io.open(P,encoding='utf-8').read()

old="""        for (var i = 0; i < items.length; i++)
          _EquipCard(item: items[i], rank: i + 1, delay: i * 35),"""
new="""        if (items.isEmpty) const _EquipEmptyState(),
        for (var i = 0; i < items.length; i++)
          _EquipCard(item: items[i], rank: i + 1, delay: i * 35),"""
n=s.count(old)
assert n==4, n
s=s.replace(old,new)

empty_class = '''

/// 装备空态：云库还没有真实商品数据时如实提示，不再用假数据填充
class _EquipEmptyState extends StatelessWidget {
  const _EquipEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          const Text('暂无真实装备数据',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
          const SizedBox(height: 6),
          const Text('装备库由运营后台导入，当前还未同步',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
'''
s = s.rstrip() + '\n' + empty_class
io.open(P,'w',encoding='utf-8').write(s)
print('ok')
