import 'package:flutter/material.dart';
import 'catch_detail_page.dart';

/// 我的鱼获
class MyCatchPage extends StatelessWidget {
  const MyCatchPage({super.key});

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

  static const _catches = [
    {'fish': '蓝鳍金枪鱼', 'weight': '328.5斤', 'emoji': '🐟', 'rank': 1, 'time': '2026年7月'},
    {'fish': '青鱼', 'weight': '128.6斤', 'emoji': '🦈', 'rank': 2, 'time': '2026年6月'},
    {'fish': '草鱼', 'weight': '96.2斤', 'emoji': '🐠', 'rank': 3, 'time': '2026年5月'},
    {'fish': '鲶鱼', 'weight': '82.3斤', 'emoji': '🐡', 'rank': 4, 'time': '2026年4月'},
    {'fish': '鲤鱼', 'weight': '68.8斤', 'emoji': '🎣', 'rank': 5, 'time': '2026年3月'},
    {'fish': '黑鱼', 'weight': '54.1斤', 'emoji': '🐟', 'rank': 6, 'time': '2026年2月'},
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
          '我的鱼获',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _kPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 总计卡
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kDarkTeal, _kLightTeal, _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: _kGold, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '累计渔获',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '788.5 斤',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '共 128 种鱼 · 历史最高第 1 名',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 鱼获列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: _catches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = _catches[i];
                return _CatchCard(
                  emoji: c['emoji'] as String,
                  fish: c['fish'] as String,
                  weight: c['weight'] as String,
                  rank: c['rank'] as int,
                  time: c['time'] as String,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CatchDetailPage(
                          name: '老李',
                          avatar: '🎣',
                          fish: c['fish'] as String,
                          weight: c['weight'] as String,
                          rank: c['rank'] as int,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatchCard extends StatelessWidget {
  final String emoji;
  final String fish;
  final String weight;
  final int rank;
  final String time;
  final VoidCallback onTap;

  const _CatchCard({
    required this.emoji,
    required this.fish,
    required this.weight,
    required this.rank,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final rankColor = rank == 1
        ? const Color(0xFFC49A5E)
        : rank == 2
            ? const Color(0xFFB0B6BC)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : const Color(0xFFE6F2F0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: isTop3
              ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 12,
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            // 鱼种图标
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fish,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            // 重量和排名
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  weight,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC49A5E),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isTop3
                        ? rankColor.withValues(alpha: 0.15)
                        : const Color(0xFFE6F2F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '第$rank名',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isTop3 ? rankColor : const Color(0xFF0A7C74),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
