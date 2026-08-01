import 'package:flutter/material.dart';

/// 历史钓点页
class HistoryPlacesPage extends StatelessWidget {
  const HistoryPlacesPage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _places = [
    {
      'name': '南京·紫金山野钓点',
      'dist': '1.2km',
      'fish': '鲈鱼 · 鲫鱼 · 鲤鱼',
      'stars': '4.8',
      'times': '12次',
      'emoji': '🎣',
      'date': '2026-07-28',
    },
    {
      'name': '扬州·邵伯湖休闲钓',
      'dist': '38km',
      'fish': '草鱼 · 青鱼 · 鳊鱼',
      'stars': '4.5',
      'times': '8次',
      'emoji': '🐟',
      'date': '2026-07-15',
    },
    {
      'name': '苏州·阳澄湖蟹塘',
      'dist': '95km',
      'fish': '大闸蟹 · 鳜鱼',
      'stars': '4.3',
      'times': '3次',
      'emoji': '🦀',
      'date': '2026-06-20',
    },
    {
      'name': '舟山·东极岛矶钓',
      'dist': '320km',
      'fish': '海鲈 · 黑鲷 · 石斑',
      'stars': '4.9',
      'times': '5次',
      'emoji': '🚤',
      'date': '2026-05-10',
    },
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
          '历史钓点',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, color: _kPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                _StatPill(icon: Icons.location_on, value: '28', label: '累计钓点'),
                const SizedBox(width: 12),
                _StatPill(icon: Icons.calendar_today, value: '86', label: '出钓次数'),
                const SizedBox(width: 12),
                _StatPill(icon: Icons.star, value: '4.7', label: '平均评分'),
              ],
            ),
          ),
          // 钓点列表
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: _places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = _places[i];
                return _PlaceCard(
                  emoji: p['emoji'] as String,
                  name: p['name'] as String,
                  dist: p['dist'] as String,
                  fish: p['fish'] as String,
                  stars: p['stars'] as String,
                  times: p['times'] as String,
                  date: p['date'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
          children: [
            Icon(icon, color: const Color(0xFF0A7C74), size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A7C74),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String dist;
  final String fish;
  final String stars;
  final String times;
  final String date;

  const _PlaceCard({
    required this.emoji,
    required this.name,
    required this.dist,
    required this.fish,
    required this.stars,
    required this.times,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 图标
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F2F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            dist,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fish,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Color(0xFFC49A5E)),
                          const SizedBox(width: 2),
                          Text(
                            stars,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC49A5E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.repeat,
                              size: 12, color: Color(0xFF999999)),
                          const SizedBox(width: 2),
                          Text(
                            '$times · $date',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF999999), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
