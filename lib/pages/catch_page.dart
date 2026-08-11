import 'package:flutter/material.dart';
import '../models/catch_item.dart';
import '../services/catch_service.dart';
import 'catch_detail_page.dart';

/// 鱼获页：多维度榜单（Bassmaster风格）
class CatchPage extends StatefulWidget {
  const CatchPage({super.key});

  @override
  State<CatchPage> createState() => _CatchPageState();
}

class _CatchPageState extends State<CatchPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _currentCity = '昆明'; // 后续可从用户定位获取

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

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
              icon: const Icon(Icons.info_outline,
                  color: Color(0xFF0A7C74), size: 22),
              onPressed: () => _showRules(context),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF0A7C74),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0A7C74),
          unselectedLabelColor: const Color(0xFF999999),
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '重量榜'),
            Tab(text: '赛季榜'),
            Tab(text: '新秀榜'),
            Tab(text: '同城榜'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _WeightRankingTab(),
          _SeasonRankingTab(),
          _RookieRankingTab(),
          _CityRankingTab(city: _currentCity),
        ],
      ),
    );
  }

  void _showRules(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('榜单规则', style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            )),
            const SizedBox(height: 16),
            _ruleItem('🏆 重量榜', '单尾最重，大鱼认证≥5kg'),
            _ruleItem('⭐ 赛季榜', '积分累计：发帖+1，获赞+1，大鱼认证+10'),
            _ruleItem('🌱 新秀榜', '注册30天内独立赛道'),
            _ruleItem('📍 同城榜', '当前城市重量排名'),
            const SizedBox(height: 12),
            const Text('参考 Bassmaster Angler of the Year 赛制',
                style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
          ],
        ),
      ),
    );
  }

  Widget _ruleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          )),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
          ))),
        ],
      ),
    );
  }
}

/// 重量榜Tab
class _WeightRankingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ranking = CatchService.weightRanking(limit: 20);
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHero('重量榜', '单尾最重，大鱼认证', '🏋️'),
        const SizedBox(height: 16),
        for (var i = 0; i < ranking.length; i++)
          _WeightCard(
            item: ranking[i],
            rank: i + 1,
            delay: i * 60,
          ),
      ],
    );
  }

  Widget _buildHero(String title, String subtitle, String emoji) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0B670).withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(34),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 36)),
          ),
        ],
      ),
    );
  }
}

/// 赛季榜Tab
class _SeasonRankingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ranking = CatchService.seasonRanking(limit: 20);
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHeader('赛季榜', '积分累计制，稳定性优先'),
        const SizedBox(height: 12),
        for (var i = 0; i < ranking.length; i++)
          _SeasonCard(
            data: ranking[i],
            rank: i + 1,
            delay: i * 50,
          ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A7C74).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.leaderboard, color: Color(0xFF0A7C74), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 新秀榜Tab
class _RookieRankingTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ranking = CatchService.rookieRanking(limit: 20);
    
    if (ranking.isEmpty) {
      return _buildEmpty('暂无新秀数据', '新注册钓友快来发第一条鱼获吧！');
    }
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHeader('新秀榜', '注册30天内独立赛道'),
        const SizedBox(height: 12),
        for (var i = 0; i < ranking.length; i++)
          _SeasonCard(
            data: ranking[i],
            rank: i + 1,
            delay: i * 50,
            isRookie: true,
          ),
      ],
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFC49A5E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.spa, color: Color(0xFFC49A5E), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                )),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF999999),
          )),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFBBBBBB),
          )),
        ],
      ),
    );
  }
}

/// 同城榜Tab
class _CityRankingTab extends StatelessWidget {
  final String city;
  
  const _CityRankingTab({required this.city});
  
  @override
  Widget build(BuildContext context) {
    final ranking = CatchService.cityRanking(city, limit: 20);
    
    if (ranking.isEmpty) {
      return _buildEmpty(city);
    }
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _buildHeader(city),
        const SizedBox(height: 12),
        for (var i = 0; i < ranking.length; i++)
          _WeightCard(
            item: ranking[i],
            rank: i + 1,
            delay: i * 60,
          ),
      ],
    );
  }

  Widget _buildHeader(String city) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A7C74).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF0A7C74), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$city · 鱼获榜', style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            )),
          ),
          Text('实时更新', style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          )),
        ],
      ),
    );
  }

  Widget _buildEmpty(String city) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('$city 暂无鱼获', style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF999999),
          )),
          const SizedBox(height: 8),
          const Text('快来发布第一条吧！', style: TextStyle(
            fontSize: 13,
            color: Color(0xFFBBBBBB),
          )),
        ],
      ),
    );
  }
}

/// 重量卡片
class _WeightCard extends StatefulWidget {
  final CatchItem item;
  final int rank;
  final int delay;
  
  const _WeightCard({
    required this.item,
    required this.rank,
    required this.delay,
  });
  
  @override
  State<_WeightCard> createState() => _WeightCardState();
}

class _WeightCardState extends State<_WeightCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
        ? const Color(0xFFC49A5E)
        : widget.rank == 2
            ? const Color(0xFFB0B6BC)
            : widget.rank == 3
                ? const Color(0xFFCD7F32)
                : const Color(0xFFE6F2F0);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CatchDetailPage(
                      name: widget.item.userName,
                      avatar: '🎣',
                      fish: widget.item.fish,
                      weight: '${(widget.item.weight * 2).toStringAsFixed(1)}斤',
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
                      ? Border.all(color: rankColor.withValues(alpha: 0.35), width: 1.5)
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isTop3
                              ? LinearGradient(
                                  colors: [
                                    rankColor.withValues(alpha: 0.95),
                                    rankColor.withValues(alpha: 0.72),
                                  ],
                                )
                              : null,
                          color: isTop3 ? null : const Color(0xFFE6F2F0),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: isTop3
                            ? const Icon(Icons.emoji_events, color: Colors.white, size: 20)
                            : Text(
                                '${widget.rank}',
                                style: const TextStyle(
                                  color: Color(0xFF0A7C74),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      // 用户信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.item.userName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                if (widget.item.verified) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4458).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '已认证',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFF4458),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.item.fish} · ${widget.item.spotName ?? "未知钓点"}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 重量
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(widget.item.weight * 2).toStringAsFixed(1)}斤',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A7C74),
                            ),
                          ),
                          Text(
                            '${widget.item.weight.toStringAsFixed(1)}kg',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
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

/// 赛季/新秀卡片
class _SeasonCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int rank;
  final int delay;
  final bool isRookie;
  
  const _SeasonCard({
    required this.data,
    required this.rank,
    required this.delay,
    this.isRookie = false,
  });
  
  @override
  State<_SeasonCard> createState() => _SeasonCardState();
}

class _SeasonCardState extends State<_SeasonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
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
    final points = widget.data['points'] as int;
    final userName = widget.data['userName'] as String;
    
    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTop3
                      ? const Color(0xFFC49A5E).withValues(alpha: 0.3)
                      : const Color(0xFFEDEAE3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // 排名
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isTop3
                            ? const Color(0xFFC49A5E).withValues(alpha: 0.15)
                            : const Color(0xFFF7F3EE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${widget.rank}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isTop3
                              ? const Color(0xFFC49A5E)
                              : const Color(0xFF666666),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 用户
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    // 积分
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isRookie
                            ? const Color(0xFFC49A5E).withValues(alpha: 0.12)
                            : const Color(0xFF0A7C74).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$points 积分',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: widget.isRookie
                              ? const Color(0xFFC49A5E)
                              : const Color(0xFF0A7C74),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
