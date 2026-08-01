import 'package:flutter/material.dart';

/// 鱼获详情页
class CatchDetailPage extends StatelessWidget {
  final String name;
  final String avatar;
  final String fish;
  final String weight;
  final int rank;

  const CatchDetailPage({
    super.key,
    required this.name,
    required this.avatar,
    required this.fish,
    required this.weight,
    required this.rank,
  });

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // 渐变头部 AppBar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kSurface.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kDarkTeal, _kLightTeal, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // 排名徽标
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _kSurface.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kGold.withValues(alpha: 0.6),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(avatar, style: const TextStyle(fontSize: 32)),
                            Text(
                              '第$rank名',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '🏆 $weight',
                          style: const TextStyle(
                            color: _kGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 内容区
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 鱼种信息卡
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.set_meal, color: _kPrimary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '鱼种信息',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('鱼种', fish),
                        const SizedBox(height: 10),
                        _buildInfoRow('重量', weight),
                        const SizedBox(height: 10),
                        _buildInfoRow('排名', '本月第 $rank 名'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 渔获记录
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: _kPrimary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '渔获记录',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecordItem('🎣', '大鲈鱼', '3.2斤', '今天 06:30'),
                        const SizedBox(height: 10),
                        _buildRecordItem('🐟', '青鱼', '5.6斤', '昨天 17:20'),
                        const SizedBox(height: 10),
                        _buildRecordItem('🦈', '黑鱼', '2.8斤', '7月28日'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 互动按钮
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.favorite_border,
                          label: '点赞',
                          color: const Color(0xFFFF4757),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.person_add_outlined,
                          label: '关注',
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_outlined,
                          label: '分享',
                          color: _kTextWeak,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: _kShadow.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: _kTextWeak),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordItem(String emoji, String fish, String weight, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kTealBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fish,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: _kTextWeak),
                ),
              ],
            ),
          ),
          Text(
            weight,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kGold,
            ),
          ),
        ],
      ),
    );
  }
}

const _kSurfaceCD = Color(0xFFFFFFFF);
const _kShadowCD = Color(0xFF1A1A1A);

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _kSurfaceCD,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 2),
            blurRadius: 8,
            color: _kShadowCD.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
