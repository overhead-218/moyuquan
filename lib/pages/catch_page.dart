import 'package:flutter/material.dart';
import 'catch_detail_page.dart';

/// 鱼获页：排行榜 + 入场动画
class CatchPage extends StatefulWidget {
  const CatchPage({super.key});

  @override
  State<CatchPage> createState() => _CatchPageState();
}

class _CatchPageState extends State<CatchPage> {
  final _rankings = [
    {'rank': 1, 'name': '海钓阿强', 'fish': '蓝鳍金枪鱼', 'weight': '328.5斤', 'avatar': '🎣'},
    {'rank': 2, 'name': '钓鱼王', 'fish': '青鱼', 'weight': '128.6斤', 'avatar': '🐟'},
    {'rank': 3, 'name': '老李', 'fish': '草鱼', 'weight': '96.2斤', 'avatar': '🦈'},
    {'rank': 4, 'name': '阿飞', 'fish': '鲶鱼', 'weight': '82.3斤', 'avatar': '🐠'},
    {'rank': 5, 'name': '菜鸟', 'fish': '鲤鱼', 'weight': '68.8斤', 'avatar': '🎣'},
    {'rank': 6, 'name': '野钓大叔', 'fish': '黑鱼', 'weight': '54.1斤', 'avatar': '🦑'},
    {'rank': 7, 'name': '江南老饕', 'fish': '桂花鱼', 'weight': '42.7斤', 'avatar': '🎣'},
    {'rank': 8, 'name': '渔民小张', 'fish': '鲈鱼', 'weight': '38.9斤', 'avatar': '🐟'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '鱼获榜',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF0A7C74), size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const _RankingHero(),
          const SizedBox(height: 20),
          const _SectionLabel(),
          const SizedBox(height: 12),
          for (var i = 0; i < _rankings.length; i++)
            _RankingCard(
              rank: _rankings[i]['rank'] as int,
              name: _rankings[i]['name'] as String,
              fish: _rankings[i]['fish'] as String,
              weight: _rankings[i]['weight'] as String,
              avatar: _rankings[i]['avatar'] as String,
              delay: i * 80,
            ),
        ],
      ),
    );
  }
}

/// 榜单头部渐变 hero
class _RankingHero extends StatelessWidget {
  const _RankingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075C56), Color(0xFF148F86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A7C74).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0B670).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFFE0B670).withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    '本月赛季',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE0B670),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '大鱼榜',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '看看谁钓上了今年最大的那条',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(34),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.emoji_events,
              size: 36,
              color: Color(0xFFE0B670),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF0A7C74),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '排行榜',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        const Text(
          '实时更新',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
        ),
      ],
    );
  }
}

class _RankingCard extends StatefulWidget {
  final int rank;
  final String name;
  final String fish;
  final String weight;
  final String avatar;
  final int delay;

  const _RankingCard({
    required this.rank,
    required this.name,
    required this.fish,
    required this.weight,
    required this.avatar,
    required this.delay,
  });

  @override
  State<_RankingCard> createState() => _RankingCardState();
}

class _RankingCardState extends State<_RankingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTop3 = widget.rank <= 3;
    final rankColor = widget.rank == 1
        ? const Color(0xFFC49A5E) // 金
        : widget.rank == 2
            ? const Color(0xFFB0B6BC) // 银
            : widget.rank == 3
                ? const Color(0xFFCD7F32) // 铜
                : const Color(0xFFE6F2F0);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              splashColor: const Color(0xFF0A7C74).withValues(alpha: 0.06),
              highlightColor: const Color(0xFFE6F2F0).withValues(alpha: 0.5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CatchDetailPage(
                      name: widget.name,
                      avatar: widget.avatar,
                      fish: widget.fish,
                      weight: widget.weight,
                      rank: widget.rank,
                    ),
                  ),
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isTop3
                      ? Border.all(
                          color: rankColor.withValues(alpha: 0.35),
                          width: 1.5,
                        )
                      : Border.all(color: const Color(0xFFEDEAE3)),
                  boxShadow: [
                    BoxShadow(
                      color: isTop3
                          ? rankColor.withValues(alpha: 0.12)
                          : const Color(0xFF000000).withValues(alpha: 0.04),
                      blurRadius: isTop3 ? 16 : 8,
                      offset: Offset(0, isTop3 ? 4 : 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 排名徽标
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: isTop3
                              ? LinearGradient(
                                  colors: [
                                    rankColor.withValues(alpha: 0.95),
                                    rankColor.withValues(alpha: 0.72),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isTop3 ? null : const Color(0xFFE6F2F0),
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: isTop3
                              ? [
                                  BoxShadow(
                                    color: rankColor.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: isTop3
                            ? const Icon(Icons.emoji_events,
                                color: Colors.white, size: 22)
                            : Text(
                                '${widget.rank}',
                                style: const TextStyle(
                                  color: Color(0xFF0A7C74),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      // 头像
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F2F0),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.avatar,
                            style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      // 用户信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                                if (widget.rank == 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC49A5E)
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'TOP',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFC49A5E),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F2F0),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    widget.fish,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF075C56),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.weight,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isTop3
                                        ? const Color(0xFFC49A5E)
                                        : const Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFF999999), size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
