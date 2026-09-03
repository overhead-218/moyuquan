import 'package:flutter/material.dart';

/// 会员中心页
class MemberCenterPage extends StatelessWidget {
  const MemberCenterPage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kGoldLight = Color(0xFFE0B670);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _benefits = [
    {'icon': '🎣', 'title': '优先推荐', 'desc': '作品获得更多曝光'},
    {'icon': '📊', 'title': '数据报告', 'desc': '每月渔获数据分析'},
    {'icon': '🗺️', 'title': '专属钓点', 'desc': '会员专属野钓路线'},
    {'icon': '🎁', 'title': '商城折扣', 'desc': '装备商城9折优惠'},
    {'icon': '🏆', 'title': '线下活动', 'desc': '优先参与钓友聚会'},
    {'icon': '💬', 'title': '专属客服', 'desc': '7×24小时专属服务'},
  ];

  static const _plans = [
    {'name': '月度会员', 'price': '¥28', 'period': '/月', 'tag': ''},
    {'name': '年度会员', 'price': '¥198', 'period': '/年', 'tag': '推荐'},
    {'name': '永久会员', 'price': '¥398', 'period': '永久', 'tag': '超值'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '会员中心',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前会员状态
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGold, _kGoldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kGold.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '黄金钓手 Lv.5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '有效期至 2027-07-31 · 距离到期还有 365 天',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 会员权益标题
            const Row(
              children: [
                Icon(Icons.card_giftcard, color: _kPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  '会员权益',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 权益网格
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _benefits.length,
              itemBuilder: (context, i) {
                final b = _benefits[i];
                return _BenefitCell(
                  icon: b['icon'] as String,
                  title: b['title'] as String,
                  desc: b['desc'] as String,
                );
              },
            ),
            const SizedBox(height: 28),
            // 升级套餐标题
            const Row(
              children: [
                Icon(Icons.upgrade, color: _kPrimary, size: 20),
                SizedBox(width: 8),
                Text(
                  '升级套餐',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // 套餐列表
            ...List.generate(_plans.length, (i) {
              final p = _plans[i];
              final isRecommended = p['tag'] == '推荐';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(
                  name: p['name'] as String,
                  price: p['price'] as String,
                  period: p['period'] as String,
                  tag: p['tag'] as String,
                  recommended: isRecommended,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BenefitCell extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;

  const _BenefitCell({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final String tag;
  final bool recommended;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.tag,
    required this.recommended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: recommended
            ? Border.all(color: const Color(0xFFC49A5E), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          if (tag.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFC49A5E).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC49A5E),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '解锁全部会员权益',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC49A5E),
                    ),
                  ),
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC49A5E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('会员功能即将上线，敬请期待'),
                    duration: const Duration(seconds: 2),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: recommended
                      ? const Color(0xFFC49A5E)
                      : const Color(0xFF0A7C74),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  recommended ? '立即开通' : '购买',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
