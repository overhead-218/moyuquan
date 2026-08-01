import 'package:flutter/material.dart';
import 'spot_detail_page.dart';

/// 地图：UI骨架（待接入SDK）
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '钓点地图',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween<double>(begin: 0.9, end: 1),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _buildMapPlaceholder(),
              const SizedBox(height: 20),
              const Text(
                '附近钓点',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildSpotCard(context, '🎣', '青龙湖野钓点', '鲈鱼 · 鲫鱼 · 距离 1.2km'),
              const SizedBox(height: 16),
              _buildSpotCard(context, '🐟', '东海岸矶钓区', '海鲈 · 黑鲷 · 距离 3.5km'),
              const SizedBox(height: 16),
              _buildSpotCard(context, '🦑', '西山溪流水域', '溪哥 · 马口 · 距离 5.0km'),
            ],
          ),
        ),
      ),
    );
  }

  /// 地图占位区：渐变 + 圆角20 + lg 柔阴影
  Widget _buildMapPlaceholder() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kLightTeal,
            _kDarkTeal,
          ],
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 8),
            blurRadius: 24,
            color: _kShadow.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _kSurface.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 56,
                    color: _kSurface,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '地图组件待接入',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '接入地图 SDK 后展示钓点分布',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          // 钓点标记卡片：白底 + 圆角14 + md 柔阴影
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                    color: _kShadow.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place, size: 18, color: _kPrimary),
                  SizedBox(width: 6),
                  Text(
                    '热门钓点 · 1.2km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 钓点卡片：白底 + 圆角16 + md 柔阴影 + 点击区≥56
  Widget _buildSpotCard(BuildContext context, String emoji, String title, String meta) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpotDetailPage(
              name: title,
              emoji: emoji,
              meta: meta,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 16,
              color: _kShadow.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _kTealBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextWeak,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: _kTextWeak,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
